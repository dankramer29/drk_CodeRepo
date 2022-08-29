classdef TaskInterface < handle & util.StructableHierarchy
    % TASKINTERFACE Primary class for Experiment2-based experiments
    %
    %   TaskInterface is the interface class for all Experiment2-based
    %   experiments.  It creates and manages almost all task resources,
    %   including the various stages (preface, trial, and summary), display
    %   client, keyboard, sound, and effectors and targets.  
    %
    %   TaskInterface uses an event-driven operating model.  User code is
    %   largely made up of callback functions which execute at significant
    %   moments throughout the lifecycle of the task.
    %
    %   Tasks proceed in stages: preface, which runs through a series of
    %   phases once then ends; trial, which runs through a series of phases
    %   and then may repeat or end; and, summary, which runs through a
    %   series of phases once then ends.
    %
    %   TaskInterface is not intended to be directly instantiated; it is
    %   intended to be inherited by a user Task class.  The TaskInterface
    %   constructor requires a handle to a parameter function which defines
    %   task parameters (see Experiment2.Parameters).  This parameter
    %   controls many aspects of the task, including the definition of
    %   which phases should be run for the preface, trials, and summary.
    %
    %   See also PARAMETERS, STAGEINTERFACE, and PHASEINTERFACE.
    
    %*******************%
    % PUBLIC PROPERTIES %
    %*******************%
    properties
        
        % handles to task resources
        hPreface                % handle to preface
        hTrial                  % handle to current trial
        hSummary                % handle to summary
        hStage                  % handle to current stage (preface, trial, or summary)
        hDisplayClient          % handle to display client
        hKeyboard               % handle to keyboard listener
        hSound                  % handle to sound playback object
        hStimulator             % handle to stimulator interface
        hEffector               % handles to effectors (cell array)
        hTarget                 % handles to targets (cell array)
        hObstacle               % handles to obstacles (cell array)
        hNI                     % handles to NI interface object
        
        % trial properties
        nTrials                 % number of trials that have been completed
        cTrial                  % number of the currently running trial
        cTrialParams            % parameters of current trial
        TrialParams             % trial parameters
        TrialData               % struct array of finished trials' data
        
        % internal properties
        params                  % user-defined parameters
        stats                   % user-defined statistics (like score)
        isRunning = false;      % whether the task is running
    end % END properties
    
    %********************%
    % PRIVATE PROPERTIES %
    %********************%
    properties(Access=private)
        
        % event action queue
        jobQueue                % queue of actions to take from event handlers
        eventCallbackDepth      % keep track of how many events we're processing simultaneously
        
        % heartbeat
        nTrialsOld = 0;         % for the default heartbeat logic
        
        % event listener handles
        lhTask                  % struct array of task event listeners
        lhPreface               % struct array of preface event listeners
        lhTrial                 % struct array of trial event listeners
        lhSummary               % struct array of summary event listeners
        lhEffector              % struct array of effector event listeners
        lhTarget                % struct array of target event listeners
        lhKeyboard              % struct array of keyboard event listeners
        lhObstacle              % struct array of keyboard event listeners
    end % END properties(Access=private)
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        
        % version information
        versionMajor = 0;
        versionMinor = 2;
        versionPoint = 0;
        versionBeta = true;
    end % END properties(Constant)
    
    %******************************%
    % ABSTRACT,CONSTANT PROPERTIES %
    %******************************%
    properties(Abstract,Constant)
        description % short description of the task
    end % END properties(Abstract,Constant)
    
    %********%
    % EVENTS %
    %********%
    events
        TaskStart
        TaskEnd
        KeyPressExpected
    end
    
    %*********%
    % METHODS %
    %*********%
    methods
        function this = TaskInterface(parameterFcn,varargin)
            
            try
                % read parameters
                this.params = Experiment2.Parameters(this,parameterFcn);
                
                % set up Job Queue
                this.jobQueue = Experiment2.JobQueue(this);
                this.eventCallbackDepth = 0;
                
                % display client
                if this.params.useDisplay
                    this.hDisplayClient = feval(this.params.displayConstructor{1},this.params.displayConfig,this.params.displayConstructor{2:end},'commentFcn',{@comment,this});
                    assert(isa(this.hDisplayClient,'Experiment2.DisplayClient.Interface'),'DisplayClient must inherit ''Experiment2.DisplayClient.Interface''');
                    
                    % load user images
                    if isstruct(this.params.images) && isa(this.hDisplayClient,'DisplayClient.PsychToolbox')
                        imageNames = fieldnames(this.params.images);
                        for kk=1:length(imageNames)
                            this.hDisplayClient.loadImage(this.params.images.(imageNames{kk}),imageNames{kk});
                        end
                    end
                end
                
                % keyboard
                if this.params.useKeyboard
                    
                    % create the keyboard object
                    this.hKeyboard = feval(this.params.keyboardConstructor{1},this.params.keyboardConfig,this.params.keyboardConstructor{2:end},'commentFcn',{@comment,this});
                    assert(isa(this.hKeyboard,'Experiment2.Keyboard.Interface'),'Keyboard must inherit ''Experiment2.Keyboard.Interface''');
                    
                    % load default key combinations
                    if isa(this.hKeyboard,'Keyboard.Input')
                        keyNames = fieldnames(this.params.defaultKeys);
                        for kk=1:length(keyNames)
                            keycomb = util.ascell(this.params.defaultKeys.(keyNames{kk}));
                            this.hKeyboard.register(keyNames{kk},keycomb{:});
                        end
                        
                        % load user unified keys
                        if iscell(this.params.unifiedKeys)
                            for kk=1:length(this.params.unifiedKeys)
                                this.hKeyboard.unify(this.params.unifiedKeys{kk}{1},this.params.unifiedKeys{kk}{2});
                            end
                        end
                    end
                    
                    % load user key combinations
                    if isstruct(this.params.keys)
                        keyNames = fieldnames(this.params.keys);
                        for kk=1:length(keyNames)
                            keycomb = util.ascell(this.params.keys.(keyNames{kk}));
                            this.hKeyboard.register(keyNames{kk},keycomb{:});
                        end
                    end
                    
                    % print out all registered keypresses
                    this.hKeyboard.list;
                end
                
                % sound
                if this.params.useSound
                    
                    % create the sound object
                    this.hSound = feval(this.params.soundConstructor{1},this.params.soundConfig,this.params.soundConstructor{2:end});
                    assert(isa(this.hSound,'Experiment2.Sound.Interface'),'Sound must inherit ''Experiment2.Sound.Interface''');
                    
                    % load sounds
                    if isstruct(this.params.sounds)
                        soundNames = fieldnames(this.params.sounds);
                        for kk=1:length(soundNames)
                            this.hSound.register(soundNames{kk},this.params.sounds.(soundNames{kk}));
                        end
                    end
                end
                
                % stim server
                if this.params.useStimulation
                    
                    % create stim object
                    this.hStimulator = feval(this.params.stimConstructor{1},this.params.stimConfig,this.params.stimConstructor{2:end});
                    assert(isa(this.hStimulator,'Experiment2.Stim.Interface'),'Stimulation must inherit ''Experiment2.Stim.Interface''');
                    
                    % initialize stimulation server
                    this.hStimulator.loadServer;
                end
                
                % initialize preface
                this.hPreface = feval(this.params.prefaceConstructor,this);
                assert(isa(this.hPreface,'Experiment2.Preface'),'Preface must be ''Experiment2.Preface''');
                
                % initialize summary
                this.hSummary = feval(this.params.summaryConstructor,this);
                assert(isa(this.hSummary,'Experiment2.Summary'),'Summary must be ''Experiment2.Summary''');
                
                % initialize trial
                this.hTrial = feval(this.params.trialConstructor,this,this.params.trialDataConstructor);
                assert(isa(this.hTrial,'Experiment2.Trial'),'Trial must be ''Experiment2.Trial''');
                this.nTrials = 0;
                this.cTrial = 1;
                
                % initialize TrialParams
                if ~isempty(this.params.trialParamsFcn) && isa(this.params.trialParamsFcn{1},'function_handle')
                    this.TrialParams = feval(this.params.trialParamsFcn{1},this.params.user,this.params.trialParamsFcn{2:end});
                end
                if isfield(this.params.user,'TrialParams')
                    this.TrialParams = this.params.user.TrialParams;
                end
                if ~isempty(this.TrialParams)
                    setRuntimeLimit(this.hFramework,'task',length(this.TrialParams));
                end

                % NI interface server
                if this.params.useNI
                    % create the NI object
                    this.hNI = feval(this.params.niConstructor{1},this.params.niConfig,this.params.niConstructor{2:end});
                    assert(isa(this.hNI,'Experiment2.NI.Interface'),'NI object must inherit ''Experiment2.NI.Interface''');
                    
                    % initialize NI server 
                    this.hNI.initialize;
                    
                    % check whether how many stimulation 
                    var = 'electrode';
                    if ~isfield(this.TrialParams,var); var = 'electrodes'; end
                    this.hNI.setNumInputs(max(cellfun(@length,{this.TrialParams.(var)}))); % sets analog inputs as the maximum number of channels we will simulatenously stimulate
                    
                    % start the NI server
                    this.hNI.start(this.hFramework.runtime.baseFilename);
                end
                
                % display Task help
                classInfo = meta.class.fromName(class(this));
                taskNamespace = classInfo.Name;
                taskInstr = help(taskNamespace);
                paramsInstr = help(this.params.parameterFcn);
                if ~isempty(taskInstr)
                    fprintf('\n\n');
                    fprintf('  TASK\n');
                    fprintf('  ==========================\n');
                    disp(taskInstr);
                    fprintf('\n');
                    fprintf('  PARAMETERS\n');
                    fprintf('  ==========================\n');
                    disp(paramsInstr);
                    fprintf('\n\n');
                end
                
                
            catch ME
                errorHandler(this,ME,1,1);
            end
        end % END function TaskInterface
        
        function submit(this,job,varargin)
            submit(this.jobQueue,job,varargin{:});
        end % END function submit
        
        function cleanupQueue(this)
            this.jobQueue.queue.empty;
        end % END function cleaupQueue
        
        function delete(this)
            try if ~isempty(this.hPreface),delete(this.hPreface); end, catch ME, errorHandler(this,ME); end
            try if ~isempty(this.hSummary),delete(this.hSummary); end, catch ME, errorHandler(this,ME); end
            try if ~isempty(this.hTrial),delete(this.hTrial); end, catch ME, errorHandler(this,ME); end
            try if ~isempty(this.hDisplayClient),delete(this.hDisplayClient); end, catch ME, errorHandler(this,ME); end
            try if ~isempty(this.hSound),delete(this.hSound); end, catch ME, errorHandler(this,ME); end
            try if ~isempty(this.hStimulator),delete(this.hStimulator); end, catch ME, errorHandler(this,ME); end
            try if ~isempty(this.hKeyboard),delete(this.hKeyboard); end, catch ME, errorHandler(this,ME); end
            try if ~isempty(this.jobQueue),delete(this.jobQueue); end, catch ME, errorHandler(this,ME); end
            try if ~isempty(this.hNI),delete(this.hNI); end, catch ME, errorHandler(this,ME); end
        end % END function delete
        
        function skip = structableSkipFields(~)
            skip = {'TrialData','lhTask','lhPreface','lhTrial','lhSummary','lhTarget','lhEffector','jobQueue','eventCallbackDepth','hStage'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st.TrialData = this.TrialData(1:this.nTrials);
        end % END function structableManualFields
    end % END methods
    
    %****************%
    % SEALED METHODS %
    %****************%
    methods(Sealed)
        function start(this)
            
            % run TaskStart function
            evt = util.EventDataWrapper('frameId',this.frameId);
            try TaskStartFcn(this,evt); catch ME, errorHandler(this,ME); end
            
            % fire the event
            notify(this,'TaskStart',evt);
            
            try
                
                % initialize targets and effectors
                setupTaskObjects(this);
                
                % set up event handlers for task and task objects
                setupEventHandlers(this);
                
                % update display
                draw(this);
                
                % start preface
                startStage(this,'preface');
            catch ME
                errorHandler(this,ME);
                stop(this);
                return;
            end
            
            % set the task running property
            this.isRunning = true;
        end % END function start
        
        function update(this,varargin)
            
            if this.isRunning && ~isempty(this.hStage.phases)
                
                % update task objects
                for kk=1:length(this.hEffector)
                    update(this.hEffector{kk});
                end
                for kk=1:length(this.hTarget)
                    update(this.hTarget{kk});
                end
                for kk = 1:length(this.hObstacle)
                    update(this.hObstacle{kk});
                end
                
                % execute before task objects drawn
                predraw(this.hStage);
                
                % draw task objects (Effector and Targets)
                draw(this);
                
                % execute after task objects drawn
                postdraw(this.hStage);
                
                % draw sync
                gensync(this);
                
                % propagate changes to screen
                if this.params.useDisplay && ~this.params.externalDisplayRefresh
                    refresh(this);
                end
                
                % Check keyboard for input and update variables accordingly
                if this.params.useKeyboard
                    update(this.hKeyboard);
                end
                
                % run Task function
                evt = util.EventDataWrapper('frameId',this.frameId);
                try TaskUpdateFcn(this,evt); catch ME, errorHandler(this,ME); end
                
                % run Trial function
                update(this.hStage);
            end
            
            % process job queue (for-loop b/c some jobs may get re-queued)
            if this.eventCallbackDepth==0
                nRuns = this.jobQueue.numJobs;
                for kk=1:nRuns
                    if ~isempty(this.jobQueue)
                        dispatch(this.jobQueue);
                    end
                end
            end
        end % END function update
        
        function refresh(this)
            refresh(this.hDisplayClient);
        end % END function refresh
        
        function gensync(this)
            % GENSYNC generate sync pulse output
            %
            %   GENSYNC(THIS)
            %   Generate the sync pulse output depending on the status of
            %   the sync pulse state. This function depends on parameters
            %   syncFcn and syncArgs:
            %
            %     syncFcn - three possible configurations:
            %               (1) @method
            %               (2) {@method,object}
            %               (3) (@method,@(hTask)hTask.object}
            %               The last option accounts for the
            %               chicken-and-egg problem in which parameters are
            %               established before resources are initialized,
            %               such as the display client. By providing a
            %               function to obtain the correct object at
            %               runtime, we still get the flexibility to
            %               specify properties of any available resource.
            %               The function will be evaluated the first time
            %               and the object saved in place of the function
            %               to avoid re-evaluating every time.
            %     syncArgs - a cell array with arguments for syncFcn.
            
            % if disabled, just return
            if ~this.params.useSync,return;end
            
            % determine the state of the sync pulse (off or on)
            state = getSyncState( this );
            
            % if on, generate the sync pulse
            if state
                
                % get the function handle
                fn = this.params.syncFcn{1};
                
                % get the object handle if provided
                if length(this.params.syncFcn)>1
                    if isa(this.params.syncFcn{2},'function_handle')
                        
                        % evaluate the function to get the object, and save
                        % the object to avoid needing to re-evaluate again
                        obj = feval(this.params.syncFcn{2},this);
                        this.params.syncFcn{2} = obj;
                    else
                        
                        % get the object directly
                        obj = this.params.syncFcn{2};
                    end
                end
                
                % get the function arguments
                args = this.params.syncArgs;
                
                % execute the function
                feval(fn,obj,args{:});
            end
        end % END function gensync
        
        function state = getSyncState(this)
            % GETSYNCSTATE Get the logical state of the sync pulse
            %
            %   STATE = GETSYNCSTATE(THIS)
            %   Get the state of the sync pulse train.  This method
            %   depends on the parameter useFrameworkSync; if true, it will
            %   query the Framework; if false, it will use its own internal
            %   logic (for now, only false).
            
            % get the sync pulse state
            if this.params.useFrameworkSync
                
                % get the sync pulse state from the Framework
                state = getSyncState( this.hFramework );
            else
                
                % for now leave at false, but this is a placeholder for
                % future scenarios where we may want to have other
                % possibilities attached to the Experiment2 object instead
                % of the Framework
                state = false;
            end
        end % END function getSyncState
        
        function beat = heartbeat(this)
            beat = false;
            try beat = TaskHeartbeatFcn(this); catch ME, errorHandler(this,ME); end
        end % END function heartbeat
        
        function advance(this,varargin)
            
            % default progression: preface, trial, summary
            if nargin>1
                newStage = varargin{1};
            else
                switch lower(this.hStage.name)
                    case 'preface', newStage = 'trial'; % move to trials
                    case 'trial',   newStage = 'summary'; % move to summary
                    otherwise, newStage = -1; % signal to stop
                end
            end
            
            % stop the task
            if isnumeric(newStage) && newStage<0
                stop(this,1); % stop the task
                return % return immediately
            end
            
            % make sure valid stage
            assert(any(strcmpi(newStage,{'Preface','Trial','Summary'})),'Stage identifier must be one of ''preface'', ''trial'', or ''summary'', not ''%s''.',newStage);
            
            % remove any outstanding jobs
            cleanupQueue(this);
            
            % set the stage handle
            switch lower(newStage)
                case 'preface', this.hStage = this.hPreface; % move to preface
                case 'trial',   this.hStage = this.hTrial; % move to trial
                case 'summary', this.hStage = this.hSummary; % move to summary
            end
            
            % start the new stage
            start(this.hStage);
        end % END function advance
        
        function stop(this,varargin)
            
            % immediately return if not running
            if ~this.isRunning, return; end
            
            % check whether called from internal or external source
            internal = false;
            if nargin>1,internal=varargin{1};end
            
            % stop the framework to stop the task
            if internal
                
                % trigger framework stop
                stop(this.hFramework);
            else
                
                % fire the event
                evt = util.EventDataWrapper('frameId',this.frameId);
                notify(this,'TaskEnd',evt);
                
                % update properties
                this.isRunning = false;
                
                % abort the stage if external source
                if ~internal
                    abort(this.hStage);
                end
                
                % various cleanup tasks
                draw(this);
                cleanupEventHandlers(this);
                cleanupTaskObjects(this);
                try TaskEndFcn(this,[]); catch ME, errorHandler(this,ME); end
            end
        end % END function stop
        
        function expectInput(this,varargin)
            % EXPECTINPUT Prepare to listen for keyboard input
            %
            %   EXPECTINPUT(THIS,KEY1,KEY2,...)
            %   Prepare to listen to the keypress combinations defined by
            %   KEY1, KEY2, etc.  Each of these inputs is a cell array:
            %
            %     KEY = {NAME,ANYKEYS,TIMEOUT,PROBABILITY}
            %
            %   In this list, NAME is the string identifier for the
            %   registered keypress combination; ANYKEYS is a single string
            %   or cell array of strings indicating which of the ANYKEYS in
            %   the registered keypress combination are expected; TIMEOUT
            %   is the expected delay before the keypress should be
            %   detected; and PROBABILITY is the probability with which
            %   this particular keypress should occur relative to the
            %   others provided (if multiple anykeys listed, multiple 
            %   probabilities should be provided).  Probabilities will be 
            %   normalized to sum to 1 across all contributors.  Each of
            %   the keypress combinations will be enabled.
            %
            %   EXPECTINPUT(...,'ECHO',TRUE|FALSE)
            %   By default, keypresses will not be echoed to the MATLAB 
            %   command line (FALSE).  Use this option to show keypresses 
            %   (TRUE).
            
            % process user inputs
            [varargin,echo] = util.argkeyval('echo',varargin,false);
            
            % leftovers are keypress data
            keys(length(varargin)) = struct('name','','anykeys','','timeout',0,'prob',0);
            for kk=length(varargin):-1:1
                
                % name of a registered keypress combination
                name = varargin{kk}{1};
                assert(ischar(name)&&this.hKeyboard.isRegistered(name),...
                    'First element of cell array must be the string identifier of a registered keypress combination.')
                this.hKeyboard.enable(name);
                
                % list of anykeys to expect
                anykeys = this.hKeyboard.getAnykeys(name);
                if length(varargin{kk})>1 && ~isempty(varargin{kk}{2})
                    anykeys = util.ascell(varargin{kk}{2});
                    for nn=1:length(anykeys)
                        if isnumeric(anykeys{nn})
                            anykeys{nn} = sprintf('%g',anykeys{nn});
                        end
                        anykeys{nn} = this.hKeyboard.getKeyName(anykeys{nn});
                    end
                    whichAreValid = Keyboard.isValidKeyName(anykeys{:});
                    notValid = find(~whichAreValid);
                    if ~isempty(notValid)
                        warning('%d/%d key names are invalid (%s)',length(notValid),length(anykeys),strjoin(unique(anykeys(notValid)),', '));
                    end
                end
                str1 = util.cell2str(anykeys);
                str2 = util.cell2str(this.hKeyboard.getAnykeys(name));
                assert(isempty(anykeys)||all(ismember(anykeys,this.hKeyboard.getAnykeys(name))),...
                    'List of anykeys provided {%s} does not match those registered for ''%s'' {%s}',str1,name,str2);
                
                % time before input expected 
                timeout = 0;
                if length(varargin{kk})>2 && ~isempty(varargin{kk}{3})
                    timeout = varargin{kk}{3};
                end
                
                % relative expected probability of the anykeys listed for
                % this keypress.  if multiple anykeys and single prob, 
                % replicate prob to match anykeys size.
                prob = ones(1,min(1,length(anykeys)));
                if length(varargin{kk})>3 && ~isempty(varargin{kk}{4})
                    prob = varargin{kk}{4};
                end
                if length(prob)==1 && length(anykeys)>1
                    prob = repmat(prob,1,length(anykeys));
                else
                    assert(length(prob)==length(anykeys),'Must provide a probability for each anykey, or a single probability that will be equally applied to each anykey');
                end
                
                % construct info struct
                keys(kk) = struct('name',name,'anykeys',{anykeys},'timeout',timeout,'prob',prob);
                
                % remove this element from input list
                varargin(kk) = [];
            end
            
            % make sure no unprocessed inputs
            util.argempty(varargin);
            
            % fire the event
            evt = util.EventDataWrapper('keys',keys);
            notify(this,'KeyPressExpected',evt);
            
            % set keyboard listening mode
            this.hKeyboard.listen('listen',true,'echo',echo,'reset',true);
        end % END function expectInput
        
        function resetInput(this,varargin)
            % RESETINPUT Reset listening mode
            %
            %   RESETINPUT(THIS)
            %   Reset the listening mode to listen to characters and echo
            %   keypresses to the command window.  Also reset the character
            %   buffer.
            %
            %   RESETINPUT(THIS,NAME1,NAME2,...)
            %   Disable the keypress combinations NAME1, NAME2, etc.
            %
            %   RESETINPUT(...,'ECHO',TRUE|FALSE)
            %   Specify whether keypresses should echo to the command line
            %   (TRUE) or be hidden (FALSE).
            
            % process user inputs
            [varargin,echo,~,found] = util.argflag('echo',varargin,false);
            if ~found,echo=true;end
            
            % leftovers are keypress data
            while ~isempty(varargin)
                
                % name of a registered keypress combination
                name = varargin{1};
                assert(ischar(name)&&this.hKeyboard.isRegistered(name),...
                    'Strings must be valid names of a registered keypress combination.')
                this.hKeyboard.disable(name);
                
                % remove this element from input list
                varargin(1) = [];
            end
            
            % make sure no unprocessed inputs
            util.argempty(varargin);
            
            % run the listen command
            this.hKeyboard.listen('listen',true,'echo',echo,'reset',true);
        end % END function resetInput
        
        function st = getEventListeners(this)
            st.effector = this.lhEffector;
            st.target = this.lhTarget;
            st.task = this.lhTask;
            st.preface = this.lhPreface;
            st.trial = this.lhTrial;
            st.summary = this.lhSummary;
            st.obstacle = this.lhObstacle;
        end % END function getEventListeners
        
        function [restartStage,endTask] = TaskAdvanceLogicFcn(this,abort)
            % TASKADVANCELOGICFCN determine whether to advance or restart stage
            
            % defaults
            restartStage = true;
            endTask = false;
            
            % determine which stage is currently executing
            switch lower(this.hStage.name)
                case 'preface', fn = @PrefaceAdvanceLogicFcn;
                case 'trial',   fn = @TrialAdvanceLogicFcn;
                case 'summary', fn = @SummaryAdvanceLogicFcn;
                otherwise, error('Unknown stage ''%s''',this.hStage.name);
            end
            
            % execute the function
            try
                [restartStage,endTask] = feval(fn,this,abort);
            catch ME
                errorHandler(this,ME);
            end
        end % END function TaskAdvanceLogicFcn
        
        function cleanupEventHandlers(this)
            
            % delete listeners for each of the task objects
            this.lhEffector = util.destroyObjectEventListeners(this.lhEffector);
            this.lhTarget = util.destroyObjectEventListeners(this.lhTarget);
            this.lhTask = util.destroyObjectEventListeners(this.lhTask);
            this.lhPreface = util.destroyObjectEventListeners(this.lhPreface);
            this.lhTrial = util.destroyObjectEventListeners(this.lhTrial);
            this.lhSummary = util.destroyObjectEventListeners(this.lhSummary);
            this.lhObstacle = util.destroyObjectEventListeners(this.lhObstacle);
            if this.params.useKeyboard
                this.lhKeyboard = util.destroyObjectEventListeners(this.lhKeyboard);
            end
        end % End function cleanupEventHandlers
        
        function cleanupTaskObjects(this)
            
            % disable task-level key combinations
            if this.params.useKeyboard && isa(this.hKeyboard,'Keyboard.Input')
                this.hKeyboard.disable('stop','advance','abort','keyboard');
                this.hKeyboard.listen('listen',false,'echo',true,'reset',true);
            end
            
            % delete targets
            if iscell(this.hTarget), cellfun(@delete,this.hTarget); end
            this.hTarget = [];
            
            % delete effectors
            if iscell(this.hEffector), cellfun(@delete,this.hEffector); end
            this.hEffector = [];
            
            % delete obstacles
            if iscell(this.hObstacle), cellfun(@delete,this.hObstacle);end
            this.hObstacle = [];
        end % END function cleanupTaskObjects
    end % END methods(Sealed)
    
    %*****************%
    % PRIVATE METHODS %
    %*****************%
    methods(Access=private)
        function startStage(this,which)
            
            % empty the job queue
            this.cleanupQueue;
            
            % update the stage pointer
            switch lower(which)
                case 'preface', this.hStage = this.hPreface;
                case 'trial',   this.hStage = this.hTrial;
                case 'summary', this.hStage = this.hSummary;
                otherwise
                    error('Unknown stage ''%s''',which);
            end
            
            % run the stage's start function
            start(this.hStage);
        end % END function startStage
        
        function draw(this)
            if ~this.params.useDisplay, return; end
            for kk=1:3
                switch this.params.taskObjectDrawOrder{kk}
                    case 'target', obj = this.hTarget;
                    case 'effector', obj = this.hEffector;
                    case 'obstacle', obj = this.hObstacle;
                    otherwise
                        error('Unknown task object ''%s''',this.params.taskObjectDrawOrder{kk});
                end
                for nn=1:length(obj)
                    draw(obj{nn});
                end
            end

        end % END function draw
        
        function setupEventHandlers(this)
            
            % create event listeners for each of the task objects
            this.lhEffector = util.createObjectEventListeners(this.hEffector,@(h,evt)processEvents(evt,this.params.objectEventHandlers),'ObjectBeingDestroyed');
            this.lhTarget = util.createObjectEventListeners(this.hTarget,@(h,evt)processEvents(evt,this.params.objectEventHandlers),'ObjectBeingDestroyed');
            this.lhTask = util.createObjectEventListeners(this,@(h,evt)processEvents(evt,this.params.taskEventHandlers),'ObjectBeingDestroyed');
            this.lhPreface = util.createObjectEventListeners(this.hPreface,@(h,evt)processEvents(evt,this.params.prefaceEventHandlers),'ObjectBeingDestroyed');
            this.lhTrial = util.createObjectEventListeners(this.hTrial,@(h,evt)processEvents(evt,this.params.trialEventHandlers),'ObjectBeingDestroyed');
            this.lhSummary = util.createObjectEventListeners(this.hSummary,@(h,evt)processEvents(evt,this.params.summaryEventHandlers),'ObjectBeingDestroyed');
            this.lhObstacle = util.createObjectEventListeners(this.hObstacle,@(h,evt)processEvents(evt,this.params.summaryEventHandlers),'ObjectBeingDestroyed');
            if this.params.useKeyboard
                this.lhKeyboard = util.createObjectEventListeners(this.hKeyboard,@(h,evt)processEvents(evt,this.params.keyboardEventHandlers),'ObjectBeingDestroyed');
            end
            
            function processEvents(evt,handlers)
                this.eventCallbackDepth = this.eventCallbackDepth + 1;
                comment(this,sprintf('Event: %s',evt.EventName),5);
                
                % process official event handlers (located in user's Task)
                switch evt.EventName
                    case 'StageStart'
                        switch lower(evt.UserData.stageName)
                            case 'preface', fn = @PrefaceStartFcn;
                            case 'trial',   fn = @TrialStartFcn;
                            case 'summary', fn = @SummaryStartFcn;
                            otherwise, error('Unknown stage name ''%s''',evt.UserData.stageName);
                        end
                    case 'StageEnd'
                        switch lower(evt.UserData.stageName)
                            case 'preface', fn = @PrefaceEndFcn;
                            case 'trial',   fn = @TrialEndFcn;
                            case 'summary', fn = @SummaryEndFcn;
                            otherwise, error('Unknown stage name ''%s''',evt.UserData.stageName);
                        end
                    case 'StageAbort'
                        switch lower(evt.UserData.stageName)
                            case 'preface', fn = @PrefaceAbortFcn;
                            case 'trial',   fn = @TrialAbortFcn;
                            case 'summary', fn = @SummaryAbortFcn;
                            otherwise, error('Unknown stage name ''%s''',evt.UserData.stageName);
                        end
                    case 'KeyPress'
                        fn = @KeyPressFcn;
                    otherwise
                        fn = @(x,y)true;
                end
                try feval(fn,this,evt); catch ME, errorHandler(this,ME); end
                
                % process custom event handlers
                jobs = getJobsFromHandlerList(evt,handlers);
                for kk=1:length(jobs)
                    submit(this,jobs{kk});
                end
                
                % update event callback depth property
                this.eventCallbackDepth = this.eventCallbackDepth - 1;
            end % END function processEvents
            
            function jobs = getJobsFromHandlerList(evt,eventHandlers)
                % use a set precedence order to identify the function to call for this event:
                % 1. Method of the task class
                % 2. Method of the originating effector/target class (only if source was effector or target)
                % 3. Method of the phase object
                % 4. If none of the above, assumes it's a function on the path somewhere
                %
                % numbers 3/4 are not implemented because they would
                % require all events originating from task objects to
                % include UserData fields objectId and objectType, but
                % there is no way to enforce that requirement.
                jobs = {};
                
                % find the event name in the list of event handlers
                idx = [];
                if ~isempty(eventHandlers)
                    idx = find(strcmpi(eventHandlers(:,1),evt.EventName));
                end
                
                % can't find the event: comment and return
                if isempty(idx)
                    comment(this,sprintf('Unhandled event ''%s''',evt.EventName),5);
                    return;
                end
                
                % convert to string if it's a function handle
                jobs = cell(1,length(idx));
                for kk=1:length(idx)
                    
                    % THIS WILL NEVER WORK
                    % The cell array is set up as a Nx2 (or x3 or x4 ...)
                    % which means that if any event handler has arguments,
                    % they all must have the same number.  Better solution
                    % is for each of the event handlers to be a cell array
                    % itself (Nx1) and each cell could then have as many
                    % arguments as desired.
                    
                    % define args (essentially, varargin)
                    args = eventHandlers(idx(kk),3:end);
                    
                    % define fn (function handle or string)
                    fn = eventHandlers{idx(kk),2};
                    
                    % construct job
                    if isa(fn,'function_handle')
                        jobs{kk} = [{fn,this,evt} args];
                    else
                        if ismethod(this,fn)
                            jobs{kk} = [{str2func(fn),evt,this} args];
                        elseif isa(evt.Source,'Experiment2.TaskObjectInterface') && ismethod(evt.Source,fn)
                            jobs{kk} = [{str2func(fn),evt.Source,evt,this} args];
                        elseif ismethod(this.hTrial.phases{this.hTrial.phaseIdx},fn)
                            obj = this.hTrial.phases{this.hTrial.phaseIdx};
                            jobs{kk} = [{str2func(fn),obj,evt,this} args];
                        else
                            jobs{kk} = [{str2func(fn),evt,this} args];
                        end
                    end
                end
            end % END function getEventFcnCell
        end % END function setupEventHandlers
        
        function setupTaskObjects(this)
            
            % enable task-level keypress combinations
            if this.params.useKeyboard && isa(this.hKeyboard,'Keyboard.Input')
                this.hKeyboard.enable('stop','advance','abort','keyboard','screenshot');
                this.hKeyboard.listen('listen',true,'echo',true,'reset',true);
            end
            
            % set up targets
            this.hTarget = cell(1,length(this.params.targetDefinitions));
            for kk=1:length(this.params.targetDefinitions)
                this.hTarget{kk} = feval(this.params.targetDefinitions{kk}{1},this,this.params.targetDefinitions{kk}{2:end});
                assert(isa(this.hTarget{kk},'Experiment2.TaskObjectInterface'),sprintf('Target %d must inherit ''Experiment2.TaskObjectInterface''',kk));
            end
            
            % set up effectors
            this.hEffector = cell(1,length(this.params.effectorDefinitions));
            for kk=1:length(this.params.effectorDefinitions)
                this.hEffector{kk} = feval(this.params.effectorDefinitions{kk}{1},this,this.params.effectorDefinitions{kk}{2:end});
                assert(isa(this.hEffector{kk},'Experiment2.TaskObjectInterface'),sprintf('Effector %d must inherit ''Experiment2.TaskObjectInterface''',kk));
            end
            
            % set up obstacles
            this.hObstacle = cell(1,length(this.params.obstacleDefinitions));
            for kk = 1:length(this.params.obstacleDefinitions)
                this.hObstacle{kk} = feval(this.params.obstacleDefinitions{kk}{1},this,this.params.obstacleDefinitions{kk}{2:end});
                assert(isa(this.hObstacle{kk},'Experiment2.TaskObjectInterface'),sprintf('Obstacle %d must inherit ''Experiment2.TaskObjectInterface''',kk));
            end
        end % END function setupTaskObjects
        
        function kbd(this)
            
            % prepare to disable character listener
            if isa(this.hKeyboard,'Keyboard.Input')
                list = this.hKeyboard.list('enabled');
                isListening = this.hKeyboard.isListening;
                isEchoing = this.hKeyboard.isEchoing;
                this.hKeyboard.disable(list{:});
                this.hKeyboard.listen('listen',false,'echo',true,'reset',true);
            end
            
            % drop to keyboard
            keyboard;
            
            % re-enable character listener
            if isa(this.hKeyboard,'Keyboard.Input')
                this.hKeyboard.enable(list{:});
                this.hKeyboard.listen('listen',isListening,'echo',isEchoing,'reset',true);
            end
        end % END function kbd
        
        function screenshot(this,outpath)
            % SCREENSHOT Take a screenshot
            %
            %   SCREENSHOT(THIS)
            %   Take a screenshot and save it to the common output
            %   directory.
            %
            %   SCREENSHOT(THIS,OUTPATH)
            %   Specify the output path and filename of the image.
            
            % set up default output file
            if nargin<2||isempty(outpath)
                outpath = fullfile('.',sprintf('%s_%s.png',class(this),datestr(now,'yyyymmdd-HHMMSS-FFF')));
            end
            
            % try to take a screenshot
            try
                screenshot(this.hDisplayClient,outpath);
            catch ME
                util.errorMessage(ME);
            end
        end % END function screenshot
        
        function errorHandler(this,ME,dl,rt)
            % ERRORHANDLER Procedure for handling task errors.
            %
            %   ERRORHANDLER(THIS,ME,DL,RT)
            %   Print the error message based on verbosity settings.  If DL
            %   is set to TRUE, will call DELETE method to free all Task 
            %   resources.  If RT set to TRUE, will rethrow the error.
            
            % set dl default to FALSE (no delete)
            if nargin<3,dl=false;end
            
            % set rt default to FALSE (no rethrow)
            if nargin<4,rt=false;end
            
            % handle the case where options hasn't even been set yet
            if isempty(this.params)
                if ~rt, util.errorMessage(ME); end
            else
                
                % re-enable character echo
                if this.params.useKeyboard && isa(this.hKeyboard,'Experiment2.Keyboard.Input')
                    this.hKeyboard.listen('listen',true,'echo',true,'reset',true);
                end
                
                % print the error message
                % only if debug is not validation (==2)
                % only if verbosity is errors and higher (>=1)
                % only if rethrow disabled
                if this.params.debug<2 && this.params.verbosity>=1 && ~rt
                    util.errorMessage(ME);
                end
            end
            
            % delete, throw the error if in validation
            if dl, delete(this); end
            if rt, rethrow(ME); end
        end % END function errorHandler
    end % END methods(Access=private)
    
    %******************%
    % CALLBACK METHODS %
    %******************%
    methods
        function TaskStartFcn(this,evt,varargin)
            % TASKTARTFCN runs when task starts
            %
            %   Overload this method to define actions that will execute
            %   when the task begins.  This function will run before any
            %   other actions occur, so effectors and targets will not be
            %   available, for example.
        end % END function TaskStartFcn
        
        function TaskEndFcn(this,evt,varargin)
            % TASKENDFCN runs when task ends
            %
            %   Overload this method to define actions that will execute
            %   when the task ends.  This function will run after all other
            %   cleanup actions, so effectors and targets will not be
            %   available, for example.
        end % END function TaskEndFcn
        
        function TaskUpdateFcn(this,evt,varargin)
            % TASKUPDATEFCN called every cycle while task running
            %
            %   Overload this method to define actions that will execute
            %   once each update cycle while the task is running.  This
            %   function will run after all other updates occur except for
            %   the trial update function.
        end % END function TaskUpdateFcn
        
        function KeyPressFcn(this,evt,varargin)
            % KEYPRESSFCN called as event handler for keypresses
            %
            %   Overload this method to define actions to take when the
            %   Keyboard's KeyPress event fires.  This function runs before
            %   the task update and stage/phase update.
            
            % check whether the keyboard object is Keyboard.Input
            if isa(this.hKeyboard,'Keyboard.Input')
                
                % process actions
                if strcmpi(evt.UserData.name,'stop'), stop(this,1); return; end % stop the task
                if strcmpi(evt.UserData.name,'advance'), abort(this.hStage,false,false); return; end % abort the stage
                if strcmpi(evt.UserData.name,'abort')
                    abort(this.hStage,true,false); % abort the phase
                    return;
                end
                if strcmpi(evt.UserData.name,'keyboard'), kbd(this); end % drop to keyboard
                if strcmpi(evt.UserData.name,'screenshot'), screenshot(this); end % take a screenshot
                
                % reset these key combinations so not triggered later
                this.hKeyboard.reset('stop','advance','abort','keyboard');
            end
        end % END function KeyPressFcn
        
        function PrefaceStartFcn(this,evt,varargin)
            % PREFACESTARTFCN called at the beginning of preface stage
            %
            %   Overload this method to define actions that will execute at
            %   the beginning of the preface.  This function executes
            %   during a callback for the PrefaceStart event in the Preface
            %   class.  The event fires before the PhaseStart function of
            %   the first phase executes.
        end % END function PrefaceStartFcn
        
        function PrefaceEndFcn(this,evt,varargin)
            % PREFACEENDFCN called at the end of each trial
            %
            %   Overload this method to define actions that will execute at
            %   the end of the preface.  This function executes during a
            %   callback for the PrefaceEnd event in the Preface class.
            %   The event fires during a synchronous call to the preface's
            %   internalFinish method, and after the PhaseEnd function
            %   completes.
        end % END function PrefaceEndFcn
        
        function PrefaceAbortFcn(this,evt,varargin)
            % PREFACEABORTFCN called when preface aborts
            %
            %   Overload this method to define actions that will execute
            %   when the preface aborts.  This function executes during a
            %   callback for the PrefaceAbort event in the Preface class.
            %   The event fires during a synchronous call to the preface's
            %   internalAbort method, and after the PhaseEnd function
            %   completes.
        end % END function PrefaceAbortFcn
        
        function SummaryStartFcn(this,evt,varargin)
            % SUMMARYSTARTFCN called at the beginning of summary stage
            %
            %   Overload this method to define actions that will execute at
            %   the beginning of the summary.  This function executes
            %   during a callback for the SummaryStart event in the Summary
            %   class.  The event fires before the PhaseStart function of
            %   the first phase executes.
        end % END function SummaryStartFcn
        
        function SummaryEndFcn(this,evt,varargin)
            % SUMMARYENDFCN called at the end of each trial
            %
            %   Overload this method to define actions that will execute at
            %   the end of the summary.  This function executes during a
            %   callback for the SummaryEnd event in the Summary class.
            %   The event fires during a synchronous call to the summary's
            %   internalFinish method, and after the PhaseEnd function
            %   completes.
        end % END function SummaryEndFcn
        
        function SummaryAbortFcn(this,evt,varargin)
            % SUMMARYABORTFCN called when summary aborts
            %
            %   Overload this method to define actions that will execute
            %   when the summary aborts.  This function executes during a
            %   callback for the SummaryAbort event in the Summary class.
            %   The event fires during a synchronous call to the summary's
            %   internalAbort method, and after the PhaseEnd function
            %   completes.
        end % END function SummaryAbortFcn
        
        function TrialStartFcn(this,evt,varargin)
            % TRIALSTARTFCN called at the beginning of each trial
            %
            %   Overload this method to define actions that will execute at
            %   the beginning of every trial.  This function executes
            %   during a callback for the TrialStart event in the Trial
            %   class.  The event fires before the PhaseStart function of
            %   the first phase executes.
        end % END function TrialStartFcn
        
        function TrialEndFcn(this,evt,varargin)
            % TRIALENDFCN called at the end of each trial
            %
            %   Overload this method to define actions that will execute at
            %   the end of every trial.  This function executes during a
            %   callback for the TrialEnd event in the Trial class.  The
            %   event fires during a synchronous call to the trial's
            %   internalFinish method, and after the PhaseEnd function
            %   completes.
        end % END function TrialEndFcn
        
        function TrialAbortFcn(this,evt,varargin)
            % TRIALABORTFCN called when trial aborts
            %
            %   Overload this method to define actions that will execute
            %   when a trial aborts.  This function executes during a
            %   callback for the TrialAbort event in the Trial class.  The
            %   event fires during a synchronous call to the trial's
            %   internalAbort method, and after the PhaseEnd function
            %   completes.
        end % END function TrialAbortFcn
        
        function beat = TaskHeartbeatFcn(this)
            % TASKHEARTBEATFCN provides a pulse for the task
            %
            %   Overload this method to define the logic which determines
            %   when the task's heartbeat should fire.  By default, the
            %   heartbeat fires when a trial finishes in the trial stage.
            
            % default no heartbeat
            beat = 0;
            
            % check whether trial count has incremented
            if strcmpi(this.hStage.name,'trial') && this.cTrial>this.nTrialsOld
                
                % update counter and return heartbeat
                this.nTrialsOld = this.cTrial;
                beat = 1;
            end
        end % END function TaskHeartbeatFcn
        
        function [restartStage,endTask] = PrefaceAdvanceLogicFcn(this,abort)
            % PREFACEADVANCELOGICFCN advance or restart preface stage
            %
            %   Overload this method to define whether the preface stage
            %   should end (i.e., advance to trial stage) or restart (i.e.,
            %   start again with phase 1 of preface).  The default behavior
            %   is to advance to the trial stage once the preface has
            %   finished the last phase.
            
            % advance (to trial stage)
            restartStage = false;
            endTask = false;
        end % END function PrefaceAdvanceLogicFcn
        
        function [restartStage,endTask] = TrialAdvanceLogicFcn(this,abort)
            % TRIALADVANCELOGICFCN advance or restart trial stage
            %
            %   Overload this method to define whether the trial stage
            %   should end (i.e., advance to summary stage) or restart
            %   (i.e., start again with phase 1 of trial).  The default
            %   behavior is to restart the trial phase endlessly.
            
            % default keep on executing
            endTask = false;
            restartStage = true;
            
            % conditions under which we'll stop executing
            if ~isempty(this.TrialParams) && this.cTrial >= length(this.TrialParams)
                
                % no Framework, so check local trial params
                restartStage = false;
            elseif ~isempty(this.hFramework) && isa(this.hFramework,'Framework.Interface')
                
                % check whether Framework runtime limits met
                if runtimeLimitCheck(this.hFramework)
                    restartStage = false;
                end
            end
            
            % if aborting, end the stage and the task
            if abort
                restartStage = false;
                endTask = true;
            end
        end % END function TrialAdvanceLogicFcn
        
        function [restartStage,endTask] = SummaryAdvanceLogicFcn(this,abort)
            % SUMMARYADVANCELOGICFCN advance or restart summary stage
            %
            %   Overload this method to define whether the summary stage
            %   should end (i.e., end the task) or restart (i.e., start the
            %   summary stage again at phase 1).  The default behavior is
            %   to end the stage, and therefore the task, once the summary
            %   stage has finished its last phase.
            
            % task finishes
            restartStage = false;
            endTask = true;
        end % END function SummaryAdvanceLogicFcn
    end % END methods
    
    methods(Abstract)
        comment(this,msg);
    end % END methods(Abstract)
end % END classdef TaskInterface