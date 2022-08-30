classdef TrialData < handle & Experiment2.TrialDataInterface & util.Structable & util.StructableHierarchy
    
    properties
        
        % trial info
        tr_prm % struct with parameters for this trial
        tr_response % the subject's response
        
        % neural data info
        neu_filenames % filenames of the NSP recordings associated with this trial
        
        % event time info
        et_trialStart % frame id when trial starts
        et_trialCompleted % frame id when trial finishes
        et_phase % one entry for each phase, containing frame id
        et_phaseDuration
        
        % trial exit info
        ex_success % whether trial finished successfully
    end % END properties
    
    methods
        
        function this = TrialData(hTrial,varargin)
            this = this@Experiment2.TrialDataInterface(hTrial);
        end % END function TrialData
        
        function TrialStartFcn(this,evt,hTask,varargin)
            
            % trial parameters
            this.tr_prm = hTask.cTrialParams;
            
            % trial timing
            this.et_trialStart = evt.UserData.frameId;
            this.et_trialCompleted = nan;
            this.et_phase = nan(1,length(hTask.hTrial.phases));
            
            % default not successful
            this.ex_success = false;
        end % END function TrialStartFcn
        
        function TrialEndFcn(this,evt,hTask,varargin)
            finalize(this,hTask);
        end % END function TrialEndFcn
        
        function TrialAbortFcn(this,evt,hTask,varargin)
            finalize(this,hTask);
        end % END function TrialAbortFcn
        
        function PhaseStartFcn(this,evt,hTask,varargin)
            this.et_phase(hTask.hTrial.phaseIdx) = evt.UserData.frameId;
        end % END function PhaseStartFcn
        
        function finalize(this,hTask)
            this.neu_filenames = getRecordedFilenames(hTask.hFramework.hNeuralSource);
            this.et_trialCompleted = hTask.hFramework.frameId;
        end % END function finalize
        
        function calculateSuccess(this,hTask)
            if strcmpi(this.tr_response,'x')
                this.ex_success = nan;
            else
                this.ex_success = ischar(this.tr_response) && strcmpi(this.tr_response,'y');
            end
        end % END function calculateSuccessBisector
        
        function skip = structableSkipFields(this)
            skip = structableSkipFields@Experiment2.TrialDataInterface(this);
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Experiment2.TrialDataInterface(this);
        end % END function structableSkipFields
        
        function delete(this)
            delete@Experiment2.TrialDataInterface(this);
        end % END function delete
    end % END methods
end % END classdef TrialData