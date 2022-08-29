classdef TrialData < handle & Experiment2.TrialDataInterface & util.Structable & util.StructableHierarchy
    
    properties
        % trial info
        tr_groupID          % group identifier for analysis
        tr_groupDescription % group description
        tr_name             % short name - determines how trials are grouped for analysis
        tr_target           % target(s) for this trial
        tr_type             % type of trial
        tr_info             % information for this trial
        
        % neural data info
        neu_filenames       % filenames of the NSP recordings associated with this trial
        
        % decoder info
        dc                  % struct containing information retrieved from decoder
        
        % event time info
        et_trialStart       % frame id when trial starts
        et_trialCompleted   % frame id when trial finishes
        et_targetEnter      % frame id when effector enters target zone
        et_targetExit       % frame id when effector exits target zone
        et_phase            % one entry for each phase, containing frame id
        et_phaseDuration % requested phase duration
        
        % trial exit info
        ex_success          % whether trial finished successfully
        
        % task object info
        obj_target          % target object(s) (toStruct)
        obj_effector        % effector object(s) (toStruct)
    end % END properties
    
    methods
        
        function this = TrialData(hTrial,varargin)
            this = this@Experiment2.TrialDataInterface(hTrial);
        end % END function TrialData
        
        function TrialStartFcn(this,evt,hTask,varargin)
            this.et_trialStart = hTask.frameId;
            this.et_phase = nan(1,length(hTask.hTrial.phases));
            this.et_trialCompleted = nan;
            this.tr_type = nan;
        end % END function TrialStartFcn
        
        function TrialEndFcn(this,evt,hTask,varargin)
            finalize(this,hTask);
        end % END function TrialEndFcn
        
        function TrialAbortFcn(this,evt,hTask,varargin)
            finalize(this,hTask);
        end % END function TrialAbortFcn
        
        function PhaseStartFcn(this,evt,hTask,varargin)
            this.et_phase(hTask.hTrial.phaseIdx) = hTask.frameId;
        end % END function PhaseStartFcn
        
        function PhaseEndFcn(this,evt,hTask,varargin)
        end % END function PhaseEndFcn
        
        function finalize(this,hTask)
            this.dc = getTrialData(hTask.hFramework.hPredictor);
            for kk=1:length(hTask.hEffector)
                this.obj_effector{kk} = hTask.hEffector{kk}.toStruct;
            end
            for kk=1:length(hTask.hTarget)
                this.obj_target{kk} = hTask.hTarget{kk}.toStruct;
            end
            this.neu_filenames = getRecordedFilenames(hTask.hFramework.hNeuralSource);
            this.et_trialCompleted = hTask.frameId;
        end % END function finalize
        
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