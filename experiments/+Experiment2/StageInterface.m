classdef StageInterface < handle & util.Structable & util.StructableHierarchy
    
    properties(Abstract)
        name % name of the stage
    end % END properties(Abstract)
    
    properties
        startDelay = 0.20; % time (in seconds) to delay calling start function
    end % END properties
    
    properties(GetAccess=public,SetAccess=private)
        hTask % handle to Experiment2.TaskInterface object (parent)
        phases % cell array of phase definitions
        phaseNames % cell array of phase names
        phaseIdx % index of currently executing phase
        duration = 0; % duration of this stage in seconds
    end % END properties(GetAccess=public,SetAccess=private)
    
    properties(Access=private)
        hTimer % timer object for phase durations, etc.
        phaseWhenTimerStopped % remember phase when timer stopped (avoid cross-phase contamination)
        stopwatch % track how much time each execution of this stage requires
        tocs % track how much time each execution of this stage requires
    end % END properties(Access=private)
    
    events
        Timeout % fires after set duration, meant to trigger phase timeout
        StageStart % fires when stage starts
        StageEnd % fires when stage ends
        StageAbort % fires when stage aborts
        PhaseStart % fires when a phase starts
        PhaseEnd % fires when a phase finishes
    end % END events
    
    methods
        function this = StageInterface(parent)
            assert(isa(parent,'Experiment2.TaskInterface'),'Must provide Task as first argument');
            this.hTask = parent;
            
            % set up buffer to track how long this stage takes
            this.tocs = Buffer.Circular(50); % only track the last 50 executions
            
            % set up timer for task events
            setupTimer(this);
        end % END function StageInterface
        
        function phaseAdd(this,fcn)
            
            % initialize to empty cell array
            if isempty(this.phases), this.phases={}; end
            assert(~isempty(fcn)&&iscell(fcn)&&isa(fcn{1},'function_handle'),'Must provide valid phase definition (cell array, first cell is a function handle)');
            
            % construct and validate phase
            phase = feval(fcn{:});
            assert(isa(phase,'Experiment2.PhaseInterface'),'Phase must inherit ''Experiment2.PhaseInterface''');
            phase.id = length(this.phases)+1;
            
            % add to the phase queue
            this.phases{end+1} = phase;
            this.phaseNames{end+1} = phase.Name;
            
            % add to duration
            this.duration = this.duration+phase.getDurationTimeout(1);
        end % END function phaseAdd
        
        function phaseAddBefore(this,fcn,id)
            
            % validate id
            if ischar(id), id = find(strcmpi(this.phaseNames),id); end
            assert(~isnan(id)&&~isempty(id)&&id>0&&id<=length(this.phases),'Invalid id %d',id);
            
            % validate position
            assert(length(this.phases)>=id,'Phase %d does not exist',id);
            
            % construct and validate phase
            phase = feval(fcn{:});
            assert(isa(phase,'Experiment2.PhaseInterface'),'Phase must inherit ''Experiment2.PhaseInterface''');
            phase.id = id;
            
            % add new phase
            this.phases = [this.phases(1:id-1) phase this.phases(id:end)];
            this.phaseNames = [this.phaseNames(1:id-1) phase.Name this.phases(id:end)];
            
            % update IDs
            for kk=(id+1):length(this.phases)
                this.phases{kk}.id = kk;
            end
            
            % add to duration
            this.duration = this.duration+phase.getDurationTimeout(1);
        end % END function phaseAddBefore
        
        function phaseRemove(this,id)
            
            % validate id
            if ischar(id), id = find(strcmpi(this.phaseNames),id); end
            assert(~isnan(id)&&~isempty(id)&&id>0&&id<=length(this.phases),'Invalid id %d',id);
            
            % delete from list
            this.phases(id) = [];
            this.phaseNames(id) = [];
            
            % update IDs
            for kk=id:length(this.phases)
                this.phases{kk}.id = kk;
            end
            
            % add to duration
            this.duration = this.duration-phase.getDurationTimeout(1);
        end % END function phaseRemove
        
        function delete(this)
            try cleanupTimer(this); catch ME, util.errorMessage(ME); end
        end % END function delete
        
        function skip = structableSkipFields(this)
            skip = {'hTask','hTimer'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st.tocs = get(this.tocs);
        end % END function structableManualFields
    end % END methods
    
    methods(Sealed)
        function start(this)
            
            % start phases or move on
            if isempty(this.phases)
                
                % run the task advance function
                try [~,endTask] = TaskAdvanceLogicFcn(this.hTask,true); catch ME, util.errorMessage(ME); end
                
                % if no phases, move on
                if endTask
                    stop(this.hTask,true);
                else
                    advance(this.hTask);
                end
            else
                
                % track how long this stage takes
                this.stopwatch = tic;
                tc = get(this.tocs);
                if length(tc)>1,this.duration=nanmedian(tc);end
                
                % run the stage's start function
                evt = util.EventDataWrapper('frameId',this.hTask.frameId,'stageName',this.name);
                try StageStartFcn(this,evt); catch ME, util.errorMessage(ME); end
                
                % fire the Start event
                notify(this,'StageStart',evt);
                
                % start with phase 1
                startPhase(this,1);
            end
        end % END function start
        
        function update(this)
            evt = util.EventDataWrapper('frameId',this.hTask.frameId);
            try StageUpdateFcn(this,evt); catch ME, util.errorMessage(ME); end
            try PhaseFcn(this.phases{this.phaseIdx},evt,this.hTask); catch ME, util.errorMessage(ME); end
        end % END function update
        
        function predraw(this)
            evt = util.EventDataWrapper('frameId',this.hTask.frameId);
            try PreDrawFcn(this.phases{this.phaseIdx},evt,this.hTask); catch ME, util.errorMessage(ME); end
        end % END function predraw
        
        function advance(this,newPhase,varargin)
            waitTime = 0;
            if ~isempty(varargin), waitTime = varargin{1}; end
            
            % calculate new phase index
            if nargin==1,newPhase=this.phaseIdx+1;end
            if ischar(newPhase)
                newPhaseIdx = find(strcmpi(this.phaseNames,newPhase));
            else
                newPhaseIdx = newPhase;
            end
            
            % check for errors
            if isempty(newPhaseIdx) || nnz(newPhaseIdx)>1
                if ~isempty(newPhase) && ischar(newPhase)
                    newPhaseStr = newPhase;
                else
                    newPhaseStr = util.vec2str(newPhase,'%d');
                end
                error('Invalid phase ''%s''',newPhaseStr);
            end
            
            % advance or finish
            if newPhaseIdx <= length(this.phases)
                
                % submit advance job
                executionTime = GetSecs + waitTime;
                job = {@internalAdvance,this,newPhaseIdx};
                submit(this.hTask,job,executionTime);
            else
                
                % finish
                finish(this);
            end
        end % END function advance
        
        function postdraw(this)
            evt = util.EventDataWrapper('frameId',this.hTask.frameId);
            try PostDrawFcn(this.phases{this.phaseIdx},evt,this.hTask); catch ME, util.errorMessage(ME); end
        end % END function postdraw
        
        function abort(this,varargin)
            
            % schedule abort for synchronous execution
            job = [{@internalFinish,this,true} varargin];
            submit(this.hTask,job);
        end % END function abort
        
        function finish(this,varargin)
            
            % schedule finishing for synchronous execution
            job = [{@internalFinish,this,false} varargin];
            submit(this.hTask,job);
        end % END function finish
        
        function startTimer(this,phaseCheck)
            if nargin==1, phaseCheck = false; end
            
            % calculate the start delay for the timer
            delay = this.phases{this.phaseIdx}.getDurationTimeout;
            this.hTask.hTrial.TrialData.et_phaseDuration(this.phaseIdx) = delay;
            
            % start the task timer, but make sure we're still in the same
            % phase when it ended (unless phaseCheck is turned off)
            if ~phaseCheck || this.phaseWhenTimerStopped == this.phaseIdx
                comment(this.hTask,sprintf('Task timer start (delay %.2f)',delay),5);
                if ~isinf(delay) && ~isnan(delay)
                    this.hTimer.StartDelay = delay;
                    start(this.hTimer);
                end
            end
        end % END function startTimer
        
        function stopTimer(this,phaseCheck)
            if nargin==1,phaseCheck=0;end
            comment(this.hTask,'Task timer stop',5);
            if phaseCheck, this.phaseWhenTimerStopped = this.phaseIdx; end
            if strcmpi(this.hTimer.Running,'on')
                stop(this.hTimer);
            end
        end % END function stopTimer
    end % END methods(Sealed)
    
    methods(Access=protected)
        
        function setupTimer(this)
            this.hTimer = timer('Name','StageTimer');
            this.hTimer.TimerFcn = @(h,evt)TimerFcn;
            
            function TimerFcn
                evt = util.EventDataWrapper('hTask',this.hTask,'frameId',this.hTask.frameId);
                job = {@notify,this,'Timeout',evt};
                submit(this.hTask,job);
                job = {@TimeoutFcn,this.phases{this.phaseIdx},evt,this.hTask};
                submit(this.hTask,job);
            end % END function TimerFcn
        end % END function setupTimer
        
        function cleanupTimer(this)
            util.deleteTimer(this.hTimer);
        end % END function cleanupTimer
        
        function internalFinish(this,abort,restartStage,endTask)
            assert(nargin<=2||nargin==4,'Must provide either both ''restartStage'' and ''endTask'', or neither');
            if nargin<2 || isempty(abort), abort=false; end
            
            % end the phase
            endPhase(this);
            
            % fire the End event
            evt = util.EventDataWrapper('frameId',this.hTask.frameId,'stageName',this.name,'abortCondition',abort);
            if abort
                notify(this,'StageAbort',evt);
            else
                notify(this,'StageEnd',evt);
            end
            
            % run the stage finish function
            try StageFinishFcn(this,evt); catch ME, util.errorMessage(ME); end
            
            % track how long this stage takes
            add(this.tocs,toc(this.stopwatch));
            
            % run the task advance function
            if nargin==2
                try [restartStage,endTask] = TaskAdvanceLogicFcn(this.hTask,abort); catch ME, util.errorMessage(ME); end
            end
            
            % start this stage again if not stopping
            if restartStage
                
                % restart this stage (another trial)
                start(this);
            else
                
                % end the task or advance to next stage
                if endTask
                    stop(this.hTask,true);
                else
                    advance(this.hTask);
                end
            end
        end % END function internalFinish
        
        function internalAdvance(this,newPhaseIdx)
            
            % clean up old phase
            endPhase(this);
            
            % start new phase
            startPhase(this,newPhaseIdx);
        end % END function internalAdvance
        
        function startPhase(this,idx)
            
            % update the phase index
            this.phaseIdx = idx;
            
            % run the phase's StartFcn
            evt = util.EventDataWrapper('frameId',this.hTask.frameId);
            try StartFcn(this.phases{this.phaseIdx},evt,this.hTask); catch ME, util.errorMessage(ME); end
            
            % empty the job queue
            this.hTask.cleanupQueue;
            
            % fire the PhaseStart event
            notify(this,'PhaseStart',evt);
            
            % start the task timer
            startTimer(this);
        end % END function startPhase
        
        function endPhase(this)
            
            % stop the task timer
            stopTimer(this);
            
            % run the phase's EndFcn
            evt = util.EventDataWrapper('frameId',this.hTask.frameId);
            try EndFcn(this.phases{this.phaseIdx},evt,this.hTask); catch ME, util.errorMessage(ME); end
            
            % empty the job queue
            this.hTask.cleanupQueue;
            
            % fire the PhaseEnd event
            notify(this,'PhaseEnd',evt);
        end % END function endPhase
    end % END methods(Access=private)
    
    methods
        function StageStartFcn(this,evt,varargin)
            % STAGESTARTFCN executes when the stage starts
            %
            %   Overload this method to define actions that will occur at
            %   the beginning of the stage.
            
        end % END function StageStartFcn
        
        function StageUpdateFcn(this,evt,varargin)
            % STAGEUPDATEFCN executes during each frame
            %
            %   Overload this method to define actions that will occur each
            %   frame that the task is running.
            
        end % END function StageUpdateFcn
        
        function StageFinishFcn(this,evt,varargin)
            % STAGEFINISHFCN executes after the last phase.
            %
            %   STAGEFINISHFCN(THIS)
            %   Define what happens after the last phase executes.  By
            %   default, the stage will end.
            %   
            %   STAGEFINISHFCN(THIS,STOP)
            %   The logical input STOP indicates whether to start another 
            %   phase sequence, or to end this stage.  The default value of
            %   STOP is TRUE.
            %
            %   Overload this method to customize stage finish actions.
            
        end % END function StageFinishFcn
    end % END methods
end % END classdef StageInterface