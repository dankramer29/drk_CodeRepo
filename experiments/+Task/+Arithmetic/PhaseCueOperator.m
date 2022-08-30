classdef PhaseCueOperator < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        count % how many times the cue has been presented (for sound)
    end
    
    methods
        function this = PhaseCueOperator(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseCueOperator
        
        function StartFcn(this,evt,hTask,varargin)
            this.count = 0;
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
            
            % present the operator cue
            if strcmpi(hTask.cTrialParams.cuemodality,'symbol') || strcmpi(hTask.cTrialParams.cuemodality,'text')
                if strcmpi(hTask.cTrialParams.cuemodality,'symbol')
                    hTask.hDisplayClient.setTextSize(2*hTask.params.user.fontSize);
                end
                if iscell(hTask.cTrialParams.opInfo.position)
                    pos1 = hTask.cTrialParams.opInfo.position{1};
                    pos2 = hTask.cTrialParams.opInfo.position{2};
                else
                    pos1 = hTask.cTrialParams.opInfo.position(1);
                    pos2 = hTask.cTrialParams.opInfo.position(2);
                end
                drawText(hTask.hDisplayClient,...
                    hTask.cTrialParams.opInfo.string,...
                    pos1,...
                    pos2,...
                    hTask.params.user.fontColor,...
                    [],[],[],[],[],...
                    hTask.cTrialParams.opInfo.bounds);
            elseif strcmpi(hTask.cTrialParams.cuemodality,'audio')
                if this.count<1
                    hTask.hSound.play(hTask.cTrialParams.opInfo.soundname);
                    this.count = this.count+1;
                end
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
end % END classdef PhaseCueOperator