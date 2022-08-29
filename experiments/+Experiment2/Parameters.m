classdef Parameters < handle & util.Structable
    
    properties(GetAccess=public,SetAccess=private)
        hTask                           % handle to Task object
        parameterFcn                    % handle to parameter functions
        trialConstructor = @Experiment2.Trial; % constructor for Trial object
        prefaceConstructor = @Experiment2.Preface; % constructor for Preface object
        summaryConstructor = @Experiment2.Summary; % constructor for Summary object
    end % END properties(GetAccess=public,SetAccess=private)
    
    properties
        trialDataConstructor            % constructor for TrialData object
        trialParamsFcn                  % function handle to create trial parameters
        useUnity = false;               % use unity  
        useDisplay = false;             % whether to use a display
        externalDisplayRefresh = false; % whether to rely on external call to refresh display (TRUE) or refresh during the task update call (FALSE)
        displayConstructor              % handle to constructor for display object
        displayConfig = @(x)x;          % config function handle passed to display object constructor
        images                          % struct with fields/values indicating image names/paths to pre load in display client
        
        useKeyboard = false;            % whether to use keyboard input
        keyboardConstructor             % handle to constructor for keyboard object
        keyboardConfig = @(x)x;         % config function handle passed to keyboard object constructor
        defaultKeys                     % struct with fields/values indicating name/key-combination of key presses to register (task defaults)
        unifiedKeys                     % cell array of 1x2 cell arrays containing the "primary" and "key list" inputs for Keyboard.Input.unify()
        keys                            % struct with fields/values indicating names/key-combinations of key presses to register
        
        useSound = false;               % whether to use sound output
        soundConstructor                % handle to constructor for sound object
        soundConfig = @(x)x;            % config function handle passed to sound object constructor
        sounds                          % struct with fields/values indicating names/files of sounds to load
        
        useSync = false;                % whether to connect to process sync pulse train
        useFrameworkSync = true;        % if useSync, then whether to use the Framework's sync pulse train
        syncFcn                         % function to produce sync output; single function handle @method, or cell array with {@method,object} or {@method,@(hTask)hTask.object}
        syncArgs                        % arguments to sync output function
        
        useStimulation = false;         % whether stimulation will be used
        stimConstructor                 % handle to constructor for stimulator object
        stimConfig = @(x)x;             % config function handle passed to stimulator object constructor
        
        useNI = false;                  % whether NI modules will be used
        niConstructor                   % handle to constructor for NI modules interface/server
        niConfig = @(x)x;               % config function handle passed to NI interface constructor
        
        taskEventHandlers = {};         % Nx2 cell array for N task events (each row EventName (string) / Callback (string or function handle) pair
        prefaceEventHandlers = {};      % Nx2 cell array for N preface events (each row EventName (string) / Callback (string or function handle) pair
        trialEventHandlers = {};        % Nx2 cell array for N trial events (each row EventName (string) / Callback (string or function handle) pair
        summaryEventHandlers = {};      % Nx2 cell array for N summary events (each row EventName (string) / Callback (string or function handle) pair
        objectEventHandlers = {};       % Nx2 cell array for N object events (each row EventName (string) / Callback (string or function handle) pair
        keyboardEventHandlers = {};     % Nx2 cell array for N keyboard events (each row EventName (string) / Callback (string or function handle) pair
        
        targetDefinitions = {};         % 1xN cell array of parameters for N targets
        effectorDefinitions = {};       % 1xN cell array of parameters for N effectors
        obstacleDefinitions = {};
        
        prefaceDefinitions = {};        % 1xN cell array of parameters for N preface phases
        phaseDefinitions = {};          % 1xN cell array of parameters for N trial phases
        summaryDefinitions = {};        % 1xN cell array of parameters for N summary phases
        
        taskObjectDrawOrder = {'target','effector','obstacle'}; % 1xN cell array of task objects, in the order in which they should be drawn
        
        user                            % user-defined parameters
        debug
        verbosity
    end  % END properties
    
    methods
        function this = Parameters(hTask,cfg,varargin)
            this.hTask = hTask;
            
            % load HST env vars for verbosity and debug
            [this.verbosity,this.debug] = env.get('verbosity','debug');
            
            % specify default task key combinations
            % if these are modified, update KeyPressFcn
            this.defaultKeys.stop = {{'LeftControl','LeftAlt'},'ESC','Stop the task'};
            this.defaultKeys.advance = {{'LeftControl','LeftShift'},'DownArrow','Advance to the next stage'};
            this.defaultKeys.abort = {{'LeftControl','LeftShift'},'RightArrow','Abort the current trial'};
            this.defaultKeys.keyboard = {{'LeftControl','LeftShift'},'k','Drop to keyboard prompt'};
            this.defaultKeys.screenshot = {{'LeftControl','LeftShift'},'t','Take a screenshot'};
            
            % make sure config is a cell
            cfg = util.ascell(cfg);
            
            % save parameter function, validate
            this.parameterFcn = char(cfg{1});
            assert(isa(cfg{1},'function_handle'),'Must provide a function handle');
            
            % run config
            feval(cfg{1},this,cfg{2:end});
            
            % local inputs override config
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % make sure constructors are cell arrays
            this.displayConstructor = util.ascell(this.displayConstructor);
            this.soundConstructor = util.ascell(this.soundConstructor);
            this.keyboardConstructor = util.ascell(this.keyboardConstructor);
            this.stimConstructor = util.ascell(this.stimConstructor);
            
            % make sure sync function/arguments are cell arrays
            if this.useSync
                this.syncFcn = util.ascell(this.syncFcn);
                this.syncArgs = util.ascell(this.syncArgs);
            end
            
            % make sure trial params fcn is empty or a cell array
            if ~isempty(this.trialParamsFcn)
                this.trialParamsFcn = util.ascell(this.trialParamsFcn);
            end
            
            % error checking
            assert(~isempty(this.phaseDefinitions),'Must define at least one phase');
        end % END function Parameters
        
        function st = toStruct(this,varargin)
            skip = {'hTask'};
            st = toStruct@util.Structable(this,skip{:});
        end % END function toStruct
    end % END methods
end % END classdef ParameterInterface