classdef NSx < handle & util.Structable
% NSx Class representing a Blackrock NSx file
%
%   The Blackrock.NSx class provides a convenient interface to reading and
%   writing NSx files. For a NSx file NSXFILE and corresponding map file 
%   MAPFILE, this example shows how to open the file and read the first
%   100 seconds of data:
%
%     >> ns = Blackrock.NSx(NSXFILE,MAPFILE);
%     >> data = ns.read('time',[0 100]);
%
%   Additionally, instantiated objects have numerous properties to
%   represent header information stored in the NSx files, and methods
%   to interact with the files in various ways (see full documentation).
%
%   There are several key concepts that are important to understand when
%   working with NSx files:
%
%   Channel vs. Electrode
%   Most Blackrock products distinguish between channels and electrodes.
%   However, NSx and NEV files store data by CHANNEL numbers despite the
%   fact that the file spec labels the field as the Electrode ID. The NPMK
%   package also uses the file spec field name instead of the actual
%   meaning of the data. To avoid confusion, the Blackrock.NSx class refers
%   to this number as the ChannelID, which is what it actually is. Note
%   that the ChannelID will be the same between NEV and NSx files. If the
%   map file is supplied when instantiating the object, a field
%   "ElectrodeID" will be added which indicates the electrode ID for that
%   channel.
%
%   Data points vs. samples
%   In NSx files, a single data point consists of one 16-bit sample from
%   each of the channels enabled for that sampling rate.
%
%   Data packets
%   In contrast to NEV files, where each event is in its own data packet,
%   NSx files consist of one or more large data packets which contain many
%   data points. The header of each data packet specifies the timestamp of
%   the first data point in the packet, and the number of data points in
%   the packet. The timestamp counter runs at the sampling frequency
%   specified by the property "TimestampTimeResolution" which may be
%   different from the sampling frequency of the data itself ("Fs"
%   property). In some situations, the timestamp counter may be reset, for
%   example when two NSPs synchronize. When this occurs, it is impossible
%   to know the timing of the packet before the reset with respect to the
%   packet after the reset, since there is a pause of unknown length before
%   the counter starts running again. Typically, the number of data points
%   in the pre-sync packet will represent more time than is evident from
%   the timestamps of the two packets.
%
%   Version History
%
%   v1.0 - First numbered version. In use for several years; see SVN log
%   for detailed change information.
    
    properties
        verbosity % verbosity level: 0=> critical, 1=> error, 2=> warning, 3=> info, 4=> hints, 5=> debug
        debug % debug level: 0=> off, 1=> on, 2=> validation
        logfcn % 1x2 cell array of cell arrays; {1}{:} will be passed to feval prior to msg and vb; {2}{:} will be passed to feval after msg and vb
    end % END properties
    
    properties(SetAccess='private',GetAccess='public')
        hArrayMap % handle to Blackrock.ArrayMap object
        
        % source file information
        SourceFileRead = false; % flag to indicate file read successfully
        SourceDirectory
        SourceBasename
        SourceExtension
        SourceFileSize
        
        % Basic Headers
        FileTypeID = 'NEURALEV';
        FileSpecMajor = 2;
        FileSpecMinor = 3;
        BytesInHeaders = 14224;
        Label
        Comment = 'No Original Source Specified';
        TimestampTimeResolution
        TimestampsPerSample = 30e3;
        Fs
        Period
        OriginTimeString
        OriginTimeDatenum
        ChannelCount
        
        % Extended Headers
        ChannelInfo
        
        % Data Packets
        NumDataPackets = 0;
        Timestamps
        PointsPerDataPacket
        DataPacketByteIdx
        
        % miscellaneous
        fs2ttr % conversion between sampling rate and timestamp resolution
        
        % error/warning handling
        warnCount = 0;
        maxWarnCount = 20;
        exitOnWarnThreshold = 1; % 0 => continue; 1 => exit with error;
    end % END properties(SetAccess='private',GetAccess='public')
    
    properties(Constant)
        versionMajor = 1;
        versionMinor = 1;
        BasicHeaderSize = 314; % size of basic headers in bytes
        AllowedFileSpecMajor = 2;
        AllowedFileSpecMinor = 3;
    end % END properties(Constant)
    
    methods
        function this = NSx(varargin)
            
            % verbosity and debug defaults
            [varargin,quietmode] = util.argflag('quiet',varargin,false);
            [this.verbosity,this.debug] = env.get('verbosity','debug');
            if quietmode,this.verbosity=0;end
            
            % capture source file
            src = [];
            srcIdx = cellfun(@(x)ischar(x)&&exist(x,'file')==2&&any(cellfun(@(y)~isempty(regexpi(x,y)),{'.ns1','.ns2','.ns3','.ns4','.ns5','.ns6'})),varargin);
            if any(srcIdx)
                src = varargin{srcIdx};
                varargin(srcIdx) = [];
            end
            assert(~isempty(src),'Must provide a NSx file to load');
            
            % look for array map object
            [varargin,this.hArrayMap,found] = util.argisa('Blackrock.ArrayMap',varargin,nan);
            if ~found
                this.hArrayMap = Blackrock.ArrayMap('quiet');
            end
            
            % look for debugger
            [varargin,this.logfcn,found] = util.argisa('Debug.Debugger',varargin,[]);
            if found
                this.logfcn.registerClient(this,'alias','Blackrock.NSx');
            else
                this.logfcn = {{@internalLog,this},{}};
            end
            
            % process remaining inputs
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % open the file to read basic information (headers, etc.)
            open(this,src);
        end % END function NSx
        
        function [timestampStart,timestampEnd,timestampLen,short,preReset,preSync,zeroLen] = analyzePackets(this)
            % ANALYZEPACKETS Get packet characteristics
            %
            %   [IDXSTART,IDXEND,LEN,SHORT,PRERESET,PRESYNC,ZEROLEN] = ...
            %       ANALYZEPACKETS(THIS)
            %   Get the index of the starting and ending timestamps for
            %   each packet, the length of each packet, and logical
            %   indications whether each packet is short, prior to a clock
            %   reset, prior to a NSP sync, or zero-length.
            
            % define the maximum length of a pre-sync packet. technically should be 3
            % sec or less, but in practice values range as high as 5+ sec (no
            % additional information available on frequency, distribution, etc.)
            lenpresync = 6; % in seconds
            
            % since Timestamps header fields are 0-indexed, we have to
            % differentiate between the timestamp itself and the index into the
            % timestamps. here, convert all packet timing values to
            % TimestampTimeResolution sampling rate, which may be different from the
            % data sampling rate (Fs), and convert from 0-indexed (actual timesetamps)
            % to 1-indexed (index into list of timestamps).
            timestampLen = this.PointsPerDataPacket*this.fs2ttr;
            timestampStart = this.Timestamps; % already in timestamp timer resolution sampling rate
            timestampEnd = timestampStart + timestampLen - 1;
            
            % Downsampling happens on the NSP, but sometimes data samples
            % get lost in transport over the network. When this happens,
            % Central throws up a warning about lost data packets -- this
            % corresponds to samples, not UDP packets or other things.
            % When samples are dropped, Central puts a pause in all files
            % being recorded, which, in the case of NSx files, results in a
            % new data packet. However, sometimes the number of dropped
            % data samples (which are counted at the 30k sampling rate) is
            % less than the number of samples needed to produce one sample
            % at a lower sampling rate. For example, ns3 files at 2k
            % sampling rate effectively need 15 samples at 30k to produce
            % one sample at 2k. In this scenario, if fewer than 15 samples
            % are dropped (you can check the log files for the actual
            % number), the pause in the 2k file (*.ns3) will be shorter
            % than the duration of one sample. In fact, the pause may not
            % even be necessary. Since downsampling runs on the NSP,
            % network drops don't necessarily affect the data being sent
            % over -- only if the segment of dropped packets crosses the
            % boundary between downsampled samples. In other words,
            % downsampling is deterministically timed such that samples
            % come at timestamps 1, 16, 31, 46, ... until the end of the
            % recording. So if 12 samples were dropped between timestamps
            % 2-13, that doesn't cross a boundary and there were no lost 2k
            % samples. But if the 12 samples occurred between timestamps
            % 10-21, that crosses a boundary and one 2k sample was lost.
            % **HACK ALERT** For right now we're going to assume that any
            % difference in timestamps less than a full sample at the local
            % sampling rate is effectively meaningless and that there is no
            % data loss.
