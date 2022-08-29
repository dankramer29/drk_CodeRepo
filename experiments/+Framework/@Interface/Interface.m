classdef Interface < handle & util.Structable
    % INTERFACE The core element of the Caltech BMI Task Framework
    %
    %   Framework.Interface substantiates "the Framework" and is
    %   responsible for managing all incorporated modules including neural
    %   data, decoder, GUI, task, and video.
    %
    %     Example:
    %     fw = Framework.Interface(@config)
    %
    %   The above example starts the Framework with the handle to a config
    %   function.
    %
    %   The Framework uses a timer to execute pseudo-realtime data
    %   streaming and processing.  The timer functions are methods of the
    %   Interface class: timerFcn, errorFcn, startFcn, and stopFcn.
    %
    %   See also FRAMEWORK.OPTIONS.
    
    %**************************%
    % PUBLIC READ, PRIVATE SET %
    %**************************%
    properties(GetAccess=public,SetAccess=private)
        hTimer % timer handle
        hNeuralSource % neural source object handle
        hPredictor % cell array of Predictor handles
        hGUI % GUI handle
        hTask % task controller handle
        hVideo % control video recording
        hSync % sync pulse train
        hEyeTracker % eye tracker
        options % Framework options
        runtime % Framework runtime
        buffers % Framework buffers
        configFcn % function used to configure the Framework
        diaryFile % name of diary file
        updateFcnList % list of functions to execute each frame
        state % state of the effector
        target % target (from the task)
        idString % ID string for this instance of the Framework
        frameId = 0; % the current frame
        isInitialized = false; % whether the Framework has been initialized
        isRunning = false; % whether the Framework is running
        lastError % the last error encountered by the Framework
        output % same struct saved to output f
    end % END properties(GetAccess=public,SetAccess=private)
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        versionMajor = 0; % major version
        versionMinor = 8; % minor version
        versionPoint = 1; % point release for within-version updates
        versionBeta = true; % whether beta or stable
    end % END properties(Constant)
    
    %********%
    % EVENTS %
    %********%
    events
        FrameworkStart % fires when the Framework starts
        FrameworkStop % fires when the Framework stops
        FrameworkClose % fires when the Framework closes
        FrameworkHeartbeat % fires at intervals determined by Framework options
        FrameworkError % fires when the Framework encounters an error
    end % END events
    
    %****************%
    % PUBLIC METHODS %
    %****************%
    methods
        function this = Interface(cfg,varargin)
            % INTERFACE Constructor for the Interface object
            %
            %   FW = INTERFACE(CFG)
            %   Uses the function handle in CFG to configure the Framework
            %   and return a handle to the Framework in FW.
            %
            %   FW = INTERFACE(...,ARG1,ARG2,...,ARGn)
            %   ARG1 through ARGn will be passed directly to the Framework
            %   Options object.
            
            % check inputs
            assert(nargin>0 && isa(cfg,'function_handle'),'Must provide config input as a function handle');
            
            % configure the Framework
            try
                this.configFcn = cfg;
                configure(this,varargin{:});
            catch ME
                errorHandler(this,ME,true);
                return;
            end
            
            % start the diary
            this.diaryFile = fullfile(this.options.saveDirectory{1},[this.idString '_diary.txt']);
            fwComment(this,sprintf('Starting diary file ''%s''',this.diaryFile),3);
            diary(this.diaryFile);
            
            % display basic version information
            betaString = '';
            if this.versionBeta, betaString = 'b'; end
            fwComment(this,'Caltech BMI Framework',1);
            fwComment(this,sprintf('Version %d.%d.%d%s\n',this.versionMajor,this.versionMinor,this.versionPoint,betaString),1);
            fwComment(this,sprintf('Config: %s\n',func2str(cfg)),1);
            
            % display warning if beta
            if this.versionBeta
                fwComment(this,'BETA -- USE WITH CAUTION !!',1);
            end
            
            % display task, parameters, subject, researcher
            try
                if ~isempty(this.options.taskConstructor) && isa(this.options.taskConstructor,'function_handle')
                    taskName = strsplit(func2str(this.options.taskConstructor),'.');
                    taskName(strcmpi(taskName,'task')) = [];
                    if length(taskName)>1
                        taskName = func2str(this.options.taskConstructor);
                        warning('Unknown task package hierarchy for ''%s''',taskName);
                    else
                        taskName = taskName{1};
                    end
                    fwComment(this,sprintf('Task: %s',taskName),1);
                else
                    fwComment(this,'Task: UNDEFINED',1);
                end
                if ~isempty(this.options.taskConfig) && iscell(this.options.taskConfig) && isa(this.options.taskConfig{1},'function_handle')
                    parameterName = strsplit(func2str(this.options.taskConfig{1}),'.');
                    parameterName(strcmpi(parameterName,'task')) = [];
                    parameterName(strcmpi(parameterName,taskName)) = [];
                    if length(parameterName)>1
                        parameterName = func2str(this.options.taskConfig{1});
                        warning('Unknown parameter for task hierarchy in ''%s''',parameterName);
                    else
                        parameterName = parameterName{1};
                    end
                    fwComment(this,sprintf('Parameters: %s',parameterName),1);
                else
                    fwComment(this,'Parameters: UNDEFINED',1);
                end
                if ~isempty(this.options.subject)
                    fwComment(this,sprintf('Subject: %s',this.options.subject));
                else
                    fwComment(this,'Subject: UNDEFINED',1);
                end
                if ~isempty(this.options.researcher)
                    fwComment(this,sprintf('Researcher: %s',this.options.researcher));
                else
                    fwComment(this,'Researcher: UNDEFINED',1);
                end
            catch ME
                util.errorMessage(ME);
            end
            
            % display instructions if headless
            if this.options.headless
                fwComment(this,'HEADLESS MODE: start(fw), stop(fw), close(fw)',1);
            end
            
            % display environment variables
            hstvars = env.get;
            for kk=1:length(hstvars)
                fwComment(this,sprintf('HST var ''%s'': %s',hstvars{kk},getenv(env.str2name(hstvars{kk}))),3);
            end
            
            % make sure the framework is initialized
            assert(this.isInitialized,'Framework did not initialize successfully');
        end % END function Interface
        
        function start(this,varargin)
            % START Start the Framework
            %
            %   START(THIS)
            %   Start the timer controlling Framework execution.
            %
            %   START(...,'TASKLIMIT',LIMIT)
            %   START(...,'TIMELIMIT',LIMIT)
            %   START(...,'FRAMELIMIT',LIMIT)
            %   Override the task, time, or frame limit specified in the
            %   config file (or default option) just for this run of the
            %   Framework.
            
            % validate current status
            if this.isRunning, return; end
            assert(this.isInitialized,'Framework has not been initialized yet');
            this.isRunning = false;
            
            % start the Framework
            try
                
                % reset buffers and frameId
                reset(this.buffers);
                this.frameId = 0;
                
                % issue comment
                fwComment(this,'Framework.Interface.start',5);
                
                % initialize the runtime
                varargin = initializeRuntime(this,varargin{:});
                util.argempty(varargin);
                
                % initialize target/state
                if this.options.enableTask
                    this.target = nan(1,this.options.nDOF);
                end
                if this.options.enableTask || this.options.enablePredictor
                    this.state = zeros(1,sum(this.options.nVarsPerDOF));
                end
                
                % start recording neural data and audio/video
                if this.options.enableNeural
                    startRecording(this.hNeuralSource,'basefilename',this.runtime.baseFilename);
                end
                
                if this.options.enableVideo
                    record(this.hVideo);
                end
                if this.options.enableSync
                    start(this.hSync);
                end
                if this.options.enableEyeTracker
                    startRecording(this.hEyeTracker);
                end
                
                % options start function (start stopwatch)
                StartFcn(this.options);
                
                % initialize task
                if this.options.enableTask
                    initializeTask(this);
                end
                
                % run GUI run function
                if ~this.options.headless && ~isempty(this.hGUI)
                    cellfun(@StartFcn,this.hGUI);
                end
                
                % create and start timer
                initializeTimer(this);
                start(this.hTimer);
                
                % fire the Framework start event
                evt = util.EventDataWrapper('idString',this.idString,'runString',this.runtime.runString);
                notify(this,'FrameworkStart',evt);
                
                % update status
                this.isRunning = true;
            catch ME
                internalStop(this);
                errorHandler(this,ME,false);
            end
        end % END function start
        
        function stop(this,varargin)
            % STOP Stop the Framework
            %
            %   STOP(THIS)
            %   Request the Framework to stop on the next timer cycle.
            %   This function may be called asynchronously with respect to
            %   the timer update cycle, and it will set a flag to request
            %   that the Framework be stopped synchronously on the next
            %   update cycle.
            %
            %   STOP(THIS,TRUE)
            %   Force the Framework to stop immediately.
            
            FORCE_STOP_NOW = false;
            if nargin>1, FORCE_STOP_NOW = varargin{1}; end
            if FORCE_STOP_NOW
                internalStop(this);
            else
                if ~this.isRunning, return; end
                this.runtime.stopRequested = true;
            end
        end % END function stop
        
        function close(this)
            % CLOSE Close the Framework
            %
            %   CLOSE(THIS)
            %   Close the Framework.  This function may be called
            %   asynchronously with respect to the timer update cycle, and
            %   it will set a flag to request that the Framework be stopped
            %   synchronously on the next update cycle.
            
            if ~isvalid(this), return; end
            if this.isRunning
                this.runtime.stopRequested = true;
                this.runtime.closeRequested = true;
            else
                internalClose(this);
            end
        end % END function close
        
        function comment(this,label,msg,varargin)
            % COMMENT Log a comment
            %
            %   COMMENT(THIS,LABEL,MSG)
            %   Use the string in LABEL to identify the source of the
            %   string comment in MSG.
            %
            %   COMMENT(...,VERBOSITY)
            %   Override the default verbosity level (0) with the value in
            %   VERBOSITY.
            
            lbl = sprintf('[%s]',upper(label));
            msg = sprintf('%-12s %5d %s',lbl,this.frameId,msg);
            verbosityLevel = 0;
            if ~isempty(varargin), verbosityLevel = varargin{1}; end
            internalComment(this,msg,verbosityLevel);
        end % END function comment
        
        function neuralComment(this,msg,varargin)
            % NEURALCOMMENT Log a comment to the neural data source
            %
            %   NEURALCOMMENT(THIS,MSG)
            %   Send the string in MSG to the neural data source to log as
            %   a comment.
            
            if ~isempty(this.hNeuralSource)
                msg = regexprep(msg,'(]\s+)','] '); % remove white space between [ID] and message
                neuralComment(this.hNeuralSource,msg,varargin{:});
            end
        end % END function neuralComment
        
        function save(this)
            % SAVE Save the Framework
            %
            %   SAVE(THIS)
            %   Save the Framework.
            
            if isempty(this.buffers,'frameId') || this.frameId < 100, return; end
            fwComment(this,'Framework.Interface.save',5);
            
            % initialize Block structure
            Block.idString = this.idString;
            Block.Runtime = this.runtime;
            
            % end comment
            try
                response = 'NoEndComment';
                if this.frameId >= this.options.endCommentFrameId
                    response = '';
                    defAns = '';
                    winTitle = 'Final Recording Comment';
                    winPrompt = 'Enter a description of what was just recorded:';
                    while isempty(response)  % use while loop to force nonempty comment
                        response = inputdlg(winPrompt,winTitle,2,{defAns});
                        response = strtrim(response{1});
                    end
                    response = sprintf('UserEndComment : %s',response);
                end
                fwComment(this,response,-inf); %-inf to make sure comment is included
            catch ME
                errorHandler(this,ME,false);
            end
            
            % save Buffered data
            [d,names] = all(this.buffers);
            for kk=1:length(names)
                Block.Data.(names{kk}) = d{kk};
            end
            
            % save Options
            Block.Options = this.options.toStruct;
            
            % save Predictors
            if this.options.enablePredictor
                Block.Predictor = this.hPredictor.toStruct;
            end
            
            % save NeuralSource
            if this.options.enableNeural
                Block.NeuralSource = this.hNeuralSource.toStruct;
            end
            
            % save Task
            if this.options.enableTask
                Block.Task = this.hTask.toStruct;
            end
            
            % save Sync
            if this.options.enableSync
                Block.Sync = this.hSync.toStruct;
            end
            
            
            % save EyeTracker
            if this.options.enableEyeTracker
                Block.EyeTracker = this.hEyeTracker.toStruct;
            end
            
            % set the output
            this.output = Block;
            
            % loop over save directories
            for kk = 1:length(this.options.saveDirectory)
                try
                    outputPath = fullfile(this.options.saveDirectory{kk},sprintf('%s.mat',this.runtime.baseFilename));
                    assert(exist(outputPath,'file')~=2,'File ''%s'' already exists',outputPath);
                    save(outputPath,'-struct','Block');
                    env.set('lastFrameworkFile',outputPath)
                    fprintf('Saved output to <a href="matlab:load(''%s'');">%s</a>\n',outputPath,outputPath);
                catch ME
                    if this.options.debug<2 % not in validation
                        util.errorMessage(ME);
                        fprintf('\n');
                        fprintf('*****************************************************************\n');
                        fprintf('* Please update variable ''outputPath'' and hit F5 to continue. *\n');
                        fprintf('*****************************************************************\n');
                        fprintf('\n');
                        keyboard;
                    else
                        errorHandler(this,ME,false);
                    end
                end
                
                % copy config file to save directory
                try
                    cfgSource = which(func2str(this.configFcn));
                    cfgDest = fullfile(this.options.saveDirectory{kk},sprintf('%s_FrameworkConfig.m',this.runtime.baseFilename));
                    copyfile(cfgSource,cfgDest);
                catch ME
                    if this.options.debug<2 % not in validation
                        util.errorMessage(ME);
                        fprintf('\n');
                        fprintf('*******************************************************************************\n');
                        fprintf('* Could not copy config file ''%s''.  Copy manually, then hit F5 to continue. *\n',this.configFcn);
                        fprintf('*******************************************************************************\n');
                        fprintf('\n');
                        keyboard
                    else
                        errorHandler(this,ME,false);
                    end
                end
            end
        end % END function save
        
        function runtimeLimitFcn(this)
            % RUNTIMELIMITFCN Default function to run when runtime limit reached
            %
            %   RUNTIMELIMITFCN(THIS)
            %   By default, if the task is enabled this function will run
            %   hTask.advance().  Otherwise, this function will run the
            %   Framework's stop function.
            
            % the task handles limits on its own
            if ~this.options.enableTask
                this.stop;
                %this.hTask.hStage.abort(false,false);
            end
        end % END function runtimeLimitFcn
        
        function chk = runtimeLimitCheck(this)
            % RUNTIMELIMITCHECK Evaluate whether the runtime limit is met
            %
            %   CHK = RUNTIMELIMITCHECK(THIS)
            %   Check the frame, task, and/or time limits to see if any
            %   have been met.  Return the logical result in CHK.
            
            % check frame ID limit
            frameCheck = this.frameId >= this.runtime.frameLimit;
            
            % check time limit
            timeCheck = toc(this.options.stopwatch) >= this.runtime.timeLimit;
            
            % check task limit
            if this.options.enableTask
                taskCheck = this.hTask.nTrials >= this.runtime.taskLimit;
            else
                taskCheck = false;
            end
            
            % return logical result
            chk = frameCheck || timeCheck || taskCheck;
        end % END function runtimeLimitCheck
        
        function setRuntimeLimit(this,which,lim)
            % SETRUNTIMELIMIT Allow the task to set the runtime limits
            %
            %   SETRUNTIMELIMIT(THIS,WHICH,LIM)
            %   Set the limit specified by WHICH to the value in LIM,
            %   overriding any other limits set through the GUI.  WHICH may
            %   take any of 'task', 'frame', or 'time' (case-insensitive).
            
            % if not running, update options; otherwise, update runtime
            optfld = 'runtime';
            
            % identify the limit to be modified
            switch lower(which)
                case {'task','tasklimit'},limfld='taskLimit';
                case {'time','timelimit'},limfld='timeLimit';
                case {'frame','framelimit'},limfld='frameLimit';
                otherwise
                    error('Unknown limit ''%s''',which);
            end
            
            % verify that the user hasn't already set a limit
            if this.(optfld).(limfld)<inf,return;end
            
            % reset all limits to infinite
            this.(optfld).timeLimit = inf;
            this.(optfld).frameLimit = inf;
            this.(optfld).taskLimit = inf;
            
            % update the selected
            this.(optfld).(limfld) = lim;
            
            % set the popup index
            if ~this.options.headless
                cellfun(@(x)x.updateRuntimeLimit(which,lim),this.hGUI);
            end
        end % END function setRuntimeLimit
        
        function id = registerUpdateFcn(this,updateFcn,varargin)
            % REGISTERUPDATEFCN Register a function to run on each update
            %
            %   ID = REGISTERUPDATEFCN(THIS,UPDATEFCN)
            %   Register the function handle in UPDATEFCN to execute on
            %   each timer cycle, and return the update identifier in ID.
            %
            %   REGISTERUPDATEFCN(...,ARG1,ARG2,...,ARGn)
            %   Provide additional arguments which will be passed directly
            %   to the registered function.
            
            id = 1;
            if ~isempty(this.updateFcnList)
                id = max(cellfun(@(x)x{1},this.updateFcnList))+1;
            end
            assert(isa(updateFcn,'function_handle'),'Update funcdtion must be provided as a function handle');
            this.updateFcnList{id} = [{id} {updateFcn} varargin];
        end % END function registerUpdateFcn
        
        function deregisterUpdateFcn(this,id)
            % DEREGISTERUPDATEFCN Stop function from running on each update
            %
            %   DEREGISTERUPDATEFCN(THIS,ID)
            %   Use the update identifier returned by REGISTERUPDATEFCN to
            %   de-register the function and stop it from executing on each
            %   timer cycle.
            
            idx = cellfun(@(x)x{1},this.updateFcnList)==id;
            this.updateFcnList(idx) = [];
        end % END function deregisterUpdateFcn
        
        function registerBuffer(this,name,orient)
            % REGISTERBUFFER Register a buffer to store data
            %
            %   REGISTERBUFFER(THIS,NAME)
            %   Register a buffer under the identifier NAME. By default,
            %   the new buffer will accept data in row format (variables in
            %   columns).
            %
            %   REIGSTERBUFFER(THIS,NAME,ORIENT)
            %   Specify the orientation of incoming data: 'r' for row data
            %   input (default), and 'c' for column data input.
            
            if nargin<3||isempty(orient),orient='r';end
            assert(ischar(name),'Buffer name should be ''char'', not ''%s''',class(name));
            assert(ischar(orient),'Buffer orientation should be ''char'', not ''%s''',class(orient));
            assert(~this.isInitialized,'Buffers cannot be registered once the Framework has been initialized');
            register(this.buffers,name,orient);
        end % END function registerBuffer
        
        function state = getSyncState(this)
            % GETSYNCSTATE Get the logical state of the sync pulse
            %
            %   STATE = GETSYNCSTATE(THIS)
            %   Get the state of the sync pulse returned as logical TRUE
            %   (high) or FALSE (low).  If sync is disabled, will return
            %   FALSE with a warning.
            
            if this.options.enableSync
                state = this.hSync.state;
            else
                fwComment(this,'Sync disabled',1);
                state = false;
            end
        end % END function getSyncState
        
        function sync(this,fcn,varargin)
            % SYNC Call a sync method
            %
            %   SYNC(THIS,FCN,ARG1,ARG2,...)
            %   Call the method of the hSync object identified in the
            %   function handle FCN, providing the additional arguments
            %   ARG1, ARG2, etc.
            
            % tag this sync command with a comment in the neural data
            if this.options.enableNeural && nargin>2
                idx1 = strcmpi(varargin,'tag');
                if any(idx1)
                    idx2 = circshift(idx1,1,2);
                    tag = varargin{idx2};
                    varargin(idx1|idx2) = [];
                    
                    % check whether neural data being recorded
                    isRecording = ~isempty(this.hNeuralSource) && ...
                        isobject(this.hNeuralSource) && this.hNeuralSource.isRecording;
                    
                    % issue comment
                    if isRecording
                        neuralComment(this,tag,'color',this.hSync.neuralCommentId);
                    end
                end
            end
            
            % send the sync command on to the hSync object
            if this.options.enableSync
                feval(fcn,this.hSync,varargin{:});
            else
                fwComment(this,'Sync disabled',1);
            end
        end % END function sync
        
        function errorHandler(this,ME,dl)
            % ERRORHANDLER Procedure for handling framework errors.
            %
            %   ERRORHANDLER(THIS,ME,DL)
            %   Print the error message, set the lastError property, and
            %   fire the FrameworkError event.  If DL is set to TRUE, or if
            %   rethrow debug setting is TRUE, will call DELETE method to
            %   free all Framework resources.
            
            % set dl default to FALSE (no cleanup unless rethrow error)
            if nargin<3,dl=false;end
            
            % save this error
            this.lastError = ME;
            
            % fire the framework error event
            evt = util.EventDataWrapper('ME',ME);
            notify(this,'FrameworkError',evt);
            
            % handle the case where options hasn't even been set yet
            if isempty(this.options)
                util.errorMessage(ME);
                if dl, delete(this); end
            else
                
                % print the error message
                % only if debug is not validation (==2)
                % only if verbosity is >=1
                if this.options.debug<2 && this.options.verbosity>=1
                    util.errorMessage(ME);
                end
                
                % cleanup/delete, throw the error if in validation
                if this.options.debug==2
                    if dl, cleanup(this); end
                    rethrow(ME);
                elseif dl
                    delete(this);
                end
            end
        end % END function errorHandler
        
        function delete(this)
            % DELETE Delete the Framework object
            %
            %   DELETE(THIS)
            %   Run the cleanup routine to cleanly release all resources
            %   and delete the Framework object.
            
            cleanup(this);
        end % END function delete
        
        function editTaskFile(this)
            fun = functions(this.options.taskConstructor);
            edit(fun.function);            
        end
        
        function editParametersFile(this)
            fun = functions(this.options.taskConfig{1});
            edit(fun.function);            
        end
    end % END methods
    
    methods(Access=private)
        function configure(this,varargin)
            % CONFIGURE Configure the Framework
            %
            %   CONFIGURE(THIS)
            %   Configure the Framework, including filenames, buffers,
            %   options, timers, neural data, video, predictor, and GUI.
            %
            %   CONFIGURE(...,ARG1,ARG2,...,ARGn)
            %   ARG1 through ARGn will be passed directly to the Framework
            %   Options object.
            
            % set idString
            this.idString = datestr(now,'yyyymmdd-HHMMSS');
            
            % load options
            this.options = Framework.Options(this.configFcn,varargin{:});
            
            % set up buffers
            assert(exist('Buffer.Dynamic','class')==8,'Cannot locate ''Buffer.Dyanmic'' class');
            initializeBuffers(this);
            
            % check neural source
            if this.options.enableNeural
                pinfo = meta.class.fromName(func2str(this.options.neuralConstructor));
                neuralSourceIsSimulated = pinfo.PropertyList(strcmpi({pinfo.PropertyList.Name},'isSimulated')).DefaultValue;
                if strcmpi(this.options.type,'PRODUCTION') && neuralSourceIsSimulated
                    fwComment(this,'Neural data source indicates simulated data, but options indicate this is a live recording session!',2);
                end
            end
            
            % create the save directory if needed
            for kk=1:length(this.options.saveDirectory)
                if exist(this.options.saveDirectory{kk},'dir')~=7
                    fwComment(this,sprintf('Creating directory ''%s''',this.options.saveDirectory{kk}),3);
                    mkdir(this.options.saveDirectory{kk});
                end
            end
            
            % set up framework components
            if this.options.enableNeural
                initializeNeuralSource(this);
            end
            if this.options.enableVideo
                initializeVideo(this);
            end
            if this.options.enableSync
                initializeSync(this);
            end
            if this.options.enableEyeTracker
                initializeEyeTracker(this);
            end
            if this.options.enablePredictor
                initializePredictor(this);
            end
            
            % start GUI if not running headless
            if ~this.options.headless
                initializeGUI(this);
            end
            
            % output ID string and run name for the record
            fwComment(this,sprintf('ID String: %s',this.idString),3);
            fwComment(this,sprintf('Run Name:  %s',this.options.runName),3);
            
            % update status
            this.isInitialized = true;
        end % END function configure
        
        function internalUpdate(this)
            % INTERNALUPDATE Internal Framework processing for each update
            %
            %   INTERNALUPDATE(THIS)
            %   Check time, frame, and task limits, and process heartbeats
            %   and stop and close requests.  Only intended to be called by
            %   the timerFcn method of this same class.
            
            switch lower(this.options.heartbeatMode)
                case 'time'
                    this.runtime.heartbeatCounter = this.runtime.heartbeatCounter + this.hTimer.InstantPeriod;
                case 'frame'
                    this.runtime.heartbeatCounter = this.runtime.heartbeatCounter + 1;
                case 'task'
                    this.runtime.heartbeatCounter = this.runtime.heartbeatCounter + heartbeat(this.hTask);
            end
            if this.runtime.heartbeatCounter >= this.options.heartbeatInterval
                fwComment(this,sprintf('Framework heartbeat (mode=''%s'')',this.options.heartbeatMode),7);
                notify(this,'FrameworkHeartbeat');
                this.runtime.heartbeatCounter = 0;
            end
            if this.runtime.closeRequested % first because it will stop + close, no need to run stop first
                internalClose(this);
                return;
            end
            if this.runtime.stopRequested
                internalStop(this);
            end
        end % END function internalUpdate
        
        function internalStop(this)
            % INTERNALSTOP Execute processes for stopping the Framework.
            %
            %   INTERNALSTOP(THIS)
            %   Execute all processes associated with stopping the
            %   Framework including saving, cleanup up the task, stopping
            %   video and neural data recording, and resetting the GUI.
            
            % reset request flag and update Framework status
            this.runtime.stopRequested = false;
            this.isRunning = false;
            
            % issue comment
            fwComment(this,'Framework.Interface.internalStop',5);
            
            % stop the timer first so we don't get interrupted
            try util.deleteTimer(this.hTimer); catch ME, errorHandler(this,ME,false); end
            
            % stop the task before saving
            if this.options.enableTask
                try stopTask(this); catch ME, errorHandler(this,ME,false); end
            end
            
            % save the Framework before deleting things
            try save(this); catch ME, errorHandler(this,ME,false); end
            
            % delete task
            if this.options.enableTask
                try deleteTask(this); catch ME, errorHandler(this,ME,false); end
            end
            
            % stop recording audio, video, neural data
            if this.options.enableVideo
                try stop(this.hVideo); catch ME, errorHandler(this,ME,false); end
            end
            if this.options.enableSync
                try stop(this.hSync); catch ME, errorHandler(this,ME,false); end
            end
            if this.options.enableEyeTracker
                try stopRecording(this.hEyeTracker); catch ME, errorHandler(this,ME,false); end
            end
            if this.options.enableNeural
                try stopRecording(this.hNeuralSource); catch ME, errorHandler(this,ME,false); end
            end
            
            % reset GUIs
            if ~this.options.headless && ~isempty(this.hGUI)
                try cellfun(@StopFcn,this.hGUI); catch ME, errorHandler(this,ME,false); end
            end
            
            % notify stop event
            str = '';
            if isfield(this.runtime,'runString'),str=this.runtime.runString;end
            evt = util.EventDataWrapper('idString',this.idString,'runString',str);
            notify(this,'FrameworkStop',evt);
        end % END function internalStop
        
        function internalClose(this)
            % INTERNALCLOSE Execute processes for closing the Framework.
            %
            %   INTERNALCLOSE(THIS)
            %   Handle a close request and execute all processes associated
            %   with closing the Framework.
            
            fwComment(this,'Framework.Interface.internalClose',5);
            if this.isRunning, internalStop(this); end
            
            % update initialized property
            this.isInitialized = false;
            
            % notify close event
            idstr = '';
            if isprop(this,'idString')
                idstr = this.idString;
            end
            runstr = '';
            if isprop(this,'runtime') && isstruct(this.runtime) && isfield(this.runtime,'runString')
                runstr = this.runtime.runString;
            end
            evt = util.EventDataWrapper('idString',idstr,'runString',runstr);
            notify(this,'FrameworkClose',evt);
            
            % delete object
            delete(this);
        end % END function internalClose
        
        function varargin = initializeRuntime(this,varargin)
            % INITIALIZERUNTIME Initialize runtime parameters
            %
            %   INITIALIZERUNTIME(THIS)
            %   Initialize flags, run strings, filenames, heartbeat
            %   counter, and limits.
            
            % runtime limits
            if this.options.enableTask
                [varargin,this.runtime.taskLimit] = util.argkeyval('taskLimit',varargin,this.options.taskLimit);
            end
            [varargin,this.runtime.timeLimit] = util.argkeyval('timeLimit',varargin,this.options.timeLimit);
            [varargin,this.runtime.frameLimit] = util.argkeyval('frameLimit',varargin,this.options.frameLimit);
            
            % processing flag, ensure the limit function runs only once
            this.runtime.limitProcessed = false;
            
            % stop/close request flags initialize to false
            this.runtime.stopRequested = false;
            this.runtime.closeRequested = false;
            
            % filenames
            this.runtime.runString = sprintf('%s-%s',datestr(now,'HHMMSS'),this.options.runName);
            this.runtime.baseFilename = sprintf('%s-%s',this.idString,this.runtime.runString);
            
            % heartbeat counter initialize to zero
            this.runtime.heartbeatCounter = 0;
            this.runtime.tic = tic;
        end % END function initializeRuntime
        
        function initializeBuffers(this)
            % INITIALIZEBUFFERS Initialize the Framework buffers
            %
            %   INITIALIZEBUFFERS(THIS)
            %   Initialize all Framework buffers.
            
            % create buffer collection
            this.buffers = Buffer.DynamicCollection;
            
            % register buffers
            register(this.buffers,'frameId','r');
            if this.options.enableNeural
                register(this.buffers,'neuralTime','r');
            end
            register(this.buffers,'computerTime','r');
            register(this.buffers,'elapsedTime','r');
            register(this.buffers,'instantPeriod','r');
            if this.options.enablePredictor
                register(this.buffers,'prediction','r');
            end
            if this.options.enableTask || this.options.enablePredictor
                register(this.buffers,'state','r');
            end
            if this.options.enableTask
                register(this.buffers,'target','r');
            end
            if this.options.enableNeural
                register(this.buffers,'features','r');
            end
            if this.options.enableEyeTracker
                register(this.buffers,'gazePosition','r');
                register(this.buffers,'gazeConfidence','r');
                register(this.buffers,'gazeTime','r');
                register(this.buffers,'gazeOnSurface','r');
                register(this.buffers,'pupilDiam','r');
                register(this.buffers,'pupilDiamTime','r');
            end
            register(this.buffers,'comments','object');
        end % END function initializeBuffers
        
        function initializeTask(this)
            % INITIALIZETASK Initialize the behavioral task
            %
            %   INITIALIZETASK(THIS)
            %   Start the behavioral task.
            
            % issue comment
            fwComment(this,sprintf('Starting task (%s)',func2str(this.options.taskConstructor)),3);
            
            % create new task
            this.hTask = feval(this.options.taskConstructor,this,this.options.taskConfig);
            assert(isa(this.hTask,'Framework.Task.Interface'),'Task must inherit ''Framework.Task.Interface''');
            
            % start the task
            start(this.hTask);
        end % END function initializeTask
        
        function stopTask(this)
            % STOPTASK Stop the behavioral task
            %
            %   STOPTASK(THIS)
            %   Stop the behavioral task.
            
            % issue comment
            fwComment(this,sprintf('Stopping task (%s)',func2str(this.options.taskConstructor)),3);
            
            % stop the task
            if ~isempty(this.hTask)
                stop(this.hTask);
            end
        end % END function stopTask
        
        function deleteTask(this)
            % DELETETASK Delete the behavioral task
            %
            %   DELETETASK(THIS)
            %   Delete the behavioral task.
            
            % issue comment
            fwComment(this,sprintf('Deleting task (%s)',func2str(this.options.taskConstructor)),3);
            
            % clean up the task
            if ~isempty(this.hTask)
                delete(this.hTask);
            end
            this.hTask = [];
        end % END function deleteTask
        
        function initializePredictor(this)
            % INITIALIZEPREDICTOR Initialize the predictor
            %
            %   INITIALIZEPREDICTOR(THIS)
            %   Start the predictor.
            
            fwComment(this,sprintf('Initializing predictor (%s)',func2str(this.options.predictorConstructor)),3);
            this.hPredictor = feval(this.options.predictorConstructor,this,this.options.predictorConfig);
            assert(isa(this.hPredictor,'Framework.Predictor.Interface'),'Predictor must inherit ''Framework.Predictor.Interface''');
        end % END function initializePredictor
        
        function initializeNeuralSource(this)
            % INITIALIZENEURALSOURCE Initialize the neural data source
            %
            %   INITIALIZENEURALSOURCE(THIS)
            %   Start the neural data source.
            
            fwComment(this,sprintf('Initializing neural source (%s)',func2str(this.options.neuralConstructor)),3);
            this.hNeuralSource = feval(this.options.neuralConstructor,this,this.options.neuralConfig);
            assert(isa(this.hNeuralSource,'Framework.NeuralSource.Interface'),'NeuralSource must inherit ''Framework.NeuralSource.Interface''');
            initialize(this.hNeuralSource);
        end % END function initializeNeuralSource
        
        function initializeVideo(this)
            % INITIALIZEVIDEO Initialize video object
            %
            %   INITIALIZEVIDEO(THIS)
            %   Start the video object.
            
            fwComment(this,sprintf('Initializing video (%s)',func2str(this.options.videoConstructor)),3);
            this.hVideo = feval(this.options.videoConstructor,this,this.options.videoConfig);
            assert(isa(this.hVideo,'Framework.Video.Interface'),'Video must inherit ''Framework.Video.Interface''');
            initialize(this.hVideo);
        end % END function initializeVideo
        
        function initializeSync(this)
            % INITIALIZESYNC Initialize sync object
            %
            %   INITIALIZESYNC(THIS)
            %   Start the sync object
            
            fwComment(this,sprintf('Initializing sync (%s)',func2str(this.options.syncConstructor)),3);
            this.hSync = feval(this.options.syncConstructor,this,this.options.syncConfig);
            assert(isa(this.hSync,'Framework.Sync.Interface'),'Sync must inherit ''Framework.Sync.Interface''');
            initialize(this.hSync);
        end % END function initializeSync
        
        function initializeEyeTracker(this)
            % INITIALIZEEYETRACKER Initialize eye tracker object
            %
            %   INITIALIZEEYETRACKER(THIS)
            %   Start the eye tracker object
            
            fwComment(this,sprintf('Initializing eye tracker (%s)',func2str(this.options.eyeConstructor)),3);
            this.hEyeTracker = feval(this.options.eyeConstructor,this,this.options.eyeConfig);
            assert(isa(this.hEyeTracker,'Framework.EyeTracker.Interface'),'EyeTracker must inherit ''Framework.EyeTracker.Interface''');
            initialize(this.hEyeTracker);
        
        end % END function initializeSync
        
        function initializeTimer(this)
            % INITIALIZETIMER Initialize the timer
            %
            %   INITIALIZETIMER(THIS)
            %   Initialize the timer.
            
            fwComment(this,'Initializing timer',3);
            this.hTimer = util.getTimer('frameworkTimer',...
                'Period',       this.options.timerPeriod,...
                'StartDelay',   this.options.timerStartDelay,...
                'ExecutionMode','fixedDelay',...
                'BusyMode',     'drop',...
                'StartFcn',     @(t,evt)timerEventFcn(evt),...
                'TimerFcn',     @(t,evt)timerEventFcn(evt),...
                'StopFcn',      @(t,evt)timerEventFcn(evt),...
                'ErrorFcn',     @(t,evt)timerEventFcn(evt));
            
            function timerEventFcn(evt)
                switch evt.Type
                    case 'StartFcn', fn = this.options.timerStartFcn;
                    case 'TimerFcn', fn = this.options.timerTimerFcn;
                    case 'StopFcn',  fn = this.options.timerStopFcn;
                    case 'ErrorFcn', fn = this.options.timerErrorFcn;
                    otherwise
                        warning('Unknown event type ''%s''',evt.Type);
                end
                try feval(fn,this); catch ME, errorHandler(this,ME,false); end
            end % END function timerEventFcn
        end % END function initializeTimer
        
        function initializeGUI(this)
            % INITIALIZEGUI Initialize the GUI
            %
            %   INITIALIZEGUI(THIS)
            %   Initialize the GUI.
            
            this.hGUI = cell(1,length(this.options.guiConstructor));
            for kk=1:length(this.options.guiConstructor)
                fwComment(this,sprintf('Initializing GUI %d (%s)',kk,func2str(this.options.guiConstructor{kk})),3);
                this.hGUI{kk} = feval(this.options.guiConstructor{kk},this,this.options.guiConfig(kk));
                InitFcn(this.hGUI{kk});
            end
        end % END function initializeGUI
        
        function deleteGUI(this)
            % DELETEGUI Delete the GUI
            %
            %   DELETEGUI(THIS)
            %   Delete the GUI.
            
            if ~isempty(this.hGUI), cellfun(@delete,this.hGUI); end
        end % END function deleteGUI
        
        function internalComment(this,msg,verbosityLevel)
            % INTERNALCOMMENT log a comment
            %
            %   INTERNALCOMMENT(THIS,MSG,VERBOSITYLEVEL)
            %   Log a comment (string in MSG) into the Framework buffer,
            %   out to the screen, and into the neural data source, under
            %   the constraints of the indicated verbosity level
            %   VERBOSITYLEVEL.
            
            msg = strtrim(msg);
            internalBufferComment(this,msg,verbosityLevel);
            internalScreenComment(this,msg,verbosityLevel);
            if this.options.enableNeural
                internalNeuralComment(this,msg,verbosityLevel);
            end
        end % END function internalComment
        
        function internalBufferComment(this,msg,verbosityLevel)
            
            % check whether buffers are set up and running
            isBuffering = isobject(this.buffers) && ...
                isa(this.buffers,'Buffer.DynamicCollection');
            
            % issue comment
            if isBuffering && verbosityLevel<=this.options.verbosityBuffer
                add(this.buffers,'comments',{{this.frameId,msg}});
            end
        end % END function internalBufferComment
        
        function internalScreenComment(this,msg,verbosityLevel)
            if verbosityLevel<=this.options.verbosityScreen
                fprintf('%s\n',msg);
            end
        end % END function internalScreenComment
        
        function internalNeuralComment(this,msg,verbosityLevel)
            
            % check whether neural data being recorded
            isRecording = (~isempty(this.hNeuralSource) && ...
                isobject(this.hNeuralSource) && ...
                this.hNeuralSource.isRecording);
            
            % issue comment
            if isRecording && verbosityLevel<=this.options.verbosityNeural && this.options.mirrorCommentsToNeural
                neuralComment(this,msg);
            end
        end % END function internalNeuralComment
        
        function fwComment(this,msg,varargin)
            % FWCOMMENT Commenting function for internal methods
            %
            %   FWCOMMENT(THIS,MSG)
            %   Create a comment (string in MSG).
            %
            %   FWCOMMENT(...,VERBOSITY)
            %   Specify a verbosity level for the comment.
            
            comment(this,'FRAMEWORK',msg,varargin{:});
        end % END function fwComment
        
        function cleanup(this)
            % CLEANUP Release all resources
            %
            %   CLEANUP(THIS)
            %   Cleanly delete all modules incorporated into the Framework
            %   object, including neural data, video, predictor, timer, and
            %   GUI.  Also finalize the diary file.
            
            % issue comment
            if isprop(this,'isInitialized') && ~isempty(this.isInitialized) && this.isInitialized
                try fwComment(this,'Framework.Interface.delete',5); catch ME, util.errorMessage(ME); end
            end
            
            % stop if running
            if isprop(this,'isRunning') && ~isempty(this.isRunning) && this.isRunning
                try internalStop(this); catch ME, util.errorMessage(ME); end
            end
            
            % individual try/catch blocks so that no single action prevents
            % any other action from being attempted
            if ~isempty(this.options)
                if this.options.enableEyeTracker && ~isempty(this.hEyeTracker) && isa(this.hEyeTracker,'Framework.EyeTracker.Interface')
                    try close(this.hEyeTracker); catch ME, util.errorMessage(ME); end
                end
                if this.options.enableNeural && ~isempty(this.hNeuralSource) && isa(this.hNeuralSource,'Framework.NeuralSource.Interface')
                    try close(this.hNeuralSource); catch ME, util.errorMessage(ME); end
                end
                if this.options.enableVideo && ~isempty(this.hVideo) && isa(this.hVideo,'Video.Interface')
                    try delete(this.hVideo); catch ME, util.errorMessage(ME); end
                end
                if this.options.enableSync && ~isempty(this.hSync) && isa(this.hSync,'Framework.Sync.Interface')
                    try delete(this.hSync); catch ME, util.errorMessage(ME); end
                end
                if this.options.enablePredictor && ~isempty(this.hPredictor) && isa(this.hPredictor,'Framework.Predictor.Interface')
                    try delete(this.hPredictor); catch ME, util.errorMessage(ME); end
                end
            end
            
            % delete GUIs if not running headless
            if ~isempty(this.options) && ~this.options.headless
                try deleteGUI(this); catch ME, util.errorMessage(ME); end
            end
            
            % clean up diary file
            if ~isempty(this.options) && exist(this.diaryFile,'file')==2
                diary off;
                
                % copy to other save locations
                for kk=2:length(this.options.saveDirectory) % copy diary file to any other locations
                    try
                        copyfile(this.diaryFile,this.options.saveDirectory{kk});
                    catch ME
                        if this.options.debug<2 % not in validation
                            util.errorMessage(ME);
                            fprintf('\n');
                            fprintf('*******************************************************************************\n');
                            fprintf('* Could not copy diary file ''%s'' to\n',this.diaryFile);
                            fprintf('*   ''%s''\n',this.options.saveDirectory{kk});
                            fprintf('* Copy the file manually, then press F5 to continue.\n');
                            fprintf('*******************************************************************************\n');
                            fprintf('\n');
                            keyboard
                        else
                            errorHandler(this,ME,false);
                        end
                    end
                end
            end
        end % END function cleanup
    end % END methods(Access=private)
end % END classdef Framework