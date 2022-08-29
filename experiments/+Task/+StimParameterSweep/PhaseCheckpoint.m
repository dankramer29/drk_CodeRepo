classdef PhaseCheckpoint < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseCheckpoint(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseCheckpoint
        
        function StartFcn(this,evt,hTask,varargin)
            
            % enable the GUI
            numTrialsRemaining = length(hTask.TrialParams) - hTask.nTrials;
            secondsRemaining = round(numTrialsRemaining*hTask.hStage.duration);
            hTask.hGUI.setTrialInformation(...
                hTask.cTrial,length(hTask.TrialParams),secondsRemaining,...
                hTask.cTrialParams.electrodeNumber,hTask.cTrialParams.electrodeLabel,...
                hTask.cTrialParams.stimAmplitude,...
                hTask.cTrialParams.stimFrequency,...
                hTask.cTrialParams.catch);
            hTask.hGUI.enableCheckpoint;
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
        end % END function EndFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
        end % END function TimeoutFcn
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Experiment2.PhaseInterface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Experiment2.PhaseInterface(this);
        end % END function structableManualFields
    end % END methods
end % END classdef PhaseCheckpoint