classdef Trial < handle & Experiment2.StageInterface & util.Structable & util.StructableHierarchy
    
    properties
        name = 'Trial';
        TrialData
    end % END properties
    
    properties(Access=private)
        trialDataConstructor
    end % END properties(Access=private)
    
    methods
        function this = Trial(parent,tdc)
            this = this@Experiment2.StageInterface(parent);
            this.trialDataConstructor = tdc;
            
            % big try-catch: errors in constructors sometimes leave handles
            % to half-constructed objects stranded in memory
            tic
            try
                % set up phases from parameters
                assert(all(cellfun(@iscell,this.hTask.params.phaseDefinitions)),'Invalid phase definitions (empty elements)');
                assert(all(cellfun(@(x)ischar(x{1})||isa(x{1},'function_handle'),this.hTask.params.phaseDefinitions)),'Invalid phase definitions (missing function handle)');
                for kk=1:length(this.hTask.params.phaseDefinitions)
                    this.phaseAdd(this.hTask.params.phaseDefinitions{kk});
                end
                
                % set up the task's trialdata struct
                tmp = feval(this.trialDataConstructor,this);
                assert(isa(tmp,'Experiment2.TrialDataInterface'),'TrialData must inherit ''Experiment2.TrialDataInterface''');
                this.hTask.TrialData = toStruct(tmp); % initialize struct array fields
                this.hTask.TrialData(1000) = toStruct(tmp); % preallocate struct array
                delete(tmp);
            catch ME
                delete(this);
                rethrow(ME);
            end
            toc
        end % END function Trial
        
        function StageStartFcn(this,evt,varargin)
            
            % set up TrialData
            this.TrialData = feval(this.trialDataConstructor,this);
            assert(isa(this.TrialData,'Experiment2.TrialDataInterface'),'TrialData must inherit ''Experiment2.TrialDataInterface''');
            
            % update trial counter
            this.hTask.cTrial = this.hTask.nTrials + 1; % current trial index
            
            % assign new trial params
            if ~isempty(this.hTask.TrialParams) && length(this.hTask.TrialParams)>=this.hTask.cTrial
                this.hTask.cTrialParams = this.hTask.TrialParams(this.hTask.cTrial);
            end
        end % END function StageStartFcn
        
        function StageUpdateFcn(this,evt,varargin)
        end % END function StageUpdateFcn
        
        function StageFinishFcn(this,evt,varargin)
            this.hTask.nTrials = this.hTask.nTrials + 1; % finished trials; starts at 0
            
            % update trial finished counter
            if ~evt.UserData.abortCondition
                comment(this.hTask,sprintf('Saving trial %d',this.hTask.nTrials),3);
                this.hTask.TrialData(this.hTask.nTrials) = toStruct(this.TrialData);
            else
                comment(this.hTask,sprintf('Aborting trial %d',this.hTask.nTrials+1),3);
            end
            
            % save trial data and delete the trialdata object
            try
                delete(this.TrialData);
                this.TrialData = [];
            catch ME
                util.errorMessage(ME);
            end
        end % END function StageFinishFcn
        
        function skip = structableSkipFields(this)
            skip = structableSkipFields@Experiment2.StageInterface(this);
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Experiment2.StageInterface(this);
        end % END function structableManualFields
    end % END methods
end % END classdef Trial