classdef PrefaceInstructions_FixationPoint < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        text
        nextPhase
        prevPhase
    end
    
    methods
        function this = PrefaceInstructions_FixationPoint(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PrefaceInstructions_FixationPoint
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                hTask.expectInput({'prev','LeftArrow'},{'next','RightArrow'},{'skip','escape'});
            end
        end % END Function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            if hTask.params.useDisplay
                msg = hTask.processInstructionString(this.text);
                hTask.hDisplayClient.setTextSize(48);
                hTask.hDisplayClient.setTextFont('Times');
                drawText(hTask.hDisplayClient,msg,200,100,[255 255 255],65,[],[],1.5);
                Task.Common.drawFixationPoint(hTask);
            end
        end % END function PostDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                [next,prev,skip] = hTask.hKeyboard.check('next','prev','skip');
                if ~isempty(next)
                    hTask.hPreface.advance(this.nextPhase);
                elseif ~isempty(prev)
                    hTask.hPreface.advance(this.prevPhase);
                elseif ~isempty(skip)
                    hTask.hPreface.advance('Countdown');
                end
            end
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                hTask.resetInput('prev','next','skip');
            end
        end % END function EndFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hPreface.advance;
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
end % END classdef PrefaceInstructions_FixationPoint