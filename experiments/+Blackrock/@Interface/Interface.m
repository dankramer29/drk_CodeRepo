classdef Interface < handle & util.Structable
    % INTERFACE Interact with Blackrock NSPs through CBMEX
    %
    %   The Blackrock Interface class serves as the MATLAB interface to
    %   Blackrock NSP hardware or NPlayServer software through the 
    %   Blackrock CBMEX MATLAB API.  This class provides basic 
    %   functionality for neural data recording and for reading timestamps
    %   and data.
    %
    %   The default settings of this class will open a connection to a
    %   single NSP or instance of NPlayServer using the default CBMEX
    %   interface.
    %
    %   Neural data recordings will be saved in the output folder defined
    %   either by the HST environment variable OUTPUT, if it is not empty,
    %   or in 'C:\Share\YYYYMMDD' if the environment variable is empty.
    %   Subdirectories of this folder will be created for each of the NSP
    %   strings.  The filenames of the recorded files will be constructed 
    %   using the idString, userString, and nspString properties with an 
    %   appended (incrementing) file index, constructed as 
    %   {idString}-{userString}-{nspString}-{fileIdx}.
    %
    %   The Blackrock CBMEX MATLAB API must be on the path, or it must
    %   reside in a subfolder 'CBMEX' of the current MATLAB folder.
    %
    %   See also BLACKROCK.INTERFACE/INTERFACE.
    
    properties
        hDebug % debug object
        outputPath % path for saving neural data recordings
        idString % character string used as first element of base filename, default YYYYMMDD
        userString % additional customizing string
        nspString = {'NSP1'}; % label each NSP, default 'NSP1'
        cbmexOpenArgs = {{}}; % arguments provided to cbmex
        cbmexInterface = 0; % default CBMEX interface type
        timeUnits = 'samples'; % return time as 'seconds' or 'samples'
    end % END properties
    
    properties(GetAccess='public',SetAccess='private')
        baseFilename % the full base filename of the output files
        recordFilenames % the filenames for actual recordings
        recordDirectories % the directories for actual recordings
        numInstances % number of attached NSPs or NPlayServers
        fileIdx = 0; % incremental index of the current file recording
        isRecording = false; % logical status indicating whether recording
        isOpen = false; % logical status indicating whether CBMEX open
    end % END properties(GetAccess='public',SetAccess='private')
    
    methods
        function this = Interface(varargin)
            % INTERFACE Constructor for the Interface class
            %
            %   B = INTERFACE
            %   Create an object of the Blackrock.Interface class.  Default
            %   behavior is to receive data from a single NSP or instance
            %   of NPlayServer using the default CBMEX interface.  Default
            %   values for each property are listed below.  Any publically
            %   writeable property may be set as a keyword-value input pair
            %   in the arguments of the constructor.  Use the MATLAB 
            %   'properties' function to get a list of all properties of 
            %   this class.
            %
            %   INTERFACE(...,'OUTPUTPATH',DIR)
            %   The default output directory will be read from the HST
            %   environment variable OUTPUT; if that is empty, it will be
            %   'C:\Share\YYYYMMDD'.  Use this input to override these
            %   default values.
            %
            %   INTERFACE(...,'IDSTRING',STR)
            %   The default ID string the current timestamp in the format
            %   YYYYMMDD-HHMMSS.  Use this input to override the default.
            %
            %   INTERFACE(...,'USERSTRING',STR)
            %   The default user string is empty (so the default filename
            %   would actually be {idString}-{nspString}-{fileIdx}).  Use
            %   this input to override the default value.
            %
            %   INTERFACE(...,'NSPSTRING',STR)
            %   The default NSP string is 'NSP1'.  Provide a single
            %   string for each CBMEX instance.  Provide a cell array of
            %   strings to use multiple CBMEX instances.
            %
            %   INTERFACE(...,'TIMEUNITS','SECONDS')
            %   INTERFACE(...,'TIMEUNITS','SAMPLES')
            %   The default unit of time is samples.  Use these options to
            %   override or confirm the default.  The default can also be
            %   overriden at run time via input arguments to the 'time' 
            %   method.
            %
            %   INTERFACE(...,'CBMEXOPENARGS',ARGS)
            %   By default, no additional arguments are provided to CBMEX 
            %   when opening the interface aside from the interface type 
            %   and the instance number.  However, CBMEX accepts a number 
            %   of arguments which can be used to customize how it looks 
            %   for the NSPs or NPlayServers and the size of the buffer:
            %
            %       'inst-addr': string containing instrument ipv4 address
            %       'inst-port': instrument port number
            %       'central-addr': string containing central ipv4 address
            %       'central-port': central port number
            %       'receive-buffer-size': network buffer size
            %
            %   Information about these CBMEX arguments is provided for 
            %   convenience only and may not be accurate in the future.  
            %   Type cbmex('help','open') at the MATLAB command line to see
            %   the current interface definition.
            %
            %   ARGS must be a cell array of cell arrays.  The outer cell
            %   array must have one cell per CBMEX instance.  The inner 
            %   cell arrays contain the keyword-value pairs that will be 
            %   passed directly to CBMEX.  Here is an example for two 
            %   instances:
            %
            %       {{'KEYWORD1',VALUE1},{'KEYWORD1',VALUE1}}
            %
            %   INTERFACE(...,'CBMEXINTERFACE',VAL)
            %   By default, CBMEX will be opened with interface 0, which
            %   specifies its own internal default.  Use this command to 
            %   override the default value (0 - default, 1 - Central, 
            %   2 - UDP).  VAL should be a vector with one entry per CBMEX
            %   instance.
            %
            %   See also BLACKROCK.INTERFACE.
            
            % check dependency
            if exist('cbmex','file')~=3
                cbmexFolder = mfilename('fullpath');
                cbmexFolder = cbmexFolder(1:strfind(cbmexFolder,meta.class.fromName(class(this)).ContainingPackage.Name)-3);
                cbmexFolder = fullfile(cbmexFolder,'cbmex');
                if exist(cbmexFolder,'dir')==7
                    addpath(cbmexFolder);
                end
            end
            assert(exist('cbmex','file')==3,'Cannot find "cbmex" dependency');
            
            % debug object
            [varargin,this.hDebug,found_dbg] = util.argisa('Debug.Debugger',varargin,nan);
            if ~found_dbg,this.hDebug=Debug.Debugger('blackrock_interface','screen');end
            
            % default id string indicating current date/time
            this.idString = datestr(now,'yyyymmdd-HHMMSS');
            
            % default output path
            [output,subject] = env.get('output','subject');
            if isempty(output), output='C:\Share'; end
            if ~isempty(subject), output=fullfile(output,upper(subject)); end
            this.outputPath = fullfile(output,datestr(now,'yyyymmdd'));
            
            % user inputs override defaults
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % define nspString
            if ~iscell(this.nspString), this.nspString={this.nspString}; end
            
            % calculate numInstances
            this.numInstances = length(this.nspString);
            this.hDebug.log(sprintf('Number of CBMEX instances set to %d',this.numInstances),'info');
            
            % trim other arguments if needed
            if length(this.cbmexOpenArgs)>this.numInstances, this.cbmexOpenArgs=this.cbmexOpenArgs(1:this.numInstances); end
            if length(this.cbmexInterface)>this.numInstances, this.cbmexInterface=this.cbmexInterface(1:this.numInstances); end
            
            % error checks
            assert(ischar(this.outputPath),'Output path must be a string');
            assert(length(this.cbmexOpenArgs)==this.numInstances,'There must be one cell array of CBMEX open arguments per CBMEX instance (expected %d, not %d)',this.numInstances,length(this.cbmexOpenArgs));
            assert(length(this.cbmexInterface)==this.numInstances,'There must be one CBMEX interface specifications per CBMEX instance (expected %d, not %d)',this.numInstances,length(this.cbmexInterface));
            
            % check output path exists, mkdir if not
            if exist(this.outputPath,'dir')~=7
                [status,msg] = mkdir(this.outputPath);
                assert(status>=0,'Could not create directory ''%s'': %s',this.outputPath,msg);
                this.hDebug.log(sprintf('Created output directory "%s"',this.outputPath),'debug');
            end
            
            % base filename: {idString}-{userString}
            % (nspString and fileIdx will be added later)
            ustr = '';
            if ~isempty(this.userString)
                ustr = sprintf('-%s',this.userString);
            end
            this.baseFilename = sprintf('%s%s',this.idString,ustr);
            this.hDebug.log(sprintf('Base filename set to "%s"',this.baseFilename),'info');
        end % END function Interface
        
        function initialize(this)
            % INITIALIZE Initialize the CBMEX interface
            %
            %   INITIALIZE(THIS)
            %   Lock the current settings and open the requested number of
            %   CBMEX instances.  Also, configure the NSPs to start 
            %   buffering data.
            
            % make sure the interface is not open
            assert(~this.isOpen,'CBMEX interface already open');
            
            % initialize CBMEX
            for kk=1:this.numInstances
                args = this.cbmexOpenArgs{kk};
                int = this.cbmexInterface(kk);
                cbmex('open',int,'instance',kk-1,args{:});
                this.hDebug.log(sprintf('cbmex(''open'',%d,''instance'',%d,%s)\n',int,kk-1,util.cell2str(args)),'debug');
            end
            
            % configure data buffering
            for kk=1:this.numInstances
                cbmex('trialconfig',1,'instance',kk-1);
                this.hDebug.log(sprintf('cbmex(''trialconfig'',1,''instance'',%d)\n',kk-1),'debug');
            end
            
            % update status
            this.isOpen = true;
            
            % update user
            this.hDebug.log('Blackrock CBMEX interface initialized','info');
        end % END function initialize
        
        function record(this,varargin)
            % RECORD Start recording neural data
            %
            %   RECORD(THIS)
            %   Start recording neural data using the existing output path
            %   and base filename constructed as described in the
            %   documentation for this class and class constructor.
            %
            %   RECORD(...,'BASE[FILENAME]',STR)
            %   Override the default base filename with the value in STR.
            %
            %   See also BLACKROCK.INTERFACE,
            %   BLACKROCK.INTERFACE/INTERFACE.
            
            % make sure the interface is open and not recording
            assert(this.isOpen,'CBMEX interface not open');
            assert(~this.isRecording,'CBMEX interface already recording');
            
            % update file index
            this.fileIdx = this.fileIdx + 1;
            
            % allow final user-override on base filename
            [varargin,base] = util.argkeyval('basefilename',varargin,this.baseFilename,4);
            util.argempty(varargin);
            
            % create full path to recorded outputs
            recordPaths = cell(1,length(this.numInstances));
            this.recordFilenames = cell(1,length(this.numInstances));
            this.recordDirectories = cell(1,length(this.numInstances));
            for kk=1:this.numInstances
                if ischar(this.nspString{kk})
                    this.recordFilenames{kk} = sprintf('%s-%s-%03d',base,this.nspString{kk},this.fileIdx);
                     this.recordDirectories{kk} = fullfile(this.outputPath,this.nspString{kk});    
                else
                    this.recordFilenames{kk} = sprintf('%s-%s-%03d',base,this.nspString{kk}.ID,this.fileIdx);
                    this.recordDirectories{kk} = fullfile(this.outputPath,this.nspString{kk}.ID);
                end
                if exist(this.recordDirectories{kk},'dir')~=7
                    [status,msg] = mkdir(this.recordDirectories{kk});
                    assert(status>=0,'Could not create directory "%s": %s',this.recordDirectories{kk},msg);
                    this.hDebug.log(sprintf('Created output directory "%s"',this.recordDirectories{kk}),'debug');
                end
                recordPaths{kk} = fullfile(this.recordDirectories{kk},this.recordFilenames{kk});
            end
            
            % check whether outputs exist already
            for kk=1:this.numInstances
                list = dir(sprintf('%s.*',recordPaths{kk}));
                if ~isempty(list)
                    warning('File already exists! Dropping to keyboard; edit ''recordPaths'' cell array and hit F5 to continue.');
                    keyboard
                end
            end
            
            % start recording
            for kk=1:this.numInstances
                cbmex('fileconfig',recordPaths{kk},'',0,'instance',kk-1); % bring up file storage app
                this.hDebug.log(sprintf('cbmex(''fileconfig'',%s,'''',0,''instance'',%d)\n',recordPaths{kk},kk-1),'debug');
                pause(1);
                cbmex('fileconfig',recordPaths{kk},'',1,'instance',kk-1); % begin recording
                this.hDebug.log(sprintf('cbmex(''fileconfig'',%s,'''',1,''instance'',%d)\n',recordPaths{kk},kk-1),'debug');
                pause(1);
            end
            this.isRecording = true;
        end % END function record
        
        function stop(this)
            % STOP Stop recording neural data
            %
            %   STOP(THIS)
            %   Stop recording neural data.  Will generate an error if the
            %   interface is not open or it is not recording.
            
            % make sure the interface is open and recording
            assert(this.isOpen,'CBMEX interface not open');
            assert(this.isRecording,'CBMEX interface not recording');
            
            % stop recording
            for kk=1:this.numInstances
                cbmex('fileconfig',fullfile(this.recordDirectories{kk},this.recordFilenames{kk}),'',0,'instance',kk-1); % stop file storage
                this.hDebug.log(sprintf('cbmex(''fileconfig'',%s,'''',0,''instance'',%d)\n',fullfile(this.recordDirectories{kk},this.recordFilenames{kk}),kk-1),'debug');
                pause(1);
            end
            this.isRecording = false;
        end % END function stop
        
        function t = time(this,varargin)
            % TIME Get the current neural time
            %
            %   Note that this function (and generally, this class) makes
            %   the assumption that physical NSPs are running in synch so
            %   that only one timestamp is ever needed to know the time for
            %   all NSPs.
            %
            %   TIME(THIS)
            %   Read a single timestamp (in seconds) from the first logical
            %   NSP.
            %
            %   TIME(...,'SAMPLES')
            %   Read all values in samples rather than in seconds.
            %
            %   TIME(...,IDX)
            %   Read timestamps from the CBMEX instances listed in the 
            %   vector IDX.
            %
            %   TIME(...,'ALL')
            %   Read timestamps from all logical NSPs.
            
            % make sure the interface is open
            assert(this.isOpen,'CBMEX interface not open');
            
            % quickly determine samples vs seconds
            args = {};
            if strcmpi(this.timeUnits,'samples') || any(strcmpi(varargin,'samples')), args={'samples'}; end
            if any(strcmpi(varargin,'seconds')), args={}; end
            
            % fast or thorough modes
            if isempty(varargin)
                
                % fast mode: no further input arguments, just get the time
                t = cbmex('time','instance',0,args{:});
                this.hDebug.log(sprintf('cbmex(''time'',''instance'',0,%s)\n',util.cell2str(args)),'debug');
            else
                
                % get rid of used arguments
                varargin(strcmpi(varargin,'samples')|strcmpi(varargin,'seconds'))=[];
                
                % process remaining inputs
                idx = 1:this.numInstances;
                if ~isempty(varargin), idx = varargin{1}; end
                
                % read cbmex times
                t = zeros(length(idx),1);
                for kk=1:length(idx)
                    t(kk) = cbmex('time','instance',idx(kk)-1,args{:});
                    this.hDebug.log(sprintf('cbmex(''time'',''instance'',%d,%s)\n',idx(kk)-1,util.cell2str(args)),'debug');
                end
            end
        end % END function time
        
        function [t,event,continuous] = read(this,varargin)
            % READ Read timestamp and neural data from the CBMEX interface
            %
            %   [T,EVENT,CONT] = READ(THIS)
            %   Read the current timestamp (units determined by TIMEUNITS 
            %   property) from the first CBMEX instance, and read the event
            %   and continuous data from each CBMEX instance in EVENT and 
            %   CONTINUOUS respectively.  EVENT and CONTINUOUS will be cell
            %   arrays with one cell per instance.
            %
            %   READ(...,IDX)
            %   Specify the CBMEX instances in IDX from which to read event
            %   and continuous data (However, timestamp will still only 
            %   from the first of the requested CBMEX instances).
            
            % make sure the interface is open
            assert(this.isOpen,'CBMEX interface not open');
            
            % user inputs
            idx = 1:this.numInstances;
            if nargin>1, idx = varargin{1}; end
            
            % get the current time (using default time units)
            t = time(this);
            
            % read data from CBMEX
            event = cell(1,length(idx));
            continuous = cell(1,length(idx));
            for kk=1:length(idx)
                [event{kk},~,continuous{kk}] = cbmex('trialdata',1,'instance',idx(kk)-1);
            end
        end % END function read
        
        function filenames = getRecordedFilenames(this,varargin)
            % GETRECORDEDFILENAMES Get the output filenames
            %
            %   GETRECORDEDFILENAMES(THIS)
            %   Retrieve the actual filename(s) (basenames only, no
            %   extensions) used to record neural data.
            %
            %   GETRECORDEDFILENAMES(...,IDX)
            %   Retrieve the filenames only for the logical NSPs specified
            %   by IDX.
            %
            %   GETRECORDEDFILENAMES(...,'ALL')
            %   Same as default behavior.
            
            % user inputs
            idx = 1:this.numInstances;
            if nargin>1, idx = varargin{1}; end
            
            % index the filenames
            if isempty(this.recordFilenames)
                filenames = {};
            else
                filenames = this.recordFilenames(idx);
            end
        end % END function getRecordedFilenames
        
        function comment(this,msg,varargin)
            % COMMENT Add a comment to the neural data recordings
            %
            %   COMMENT(THIS,MSG)
            %   Add the string in MSG to the neural data recordings of all
            %   logical NSPs.  Will generate an error if the CBMEX
            %   interface is not open or is not recording.
            %
            %   COMMENT(...,'color',CLR)
            %   Specify the color of the message by the single 24-bit
            %   integer CLR (i.e., 0-16777215). Common colors include:
            %
            %     black - 0
            %     white - 16777215
            %     red - 255
            %     green - 65280
            %     blue - 16711680
            %     yellow - 65535
            %     magenta - 16711935
            %     cyan - 16776960
            %
            %   See CBMEX documentation for more information.
            %
            %   COMMENT(...,'charset',CHR)
            %   Specify the character set of the message by the single
            %   integer CHR. Options are:
            %
            %     0 for ASCII
            %     1 for UTF16
            %
            %   See CBMEX documentation for more information.
            
            % make sure open and recording
            assert(this.isOpen,'CBMEX interface not open');
            assert(this.isRecording,'CBMEX interface not recording');
            
            % clamp the message
            if length(msg)>127
                msg(128:end)=[];
                this.hDebug.log('Clamped message length to 127 characters','debug');
            end
            
            % set the color (see CBMEX documentation)
            clr = 0;
            idx1 = strcmpi(varargin,'color');
            if any(idx1)
                idx2 = circshift(idx1,1,2);
                clr = varargin{idx2};
                varargin(idx1|idx2) = [];
            end
            
            % set the charset (see CBMEX documentation)
            charset = 0;
            idx1 = strcmpi(varargin,'charset');
            if any(idx1)
                idx2 = circshift(idx2,1,2);
                charset = varargin{idx2};
                varargin(idx1|idx2) = [];
            end
            
            % read cbmex times
            for kk=1:this.numInstances
                cbmex('comment',clr,charset,msg,'instance',kk-1);
                this.hDebug.log(sprintf('cbmex(''comment'',%d,%d,''%s'',''instance'',%d)\n',clr,charset,msg,kk-1),'debug');
            end
        end % END function comment
        
        function close(this)
            % CLOSE Close the CBMEX interface
            %
            %   CLOSE(THIS)
            %   If recording, stop recording, then close the CBMEX
            %   interface.
            
            % make sure the interface is open
            assert(this.isOpen,'CBMEX interface not open');
            
            % stop recording
            if this.isRecording, stop(this); end
            
            % close the CBMEX interface
            for kk=1:this.numInstances
                cbmex('close','instance',kk-1);
                this.hDebug.log(sprintf('cbmex(''close'',''instance'',%d)\n',kk-1),'debug');
            end
            this.isOpen = false;
            
            % unload the CBMEX interface
            clear cbmex;
        end % END function close
        
        function delete(this)
            % DELETE Delete the object
            %
            %   DELETE(THIS)
            %   If the Interface is open, close it, then delete the object
            %   as normal.
            
            % if open, close
            if this.isOpen, close(this); end
        end % END function delete
    end % END methods
    
    methods(Static)
        function cleanup
            if exist('cbmex','file')~=3, return; end
            for kk=0:3
                try
                    cbmex('close','instance',kk); catch ME, util.errorMessage(ME);
                    this.hDebug.log(sprintf('cbmex(''close'',''instance'',%d)\n',kk),'debug');
                end
            end
            clear cbmex;
        end % END function cleanup
    end % END methods(Static)
end % END classdef Interface