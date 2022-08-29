classdef PhaseExtinguish < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseExtinguish(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseExtinguish
        
        function StartFcn(this,evt,hTask,varargin)
            
            comment(hTask,'Waiting for response');
            
            %starts event log for touch screen
            tsIndex = 1;
            KbQueueCreate(tsIndex);
            KbQueueStart(tsIndex);
            
        end % END function StartFcn
 
        function PreDrawFcn(this,evt,hTask,varargin)
        end % END function PreDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            
            tsIndex = 1;
            
            %checks if mouse has been pressed, records location when
            %pressed 
            [tsPressed] = KbQueueCheck(tsIndex);
            if tsPressed
                comment(hTask,'Recorded extinguish response');
                hTask.hTrial.advance;
            end
            
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
            tsIndex = 1;
            KbQueueStop(tsIndex);
            KbQueueRelease(tsIndex);
        end % END function EndFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            comment(hTask,'No response!');
            hTask.hTrial.abort;
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
end % END classdef PhaseExtinguish