classdef PhaseShowLine < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseShowLine(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowLine
        
        function StartFcn(this,evt,hTask,varargin)
            
            % set the font size
            hTask.hDisplayClient.setTextSize(hTask.cTrialParams.symbolSize);
            hTask.hDisplayClient.setTextFont(hTask.params.user.fontFamily);
        end % END function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            
            % draw the text
            drawText(hTask.hDisplayClient,...
                hTask.cTrialParams.string,...
                hTask.cTrialParams.linePosition(1),...
                hTask.cTrialParams.linePosition(2),...
                hTask.params.user.fontColor,[],[],[],[],[],...
                hTask.cTrialParams.textBounds);
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
end % END classdef PhaseShowLine