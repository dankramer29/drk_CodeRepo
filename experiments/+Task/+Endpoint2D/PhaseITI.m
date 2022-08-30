classdef PhaseITI < Task.Common.PhaseITI
    
    properties
    end
    
    methods
        function this = PhaseITI(varargin)
            this = this@Task.Common.PhaseITI(varargin{:});
        end % END function PhaseITI
        
        function StartFcn(this,evt,hTask,varargin)
            StartFcn@Task.Common.PhaseITI(this,evt,hTask,varargin{:});
            hTask.hEffector{1}.lockState;
            hTask.hFramework.hPredictor.hDecoder.disableDecoder;
            
            % set state mode (pro or anti)
            for kk=1:length(hTask.hTarget)
                hTask.hTarget{kk}.setMode(hTask.cTrialParams.stateMode);
            end
            hTask.hEffector{1}.setMode(hTask.cTrialParams.stateMode);
        end % END function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            PreDrawFcn@Task.Common.PhaseITI(this,evt,hTask,varargin{:});
            hTarget = hTask.hTarget;
            hEffector = hTask.hEffector{1};
            user = hTask.params.user;
            
            % set profiles for rest of targets
            for kk=1:length(hTarget)
                hTask.applyObjectProfile(hTarget{kk},user.target_profile.default);
            end
            
            % set profile for effector
            hTask.applyObjectProfile(hEffector,user.effector_profile.default);
        end % END function PreDrawFcn
    end % END methods
end % END classdef PhaseShowTarget