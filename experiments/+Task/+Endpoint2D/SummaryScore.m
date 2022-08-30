classdef SummaryScore < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = SummaryScore(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function SummaryScore
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                hTask.expectInput({'next','RightArrow'});
            end
        end % END function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            assistLevel = getAssistLevel(hTask.hFramework.hPredictor);
            threshold = floor(53 * assistLevel); % 53 is the number of targets with 100% assist
            %threshold = length([hTask.TrialData.et_trialCompleted]);
            origScore = hTask.stats.score;
            if threshold>0
                modifiedScore = 100*origScore/threshold;
            else
                modifiedScore = 100*hTask.stats.score;
            end
            str = sprintf('Score: %d/%d (%.1f%%)',origScore,threshold,modifiedScore);
            if hTask.params.useDisplay
                hTask.hDisplayClient.setTextSize(96);
                hTask.hDisplayClient.setTextFont('Times');
                drawText(hTask.hDisplayClient,str,'center','center',[255 255 255],60);
            end
        end % END function PostDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                next = hTask.hKeyboard.check('next');
                if ~isempty(next)
                    assistLevel = getAssistLevel(hTask.hFramework.hPredictor);
                    if assistLevel>=1
                        hTask.hSummary.finish;
                    else
                        hTask.hSummary.advance;
                    end
                end
            else
                assistLevel = getAssistLevel(hTask.hFramework.hPredictor);
                if assistLevel>=1
                    hTask.hSummary.finish;
                else
                    hTask.hSummary.advance;
                end
            end
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                hTask.resetInput('next');
            end
        end % END function EndFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hSummary.advance;
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
end % END classdef SummaryScore