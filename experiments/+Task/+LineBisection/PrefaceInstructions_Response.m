classdef PrefaceInstructions_Response < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        text
        nextPhase
        prevPhase
        rspIdx
    end
    
    methods
        function this = PrefaceInstructions_Response(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PrefaceInstructions_Response
        
        function StartFcn(this,evt,hTask,varargin)
            hTask.expectInput({'prev','LeftArrow'},{'next','RightArrow'},{'skip','escape'});
            
            % determine which sound to play
            user = hTask.params.user;
            type = user.rsp_types{this.rspIdx}{1};
            subtype = user.rsp_types{this.rspIdx}{2};
            hTask.hSound.play(sprintf('%s_%s',type,subtype));
        end % END function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            msg = hTask.processInstructionString(this.text);
            hTask.hDisplayClient.setTextSize(48);
            hTask.hDisplayClient.setTextFont('Times');
            drawText(hTask.hDisplayClient,msg,200,100,[255 255 255],65,[],[],1.5);
        end % END function PostDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            [next,prev,skip] = hTask.hKeyboard.check('next','prev','skip');
            if ~isempty(next)
                hTask.hPreface.advance(this.nextPhase);
            elseif ~isempty(prev)
                hTask.hPreface.advance(this.prevPhase);
            elseif ~isempty(skip)
                hTask.hPreface.advance('Countdown');
            end
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
            hTask.resetInput('prev','next','skip');
        end % END function EndFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hPreface.advance(this.nextPhase);
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
end % END classdef PrefaceInstructions_Response