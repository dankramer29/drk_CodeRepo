classdef Reader < handle
    % READER Read binary data from BLC files
    %
    % This class is intended to be used to read neural data stored in the
    % open-source, binary BLC format.
    %
    % To create a BLC object, provide the full path to a BLC file to the object
    % constructor:
    %
    % >> c = BLc.Reader(PATH_TO_BLC_FILE);
    %
    % Use the READ method to read data from the file:
    %
    % >> data = c.read;
    
    properties(SetAccess=private,GetAccess=public)
        hDebug % handle to debug object
        SourceDirectory % directory of the source BLC file
        SourceBasename % basename of the source BLC file
        SourceExtension % file extension of the source BLC file
        SourceFileSize % file size (in bytes) of the source BLC file
        BytesInHeader % how many bytes in the header
        FileSpecMajor % file specification version (major)
        FileSpecMinor % file specification version (minor)
        SamplingRate % sampling rate for the data in the dataset
        BitResolution % bit resolution of the data samples
        ChannelCount % number of channels in the BLC file
        OriginTime % datetime corresponding to date/time at which data were originally recorded
        DataStartTime % datetime corresponding to the first sample in the file
        DataEndTime % datetime corresponding to the last sample in the file
        ApplicationName % name of application used to generate the BLC file
        Comment % comment for the dataset
        NumSections % % number of sections in the data file
        SectionInfo % array of struct, each with info about a section in the channel
        ChannelInfo % array of struct, each struct containing information about a channel
        DataInfo % array of structs, each struct containing information about a section of data
    end % END properties(SetAccess=private,GetAccess=public)
    
    methods
        function this = Reader(varargin)
            % READER Read binary data from BLC files
            %
            %   THIS = READER(PATH_TO_BLC_FILE)
            %   Create a READER object by providing the full path to a BLC
            %   file.
            [varargin,this.hDebug,found_debug] = util.argisa('Debug.Debugger',varargin,[]);
            if ~found_debug,this.hDebug=Debug.Debugger('BLc_Reader','screen');end
            
            % capture source file
            src = [];
            srcIdx = cellfun(@(x)ischar(x)&&exist(x,'file')==2,varargin);
            if any(srcIdx)
                src = varargin{srcIdx};
                varargin(srcIdx) = [];
            else
                dirIdx = cellfun(@(x)ischar(x)&&exist(x,'dir')==7,varargin);
                if any(dirIdx)
                    srcdir = varargin{dirIdx};
                    varargin(dirIdx) = [];
                    [srcfile,srcdir] = uigetfile(fullfile(srcdir,'*.blc'),'Select a file','MultiSelect','off');
                    assert(~isnumeric(srcfile),'Must select a valid file to continue');
                    src = fullfile(srcdir,srcfile);
                end
            end
            assert(~isempty(src),'Must provide a valid source file');
            srcinfo = dir(src);
            [this.SourceDirectory,this.SourceBasename,this.SourceExtension] = fileparts(src);
            this.SourceFileSize = srcinfo.bytes;
            this.hDebug.log(sprintf('Selected source file "%s" (%d bytes)',src,srcinfo.bytes),'info');
            
            % make sure no leftover inputs
            assert(isempty(varargin),'Unexpected inputs');
            
            % read headers
            headers(this);
        end % END function BLc
        
        function headers(this)
            % HEADERS Process headers in the BLC file
            %
            %   HEADERS(THIS)
            %   Extract information from the BLC headers and populate the
            %   various properties of the READER object.
            
            % open the file for reading
            srcfile = fullfile(this.SourceDirectory,sprintf('%s%s',this.SourceBasename,this.SourceExtension));
            fid = util.openfile(srcfile);
            
            % read out the basic header
            try
                
                % file type - must be NEURALCD for neural continuous data
                fileType = cast(fread(fid,8,'*uint8'),'char');
                assert(strcmpi('NEURALCD',fileType(:)'),'The first 8 bytes of the file must be equal to ''NEURALCD''');
                
                % bytes in header
                this.BytesInHeader = fread(fid,1,'uint16=>double');
                assert(this.SourceFileSize>=this.BytesInHeader,'Header size (%d bytes) is larger than file size (%d bytes)',...
                    this.BytesInHeader,this.SourceFileSize);
                
                % read header bytes and validate checksum
                fseek(fid,0,'bof');
                bytes = fread(fid,this.BytesInHeader,'*uint8');
                headerChecksum = bytes(end);
                computedChecksum = mod(sum(double(bytes(1:end-1))),256);
                assert(headerChecksum==computedChecksum,'Invalid checksum (found %d but expected %d)',headerChecksum,computedChecksum);
                
                % get the file specification version
                this.FileSpecMajor = cast(bytes(11),'double');
                this.FileSpecMinor = cast(bytes(12),'double');
            catch ME
                util.closefile(srcfile);
                rethrow(ME);
            end
            
            % close the file
            util.closefile(srcfile);
            
            % process remaining header based on file spec version
            this.hDebug.log(sprintf('File spec %d.%d',this.FileSpecMajor,this.FileSpecMinor),'debug');
            vstr = sprintf('v%d.%d',this.FileSpecMajor,this.FileSpecMinor);
            switch vstr
                case 'v0.0', preprocess_v0_0(this);
                case 'v0.1', preprocess_v0_1(this);
                case 'v0.2', preprocess_v0_2(this);
                otherwise
                    error('Unknown version "%s"',vstr);
            end
        end % END function headers
        
        function old_verbosity = setVerbosity(this,new_verbosity,logger)
            % SETVERBOSITY Set the verbosity level of the debug object
            %
            %   OLD = SETVERBOSITY(THIS,NEW)
            %   Set the verbosity level for THIS to the DEBUG.PRIORITYLEVEL
            %   enumeration object in NEW, and return the original
            %   verbosity level in OLD.
            assert(isa(new_verbosity,'Debug.PriorityLevel'),'Must provide valid Debug.PriorityLevel object, not "%s"',class(new_verbosity));
            if nargin<3||isempty(logger),logger='screen';end
            client = 'BLc.Reader';
            old_verbosity = this.hDebug.setVerbosity(new_verbosity,logger,client);
        end % END function setDebug
        
        function delete(this)
            try
                if ~isempty(this.SourceBasename)
                    srcfile = fullfile(this.SourceDirectory,sprintf('%s%s',this.SourceBasename,this.SourceExtension));
                    util.closefile(srcfile);
                end
            catch ME
                util.errorMessage(ME);
            end
        end % END function delete
    end % END methods
end % END classdef BLc