classdef PhaseDelayKeypressContinue < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        drawFixationPoint = false;
        soundId
    end
    
    methods
        function this = PhaseDelayKeypressContinue(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseDelayKeypressContinue
        
        function StartFcn(this,evt,hTask,varargin)
            if ~isempty(this.soundId) && hTask.params.useSound
                hTask.hSound.play(this.soundId);
            end
            if hTask.params.useKeyboard
                hTask.expectInput({'next','RightArrow'});
            end
        end % END function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            if this.drawFixationPoint
                Task.Common.drawFixationPoint(hTask);
            end
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            if hTask.params.useDisplay
                hTask.hDisplayClient.setTextSize(96);
                hTask.hDisplayClient.setTextFont('Times');
                drawText(hTask.hDisplayClient,'Press ''RightArrow'' to continue','center','center',[255 255 255],60);
            end
        end % END function PostDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                next = hTask.hKeyboard.check('next');
                if ~isempty(next)
                    hTask.hStage.advance;
                end
            end
        end % END function PhaseFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hStage.advance;
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
end % END classdef PhaseDelayKeypressContinue