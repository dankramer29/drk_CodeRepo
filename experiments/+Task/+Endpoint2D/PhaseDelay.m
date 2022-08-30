classdef PhaseDelay < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseDelay(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseDelay
        
        function StartFcn(this,evt,hTask,varargin)
        end % END function StartFcn
        
        function EndFcn(this,evt,hTask,varargin)
        end % END function EndFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
        end % END function PhaseFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            hTarget = hTask.hTarget;
            hEffector = hTask.hEffector{1};
            user = hTask.params.user;
            
            % set profiles for all targets
            for kk=1:length(hTarget)
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
end % END classdef PhaseDelay