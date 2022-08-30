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
            if hTask.params.useSync
                sync(hTask.hFramework,@high);
            end
            
            % set the font family and size
            hTask.hDisplayClient.setTextSize(96);
            hTask.hDisplayClient.setTextFont('Times');
            hTask.hDisplayClient.setTextStyle('normal');
        end % END function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            numUnknown = nnz(isnan([hTask.TrialData(1:hTask.nTrials).ex_success]));
            numKnown = hTask.nTrials - numUnknown;
            numCorrect = nnz([hTask.TrialData(1:hTask.nTrials).ex_success]==true);
            
            str = [sprintf('%d Trials\n\n',hTask.nTrials)...
                sprintf('Score: %d/%d (%2.0f%%)\n\n',numCorrect,numKnown,100*numCorrect/numKnown)];
            
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
                    hTask.hSummary.advance;
                end
            else
                hTask.hSummary.advance;
            end
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                hTask.resetInput('next');
            end
            if hTask.params.useSync
                sync(hTask.hFramework,@low);
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