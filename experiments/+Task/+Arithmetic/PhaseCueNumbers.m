classdef PhaseCueNumbers < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseCueNumbers(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseCueNumbers
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                tag = sprintf('tr%03dph%02d',hTask.cTrial,hTask.hTrial.phaseIdx);
                sync(hTask.hFramework,@high,'tag',tag);
                comment(hTask,'Sending sync high',3);
            end
            
            % set the font family and size
            hTask.hDisplayClient.setTextSize(hTask.params.user.fontSize);
            hTask.hDisplayClient.setTextFont(hTask.params.user.fontFamily);
            hTask.hDisplayClient.setTextStyle('normal');
        end % END function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            if strcmpi(hTask.cTrialParams.nummodality,'char')
                if iscell(hTask.cTrialParams.num1Info.position)
                    pos1_x = hTask.cTrialParams.num1Info.position{1};
                    pos1_y = hTask.cTrialParams.num1Info.position{2};
                else
                    pos1_x = hTask.cTrialParams.num1Info.position(1);
                    pos1_y = hTask.cTrialParams.num1Info.position(2);
                end
                if iscell(hTask.cTrialParams.num2Info.position)
                    pos2_x = hTask.cTrialParams.num2Info.position{1};
                    pos2_y = hTask.cTrialParams.num2Info.position{2};
                else
                    pos2_x = hTask.cTrialParams.num2Info.position(1);
                    pos2_y = hTask.cTrialParams.num2Info.position(2);
                end
                    
                drawText(hTask.hDisplayClient,...
                    hTask.cTrialParams.num1Info.string,...
                    pos1_x,...
                    pos1_y,...
                    hTask.params.user.fontColor,...
                    [],[],[],[],[],...
                    hTask.cTrialParams.num1Info.bounds);
                drawText(hTask.hDisplayClient,...
                    hTask.cTrialParams.num2Info.string,...
                    pos2_x,...
                    pos2_y,...
                    hTask.params.user.fontColor,...
                    [],[],[],[],[],...
                    hTask.cTrialParams.num2Info.bounds);
            end
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
end % END classdef PhaseCueNumbers