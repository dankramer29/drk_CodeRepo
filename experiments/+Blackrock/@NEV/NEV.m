classdef NEV < handle & util.Structable
% NEV Read data from a Blackrock NEV file
%
%   The Blackrock.NEV class provides a convenient interface to reading NEV
%   files. For a NEV file NVFILE and corresponding map file MAPFILE, this
%   example shows how to open the file and read the first 100 seconds of
%   data:
%
%     >> nv = Blackrock.NEV(NVFILE,MAPFILE);
%     >> data = nv.read('time',[0 100]);
%
%   Data may also be loaded into the "Data" property of the Blackrock.NEV
%   object. In the following example, the NEV file contains two recording
%   blocks  (see note on Data Packets below), and has two types of packets,
%   Spikes and Comments:
%
%     >> nv.load;
%     >> nv.Data
% 
%     ans = 
% 
%       Spike: {[1x1 struct]  [1x1 struct]}
%     Comment: {[1x1 struct]  [1x1 struct]}
%
%   There are several key concepts that are important to understand when
%   working with NEV files:
%
%   Channel vs. Electrode
%   Most Blackrock products distinguish between channels and electrodes.
%   However, NSx and NEV files store data by CHANNEL numbers despite the
%   fact that the file spec labels the field as the Electrode ID. The NPMK
%   package also uses the file spec field name instead of the actual
%   meaning of the data. To avoid confusion, the Blackrock.NEV class refers
%   to this number as the ChannelID, which is what it actually is. Note
%   that the ChannelID will be the same between NEV and NSx files. If a
%   Blackrock.ArrayMap object is available, a field "ElectrodeID" will be
%   added which indicates the electrode ID for that channel.
%
%   Data packets vs recording blocks
%   In contrast to NSx files, where a data packet consists of many
%   consecutive data points, NEV files store each event in its own data
%   packet. There are many different kinds of data packets (spike events,
%   comments, digital/serial events, etc.). The header of each data packet
%   specifies the timestamp of the packet. The timestamp counter runs at
%   the frequency specified by the property "ResolutionTimestamps" which
%   may be different from the sampling frequency of the data itself
%   ("ResolutionSamples" property). In some situations, the timestamp
%   counter may be reset, for example when two NSPs synchronize. When this
%   occurs, it is impossible to know the timing of the packet before the
%   reset with respect to the packet after the reset, since there is a
%   pause of unmeasured length before the counter starts running again.
%   Such events divide "Recording Blocks" which individually contain
%   coherently-timed data packets.
%
%   Extension of NEV data into metadata files
%   The NEV file format is defined externally and does not support
%   user-defined data packets, or user-defined fields within existing data
%   packets. Thus, if there is some additional piece of information we
%   might want to associate with a data packet, such as an indication of
%   spike quality (single unit, multiunit, etc.), that information cannot
%   be stored in a NEV file. The Blackrock.NEV and Blackrock.NEVWriter
%   classes transparently implement a solution to this problem by writing
%   and reading these data from "metadata" files. Information stored in
%   these MAT files must be stored in the same basic structure as would be
%   returned from the "read" method, i.e. as a struct with one field per
%   data type, each field containing one cell per recording block.
%   Furthermore, the metadata fields must be provided by the static method
%   Blackrock.NEV.getMetadataFields. See Blackrock.NEVWriter documentation
%   for additional instructions on creating the metadata files.
%
%   Version History
%
%   v1.3 - 20160613 - Updated the logic for inferring which recording block
%   should source requested time ranges.
%
%   v1.2 - 20160326 - Added ability to read from associated metadata files,
%   which could contain (for example) quality measurements for each spike.
%   Also added ability to load NEV data into the "Data" property of the
%   Blackrock.NEV class.
%
%   v1.1 - 20160312 - Removed "save" functionality from the NEV class
%   (moved into a separate NEVWriter class). Changed "FlagBits" property to
%   "AdditionalFlags" to more closely reflect the file spec documentation.
%
%   v1.0 - First numbered version. In use for several years; see SVN log
%   for detailed change information.
    
    properties
        verbosity % verbosity level: 0=> off, 1=> error, 2=> warning, 3=> info, 4=> hints, 5=> debug
        debug % debug level: 0=> off, 1=> on, 2=> validation
        logfcn % 1x2 cell array of cell arrays; {1}{:} will be passed to feval prior to msg and vb; {2}{:} will be passed to feval after msg and vb
    end % END properties
    
    properties(SetAccess=private,GetAccess=public)
        hArrayMap % handle to Blackrock.ArrayMap object
        SourceFileRead = false; % flag to indicate file read successfully
        SourceDataLoaded = false; % flag to indicate data loaded
        MetadataRead = false; % flag to indicate metadata read successfully
        MetadataLoaded = false; % flag to indicate metadata loaded successfully
        SourceDirectory % directory containing the source data file
        SourceBasename % basename of the source data file
        SourceExtension % extension of the source data file
        SourceFileSize % size (in bytes) of the source data file
        MetaDirectory % directory containing the metadata file
        MetaBasename % basename of the source metadata file
        MetaExtension % extension of the metadata file
        MetaDirectoryFcn = @(x)sprintf('%s',x); % function to generate the metadata file directory
        MetaBasenameFcn = @(x)sprintf('%s_metadata.mat',x); % function to generate the metadata file basename
        
        % Basic Headers
        FileTypeID % Always set to 'NEURALEV' for neural events.
        FileSpecMajor % The major and minor revision numbers of the file specification used to create the file e.g. use 0x0201 for Spec. 2.1.
        FileSpecMinor % See above
        AdditionalFlags % File format additional flags.
        BytesInHeaders % The total number of bytes in both headers (Standard and Extended). This value can also be considered to be a zero-indexed pointer to the first data packet.
        BytesPerDataPacket % The length (in bytes) of the fixed width data packets in the data section of the file. The packet sizes must be between 12 and 256 bytes (see Data Section description). Packet sizes are required to be multiples of 4 so that the  packets are well aligned for 32-bit file access.
        ResolutionTimestamps % This value denotes the frequency (counts per second) of the global clock used to index the time samples of the individual data packet entries.
        ResolutionSamples % This value denotes the sampling frequency (counts per second) used to digitize neural waveforms.
        OriginTimeString % The UTC Time at which the data in the file was collected. This also corresponds to time index zero for the time stamps in the file. The structure consists of eight 2-byte unsigned int-16 values defining the Year, Month, DayOfWeek, Day, Hour, Minute, Second, and Millisecond.
        OriginTimeDatenum % See above
        ApplicationName % A 32 character string labeling the program which created the file. Programs should also include their revision number in this label. The string must be null terminated.
        Comment % A 256 character, null-terminated string used for embedding comments into the data field. Multi-line comments should ideally use no more than 80 characters per line and no more than 8 lines. The string must be NULL terminated.
        NumExtendedHeaders % A long value indicating the number of extended header entries.
        AllSpikeWaveform16Bit = false; % flag to indicate all spike waveforms store values as 16-bit samples
        
        % Extended Headers
        ArrayName % String name of the electrode array used, Must be null-terminated.
        ExtraComment % 
        ExtHeaderIndicatedMapFile % Mapfile used in the creation of the data, must be null-terminated.
        
        ChannelInfo % Contains NEUEVWAV, NEUEVLBL, and NEUEVFLT header data
        DigitalInfo % Contains DIGLABEL header data
        VideoInfo % Video synchronization data
        TrackingInfo % Trackable object information
        
        % Recording Blocks
        NumRecordingBlocks = 0;
        RecordingBlockPacketCount
        RecordingBlockPacketIdx
        
        % Data Packets
        NumDataPackets = 0;
        Timestamps
        PacketIDs
        UniquePacketIDs
        
        % Data fields
        Data % will contain NEV data if loaded
    end % END properties(SetAccess='private',GetAccess='public')
    
    properties(Constant)
        versionMajor = 1;
        versionMinor = 3;
        BasicHeaderSize = 336; % size of basic headers in bytes
    end % END properties(Constant)
    
    methods
        function this = NEV(varargin)
            
            % verbosity and debug defaults
            [varargin,quietmode] = util.argflag('quiet',varargin);
            [this.verbosity,this.debug] = env.get('verbosity','debug');
            if quietmode,this.verbosity=0;end
            
            % capture source file
            [varargin,src] = Utilities.argfn(@(x)ischar(x)&&exist(x,'file')==2&&~isempty(regexpi(x,'.nev')),varargin,'');
            assert(~isempty(src),'Must provide a NEV file to load');
            
            % capture metadata file
            [varargin,meta,found_meta] = Utilities.argfn(@(x)ischar(x)&&exist(x,'file')==2&&~isempty(regexpi(x,'.mat')),varargin,'');
            if ~found_meta
                [srcdir,srcbase] = fileparts(src);
                meta = fullfile(this.MetaDirectoryFcn(srcdir),this.MetaBasenameFcn(srcbase));
                if exist(meta,'file')~=2,meta=[];end
            end
            
            % look for array map object
            [varargin,this.hArrayMap,found] = Utilities.argisa('Blackrock.ArrayMap',varargin,nan);
            if ~found,this.hArrayMap=Blackrock.ArrayMap('quiet');end
            
            % whether to load data
            [varargin,flagLoadData] = util.argflag('loaddata',varargin,false);
            
            % look for debugger
            [varargin,this.logfcn,found] = Utilities.argisa('Debug.Debugger',varargin,nan);
            if ~found,this.logfcn={{@internalLog,this},{}};end
            
            % process remaining inputs
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % open the file to read basic information (headers, etc.)
            open(this,src,meta);
            
            % load the data if requested
            if flagLoadData
                load(this);
            end
        end % END function NEV
        
        function load(this)
            % LOAD Load NEV data into class property Data
            %
            %   LOAD(THIS)
            %   Load the data contained in the NEV file represented by THIS
            %   into the Data property.
            
            % make sure the file has been opened/read first
            if ~this.SourceFileRead,return;end
            
            % read the data
            assert(~this.SourceDataLoaded,'Source data already loaded');
            this.Data = this.read('all');
            this.SourceDataLoaded = true;
        end % END function load
        
        function [timestampStart,timestampEnd,timestampLen,preReset,preSync] = analyzeBlocks(this)
            if isempty(this.Timestamps)
                timestampStart = nan;
                timestampEnd = nan;
                timestampLen = nan;
                preReset = nan;
                preSync = nan;
                return;
            end
            
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
            timestampStart = cellfun(@(x)x(1),this.Timestamps(:));
            timestampEnd = cellfun(@(x)x(end),this.Timestamps(:));
            timestampLen = cellfun(@(x)x(end)-x(1)+1,this.Timestamps(:));
            
            % identify packets that have too many datapoints, and infer pre-sync
            if length(timestampStart)>1
                
                % pre-sync packets should contain packets that extend beyond the start
                % of the subsequent packet's start timestamp (b/c clock reset).
                preReset = [timestampEnd(1:end-1)>timestampStart(2:end); false];
            else
                preReset = false;
            end
            
            % infer pre-sync packets
            if length(timestampStart)>1
                
                % pre-sync packets are (1) pre-reset and (2) short (<5 sec)
                preSync = preReset & timestampLen<lenpresync*this.ResolutionTimestamps;
            else
                preSync = false;
            end
        end % END function analyzeBlocks
        
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
        
        function [allBlocks,startBlock,endBlock] = getBlocksContainingTime(this,st)
            [allBlocks,startBlock,endBlock] = getBlocksContainingTimeWindow(this,st,st);
        end % END function getBlocksContainingTime
        
        function [allBlocks,startBlock,endBlock] = getBlocksContainingTimestamp(this,st)
            [allBlocks,startBlock,endBlock] = getBlocksContainingTimestampWindow(this,st,st);
        end % END function getBlocksContainingSample
        
        function [allBlocks,startBlock,endBlock] = getBlocksContainingTimeWindow(this,st,et)
            st = round(st*this.ResolutionTimestamps);
            et = round(et*this.ResolutionTimestamps);
            [allBlocks,startBlock,endBlock] = getBlocksContainingTimestampWindow(this,st,et);
        end % END function getBlocksContainingTimeWindow
        
        function [allBlocks,startBlock,endBlock] = getBlocksContainingTimestampWindow(this,st,et)
            SAMPLE_DENSITY_THREHSOLD = 1/(2*this.ResolutionTimestamps); % at least one event per 2 seconds
            
            % check each block to see how many packets if we started there
            sample_range = zeros(1,this.NumRecordingBlocks);
            num_samples = zeros(1,this.NumRecordingBlocks);
            last_block = nan(1,this.NumRecordingBlocks);
            range_is_valid = false(1,this.NumRecordingBlocks);
            for bb=1:this.NumRecordingBlocks
                local_st = st;
                if local_st==0,local_st=this.Timestamps{bb}(1);end
                
                % if requested range starts after this block, skip
                if local_st>this.Timestamps{bb}(end),continue;end
                
                % if requested range ends before this block, skip
                if et<this.Timestamps{bb}(1),continue;end
                
                % find the first packet within the requested time range
                idx_st = find(this.Timestamps{bb}>=local_st,1,'first');
                
                % find the last packet within the requested time range
                if et==local_st
                    idx_et = idx_st;
                else
                    idx_et = find(this.Timestamps{bb}<=et,1,'last');
                end
                
                % check future blocks
                last_block(bb) = bb;
                sample_range(bb) = (this.Timestamps{bb}(idx_et) - this.Timestamps{bb}(idx_st) + 1);
                num_samples(bb) = (idx_et - idx_st + 1);
                for cc=(bb+1):this.NumRecordingBlocks
                    
                    % if timestamps start over, break out - nothing more to do
                    if this.Timestamps{cc}(1)<this.Timestamps{bb}(end),break;end
                    
                    % if requested range ends before this block, break out
                    if et<this.Timestamps{bb}(1),break;end
                    
                    % add the number of packets availabe in this block
                    idx_et = find(this.Timestamps{cc}<=et,1,'last');
                    sample_range(bb) = sample_range(bb) + (this.Timestamps{cc}(idx_et) - this.Timestamps{cc}(1) + 1);
                    last_block(bb) = cc;
                end
                
                % check for single-block matches
                range_is_valid(bb) = ...
                    sample_range(bb)>0 && ... % 
                    (num_samples(bb)/sample_range(bb))>SAMPLE_DENSITY_THREHSOLD && ...
                    this.Timestamps{bb}(1)<=local_st && ...
                    this.Timestamps{last_block(bb)}(end)>=et;
            end
            % assert(nnz(range_is_contained)<=1,'If multiple contiguous timestamp sequences (which may include one or more recording blocks) match the requested time range, it is impossible to infer which of these should be used as a data source. Please provide an explicit instruction about which recording packet(s) to use.');
            
            % select the timestamp sequence which (1) wholly contains the
            % requested time range; or (2) holds the largest range of
            % timestamps within the requested time range
            if nnz(range_is_valid)>1
                
                % warn that there are multiple possibilities and select the
                % one with the highest event density
                startBlock = find(range_is_valid);
                endBlock = last_block(startBlock);
                allBlocks = arrayfun(@(x,y)x:y,startBlock,endBlock,'UniformOutput',false);
                log(this,sprintf('Multiple recording blocks match the requested time range: arbitrarily selecting %s based on spike event density',Utilities.vec2str(startBlock:endBlock)),'warn');
            elseif any(range_is_valid)
                
                % select the block(s) that contain the requested time range
                startBlock = find(range_is_valid);
                endBlock = last_block(startBlock);
                allBlocks = startBlock:endBlock;
            elseif any(sample_range>0)
                
                % select the blocks that would give the most timestamp coverage
                [~,startBlock] = max(sample_range);
                endBlock = last_block(startBlock);
                allBlocks = startBlock:endBlock;
            else
                
                % return NaNs
                startBlock = nan;
                endBlock = nan;
                allBlocks = nan;
            end
        end % END function getBlocksContainingTimetampWindow
        
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
        
        function log(this,msg,vb)
            % LOG Display a message on the screen
            %
            %   LOG(THIS,MSG,VB)
            %   Display the text in MSG on the screen depending on the
            %   message verbosity level VB.  MSG should not include a
            %   newline at the end, unless an extra newline is desired.  If
            %   VB is not specified, the default value is 1.
            
            % default message verbosity
            if nargin<3,vb=1;end
            
            % execute the log function
            if isa(this.logfcn,'Debug.Debugger')
                this.logfcn.log(msg,vb);
            else
                feval(this.logfcn{1}{:},msg,vb,this.logfcn{2}{:});
            end
        end % END function log
        
        function st = toStruct(this)
            skip = {'logFcn'}; % may have a handle to this, creating a recursive path for toStruct
            st = toStruct@util.Structable(this,skip{:});
        end % END function toStruct
        
        [packet,bytes] = getNearestPacket(this,marker,varargin);
        validate(this);
    end % END methods
    
    methods(Access=private)
        function internalLog(this,msg,vb)
            % INTERNALLOG Internal method for displaying text to screen
            %
            %   INTERNALLOG(THIS,MSG,VB)
            %   If the message verbosity level VB is less than or equal to
            %   the object verbosity level, print the text in MSG to the
            %   command window with a newline appended.
            
            % interpret char vb
            if ischar(vb)
                switch lower(vb)
                    case {'off'},vb=-Inf;
                    case {'critical'},vb=0;
                    case {'error','err'},vb=1;
                    case {'warning','warn'},vb=2;
                    case {'info'},vb=3;
                    case {'hint','hints'},vb=4;
                    case {'debug'},vb=5;
                    case {'insanity'},vb=Inf;
                    otherwise
                        error('Unrecognized verbosity term ''%s''',vb);
                end
            end
            assert(isnumeric(vb),'Must provide numeric verbosity level, not ''%s''',class(vb));
            
            % print the message to the screen if verbosity level allows
            if vb<=this.verbosity,fprintf('%s\n',msg);end
        end % END function internalLog
        
        function open(this,src,meta)
            % OPEN Read basic and extended headers from NEV file
            
            % validate the input
            [srcdir,srcbase,srcext] = fileparts(src);
            assert(~this.SourceFileRead,'This Blackrock.NEV object has already loaded a file');
            
            % validate the source file
            assert(exist(src,'file')==2,'Must provide path to existing file');
            %assert(strcmpi(srcext,'.nev'),'Must provide path to NEV file');
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
            
            % update status
            this.SourceFileRead = true;
            
            % load metadata
            if nargin>=3 && ~isempty(meta)
                
                % validate the input
                [mtadir,mtabase,mtaext] = fileparts(meta);
                assert(~this.MetadataRead,'This Blackrock.NEV object has already loaded a metadata file');
                
                % validate the metadata file
                assert(exist(meta,'file')==2,'Must provide path to existing file');
                assert(strcmpi(mtaext,'.mat'),'Must provide path to a MAT file');
                info = dir(meta);
                assert(~isempty(info),'Cannot read file ''%s''',meta);
                assert(info.bytes>0,'Metadata file ''%s'' is empty',meta);
                
                % populate basic fields
                this.MetaDirectory = mtadir;
                this.MetaBasename = mtabase;
                this.MetaExtension = mtaext;
                assert(~isempty(this.MetaDirectory)&&~isempty(this.MetaBasename)&&~isempty(this.MetaExtension),'Invalid file ''%s''',meta);
                
                % update status
                this.MetadataRead = true;
            end
        end % END function open
        
        readBasicHeader(this);
        readExtendedHeader(this);
        preprocessDataPackets(this);
    end % END methods(Access='private')
    
    methods(Static)
        [dn,ds] = systime2datenum(st);
        metafields = getMetadataFields(dtype);
    end % END methods(Static)
end % END classdef NEV