classdef NSxWriter < handle
    % NSXWRITER Create NSx files
    %
    %   The Blackrock.NSxWriter class provides a convenient interface for
    %   creating NSx files. The three basic steps for using the NSxWriter class
    %   are:
    %
    %     1. Create the NSxWriter object
    %     2. Provide a data source for the object
    %     3. Create the new NSx file
    
    properties(SetAccess=private,GetAccess=public)
        hSource % handle to object for acquiring data
        hDebug % handle to debugger object
        
        TargetDirectory % directory containing the source data file
        TargetBasename % basename of the source data file
        TargetExtension % extension of the source data file
        
        MetaDirectoryFcn = @(x)sprintf('%s',x); % function to generate the metadata file directory from the target directory
        MetaBasenameFcn = @(x)sprintf('%s_metadata.mat',x); % function to generate the metadata file basename from the target basename
        
        BasicHeader % struct with fields containing basic header info
        ExtendedHeaders % struct with fields containing extended header info
        
        MinDigitalValue % minimum value of the quantized digital data
        MaxDigitalValue % maximum value of the quantized digital data
    end % END properties(SetAccess='private',GetAccess='public')
    
    properties(Constant)
        FileTypeID = 'NEURALCD'
        FileSpecMajor = 2
        FileSpecMinor = 3
        versionMajor = 0
        versionMinor = 1
        BasicHeaderSize = 336 % size of basic headers in bytes
    end % END properties(Constant)
    
    methods
        function this = NSxWriter(varargin)
            
            % process property name-value inputs
            varargin = util.argobjprop(this,varargin);
            
            % object for source data
            [varargin,src] = util.argkeyval('source',varargin,nan);
            
            % process debug input
            this.hDebug = Debug.Debugger(sprintf('NSxWriter_%s',datestr(now,'yyyymmdd-HHMMSS')),varargin{:});
            
            % make sure nothing else remaining
            util.argempty(varargin);
            
            % process the "source" input
            assert(~isnan(src),'Must provide source data');
            if ~isempty(regexpi(class(this.hLike),'XLTekTxt'))
                this.hSource = src;
            elseif ~isempty(regexpi(class(this.hLike),'NSx'))
                this.hSource = src;
            elseif ischar(src) && exist(src,'file')==2
                [~,~,ext] = fileparts(src);
                switch lower(ext)
                    case {'.ns1','.ns2','.ns3','.ns4','.ns5','.ns6'}
                        this.hSource = Blackrock.NSx(src,this.hDebug);
                    case '.txt'
                        this.hSource = keck.XLTekTxt(src);
                    otherwise
                        error('Unknown source input with extension ''%s''',ext);
                end
            else
                error('Unknown source input of class ''%s''',class(src));
            end
            
            % validate
            assert(~isempty(this.hSource),'Must provide data source');
            
            % load header data
            initialize(this);
        end % END function NSxWriter
        
        function initialize(this)
            % HEADERS Load header data to the NSx object properties
            %
            %   HEADER(THIS)
            %   Transfer information from the data source to the properties
            %   of the NSXWRITER object THIS.
            
            % common initialization
            assert(ischar(this.hSource.Units),'Units must be char, not "%s"',class(this.hSource.Units));
            assert(any(strcmpi(this.hSource.Units,{'V','mV','uV'})),'Units must be "V", "mV", or "uV", not "%s"',this.hSource.Units);
            this.BasicHeader.FileTypeID = this.FileTypeID;
            this.BasicHeader.FileSpecMajor = cast(this.FileSpecMajor,'uint8');
            this.BasicHeader.FileSpecMinor = cast(this.FileSpecMinor,'uint8');
            this.BasicHeader.BytesInHeaders = cast(this.BytesInHeaders,'uint32');
            this.BasicHeader.Label = '';
            this.BasicHeader.Comment = '';
            
            % branch out to appropriate saving method
            if ~isempty(regexpi(class(this.hLike),'XLTekTxt'))
                initializeFromXLTekTxt(this);
            elseif ~isempty(regexpi(class(this.hLike),'NSx'))
                initializeFromNSx(this);
            else
                error('Unkown source class ''%s''',class(this.hSource));
            end
        end % END function load
        
        function initializeFromXLTekTxt(this)
            % LOADHEADERSFROMXLTTEKTXT Load headers from the XLTTekTxt
            %
            %   LOADHEADERSFROMXLTTEKTXT(THIS)
            %   Load basic information about the data to populate
            %   properties of the NSXWRITER object THIS.
            
            % process basic header
            this.BasicHeader.TimestampTimeResolution = cast(this.hSource.SamplingRate,'uint32');
            this.BasicHeader.TimestampsPerSample = cast(1,'uint32');
            this.BasicHeader.TimeOrigin = Blackrock.Helper.datenum2systime(this.hSource.OriginalStartDateTime);
            this.BasicHeader.ChannelCount = cast(this.hSource.NumChannels,'uint32');
            
            % The structure consists of eight 2-byte unsigned int-16 values defining the Year, Month, DayOfWeek, Day, Hour, Minute, Second, and Millisecond.
            % process extended header
            this.ExtendedHeaders.CC(this.hSource.NumChannels) = struct(...
                'ChannelID',[],'ElectrodeID',[],'Label',[],'PhysicalConnector',[],...
                'ConnectorPin',[],'MinDigitalValue',[],'MaxDigitalValue',[],...
                'MinAnalogValue',[],'MaxAnalogValue',[],'Units',[],...
                'HighFreqCorner',[],'HighFreqOrder',[],'HighFreqType',[],...
                'LowFreqCorner',[],'LowFreqOrder',[],'LowFreqType',[]);
            for cc = 1:this.hSource.NumChannels % one extended header per channel
                this.ExtendedHeaders(cc).ChannelID = cc;
                this.ExtendedHeaders(cc).ElectrodeID = map.ch2el(cc);
                this.ExtendedHeaders(cc).Label = zeros(1,16);
                labelstr = sprintf('elec%d',cc);
                this.ExtendedHeaders(cc).ElectrodeLabel(1:length(labelstr)) = labelstr;
                this.ExtendedHeaders(cc).PhysicalConnector = 'A';
                this.ExtendedHeaders(cc).ConnectorPin = cc;
                this.ExtendedHeaders(cc).MinDigitalValue = this.MinDigitalValue;
                this.ExtendedHeaders(cc).MaxDigitalValue = this.MaxDigitalValue;
                this.ExtendedHeaders(cc).MinAnalogValue = this.hSource.ChannelMinimum(cc);
                this.ExtendedHeaders(cc).MaxAnalogValue = this.hSource.ChannelMaximum(cc);
                UnitsBytes = Data(29:44);
                lt = find(UnitsBytes==0,1,'first');
                if isempty(lt)
                    error('Label field string must be NULL terminated.');
                end
                UnitsBytes = UnitsBytes(:)';
                this.ChannelInfo(chid).Units = char(UnitsBytes(1:lt-1));
                this.ChannelInfo(chid).HighFreqCorner = double(typecast(Data(45:48),'uint32'));
                this.ChannelInfo(chid).HighFreqOrder = double(typecast(Data(49:52),'uint32'));
                switch double(typecast(Data(53:54),'uint16'))
                    case 0
                        this.ChannelInfo(chid).HighFilterType = 'None';
                    case 1
                        this.ChannelInfo(chid).HighFilterType = 'Butterworth';
                    otherwise
                        error('Unexpected value for electrode %d HighFilterType: ''%d''',chid,double(typecast(Data(53:54),'uint16')));
                end
                this.ChannelInfo(chid).LowFreqCorner = double(typecast(Data(55:58),'uint32'));
                this.ChannelInfo(chid).LowFreqOrder = double(typecast(Data(59:62),'uint32'));
                switch double(typecast(Data(63:64),'uint16'))
                    case 0
                        this.ChannelInfo(chid).LowFilterType = 'None';
                    case 1
                        this.ChannelInfo(chid).LowFilterType = 'Butterworth';
                    otherwise
                        error('Unexpected value for electrode %d LowFilterType: ''%d''',chid,double(typecast(Data(63:64),'uint16')));
                end
            end
            
            
            
            
            % set the bit resolution
            setBitResolution(this,this.BitResolution);
            
            % decide which channels to care about
            this.indexChannelToWrite = 1:this.hSource.NumChannels;
            if ~this.FlagWriteNanChannels
                this.indexChannelToWrite = find(~isnan(this.hSource.ChannelAverage));
            end
            
            % get channel stats and determine the analog range/units
            % note this function runs over the ENTIRE file so it may
            % take a while for large files
            this.NumDataPoints = this.hSource.NumDataPoints;
            chanMin = floor(nanmin(this.hSource.ChannelMinimum(this.indexChannelToWrite)));
            chanMax = ceil(nanmax(this.hSource.ChannelMaximum(this.indexChannelToWrite)));
            analogMax = nanmax(abs(chanMin),chanMax);
            assert(~isnan(analogMax),'Max value in analog data cannot be NaN');
            this.MinAnalogValue = -analogMax;
            this.MaxAnalogValue = analogMax;
            
            % load header info
            this.Comment = '';
            this.ChannelCount = length(this.indexChannelToWrite);
            this.ChannelInfo = repmat(struct(...
                'ChannelNumber',nan,...
                'Label','',...
                'MinDigitalValue',nan,...
                'MaxDigitalValue',nan,...
                'MinAnalogValue',nan,...
                'MaxAnalogValue',nan,...
                'Units',''),1,this.ChannelCount);
            for cc=1:this.ChannelCount
                this.ChannelInfo(cc).ChannelNumber = this.indexChannelToWrite(cc);
                this.ChannelInfo(cc).Label = sprintf('ch%03d',this.indexChannelToWrite(cc));
                this.ChannelInfo(cc).MinDigitalValue = this.MinDigitalValue;
                this.ChannelInfo(cc).MaxDigitalValue = this.MaxDigitalValue;
                this.ChannelInfo(cc).MinAnalogValue = -analogMax;
                this.ChannelInfo(cc).MaxAnalogValue = analogMax;
                this.ChannelInfo(cc).Units = this.hSource.Units;
            end
            this.SamplingRate = this.hSource.SamplingRate;
            this.OriginTimeDatenum = this.hSource.OriginalStartDateTime;
            this.BytesPerDataPoint = 2*this.ChannelCount;
            
            % pre-calculate a few items
            this.rangeDigital = this.MaxDigitalValue - this.MinDigitalValue;
            this.rangeAnalog = 2*analogMax;
            
            % estimate quantization error
            % the idea here is that we'll be rounding in the "digital"
            % domain, e.g., at the quantization determined by the min/max
            % digital values. (Default is 16-bit, i.e., -3276x to 3276x).
            % Rounding will at most destroy 0.5 units out of this
            % quantization, and this will translate to a different amount
            % of voltage depending on how the analog range maps to the
            % digital quantization range. So, here we essentially identify
            % how many volts 0.5 digital units represents, and call that
            % our quantization error. If it's too big, throw an error.
            errorDigital = 0.5;
            errorAnalog = -analogMax + this.rangeAnalog*(errorDigital-this.MinDigitalValue)/(this.rangeDigital);
            if strcmpi(this.hSource.Units,'mv') % convert to uV
                errorAnalog = errorAnalog*1e3;
            elseif strcmpi(this.hSource.Units,'uv') % keep in uV
                errorAnalog = errorAnalog*1e0;
            end
            assert(errorAnalog<=this.MaxQuantizationError,...
                'Quantization error of %.2f uV is greater than the threshold %.2f uV: increase the threshold, reduce the analog range, or increase the digital range',...
                errorAnalog,this.MaxQuantizationError);
            
            % compute number of bytes in all headers
            this.BytesInHeaders = numBytesInHeaders(this);
        end % END function loadFromXLTekTxt
        
        function save(this,varargin)
            
            % capture target file
            if ~isempty(varargin)
                tgt = varargin{1};
                varargin(1) = [];
                assert(ischar(tgt),'Must provide filename as char, not ''%s''',class(tgt));
                if ~force
                    assert(exist(tgt,'file')~=2,'File ''%s'' already exists',tgt);
                end
                [tgtdir,tgtbase,tgtext] = fileparts(tgt);
                assert(strcmpi(tgtext,'.nev'),'NEV files must have the ''.nev'' extension, not ''%s''',tgtext);
                this.TargetDirectory = tgtdir;
                this.TargetBasename = tgtbase;
                this.TargetExtension = tgtext;
            end
        end % END function save
        
        function comment(this,msg,vb)
            % COMMENT Display a message on the screen
            %
            %   COMMENT(THIS,MSG,VB)
            %   Display the text in MSG on the screen depending on the
            %   message verbosity level VB.  MSG should not include a
            %   newline at the end, unless an extra newline is desired.  If
            %   VB is not specified, the default value is 1.
            
            % default message verbosity
            if nargin<3,vb=1;end
            
            % execute the comment function
            feval(this.commentFcn{:},msg,vb);
        end % END function comment
        
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
            skip = {'commentFcn'}; % may have a handle to this, creating a recursive path for toStruct
            st = toStruct@util.Structable(this,skip{:});
        end % END function toStruct
    end % END methods
    
    methods(Access=private)
        function internalComment(this,msg,vb)
            % INTERNALCOMMENT Internal method for displaying text to screen
            %
            %   INTERNALCOMMENT(THIS,MSG,VB)
            %   If the message verbosity level VB is less than or equal to
            %   the object verbosity level, print the text in MSG to the
            %   command window with a newline appended.
            
            % print the message to the screen if verbosity level allows
            if vb<=this.verbosity,fprintf('%s\n',msg);end
        end % END function internalComment
        
        function defaults(this)
            % DEFAULTS Load default values into basic and extended headers
            
            % load the default basic header values
            default = Blackrock.NSxWriter.defaultBasicHeader;
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
            this.BasicHeader.ApplicationName = sprintf('Blackrock.NSxWriter v%d.%d',this.versionMajor,this.versionMinor);
            
            % load the default extended header values
            if ~isempty(this.hNEV)
                default = this.hNEV;
            else
                default = Blackrock.NSxWriter.defaultExtendedHeaders;
            end
            fields = {'ArrayName','ExtraComment','ExtHeaderIndicatedMapFile',...
                'ChannelInfo','DigitalInfo','VideoInfo','TrackingInfo'};
            for kk=1:length(fields)
                this.ExtendedHeaders.(fields{kk}) = default.(fields{kk});
            end
        end % END function defaults
        function setBitResolution(this,val)
            assert(ismember(val,[8 16 32 64]),'This class only supports 8, 16, 32, or 64-bit resolution');
            this.BitResolution = val;
            maxval = 2^(val-1)-1;
            maxval = dec2bin(maxval);
            maxval(end-1:end) = '00';
            maxval = bin2dec(maxval);
            this.MinDigitalValue = -maxval;
            this.MaxDigitalValue = maxval;
        end % END function setBitResolution
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
end % END classdef NSxWriter