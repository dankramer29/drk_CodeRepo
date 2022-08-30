classdef PhaseShowAnswers_NoResponse < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        drawFixationPoint = false;
    end
    
    methods
        function this = PhaseShowAnswers_NoResponse(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowAnswers_NoResponse
        
        function StartFcn(this,evt,hTask,varargin)
            
            % set the font size
            hTask.hDisplayClient.setTextFont(hTask.params.user.operationFontFamily);
            hTask.hDisplayClient.setTextSize(hTask.params.user.operationFontSize);
            if hTask.params.useSync
                sync(hTask.hFramework,@high);
            end
        end % END function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            if this.drawFixationPoint
                hTask.drawFixationPoint;
            end
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)

            % draw the answer
            hTask.hDisplayClient.setTextSize(hTask.cTrialParams.answerFontSize);
            drawText(hTask.hDisplayClient,...
                hTask.cTrialParams.answerString,...
                hTask.cTrialParams.answerPosition(1),...
                hTask.cTrialParams.answerPosition(2),...
                hTask.params.user.answerFontColor,...
                [],[],[],[],[],...
                hTask.cTrialParams.answerBounds);

            % draw the distractor
            hTask.hDisplayClient.setTextSize(hTask.cTrialParams.distractorFontSize);
            drawText(hTask.hDisplayClient,...
                hTask.cTrialParams.distractorString,...
                hTask.cTrialParams.distractorPosition(1),...
                hTask.cTrialParams.distractorPosition(2),...
                hTask.params.user.distractorFontColor,...
                [],[],[],[],[],...
                hTask.cTrialParams.distractorBounds);
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
end % END classdef PhaseShowAnswers_NoResponse