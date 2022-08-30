classdef PhaseCueRespondImagined < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseCueRespondImagined(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseRespond
        
        function StartFcn(this,evt,hTask,varargin)
        end % END function StartFcn
 
        function PreDrawFcn(this,evt,hTask,varargin)
            pos = hTask.cTrialParams.target;
            clr = [1 1 1];%hTask.cTrialParams.color;
            sz = hTask.params.user.targetScale;
            brt = hTask.cTrialParams.brightness;
            
            pos = hTask.hDisplayClient.normPos2Client(pos);
            sz = hTask.hDisplayClient.normScale2Client(sz);
            hTask.hDisplayClient.drawOval(pos,sz,clr*brt);
            
            
            hTask.drawFixationPoint;

        end % END function PreDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
        end % END function EndFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hTrial.TrialData.calculateSuccessImagined(hTask);
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
end % END classdef PhaseRespond