classdef PrefaceInstructions01 < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PrefaceInstructions01(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PrefaceInstructions01
        
        function StartFcn(this,evt,hTask,varargin)
            hTask.expectInput({'prev','LeftArrow'},{'next','RightArrow'},{'skip','escape'});
        end % END Function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            text = hTask.processInstructionString(hTask.params.user.instructions{this.id-1});
            hTask.hDisplayClient.setTextSize(48);
            hTask.hDisplayClient.setTextFont('Times');
            drawText(hTask.hDisplayClient,text,200,100,[255 255 255],65,[],[],1.5);
        end % END function PostDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            [next,prev,skip] = hTask.hKeyboard.check('next','prev','skip');
            if ~isempty(next)
                hTask.hPreface.advance;
            elseif ~isempty(prev)
                hTask.hPreface.advance('Title');
            elseif ~isempty(skip)
                hTask.hPreface.advance('Countdown');
            end
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
            hTask.resetInput('prev','next','skip');
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
end % END classdef PrefaceInstructions01