classdef PhaseShowTarget < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseShowTarget(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowTarget
        
        function StartFcn(this,evt,hTask,varargin)
            
            % raise sync pulse on even target IDs
            if hTask.params.useSync && mod(hTask.cTrialParams.targetID,2)==0
                tag = sprintf('tr%03dph%02d',hTask.cTrial,hTask.hTrial.phaseIdx);
                sync(hTask.hFramework,@high,'tag',tag);
                comment(hTask,'Sending sync high',3);
            end
        end % END function StartFcn
        
        function EndFcn(this,evt,hTask,varargin)
            if hTask.params.useSync && mod(hTask.cTrialParams.targetID,2)==0
                sync(hTask.hFramework,@low);
            end
        end % END function EndFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
        end % END function PhaseFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            hTarget = hTask.hTarget;
            hEffector = hTask.hEffector{1};
            user = hTask.params.user;
            cTrialParams = hTask.cTrialParams;
            
            % set profile for active target
            hTask.applyObjectProfile(hTarget{cTrialParams.targetID},user.target_profile.active);
            
            % set profiles for rest of targets
            for kk=setdiff(1:length(hTarget),hTask.cTrialParams.targetID)
                hTask.applyObjectProfile(hTarget{kk},user.target_profile.default);
            end
            
            % set profile for effector
            hTask.applyObjectProfile(hEffector,user.effector_profile.default);
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
        end % END function PostDrawFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hTrial.advance;
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
end % END classdef PhaseShowTarget