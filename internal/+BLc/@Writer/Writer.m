classdef Writer < handle
    % WRITER Create BLc files
    %
    % The WRITER class creates binary BLc files to store
    % continuously-sampled neural data. The following example illustrates
    % how to convert an ASCII file exported from Natus NeuroWorks into a
    % BLc file:
    %
    % >> xlt = XLTekTxt(PATH_TO_TEXT_FILE);
    % >> blcw = BLc.Writer(xlt);
    % >> blcw.save;
    %
    % The result of these commands will be a *.BLC file residing in the
    % same directory as the original *.TXT file containing the source data.
    
    properties(SetAccess=private,GetAccess=public)
        hDebug % handle to debugger object
        hSource % handle to the data source object (typically XLTekTxt object)
        FileSpecMajor % file specification version (major point)
        FileSpecMinor % file specification version (minor point)
        SecondsPerOutputFile % number of seconds in a single output file
        BytesPerFrame % number of bytes in each data point
        Comment % command about the dataset (256 characters; 0-terminated)
        SamplingRate % sampling rate of the data (in samples/second)
        BitResolution % bit resolution of the data (e.g., 16 for 16-bit)
        OriginTime % datetime indicating date/time at which the original data were numFramesWrittened
        ApplicationName % name of the application creating the file
        ChannelCount % number of channels in the source data
        ChannelInfo % array of structs, one entry per channel, with information about each channel
        MinDigitalValue % minimum digital (quantized) value
        MaxDigitalValue % maximum digital (quantized) value
        MinAnalogValue % minimum analog value
        MaxAnalogValue % maximum analog value
        MaxQuantizationError % maximum error allowable in the quantization process (in uV)
        FlagExecuteSafetyChecks = true % whether to run safety checks like max quantization error
        FlagWriteNanChannels = false % whether to write channels that consist entirely of NaN values
        FlagIncludeFsInFilename = false % whether to include the sampling rate in the file basename
        FlagIncludeSegmentInFilename = false % whether to include the segment number in the file basename
        FlagSplitFilesOnSegments = true % whether to force different segments into separate files
        Segment % which segment(s) of the file to process (currently only applies to Nicolet)
    end % END properties(SetAccess=private,GetAccess=public)
    
    properties(Access=private)
        outputIndex % track the current output file index
        rangeDigital % range of digital values (globally)
        rangeAnalog % range of analog values (globally)
        indexChannelToWrite % index of channels to write to disk
    end % END properties(Access=private)
    
    methods
        function this = Writer(varargin)
            % WRITER Create BLc files
            %
            %   THIS = WRITER(SOURCE)
            %   Create a WRITER object by providing a source dataset. At
            %   the moment, the only accepted source input is an object of
            %   class XLTEKTXT, which represents a text file exported from
            %   Natus NeuroWorks EEG viewer software.
            
            % process inputs
            [varargin,this.hDebug,found] = util.argisa('Debug.Debugger',varargin,[]);
            if ~found
                this.hDebug = Debug.Debugger(sprintf('blc_writer_%s',datestr(now,'yyyymmdd-HHMMSS')));
            end
            [varargin,sourceNatus,foundNatus] = util.argisa('Natus.XLTekTxt',varargin,[]);
            [varargin,sourceBlackrock,foundBlackrock] = util.argisa('Blackrock.NSx',varargin,[]);
            [varargin,sourceNicolet,foundNicolet] = util.argisa('Natus.NicoletEFile',varargin,[]);
            assert(foundNatus|foundBlackrock|foundNicolet,'Must provide a source file');
            if foundNatus
                this.hSource = sourceNatus;
            elseif foundNicolet
                this.hSource = sourceNicolet;
                this.FlagIncludeSegmentInFilename = true;
            elseif foundBlackrock
                this.hSource = sourceBlackrock;
                this.hSource.setDebug(this.hDebug);
                if ~this.hDebug.isRegistered('Blackrock.NSx')
                    this.hDebug.registerClient('Blackrock.NSx','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
                end
                this.FlagIncludeFsInFilename = true;
            end
            [varargin,this.Segment,~,foundSegment] = util.argkeyval('segment',varargin,[]);
            if ~foundSegment && foundNicolet
                this.Segment = 1:this.hSource.NumSegments;
            end
            if ~isempty(this.Segment)
                if foundNicolet
                    assert(max(this.Segment)<=this.hSource.NumSegments,'Maximum possible segment is %d (user requested %d)',this.hSource.NumSegments,max(this.Segment));
                else
                    assert(max(this.Segment)==1,'For all sources apart from Nicolet, maximum segment is 1');
                end
            end
            [varargin,this.SecondsPerOutputFile] = util.argkeyval('secondsperoutputfile',varargin,inf);
            [varargin,this.BitResolution] = util.argkeyval('bitresolution',varargin,16);
            [varargin,this.MaxQuantizationError] = util.argkeyval('maxquantizationerror',varargin,0.5);
            [varargin,this.FlagExecuteSafetyChecks] = util.argflag('nosafetychecks',varargin,true);
            [varargin,this.indexChannelToWrite] = util.argkeyval('channels',varargin,[],2);
            this.indexChannelToWrite = util.ascell(this.indexChannelToWrite);
            util.argempty(varargin);
            assert(~isempty(this.hDebug),'Must provide a debug object');
            assert(~isempty(this.hSource),'Must provide a source object');
            
            % update log
            this.hDebug.log(sprintf('Source object is "%s"',class(this.hSource)),'debug');
            this.hDebug.log(sprintf('Seconds per output file set to %d seconds',this.SecondsPerOutputFile),'debug');
            this.hDebug.log(sprintf('Bit resolution set to %d bits',this.BitResolution),'debug');
            if foundNicolet
                this.hDebug.log(sprintf('Processing segments %s',util.vec2str(this.Segment)),'debug');
            end
            
            % set properties
            this.FileSpecMajor = BLc.Properties.FileSpecMajor;
            this.FileSpecMinor = BLc.Properties.FileSpecMinor;
            this.ApplicationName = sprintf('BLc.Writer v%d.%d',this.FileSpecMajor,this.FileSpecMinor);
            
            % load the source file
            if ~isempty(this.hSource)
                loadFromSource(this);
            end
        end % END function Writer
        
        function files = getOutputFilenames(this,varargin)
            
            % validate source
            assert(~isempty(this.hSource),'Must provide source in order to save a BLc file');
            
            % branch out to appropriate saving method
            if ~isempty(regexpi(class(this.hSource),'XLTekTxt'))
                files = saveFromXLTekTxt(this,'nosave',varargin{:});
            elseif ~isempty(regexpi(class(this.hSource),'NicoletEFile'))
                files = saveFromNicolet(this,'nosave',varargin{:});
            elseif ~isempty(regexpi(class(this.hSource),'Blackrock'))
                files = saveFromBlackrock(this,'nosave',varargin{:});
            else
                error('Unkown source class ''%s''',class(this.hSource));
            end
        end % END function getOutputFilenames
        
        function files = save(this,varargin)
            % SAVE Write data from source to the output BLc file
            %
            %   SAVE(THIS,...)
            %   Transfer information from the data source to the binary BLc
            %   file. Any arguments after THIS will be passed without
            %   modification to the specialized method for transferring
            %   data from specific sources.
            
            % validate source
            assert(~isempty(this.hSource),'Must provide source in order to save a BLc file');
            
            % branch out to appropriate saving method
            if ~isempty(regexpi(class(this.hSource),'XLTekTxt'))
                files = saveFromXLTekTxt(this,varargin{:});
            elseif ~isempty(regexpi(class(this.hSource),'NicoletEFile'))
                files = saveFromNicolet(this,varargin{:});
            elseif ~isempty(regexpi(class(this.hSource),'Blackrock'))
                files = saveFromBlackrock(this,varargin{:});
            else
                error('Unkown source class "%s"',class(this.hSource));
            end
        end % END function save
    end % END methods
        
    methods(Access=private)
        function loadFromSource(this)
            % LOADFROMSOURCE Load data from source to the BLc object properties
            %
            %   LOADFROMSOURCE(THIS)
            %   Transfer information from the data source to the properties
            %   of the WRITER object THIS.
            
            % branch out to appropriate saving method
            if ~isempty(regexpi(class(this.hSource),'XLTekTxt'))
                loadFromXLTekTxt(this);
            elseif ~isempty(regexpi(class(this.hSource),'Blackrock'))
                loadFromBlackrock(this);
            elseif ~isempty(regexpi(class(this.hSource),'NicoletEFile'))
                loadFromNicolet(this);
            else
                error('Unkown source class "%s"',class(this.hSource));
            end
        end % END function loadFromSource
        
        function bytes = getHeaderBytes(this,numDataSections,segment)
            % GETHEADERBYTES Get header bytes
            %
            %   BYTES = GETHEADERBYTES(THIS)
            %   Place all relevant information into fields in a byte vector
            %   which represents the basic header for the BLC file.
            if nargin<2||isempty(numDataSections),numDataSections=length(this.hSource.SectionStart);end
            if iscell(this.ChannelInfo)
                idxSegment = this.Segment==segment;
                assert(nnz(idxSegment)==1,'Could not identify segment %d in list of available segments %s',segment,util.vec2str(this.Segment));
                chanCount = this.ChannelCount(idxSegment);
                samplingRate = this.SamplingRate(idxSegment);
                originTime = this.OriginTime{idxSegment};
            else
                chanCount = this.ChannelCount;
                samplingRate = this.SamplingRate;
                originTime = this.OriginTime;
            end
            
            % comment field
            CommentBytes = cast(this.Comment(1:min(255,length(this.Comment))),'uint8');
            CommentBytes(end+1:256) = 0; % null-terminated, 256-byte
            this.hDebug.log(sprintf('Set comment to "%s"',this.Comment(1:min(255,length(this.Comment)))),'debug');
            
            % application name
            ApplicationNameBytes = cast(this.ApplicationName(1:min(length(this.ApplicationName),31)),'uint8');
            ApplicationNameBytes(end+1:32) = 0; % null-terminated, 32-byte
            this.hDebug.log(sprintf('Set application name to "%s"',this.ApplicationName(1:min(length(this.ApplicationName),31))),'debug');
            
            % get byte vector for origin time
            TimeOrigin = util.datenum2systime(originTime);
            
            % validate info
            assert(isnumeric(this.FileSpecMajor)&&isnumeric(this.FileSpecMinor),'FileSpecMajor and FileSpecMinor must be numeric, not ''%s''',strjoin(unique({class(this.FileSpecMajor),class(this.FileSpecMinor)}),', '));
            assert(length(TimeOrigin)==8,'TimeOrigin must be a vector of length 8, not %d (one element for each of Year, Month, DayOfWeek, Day, Hour, Minute, Second, and Millisecond)',length(TimeOrigin));
            
            % count number of sections (+1 for ChannelInfo)
            numSections = 1 + numDataSections;
            
            % bytes
            bytes = zeros(1,BLc.Properties.BasicHeaderSize,'uint8');
            bytes(1:8)      = uint8('NEURALCD');
            bytes(9:10)     = typecast(cast(BLc.Properties.BasicHeaderSize,'uint16'),'uint8');
            bytes(11)       = typecast(cast(this.FileSpecMajor,'uint8'),'uint8');
            bytes(12)       = typecast(cast(this.FileSpecMinor,'uint8'),'uint8');
            bytes(13:16)    = typecast(cast(samplingRate,'uint32'),'uint8');
            bytes(17:17)    = typecast(cast(this.BitResolution,'uint8'),'uint8');
            bytes(18:25)    = typecast(cast(chanCount,'uint64'),'uint8');
            bytes(26:41)    = typecast(cast(TimeOrigin,'uint16'),'uint8');
            bytes(42:73)    = ApplicationNameBytes;
            bytes(74:329)   = CommentBytes;
            bytes(330:331)  = typecast(cast(numSections,'uint16'),'uint8');
            bytes(332:332)  = cast(mod(sum(double(bytes(1:BLc.Properties.BasicHeaderSize-1))),256),'uint8');
        end % END function getHeaderBytes
        
        function bytes = getChannelInfoBytes(this,segment)
            % GETCHANNELINFOBYTES Get bytes for channel info headers
            %
            %   BYTES = GETCHANNELINFOBYTES(THIS)
            %   Place all relevant information into fields in a byte vector
            %   which represents the channel info header section for the
            %   BLC file.
            if iscell(this.ChannelInfo)
                idxSegment = this.Segment==segment;
                assert(nnz(idxSegment)==1,'Could not identify segment %d in list of available segments %s',segment,util.vec2str(this.Segment));
                chanCount = this.ChannelCount(idxSegment);
                chanInfo = this.ChannelInfo{idxSegment};
                minAnalogValue = this.MinAnalogValue{idxSegment};
                maxAnalogValue = this.MaxAnalogValue{idxSegment};
            else
                chanCount = this.ChannelCount;
                chanInfo = this.ChannelInfo;
                minAnalogValue = this.MinAnalogValue;
                maxAnalogValue = this.MaxAnalogValue;
            end
            
            % pre-allocate byte vector
            numBytes = BLc.Properties.ChannelInfoHeaderLength + BLc.Properties.ChannelInfoContentLength*chanCount;
            bytes = zeros(1,numBytes,'uint8');
            
            % add the section header
            bytes(1:11)     = uint8('CHANNELINFO');
            bytes(17:18)    = typecast(cast(BLc.Properties.ChannelInfoHeaderLength,'uint16'),'uint8');
            bytes(19:26)    = typecast(cast(numBytes,'uint64'),'uint8');
            bytes(27:34)    = typecast(cast(chanCount,'uint64'),'uint8');
            bytes(35)       = cast(mod(sum(double(bytes(1:BLc.Properties.ChannelInfoHeaderLength-1))),256),'uint8');
            
            % add the channel info packets
            currByte = BLc.Properties.ChannelInfoHeaderLength;
            for kk=1:chanCount
                
                % channel label
                LabelBytes = cast(chanInfo(kk).Label(1:min(15,length(chanInfo(kk).Label))),'uint8');
                LabelBytes(end+1:16) = 0; % null-terminated, 16-byte
                
                % units
                UnitBytes = cast(chanInfo(kk).Units(1:min(15,length(chanInfo(kk).Units))),'uint8');
                UnitBytes(end+1:16) = 0; % null-terminated, 16-byte
                this.hDebug.log(sprintf('Channel %d: label "%s", units "%s"',kk,...
                    chanInfo(kk).Label(1:min(15,length(chanInfo(kk).Label))),...
                    chanInfo(kk).Units(1:min(15,length(chanInfo(kk).Units)))),'debug');
                
                % add bytes
                bytes(currByte + (1:8))     = typecast(cast(chanInfo(kk).ChannelNumber,'uint64'),'uint8');
                bytes(currByte + (9:24))    = LabelBytes;
                bytes(currByte + (25:28))   = typecast(cast(this.MinDigitalValue,'int32'),'uint8');
                bytes(currByte + (29:32))   = typecast(cast(this.MaxDigitalValue,'int32'),'uint8');
                bytes(currByte + (33:36))   = typecast(cast(minAnalogValue,'int32'),'uint8');
                bytes(currByte + (37:40))   = typecast(cast(maxAnalogValue,'int32'),'uint8');
                bytes(currByte + (41:56))   = UnitBytes;
                
                % increment currByte
                currByte = currByte + BLc.Properties.ChannelInfoContentLength;
            end
        end % END function getChannelInfoBytes
        
        function [bytes,numSectionBytes] = getDataSectionHeaderBytes(this,numFramesInSection,sectionTimestamp,sectionDatetime,segment)
            if iscell(this.ChannelInfo)
                idxSegment = this.Segment==segment;
                assert(nnz(idxSegment)==1,'Could not identify segment %d in list of available segments %s',segment,util.vec2str(this.Segment));
                bytesPerFrame = this.BytesPerFrame(idxSegment);
            else
                bytesPerFrame = this.BytesPerFrame;
            end
            
            % compute number of bytes in the section
            numSectionBytes = BLc.Properties.DataHeaderLength + numFramesInSection*bytesPerFrame;
            
            % construct bytes
            bytes = zeros(1,BLc.Properties.DataHeaderLength,'uint8');
            bytes(1:4)    = uint8('DATA');
            bytes(17:18)  = typecast(cast(BLc.Properties.DataHeaderLength,'uint16'),'uint8');
            bytes(19:26)  = typecast(cast(numSectionBytes,'uint64'),'uint8');
            bytes(27:34)  = typecast(cast(numFramesInSection,'uint64'),'uint8');
            bytes(35:42)  = typecast(cast(sectionTimestamp,'uint64'),'uint8');
            bytes(43:58)  = typecast(cast(util.datenum2systime(sectionDatetime),'uint16'),'uint8');
            bytes(59:59)  = mod(sum(double(bytes(1:BLc.Properties.DataHeaderLength-1))),256);
        end % END function getDataSectionHeaderBytes
        
        function setBitResolution(this,val)
            assert(ismember(val,[8 16 32 64]),'This class only supports 8, 16, 32, or 64-bit resolution');
            this.BitResolution = val;
            maxval = 2^(val-1)-1;
            maxval = dec2bin(maxval);
            maxval(end-1:end) = '00';
            maxval = bin2dec(maxval);
            this.MinDigitalValue = -maxval;
            this.MaxDigitalValue = maxval;
            this.hDebug.log(sprintf('Set bit resolution to %d bits with min/max digital values [%d %d]',this.BitResolution,this.MinDigitalValue,this.MaxDigitalValue),'debug');
        end % END function setBitResolution
        
        function [framesPerOutputFile,numOutputFiles] = getFramesPerFile(this,samplingRate)
            
            
            error('This function is broken!');
            maxFramesPerOutputFile = this.SecondsPerOutputFile*samplingRate;
            numFramesLeftInSegment = getSegmentLength(this.hSource,this.Segment);
            numFramesAccountedFor = 0;
            numFramesLeftToWrite = getTotalFrames(this.hSource,this.Segment);%sum(this.hSource.NumDataPoints);
            currFile = 1;
            framesPerOutputFile = nan(1,1e3);
            while numFramesLeftToWrite > 0
                if this.FlagSplitFilesOnSegments
                    
                    % write as many data points as we can, up to the size
                    % of the segment
                    numFramesInThisFile = min(numFramesLeftInSegment,maxFramesPerOutputFile);
                else
                    
                    % here we want to just write the maximum number of data
                    % points possible
                    numFramesInThisFile = min(numFramesLeftToWrite,maxFramesPerOutputFile);
                    
                    % only allow this correction if we don't split on
                    % segments, since we don't want to accidentally merge
                    % two segments
                    if currFile>1 && numFramesInThisFile/framesPerOutputFile(currFile-1)<0.01
                        framesPerOutputFile(end-1) = framesPerOutputFile(end-1) + numFramesInThisFile;
                        numFramesInThisFile = 0;
                    end
                end
                
                % save the results and increment file index
                if numFramesInThisFile>0
                    framesPerOutputFile(currFile) = numFramesInThisFile;
                    currFile = currFile + 1;
                end
                
                
                numFramesAccountedFor = numFramesAccountedFor + numFramesInThisFile;
                numFramesLeftInSegment = numFramesLeftInSegment - numFramesAccountedFor;
                numFramesLeftToWrite = numFramesLeftToWrite - numFramesAccountedFor;
            end
            
            if this.SecondsPerOutputFile < Inf
                maxFramesPerOutputFile = this.SecondsPerOutputFile*samplingRate;
                numOutputFiles = ceil(numDataPoints/maxFramesPerOutputFile);
                framesPerOutputFile = [repmat(maxFramesPerOutputFile,1,numOutputFiles-1) nan];
                framesPerOutputFile(end) = numDataPoints - nansum(framesPerOutputFile);
                if numOutputFiles>1 && framesPerOutputFile(end)/framesPerOutputFile(end-1)<0.01
                    framesPerOutputFile(end-1) = framesPerOutputFile(end-1)+framesPerOutputFile(end);
                    framesPerOutputFile(end) = [];
                    numOutputFiles = length(framesPerOutputFile);
                end
            else
                framesPerOutputFile = numDataPoints;
                numOutputFiles = 1;
            end
            this.hDebug.log(sprintf('Will create %d output files with %s frames per file',numOutputFiles,util.vec2str(framesPerOutputFile)),'debug');
        end % END function getFramesPerFile
        
        function fsstr = getSamplingRateString(this,fsinbase)
            fsstr = '';
            if ~fsinbase,return;end
            if floor(this.SamplingRate/1e3)>=1
                fsstr = sprintf('-fs%dk',floor(this.SamplingRate/1e3));
            else
                fsstr = sprintf('-fs%d',this.SamplingRate);
            end
        end % END function getSamplingRateString
        
        
        % placeholders for externally defined functions
        loadFromXLTekTxt(this);
        loadFromNicolet(this);
        loadFromBlackrock(this);
        files = saveFromXLTekTxt(this,varargin);
        files = saveFromNicolet(this,varargin);
        files = saveFromBlackrock(this,varargin);
        [Fs,NumDataPoints,DataChannels,bytesPerN] = processNicoletObject(this,src);
    end % END methods(Access=private)
end % END classdef Writer