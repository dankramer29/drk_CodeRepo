classdef PhaseITI < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseITI(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseITI
        
        function StartFcn(this,evt,hTask,varargin)
            hTask.hEffector{1}.brightness = hTask.hEffector{1}.defaultBrightness;
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
    
end % END classdef PhaseITI