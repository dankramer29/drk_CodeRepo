classdef Options < handle & util.Structable
    % OPTIONS Manage Framework parameters and options
    %   
    %   The OPTIONS class is intended to be used internally by the
    %   Framework.  However, Framework config files may set any of the
    %   properties listed below to override default values.
    %   
    %   See also FRAMEWORK.INTERFACE.
    
    properties
        
        % internal parameters
        saveDirectory % directory where all outputs will be saved
        runName = 'framework'; % a string to be inserted into saved filenames
        headless = false; % run without any GUIs
        enableNeural = true; % enable or disable neural data recording
        enableTask = true; % enable or disable the task
        enablePredictor = true; % enable or disable the predictor
        enableVideo = true; % enable or disable video recording
        enableSync = false; % enable or disable sync pulse generator
        enableEyeTracker = false; % enable or disable eye tracking
        
        % control verbosity
        verbosity % 0 no output, 1 +errors, 2 +warnings, 3 +info, 4 +hints, 5 +debug
        verbosityBuffer = inf; % level of verbosity for Framework buffer
        verbosityScreen = 1; % level of verbosity for the screen
        verbosityNeural = 1; % level of verbosity for the neural file
        unifiedVerbosityControl = true; % if true, "verbosity" option overwrites all individual "verbosity*" options
        mirrorCommentsToNeural = true; % send all comments (within verbosityNeural constraint) to the neural file
        endCommentFrameId = Inf; % frame ID after which end comment will be required when framework stops
        
        % timer parameters
        timerPeriod = 0.05; % interval for timer object (seconds)
        timerStartDelay = 2; % start delay for timer object (seconds)
        timerTimerFcn = @timerFcn; % timer function (runs every timerPeriod seconds)
        timerErrorFcn = @errorFcn; % error function (runs when error occurs)
        timerStartFcn = @startFcn; % start function (runs once when timer starts)
        timerStopFcn = @stopFcn; % stop function (runs once when timer stops)
        
        % framework heartbeat event
        heartbeatMode = 'frame'; % 'time','task','frame'
        heartbeatInterval = 1; % interval at which to notify FrameworkHeartbeat event
        
        % limits on runtime
        frameLimit = inf; % stop running after certain number of frames
        timeLimit = inf; % stop running after certain amount of time
        taskLimit = inf; % stop running after a certain task quanta
        limitFcn = @(fw)fw.runtimeLimitFcn; % function to run when limit reached ~ @(hFramework)
        
        % GUIs
        guiConstructor = {@Framework.GUI.Default}; % cell array of function handles to GUI class constructors
        guiConfig = {[]}; % specify which config files to use for each GUI
        
        % predictor
        predictorConstructor = @Framework.Predictor.Dummy; % list of constructor function handles for predictors to use (cell array)
        predictorConfig = @(x)x; % handles to config functions for predictor objects (cell array)
        
        % task
        taskConstructor % file in the Task or Experiment package to give task controller handle
        taskConfig % script name containing parameters for the task
        taskDisplayRefresh = false; % whether to trigger the display refresh from the Framework
        
        % neural source
        neuralConstructor = @Framework.NeuralSource.Rand; % source of neural data
        neuralConfig = @Framework.NeuralSource.Config.RandData; % handle to configuration function
        
        % sync
        syncConstructor % handle to constructing function which returns video object
        syncConfig % config file for setting parameters of the video object
        
        % eye tracking
        eyeConstructor % handle to constructing function which returns eye tracking object
        eyeConfig % config file for setting parameters of the eye tracking object
        
        % video
        videoConstructor = @Framework.Video.Dummy; % handle to constructing function which returns video object
        videoConfig = @(x)x; % config file for setting parameters of the video object
        
        % DOF configuration
        nVarsPerDOF % number of quantities for each DOF (1xnDOF vector)
        
        % environment information
        location % name of the current location (e.g., 'Keck')
        nsps % names of the NSPs
        type % type of location ('PRODUCTION' or 'DEVELOPMENT')
        subject % which subject is connected
        researcher % which researcher is running the session
        output % output parent directory
        debug % debug mode
    end % END properties
    
    properties(Access=private)
        original
    end % END properties(Access=private)
    
    properties(GetAccess=public,SetAccess=private)
        nDOF % number of DOFs in the system
        stopwatch % track time elapsed
    end % END properties(GetAccess=public,SetAccess=private)
    
    methods
        function val = get.verbosityBuffer(this)
            val = this.verbosityBuffer;
            if this.unifiedVerbosityControl
                val = this.verbosity;
            end
        end % END function get.verbosityBuffer
        function val = get.verbosityScreen(this)
            val = this.verbosityScreen;
            if this.unifiedVerbosityControl
                val = this.verbosity;
            end
        end % END function get.verbosityScreen
        function val = get.verbosityNeural(this)
            val = this.verbosityNeural;
            if this.unifiedVerbosityControl
                val = this.verbosity;
            end
        end % END function get.verbosityNeural
        function set.verbosityBuffer(this,val)
            assert(isnumeric(val),'Verbosity level must be a number');
            this.verbosityBuffer = round(val);
        end % END function set.verbosityBuffer
        function set.verbosityScreen(this,val)
            assert(isnumeric(val),'Verbosity level must be a number');
            this.verbosityScreen = round(val);
        end % END function set.verbosityScreen
        function set.verbosityNeural(this,val)
            assert(isnumeric(val),'Verbosity level must be a number');
            this.verbosityNeural = round(val);
        end % END function set.verbosityNeural
        function set.taskLimit(this,val)
            assert(isnumeric(val),'Task limit must be a number');
            this.taskLimit = round(val);
        end % END function set.taskLimit
        function set.frameLimit(this,val)
            assert(isnumeric(val),'Frame limit must be a number');
            this.frameLimit = round(val);
        end % END function set.frameLimit
        function set.timeLimit(this,val)
            assert(isnumeric(val),'Time limit must be a number');
            this.timeLimit = round(val);
        end % END function set.timeLimit
        
        function this = Options(cfg,varargin)
            assert(isa(cfg,'function_handle'),'Must provide a config function handle');
            
            % load environment variables in this order for dependencies
            [this.type,this.location,this.subject,this.researcher] = env.get('type','location','subject','researcher');
            [this.nsps,this.output,this.debug,this.verbosity] = env.get('nsps','output','debug','verbosity');
            assert(~isempty(this.type),'Must set the TYPE environment variable');
            assert(~isempty(this.location),'Must set the LOCATION environment variable');
            if strcmpi(this.type,'PRODUCTION')
                assert(~isempty(this.subject),'Must set the SUBJECT environment variable');
                assert(~isempty(this.researcher),'Must set the RESEARCHER environment variable');
                this.endCommentFrameId = 500; % require end comment if frame id > 500 when framework stops
            end
            if isempty(this.output), this.output = 'C:\Share'; end
            if ~isempty(this.subject), this.output = fullfile(this.output,upper(this.subject)); end
            this.output = fullfile(this.output,datestr(now,'yyyymmdd'));
            
            % default save directory
            this.saveDirectory = {fullfile(this.output,'Task')};
            
            % process overriding command-line inputs (name-value pairs)
            % do this before passing varargin to config so that everything
            % left is just for config file -- not for overriding options
            user = [];
            propertyNames = properties(this);
            for kk=1:length(propertyNames)
                idx = find(strcmpi(varargin,propertyNames{kk}));
                if ~isempty(idx) && length(varargin)>=idx+1
                    user.(propertyNames{kk}) = varargin{idx+1};
                    varargin(idx:idx+1) = [];
                end
            end
            
            % process user-specified config files
            feval(cfg,this,varargin{:});
            
            % verify nsps identified in production environment
            if strcmpi(this.type,'PRODUCTION')
                assert(~isempty(this.nsps),'Must identify NSPs in production environment');
            end
            
            % assign user overriding command-line inputs
            if ~isempty(user)
                propertyNames = fieldnames(user);
                for kk=1:length(propertyNames)
                    this.(propertyNames{kk}) = user.(propertyNames{kk});
                end
            end
            
            % saveDirectory should be a cell array
            if ~iscell(this.saveDirectory)
                this.saveDirectory = {this.saveDirectory};
            end
            
            % whole numbers for verbosity
            this.verbosityBuffer = round(this.verbosityBuffer);
            this.verbosityNeural = round(this.verbosityNeural);
            this.verbosityScreen = round(this.verbosityScreen);
            this.verbosity = round(this.verbosity);
            
            % basic error checking
            assert(any(strcmpi(this.type,{'PRODUCTION','DEVELOPMENT'})),'type must be one of ''PRODUCTION'' or ''DEVELOPMENT''');
            assert(isa(this.timerTimerFcn,'function_handle'),'timerTimerFcn must be a function handle');
            assert(isa(this.timerErrorFcn,'function_handle'),'timerErrorFcn must be a function handle');
            assert(isa(this.timerStartFcn,'function_handle'),'timerStartFcn must be a function handle');
            assert(isa(this.timerStopFcn,'function_handle'),'timerStopFcn must be a function handle');
            assert(any(strcmpi(this.heartbeatMode,{'time','task','frame'})),'HeartbeatMode must be one of ''time'', ''task'', or ''frame''');
            if ~this.enableTask,assert(~strcmpi(this.heartbeatMode,'task'),'HeartbeatMode cannot be task when task is disabled');end
            assert(isa(this.limitFcn,'function_handle'),'limitFcn must be a function handle');
            if ~this.headless
                this.guiConfig = util.ascell(this.guiConfig);
                assert(iscell(this.guiConstructor),'guiConstructor must be a cell array');
                assert(length(this.guiConstructor)==length(this.guiConfig),'guiConfig must have the same length as guiConstructor');
                assert(exist(func2str(this.guiConstructor{1}),'class')==8,'Cannot locate GUI constructor ''%s''',func2str(this.guiConstructor{1}));
            end
            if this.enablePredictor
                assert(isa(this.predictorConstructor,'function_handle'),'predictorConstructor must be a function_handle');
                assert(exist(func2str(this.predictorConstructor),'class')==8,'Cannot locate predictor constructor ''%s''',func2str(this.predictorConstructor));
            end
            if this.enableTask
                this.taskConfig = util.ascell(this.taskConfig);
                assert(isa(this.taskConstructor,'function_handle'),'taskConstructor must be a function_handle');
                assert(exist(func2str(this.taskConstructor),'class')==8,'Cannot locate task constructor ''%s''',func2str(this.taskConstructor));
            end
            if this.enableNeural
                this.neuralConfig = util.ascell(this.neuralConfig);
                assert(isa(this.neuralConstructor,'function_handle'),'neuralConstructor must be a function_handle');
                assert(exist(func2str(this.neuralConstructor),'class')==8,'Cannot locate neural constructor ''%s''',func2str(this.neuralConstructor));
            end
            if this.enableVideo
                this.videoConfig = util.ascell(this.videoConfig);
                assert(isa(this.videoConstructor,'function_handle'),'videoConstructor must be a function_handle');
                assert(exist(func2str(this.videoConstructor),'class')==8,'Cannot locate video constructor ''%s''',func2str(this.videoConstructor));
            end
            if this.enableSync
                this.syncConfig = util.ascell(this.syncConfig);
                assert(isa(this.syncConstructor,'function_handle'),'syncConstructor must be a function_handle');
                assert(exist(func2str(this.syncConstructor),'class')==8,'Cannot locate sync constructor ''%s''',func2str(this.syncConstructor));
            end
            if this.enableEyeTracker
                this.eyeConfig = util.ascell(this.eyeConfig);
                assert(isa(this.eyeConstructor,'function_handle'),'eyeConstructor must be a function_handle');
                assert(exist(func2str(this.eyeConstructor),'class')==8,'Cannot locate eye tracking constructor ''%s''',func2str(this.eyeConstructor));
            end
            
            % handle task config differently: if empty or nonexistent, set
            % to empty, and GUI drop-down box's value will be used
            if this.enableTask
                if isempty(this.taskConfig) || ~isa(this.taskConfig{1},'function_handle')
                    this.taskConfig = [];
                elseif util.existp(func2str(this.taskConfig{1}))~=2
                    if this.verbosity>=2
                        warning('Could not locate task config ''%s'': will use GUI selection instead.',func2str(this.taskConfig{1}));
                    end
                    this.taskConfig = [];
                end
            end
            
            % number of State DOFs in the system
            assert(isempty(this.nVarsPerDOF)||isnumeric(this.nVarsPerDOF),'Invalid value for nVarsPerDOF');
            this.nDOF = length(this.nVarsPerDOF);
            
            % save original values for restoration if needed
            propertyNames = properties(this);
            for kk=1:length(propertyNames)
                this.original.(propertyNames{kk}) = this.(propertyNames{kk});
            end
        end % END function Options
        
        function restore(this,name)
            assert(isprop(this,name),'''%s'' is not a valid property name',name);
            this.(name) = this.original.(name);
        end % END function restore
        
        function StartFcn(this)
            this.stopwatch = tic;
        end % END function StartFcn
    end % END methods
end % END classdef Options