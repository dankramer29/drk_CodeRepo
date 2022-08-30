classdef NEVWriter < handle
% NEVWRITER Create NEV files
%
%   The Blackrock.NEVWriter class provides a convenient interface for
%   writing NEV files. The three basic steps for using the NEVWriter class
%   are:
%
%     1. Create the NEVWriter object
%     2. Add data to the NEVWriter object
%     3. Save the new NEV file
%
%   In step 1, provide the NEVWriter constructor the path to the new NEV
%   file. This target file cannot already exist, and must have a *.nsX
%   extension where the X is any number between 1 and 6 inclusive.
%
%   In step 2, call the ADDDATA method once per recording block. Provide
%   all data types in each call to the ADDDATA method. The data should be
%   provided in the same format as it is received by the Blackrock.NEV/read
%   method, that is, as structures with the appropriate fields.
%
%   In step 3, call the NEVWriter/save method to generate a new NEV file.
%
%   The following example illustrates how to create a NEV file NVFILE based
%   on the data NVDATA obtained from the Blackrock.NEV/read method. In this
%   example, the Blackrock.NEV object NV is created from the original NEV
%   file OLDFILE, which contains spikes and comments in two recording
%   blocks.
%
%     >> NV = Blackrock.NEV(OLDFILE);
%     >> NVDATA = NV.read('all');
%     ...
%     >> % modify data, such as the unit assignments
%     ...
%     >> NVW = Blackrock.NEVWriter(NVFILE,'like',NV);
%     >> NVW.addData(NVDATA.Spike{1},NVDATA.Comment{1});
%     >> NVW.addData(NVDATA.Spike{2},NVDATA.Comment{2});
%     >> NVW.save;
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
%   Such events divide "Recording Blocks" which contain coherently-timed
%   data packets.
%
%   Extension of NEV data into metadata files
%   The NEV file format is defined externally and does not support
%   user-defined data packets, or user-defined fields within existing data
%   packets. Thus, if there is some additional piece of information we
%   might want to associate with a data packet, such as an indication of
%   spike quality (single unit, multiunit, etc.), that information cannot
%   be stored in a NEV file. The Blackrock.NEV and Blackrock.NEVWriter
%   classes transparently implement a solution to this problem by writing
%   and reading these data from "metadata" files. To add metadata when
%   creating a new NEV file, make sure the metadata field name is listed in
%   the BLACKROCK.NEV/GETMETADATAFIELDS static method, and include the
%   metadata field in the data structure(s) provided to the
%   NEVWRITER/ADDDATA method.
%
%   Step 1: edit BLACKROCK.NEV/GETMETADATAFIELDS
%   Edit the function to list all metadata fields possible for the
%   appropriate data type. For example, to have "Quality" available as a
%   field for "Spike":
%
%     metafields.Spike = {'Quality'};
%
%   Step 2: include metadata in the data provided to
%   BLACKROCK.NEVWRITER/ADDDATA
%   Read the data from the NEV file, add metadata to the structs, and
%   provide the updated data structs to the BLACKROCK.NEVWRITER/ADDDATA
%   method:
%
%     % read NEV data
%     >> NV = Blackrock.NEV(OLDFILE);
%     >> NVDATA = NV.read('all');
%
%     % add quality to the data struct
%     >> NVDATA.Spike{1}.Quality = 4*ones(size(NVDATA.Spike{1}.Units));
%     >> NVDATA.Spike{2}.Quality = 4*ones(size(NVDATA.Spike{2}.Units));
%
%     % create the new NEV file with metadata
%     >> NVW = Blackrock.NEVWriter(NVFILE,'like',NV);
%     >> NVW.addData(NVDATA.Spike{1},NVDATA.Comment{1});
%     >> NVW.addData(NVDATA.Spike{2},NVDATA.Comment{2});
%     >> NVW.save;
    
    properties
        verbosity % verbosity level: 0=> off, 1=> error, 2=> warning, 3=> info, 4=> hints, 5=> debug
        debug % debug level: 0=> off, 1=> on, 2=> validation
        logfcn % cell array in which first cell is function handle to function whose last two args are string and verbosity level
    end % END properties
    
    properties(SetAccess=private,GetAccess=public)
        hNEV % Blackrock.NEV object to use for some default values
        hArrayMap % handle to Blackrock.ArrayMap object
        
        TargetDirectory % directory containing the source data file
        TargetBasename % basename of the source data file
        TargetExtension % extension of the source data file
        
        MetaDirectoryFcn = @(x)sprintf('%s',x); % function to generate the metadata file directory from the target directory
        MetaBasenameFcn = @(x)sprintf('%s_metadata.mat',x); % function to generate the metadata file basename from the target basename
        
        BasicHeader % struct with fields containing basic header info
        ExtendedHeaders % struct with fields containing extended header info
        
        SpikeData % spike data to be written
        CommentData % comment data to be written
        DigitalData % digital data to be written
        VideoData % video data to be written
        TrackingData % tracking data to be written
        ButtonData % button data to be written
        ConfigData % config data to be written
    end % END properties(SetAccess='private',GetAccess='public')
    
    properties(Constant)
        versionMajor = 1;
        versionMinor = 0;
        BasicHeaderSize = 336; % size of basic headers in bytes
    end % END properties(Constant)
    
    methods
        function this = NEVWriter(varargin)
            
            % verbosity and debug defaults
            [varargin,quietmode] = util.argflag('quiet',varargin);
            [this.verbosity,this.debug] = env.get('verbosity','debug');
            if quietmode,this.verbosity=0;end
            
            % look for array map object
            [varargin,this.hArrayMap,found] = util.argisa('Blackrock.ArrayMap',varargin,nan);
            if ~found,this.hArrayMap=Blackrock.ArrayMap('quiet');end
            
            % check for "force overwrite" flag
            [varargin,flag_overwrite] = Utilities.argflag('overwrite',varargin,false);
            
            % process property name-value inputs
            varargin = util.argobjprop(this,varargin);
            
            % look for debugger
            [varargin,this.logfcn,found] = Utilities.argisa('Debug.Debugger',varargin,[]);
            if ~found
                this.logfcn = {{@internalLog,this},{}};
            end
            
            % load header and other information from a similar NEV file
            [varargin,src,~,found] = util.argkeyval('like',varargin,nan);
            if found
                if isa(src,'Blackrock.NEV')
                    this.hNEV = src;
                else
                    assert(ischar(src),'Must provide filename as char, not ''%s''',class(src));
                    assert(exist(src,'file')==2,'File ''%s'' already exists',src);
                    [~,~,srcext] = fileparts(src);
                    assert(strcmpi(srcext,'.nev'),'The ''like'' file must have a ''.nev'' extension, not ''%s''',srcext);
                    this.hNEV = Blackrock.NEV(src);
                end
            end
            
            % capture target file
            [varargin,tgt,found] = util.argisa('char',varargin,'');
            if found
                assert(ischar(tgt),'Must provide filename as char, not ''%s''',class(tgt));
                if ~flag_overwrite
                    assert(exist(tgt,'file')~=2,'File ''%s'' already exists',tgt);
                end
                [tgtdir,tgtbase,tgtext] = fileparts(tgt);
                assert(strcmpi(tgtext,'.nev'),'NEV files must have the ''.nev'' extension, not ''%s''',tgtext);
                this.TargetDirectory = tgtdir;
                this.TargetBasename = tgtbase;
                this.TargetExtension = tgtext;
            end
            
            % make sure nothing else remaining
            util.argempty(varargin);
            
            % load file if provided, or load default values
            defaults(this);
        end % END function NEVWriter
        
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
        
        function st = toStruct(this)
            skip = {'logfcn'}; % may have a handle to this, creating a recursive path for toStruct
            st = toStruct@util.Structable(this,skip{:});
        end % END function toStruct
    end % END methods
    
    methods(Access=private)
        function internalLog(this,msg,priority)
            % INTERNALLOG Internal method for displaying text to screen
            %
            %   INTERNALLOG(THIS,MSG,PRIORITY)
            %   If the message priority level PRIORITY is less than or
            %   equal to the object priority level, print the text in MSG
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
        
        function defaults(this)
            % DEFAULTS Load default values into basic and extended headers
            
            % load the default basic header values
            default = Blackrock.NEVWriter.defaultBasicHeader;
            this.BasicHeader.TimeOrigin = default.TimeOrigin;
            if ~isempty(this.hNEV)
                this.BasicHeader.AdditionalFlags = this.hNEV.AdditionalFlags;
                default = this.hNEV;
            else
                this.BasicHeader.AdditionalFlags = default.AdditionalFlags;
            end
            fields = {'FileTypeID','FileSpecMajor','FileSpecMinor','BytesInHeaders',...
                'BytesPerDataPacket','ResolutionTimestamps','ResolutionSamples',...
                'NumExtendedHeaders','Comment'};
            for kk=1:length(fields)
                this.BasicHeader.(fields{kk}) = default.(fields{kk});
            end
            this.BasicHeader.ApplicationName = sprintf('Blackrock.NEVWriter v%d.%d',this.versionMajor,this.versionMinor);
            
            % load the default extended header values
            if ~isempty(this.hNEV)
                default = this.hNEV;
            else
                default = Blackrock.NEVWriter.defaultExtendedHeaders;
            end
            fields = {'ArrayName','ExtraComment','ExtHeaderIndicatedMapFile',...
                'ChannelInfo','DigitalInfo','VideoInfo','TrackingInfo'};
            for kk=1:length(fields)
                this.ExtendedHeaders.(fields{kk}) = default.(fields{kk});
            end
        end % END function defaults
    end % END methods(Access='private')
    methods(Static)
        createDefaultChannelInfoScript(nvfile);
        [bytes,info] = genBasicHeaderBytes(info,numExtendedHeaders);
        [bytes,info] = genExtendedHeaderBytes(info);
        bh = defaultBasicHeader;
        eh = defaultExtendedHeaders;
        ci = defaultChannelInfo;
        di = defaultDigitalInfo;
    end % END methods(Static)
end % END classdef NEVWriter