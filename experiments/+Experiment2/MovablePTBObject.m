classdef MovablePTBObject < handle & Experiment2.TaskObjectInterface & DisplayClient.PsychToolboxObjectInterface & util.StructableHierarchy
    
    properties
        durationHold            % hold time required to fire hit event
        primaryTarget           % index of the primary target for this effector
        
        nStateVars              % number of variables required in the state vector
        idxStateHitTest         % which state variables to use when testing hits
        stateDecimalAccuracy = 5% number of decimal places allowed in state variables
        stateIntExtMode         % how the internal state is set relative to external state
    end % END properties
    
    properties(SetAccess=private)
        status                  % current status
        visible                 % whether this object will be visible on the screen
        eventsActive            % whether this object will fire Enter/Exit events
        stateLocked             % lock state to its current position
        
        stateExternal           % vector of state variables for DOFs associated with this object
        stateInternal           % vector of state variables for DOFs associated with this object
        
        hitObject               % handle to the object that triggered a hit
    end % END properties(SetAccess=private)
    
    properties(Access=private)
        hTimer                  % handle to target hit timer function
    end % END properties(Access=private)
    
    events
        StatusChange            % fires when setStatus function is called
        StateLocked             % fires when state is locked
        StateUnlocked           % fires when state is unlocked
        SetVisible              % fires when object set to visible
        SetInvisible            % fires when object set to invisible
        EventsEnabled           % fires when events enabled
        EventsDisabled          % fires when events disabled
        ObjectHit               % fires when this object stays in its primary target's zone for the specified duration
        ObjectEnter             % fires when this object enters its primary target's zone
        ObjectExit              % fires when this object exits its primary target's zone
    end % END events
    
    methods
        
        function this = MovablePTBObject(parent,id,varargin)
            this = this@Experiment2.TaskObjectInterface(parent,id);
            this = this@DisplayClient.PsychToolboxObjectInterface(varargin{:});
            this.stateDecimalAccuracy;
            
            % set up the timer
            setupHitTimer(this);
            
            % initialize status
            this.setStatus('normal');
            
            % leftover properties to set
            idx = 1;
            while idx <= length(varargin)
                if strcmpi(varargin{idx},'stateIntExtMode')
                    this.stateIntExtMode = varargin{ idx+1 };
                    idx = idx + 1;
                elseif strcmpi(varargin{idx},'stateDecimalAccuracy')
                    this.stateDecimalAccuracy = varargin{ idx+1 };
                    idx = idx + 1;
                elseif strcmpi(varargin{idx},'idxStateHitTest')
                    this.idxStateHitTest = varargin{ idx+1 };
                    idx = idx + 1;
                elseif strcmpi(varargin{idx},'nStateVars')
                    this.idxStateHitTest = varargin{ idx+1 };
                    idx = idx + 1;                
                end
                idx = idx + 1;
            end
            
        end % END function MovablePTBObject
        
        function setState(this,val)
            if length(val) ~= this.nStateVars
                error('Wrong number of state variables: received %d but expected %d',length(val),this.nStateVars);
            end
            if this.stateLocked, return; end
            val = round(val.*(10^this.stateDecimalAccuracy))/(10^this.stateDecimalAccuracy); % round to requested number of places
            this.stateExternal = val(:)';
            
            switch this.stateIntExtMode
                case 'same'
                    this.stateInternal = this.stateExternal;
                case 'anti'
                    this.stateInternal = -this.stateExternal;
                case 'zero'
                    this.stateInternal = zeros(size(this.stateExternal));
                otherwise
                    error('Unrecognized stateIntExtMode ''%s''',this.stateIntExtMode);
            end
            
            % comment to framework if target or distractor
            if this.type==Experiment2.TaskObjectType.TARGET
                comment(this.hTask,sprintf('Target %d -- state %s -- stateIntExtMode ''%s''',this.id,util.vec2str(val,'%.2f'),this.stateIntExtMode));
            end
        end % END function setState
        
        function val = getState(this,varargin)
            which = 'internal';
            if nargin>1
                if strncmpi(varargin{1},'internal',3), which = 'internal';
                elseif strncmpi(varargin{1},'external',3), which = 'external';
                end
            end
            switch which
                case 'internal'
                    val = this.stateInternal;
                case 'external'
                    val = this.stateExternal;
                otherwise
                    error('Unrecognized state option ''%s''',which);
            end
        end % END function getState
        
        function pos = getDisplayPosition(this)
            pos = this.stateExternal(this.idxStateHitTest);
        end % END functiong getDisplayPosition
        
        function setStatus(this,newStatus)
            if strcmpi(this.status,newStatus), return; end
            oldStatus = this.status;
            this.status = newStatus;
            eventData = util.EventDataWrapper('hTask',this.hTask,'newStatus',this.status,'oldStatus',oldStatus);
            notify(this,'StatusChange',eventData);
        end % END function setStatus
        
        function enableEvents(this)
            this.eventsActive = true;
            eventData = util.EventDataWrapper('hTask',this.hTask,'eventsActive',true);
            notify(this,'EventsEnabled',eventData);
        end % END function activateEvents
        
        function disableEvents(this)
            this.eventsActive = false;
            eventData = util.EventDataWrapper('hTask',this.hTask,'eventsActive',false);
            notify(this,'EventsDisabled',eventData);
        end % END function deactivateEvents
        
        function lockState(this)
            this.stateLocked = true;
            
            % only disable if this is an effector, NOT if it's a target.
            % NOTE this will disable ALL decoders, not just the one that
            % controls this effector's DOFs
            if this.type==Experiment2.TaskObjectType.EFFECTOR
                this.hTask.hFramework.hPredictor.disablePredictor;
            end
            eventData = util.EventDataWrapper('hTask',this.hTask,'stateLocked',true);
            notify(this,'StateLocked',eventData);
        end % END function lockState
        
        function unlockState(this)
            this.stateLocked = false;
            
            % only disable if this is an effector, NOT if it's a target.
            % NOTE this will disable ALL decoders, not just the one that
            % controls this effector's DOFs
            if this.type==Experiment2.TaskObjectType.EFFECTOR
                this.hTask.hFramework.hPredictor.enablePredictor;
            end
            eventData = util.EventDataWrapper('hTask',this.hTask,'stateLocked',false);
            notify(this,'StateUnlocked',eventData);
        end % END function unlockState
        
        function setVisible(this)
            this.visible = true;
            eventData = util.EventDataWrapper('hTask',this.hTask,'visible',true);
            notify(this,'SetVisible',eventData);
        end % END function setVisible
        
        function setInvisible(this)
            this.visible = false;
            eventData = util.EventDataWrapper('hTask',this.hTask,'visible',false);
            notify(this,'SetInvisible',eventData);
        end % END function setInvisible
        
        function draw(this)
            if this.hTask.params.useDisplay && this.visible && ~this.hTask.params.useUnity
                updateObject(this.hTask.hDisplayClient,this)
            end
        end % END function draw
        
        function hit = testEffectorEnterExit(this,effector)
            % called for TARGET objects to see whether an EFFECTOR has 
            % entered their space
            
            % default no hit
            hit = false;
            
            % return immediately if hits disabled
            if ~this.eventsActive
                this.setStatus('normal');
                return
            end
            
            % verify inputs
            if this.type ~= Experiment2.TaskObjectType.TARGET && this.type ~= Experiment2.TaskObjectType.OBSTACLE
                error('testEffectorEnterExt requires that the first argument be a target or distractor');
            end
            if effector.type ~= Experiment2.TaskObjectType.EFFECTOR
                error('testEffectorEnterExit requires that the second argument be an effector');
            end
            
            % retrieve state and scale values
            thisState = this.getState;
            thisScale = this.scale;
            effectorState = effector.getState;
            effectorScale = effector.scale;
            
            % pull out just the indices to be used for testing
            thisState = thisState(this.idxStateHitTest);
            effectorState = effectorState(effector.idxStateHitTest);
            
            % convert positions/scales to pixels
            if this.hTask.params.useDisplay
                thisState = this.hTask.hDisplayClient.normPos2Client(thisState);
                thisScale = this.hTask.hDisplayClient.normScale2Client(thisScale);
                effectorState = this.hTask.hDisplayClient.normPos2Client(effectorState);
                effectorScale = this.hTask.hDisplayClient.normScale2Client(effectorScale);
            end
            
            % calculate distance between them and threshold for hit
            EffectorTargetDistance=thisState(:)-effectorState(:);
            d = util.mnorm(EffectorTargetDistance(:)');
            threshold = (thisScale + effectorScale)/2;
            
            % act on distance/threshold
            if all(d <= threshold)
                hit = true;
                if strcmpi(this.status,'normal')
                    this.setStatus('on_effector');
                    evt = util.EventDataWrapper('hTask',this.hTask);
                    notify(this,'ObjectEnter',evt);
                    try EnterFcn(this,evt,this.hTask); catch ME, util.errorMessage(ME); end
                    this.hitObject = effector;
                end
            elseif any(d > threshold)
                hit = false;
                if strcmpi(this.status,'on_effector')
                    this.setStatus('normal');
                    evt = util.EventDataWrapper('hTask',this.hTask);
                    notify(this,'ObjectExit',evt);
                    try ExitFcn(this,evt,this.hTask); catch ME, util.errorMessage(ME); end
                    this.hitObject = [];
                end
            end
        end % END function testEffectorEnterExit
        
        function testTargetEnterExit(this,targets)
            % called for an EFFECTOR to see whether it has entered any
            % TARGET spaces
            if ~this.eventsActive
                this.setStatus('normal');
                return
            end
            
            % break out of the loop(s) once any event has been triggered
            % (avoid multiple events but only storing most recent state)
            hit = false;
            if ~iscell(targets), targets={targets}; end
            
            % loop over all targets provided
            timerStarted = false;
            for k=1:length(targets)
                hit = testEffectorEnterExit(targets{k},this);
                if hit && strcmpi(this.status,'normal')
                    this.setStatus('on_target');
                    st1 = this.toStruct;
                    st2 = targets{k}.toStruct;
                    if isempty(this.hTask.hTrial.TrialData.et_targetEnter)
                        this.hTask.hTrial.TrialData.et_targetEnter = {this.hTask.frameId,st1,st2,this.hTask.hTrial.phaseIdx};
                    else
                        this.hTask.hTrial.TrialData.et_targetEnter(end+1,:) = {this.hTask.frameId,st1,st2,this.hTask.hTrial.phaseIdx};
                    end
                    evt = util.EventDataWrapper('hTask',this.hTask);
                    notify(this,'ObjectEnter',evt);
                    stopTimer(this.hTask.hTrial,1);
                    try EnterFcn(this,evt,this.hTask); catch ME, util.errorMessage(ME); end
                    startHitTimer(this,targets{k}.durationHold);
                    timerStarted = true;
                    this.hitObject = targets{k};
                end
                if timerStarted, break; end
            end
            if ~hit && strcmpi(this.status,'on_target')
                this.setStatus('normal');
                if isempty(this.hTask.hTrial.TrialData.et_targetExit)
                    this.hTask.hTrial.TrialData.et_targetExit = {this.hTask.frameId,this.toStruct,[],this.hTask.hTrial.phaseIdx};
                else
                    this.hTask.hTrial.TrialData.et_targetExit(end+1,:) = {this.hTask.frameId,this.toStruct,[],this.hTask.hTrial.phaseIdx};
                end
                evt = util.EventDataWrapper('hTask',this.hTask);
                notify(this,'ObjectExit',evt);
                stopHitTimer(this);
                try ExitFcn(this,evt,this.hTask); catch ME, util.errorMessage(ME); end
                startTimer(this.hTask.hTrial,1);
                this.hitObject = [];
            end
        end % END function testTargetEnterExit
        
        function startHitTimer(this,delay)
            if strcmpi(this.hTimer.Running,'on')
                stop(this.hTimer);
            end
            if isempty(delay)
                error('Cannot specify an empty delay value');
            end
            if ~isnan(delay) && ~isinf(delay)
                this.hTimer.StartDelay = delay;
                start(this.hTimer);
            end
        end % END function startHitTimer
        
        function stopHitTimer(this)
            stop(this.hTimer);
        end % END function startHitTimer
        
        function CleanupFcn(this)
            stopHitTimer(this);
            setStatus(this,'normal');
        end % END function CleanupFcn
        
        function delete(this)
            try util.deleteTimer(this.hTimer); catch ME, util.errorMessage(ME); end
        end % END function delete
        
        function skip = structableSkipFields(this,varargin)
            skip1 = structableSkipFields@DisplayClient.PsychToolboxObjectInterface(this);
            skip2 = structableSkipFields@Experiment2.TaskObjectInterface(this);
            skip = [{'hTimer','hitObject'} skip1 skip2];
        end % END function structableSkipFields
        
        function st = structableManualFields(this,varargin)
            st1 = structableManualFields@DisplayClient.PsychToolboxObjectInterface(this);
            st2 = structableManualFields@Experiment2.TaskObjectInterface(this);
            st = util.catstruct(st1,st2);
        end % END function structableManual
    end % END methods
    
    methods(Access=private)
        function setupHitTimer(this)
            % set up target hit timer
            this.hTimer = timer('Name',sprintf('%s%02d_Timer',char(this.type),this.id));
            this.hTimer.TimerFcn = @HitTimerFcn;
            
            % inline timer function
            function HitTimerFcn(~,~)
                evt = util.EventDataWrapper('hTask',this.hTask,'objectType',this.type,'objectId',this.id,'hitObjectId',this.hitObject.id);
                notify(this,'ObjectHit',evt);
                try HitFcn(this,evt,this.hTask); catch ME, util.errorMessage(ME); end
            end % END function ObjectHitTimerFcn
        end % END function setupHitTimer
    end % END methods(Access=private)
    
    methods(Abstract)
        HitFcn(this,evt,hTask,varargin)
        EnterFcn(this,evt,hTask,varargin)
        ExitFcn(this,evt,hTask,varargin)
    end % END methods(Abstract)
end % END classdef MovingTaskObject