%             if length(timestampStart)>1 && this.fs2ttr>1
%                 sep_timestamps = timestampEnd(1:end-1) - timestampStart(2:end);
%                 idx = find(sep_timestamps<this.fs2ttr & sep_timestamps>=0);
%                 if ~isempty(idx)
%                     for kk=1:length(idx)
%                         timestampEnd(idx(kk)) = timestampStart(idx(kk)+1)-1;
%                     end
%                 end
%             end
            
            % sometimes, a data packet will only be one TimestampTimeResolution
            % packet (i.e. 1/30e3 sec) despite the data sampling rate being slower
            % (e.g. 2e3 samples/sec). in this case, the PointsPerDataPacket field
            % would indicate a full 1/2e3 sample, but the Timestamps field would
            % indicate only one 1/30e3 sample difference. the below logic adjusts
            % the packet length to account for these short packets and thereby
            % avoid falsely triggering the pre-sync detection logic.
            short = [diff(timestampStart) 0]>0 & [diff(timestampStart) 0]<this.fs2ttr & this.PointsPerDataPacket==1;
            idx = find(short);
            for kk=1:length(idx)
                
                % new length is the difference in Timestamps
                timestampLen(idx(kk)) = timestampStart(idx(kk)+1)-timestampStart(idx(kk));
                
                % new end subtracts one off the length to account for sample diff
                timestampEnd(idx(kk)) = timestampStart(idx(kk)) + timestampLen(idx(kk)) - 1;
            end
            
            % infer clock reset from nonincreasing timestamps
            if length(timestampStart)>1
                
                % pre-reset packets should contain data points that extend beyond the
                % start of the subsequent packet's start timestamp (b/c clock reset).
                %preReset = [timestampEnd(1:end-1)>timestampStart(2:end) false];
                df = timestampEnd(1:end-1) - timestampStart(2:end);
                preReset = [ df>this.fs2ttr false];
            else
                preReset = false;
            end
            
            % infer pre-sync packets
            if length(timestampStart)>1
                
                % pre-sync packets are (1) pre-reset and (2) short (<5 sec)
                preSync = preReset & timestampLen<lenpresync*this.TimestampTimeResolution;
            else
                preSync = false;
            end
            
            % identify zero-length packets
            zeroLen = this.PointsPerDataPacket==0;
        end % END function analyzePackets
        
        function setArrayMap(this,map)
            % SETARRAYMAP Set the array map for the Blackrock.NSx object
            %
            %   SETARRAYMAP(THIS,MAP)
            %   If MAP is a string containing the full path to a *.cmp
            %   file, creates a new Blackrock.ArrayMap object with the map
            %   file as input.  If MAP is an object of class
            %   'Blackrock.ArrayMap', uses the object directly.  If
            %   ChannelInfo has already been processed, updates the
            %   Electrode ID field with the new ArrayMap.
            
            % either load the map file, or pull in the handle
            if ischar(map) && exist(map,'file')==2 && ~isempty(regexpi(map,'\.cmp$'))
                this.hArrayMap = Blackrock.ArrayMap(map,'quiet');
            elseif isa(map,'Blackrock.ArrayMap')
                this.hArrayMap = map;
            end
            
            % update the electrode ID in the channel info
            if ~isempty(this.ChannelInfo)
                for kk=1:length(this.ChannelInfo)
                    chid = this.ChannelInfo(chid).ChannelID;
                    this.ChannelInfo(chid).ElectrodeID = this.hArrayMap.ch2el(chid);
                end
            end
        end % END function setArrayMap
        
        function Byte = getNearestByteTime(this,time,varargin)
            sample = round(time * this.Fs);
            Byte = this.getNearestByteSample(sample,varargin{:});
        end % END function getTimeNearestByte
        
        function Byte = getNearestByteSample(this,sample,varargin)
            % default to largest segment
            if nargin==2
                [~,segment] = max(this.PointsPerDataPacket);
            elseif nargin>2
                segment = varargin{1};
            end
            
            % calculate offsets
            SegmentStart = this.DataPacketByteIdx(segment,1) + 9; % 9b header
            SampleByte = (sample-1) * this.ChannelCount*2;
            Byte = this.BytesInHeaders + SegmentStart + SampleByte;
            if Byte > this.SourceFileSize
                error('Byte %d larger than NSx file size %d.',Byte,this.SourceFileSize);
            end
        end % END function getSampleNearestByte
        
        function [allPackets,startPackets,middlePackets,endPackets] = getPacketsContainingTime(this,st)
            [allPackets,startPackets,middlePackets,endPackets] = getPacketsContainingTimeWindow(this,st,0);
        end % END function getPacketsContainingTime
        
        function [allPackets,startPackets,middlePackets,endPackets] = getPacketsContainingSample(this,st)
            [allPackets,startPackets,middlePackets,endPackets] = getPacketsContainingSampleWindow(this,st,0);
        end % END function getPacketsContainingSample
        
        function [allPackets,startPackets,middlePackets,endPackets] = getPacketsContainingTimeWindow(this,st,len,ref)
            if nargin<4||isempty(ref),ref='timestamp';end
            st = round(st*this.Fs*this.fs2ttr);
            len = round(len*this.Fs*this.fs2ttr);
            [allPackets,startPackets,middlePackets,endPackets] = getPacketsContainingTimestampWindow(this,st,len,ref);
        end % END function getPacketsContainingTimeWindow
        
        function [allPackets,startPackets,middlePackets,endPackets] = getPacketsContainingSampleWindow(this,st,len,ref)
            % GETPACKETSCONTAININGSAMPLEWINDOW Get packets for a sample window
            if nargin<4||isempty(ref),ref='timestamp';end
            
            % a key difference between data points and timestamps is that
            % data points are 1-indexed (the first sample in the packet is
            % the first data point) whereas timestamps are 0-indexed (the
            % first sample could correspond to a timestamp of 0, 1, or any
            % other number >=0). 
            % another is that timestamps are always in the
            % TimestampTimeResolution sampling rate (i.e. 30k samples/sec)
            % whereas datapoints may be sampled at a lower rate (2k, 10k,
            % etc.).
            % here, we convert from data point to timestamp.
            st = round((st-1)*this.fs2ttr);
            len = round(len*this.fs2ttr);
            [allPackets,startPackets,middlePackets,endPackets] = getPacketsContainingTimestampWindow(this,st,len,ref);
        end % END function getPacketsContainingSampleWindow
        
        function [allPackets,startPackets,middlePackets,endPackets] = getPacketsContainingTimestampWindow(this,st,len,ref)
            
            % only accept scalars
            assert(isscalar(st)&&isscalar(len),'Can only process scalar time inputs');
            et = st+len-1;
            
            % get packet information
            % define packet starts and ends for non-pre-sync and
            % non-zero-length packets
            [packetStartTimestamp,packetEndTimestamp,~,~,~,isPreSyncPacket,isZeroLengthPacket] = analyzePackets(this);
            packetStarts = packetStartTimestamp(~isPreSyncPacket&~isZeroLengthPacket);
            packetEnds = packetEndTimestamp(~isPreSyncPacket&~isZeroLengthPacket);
            packetNumbers = find(~isPreSyncPacket&~isZeroLengthPacket);
            
            % determine all packets corresponding to requested time range
            switch lower(ref)
                case 'packet'
                    
                    % re-reference packet start/end to the start of the
                    % first non-pre-sync, non-zero-length packet
                    if ~isempty(packetStarts)
                        packetEnds = packetEnds - packetStarts(1); % re-reference so that first sample of first non-pre-sync packet is "0"
                        packetStarts = packetStarts - packetStarts(1); % re-reference so that first sample of first non-pre-sync packet is "0"
                    end
                case 'timestamp'
                    
                    % no re-referencing needed here
                otherwise
                    error('Unknown ref "%s"',ref);
            end
            startPackets = packetNumbers( st>=packetStarts & st<=packetEnds );
            middlePackets = packetNumbers( packetStarts>=st & packetEnds<=et );
            endPackets = packetNumbers( et>=packetStarts & et<=packetEnds );
            
            % determine all packets corresponding to requested time range
            packets = unique([startPackets(:)' middlePackets(:)' endPackets(:)']);
            packets = min(packets):max(packets);
            
            % place nan values at start/end as needed (to fill in NaNs)
            if isempty(startPackets) && isempty(endPackets)
                if isempty(packets)
                    allPackets = nan;
                else
                    allPackets = [nan packets nan];
                end
            elseif isempty(startPackets)
                allPackets = [nan packets];
            elseif isempty(endPackets)
                allPackets = [packets nan];
            else
                allPackets = packets;
            end
            
            % check for gaps between packets
            for kk=(length(allPackets)-1):-1:1
                if isnan(allPackets(kk)) || isnan(allPackets(kk+1))
                    continue;
                else
                    if packetStartTimestamp(allPackets(kk+1)) - packetEndTimestamp(allPackets(kk)) > 1
                        allPackets = [allPackets(1:kk) nan allPackets(kk+1:end)];
                    end
                end
            end
        end % END function getPacketsContainingSampleWindow
        
        function setDebug(this,dbg)
            % SETDEBUG Set the debug client
            %
            %   SETDEBUG(THIS,DBG)
            %   Provide a debug object or other log function for the
            %   BLACKROCK.NSX object after construction.
            this.logfcn = dbg;
        end % END function setDebug
        
        function prev = setVerbosity(this,new)
            % SETVERBOSITY Set the verbosity level
            %
            %   PREV = SETVERBOSITY(THIS,NEW)
            %   Set the verbosity to the level specified by NEW, which can
            %   be an object of class DEBUG.PRIORITYLEVEL, or a string
            %   matching one of the enumerations of DEBUG.PRIORITYLEVEL.
            %   Returns the old verbosity in PREV.
            if util.existp('Debug.PriorityLevel','class')==8
                
                % process input
                if ~isa(new,'Debug.PriorityLevel')
                    if ischar(new)
                        new = Debug.PriorityLevel.fromString(new);
                    elseif isnumeric(new)
                        new = Debug.PriorityLevel.fromNumber(new);
                    end
                end
                assert(isa(new,'Debug.PriorityLevel'),'Input must be an object of class ''Debug.PriorityLevel'' not ''%s''',class(new));
                
                % if the logfcn is a Debug.Debugger object, that object
                % manages the verbosity and we need to update it
                if isa(this.logfcn,'Debug.Debugger')
                    prev = setVerbosity(this.logfcn,new);
                else
                    prev = this.verbosity;
                    if ~isa(prev,'Debug.PriorityLevel')
                        if ischar(prev)
                            prev = Debug.PriorityLevel.fromString(prev);
                        elseif isnumeric(prev)
                            prev = Debug.PriorityLevel.fromNumber(prev);
                        end
                    end
                    assert(isa(prev,'Debug.PriorityLevel'),'Previous verbosity level was of class ''%s'', not ''Debug.PriorityLevel''',class(prev));
                end
            else
                prev = this.verbosity;
            end
            
            % set the verbosity
            this.verbosity = new;
        end % END function setVerbosity
        
        function log(this,msg,priority)
            % LOG Display a message on the screen
            %
            %   LOG(THIS,MSG,PRIORITY)
            %   Display the text in MSG on the screen depending on the
            %   message priority level PRIORITY.  MSG should not include a
            %   newline at the end, unless an extra newline is desired.  If
            %   PRIORITY is not specified, the default value is 1.
            
            % default message priority
            if nargin<3,priority=1;end
            
            % execute the log function
            if isa(this.logfcn,'Debug.Debugger')
                this.logfcn.log(msg,priority);
            else
                feval(this.logfcn{1}{:},msg,priority,this.logfcn{2}{:});
            end
        end % END function log
        
        function st = toStruct(this)
            skip = {'logfcn'}; % may have a handle to this, creating a recursive path for toStruct
            st = toStruct@util.Structable(this,skip{:});
        end % END function toStruct
        
        validate(this,which);
    end % END methods
    
    methods(Access='private')
        function internalLog(this,msg,priority)
            % INTERNALLOG Internal method for displaying text to screen
            %
            %   INTERNALLOG(THIS,MSG,PRIORITY)
            %   If the message priority level PRIORITY is less than or
            %   equal to the object verbosity level, print the text in MSG
            %   to the command window with a newline appended.
            
            % interpret char vb
            if ischar(priority)
                switch lower(priority)
                    case {'off'},priority=-Inf;
                    case {'critical'},priority=0;
                    case {'error','err'},priority=1;
                    case {'warning','warn'},priority=2;
                    case {'info'},priority=3;
                    case {'hint','hints'},priority=4;
                    case {'debug'},priority=5;
                    case {'insanity'},priority=Inf;
                    otherwise
                        error('Unrecognized verbosity term ''%s''',priority);
                end
            end
            assert(isnumeric(priority),'Must provide numeric verbosity level, not ''%s''',class(priority));
            
            % print the message to the screen if verbosity level allows
            if priority<=this.verbosity,fprintf('%s\n',msg);end
        end % END function internalLog
        
        function open(this,src)
            % OPEN Read basic and extended headers from NEV file
            
            % validate the input
            [srcdir,srcbase,srcext] = fileparts(src);
            assert(~this.SourceFileRead,'This Blackrock.NSx object has already loaded a file');
            
            % validate the source file
            assert(exist(src,'file')==2,'Must provide path to existing file');
            assert(any(strcmpi(srcext,{'.ns1','.ns2','.ns3','.ns4','.ns5','.ns6'})),'Must provide path to NSx file');
            info = dir(src);
            assert(~isempty(info),'Cannot read file ''%s''',src);
            assert(info.bytes>0,'Source file ''%s'' is empty',src);
            
            % populate basic fields
            this.SourceDirectory = srcdir;
            this.SourceBasename = srcbase;
            this.SourceExtension = srcext;
            this.SourceFileSize = info.bytes;
            assert(~isempty(this.SourceDirectory)&&~isempty(this.SourceBasename)&&~isempty(this.SourceExtension),'Invalid file ''%s''',src);
            
            % preprocess the file
            readBasicHeader(this);
            readExtendedHeader(this);
            preprocessDataPackets(this);
            
            % useful quantity to calculate once up front
            this.fs2ttr = round(this.TimestampTimeResolution/this.Fs);
            
            % update status
            this.SourceFileRead = true;
        end % END function open
        
        readBasicHeader(this);
        readExtendedHeader(this);
        preprocessDataPackets(this);
    end % END methods(Access='private')
end % END classdef NSx