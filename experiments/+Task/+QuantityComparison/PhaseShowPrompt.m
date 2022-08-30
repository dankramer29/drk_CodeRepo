classdef PhaseShowPrompt < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseShowPrompt(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowPrompt
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                tag = sprintf('tr%03dph%02d',hTask.cTrial,hTask.hTrial.phaseIdx);
                sync(hTask.hFramework,@high,'tag',tag);
            end
            
            % set the font size
            hTask.hDisplayClient.setTextSize(hTask.cTrialParams.promptFontSize);
            hTask.hDisplayClient.setTextFont(hTask.cTrialParams.promptFontFamily);
        end % END function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)

            % draw the text
            drawText(hTask.hDisplayClient,...
                hTask.cTrialParams.promptString,...
                hTask.cTrialParams.promptPosition(1),...
                hTask.cTrialParams.promptPosition(2),...
                hTask.cTrialParams.promptFontBrightness*hTask.cTrialParams.promptFontColor);
        end % END function PostDrawFcn
        
        function EndFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                sync(hTask.hFramework,@low);
            end
        end % END function EndFcn
        
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
end % END classdef PhaseShowPrompt