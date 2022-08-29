classdef PhaseShowOutboundTarget < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseShowOutboundTarget(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowOutboundTarget
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                sync(hTask.hFramework,@high);
            end
            hTask.hEffector{1}.brightness = hTask.hEffector{1}.defaultBrightness;
            
            % set up target
            hTask.hTarget{1}.unlockState;
            hTask.hTarget{1}.enableEvents;
            hTask.hTarget{1}.newTarget;
            hTask.hTarget{1}.setVisible;
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
%             if hTask.hFramework.frameId > hTask.params.user.frameLimit
%                 hTask.hTrial.finish;
%             end
        end % END function PhaseFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            pos = hTask.hDisplayClient.normPos2Client([0 0]);
            diam = hTask.hDisplayClient.normScale2Client(0.02);
            hTask.hDisplayClient.drawOval(pos,diam,[0 0 1]*50)
        end % END function PostDrawFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hTrial.advance;
        end % END function TimeoutFcn
        
        function EndFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                sync(hTask.hFramework,@low);
            end
        end % END function EndFcn
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Experiment2.PhaseInterface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Experiment2.PhaseInterface(this);
        end % END function structableManualFields
    end % END methods
end % END classdef PhaseShowOutboundTarget