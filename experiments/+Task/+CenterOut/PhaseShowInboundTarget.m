classdef PhaseShowInboundTarget < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseShowInboundTarget(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowInboundTarget
        
        function StartFcn(this,evt,hTask,varargin)
            
            % set up target
            hTask.hTarget{1}.homeTarget;
            hTask.hTarget{1}.setVisible;
            
            % restore settings from potential anti changes
            hTask.hTarget{1}.color = [1 0 0];
            hTask.hTarget{1}.stateIntExtMode = 'same';
            
        end % END function StartFcn
        
        function EndFcn(this,evt,hTask,varargin)
        end % END function EndFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
        end % END function PhaseFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            pos = hTask.hDisplayClient.normPos2Client([0 0]);
            diam = hTask.hDisplayClient.normScale2Client(0.02);
            hTask.hDisplayClient.drawOval(pos,diam,[0 0 1]*50)
        end % END function PostDrawFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            
            % abort the trial
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
    
end % END classdef PhaseShowInboundTarget