classdef PhaseShowAnswers < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseShowAnswers(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowAnswers
        
        function StartFcn(this,evt,hTask,varargin)
            comment(hTask,'Waiting for response');
            
            % notify the task to expect input
            hTask.expectInput({'response',hTask.cTrialParams.response,0.25,0.75},{'dontknow','x',0.25,0.25},'echo',false);
            
            % set the font family and size
            hTask.hDisplayClient.setTextSize(hTask.params.user.fontSize);
            hTask.hDisplayClient.setTextFont(hTask.params.user.fontFamily);
            hTask.hDisplayClient.setTextStyle('normal');
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            
            % check for response
            [resp,dnk] = hTask.hKeyboard.check('response','dontknow');
            if ~isempty(resp)
                if length(resp.anykeys)>1
                    comment(hTask,'Detected multiple keypresses but expected only one - please try again!',1);
                    return;
                end
                hTask.hTrial.TrialData.tr_response = resp.anykeys{1};
            elseif ~isempty(dnk)
                if length(dnk.anykeys)>1
                    comment(hTask,'Detected multiple keypresses but expected only one - please try again!',1);
                    return;
                end
                hTask.hTrial.TrialData.tr_response = 'x';
            end
            
            % if response provided, check success and move on
            if ~isempty(hTask.hTrial.TrialData.tr_response)
                hTask.hTrial.TrialData.calculateSuccess(hTask);
                exstr = 'SUCCESS';
                if isnan(hTask.hTrial.TrialData.ex_success)
                    exstr = 'DONTKNOW';
                elseif ~hTask.hTrial.TrialData.ex_success
                    exstr = 'FAILURE';
                end
                comment(hTask,sprintf('Recorded response ''%s'' (%s)',util.aschar(hTask.hTrial.TrialData.tr_response),exstr));
                hTask.hTrial.advance;
            end
        end % END function PhaseFcn
        
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
        
        function EndFcn(this,evt,hTask,varargin)
            hTask.resetInput('response','dontknow');
        end % END function EndFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            comment(hTask,'No response!');
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
end % END classdef PhaseShowAnswers