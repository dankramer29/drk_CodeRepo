classdef PrefaceCountdown < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        markTime
        countdown
        countdownStartValue = 3;
        countdownInterval = 1.5;
    end
    
    methods
        function this = PrefaceCountdown(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PrefaceCountdown
        
        function StartFcn(this,evt,hTask,varargin)
            this.markTime = GetSecs;
            this.countdown = this.countdownStartValue;
            if hTask.params.useSound
%                 hTask.hSound.play('countdown');
            end
        end % END function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            if hTask.params.useDisplay
                oldTextSize = hTask.hDisplayClient.getTextSize();
                oldTextFont = hTask.hDisplayClient.getTextFont();
                hTask.hDisplayClient.setTextSize(96);
                hTask.hDisplayClient.setTextFont('Times');
                drawText(hTask.hDisplayClient,sprintf('%d',this.countdown),'center','center',[255 255 255]);
                hTask.hDisplayClient.setTextSize(oldTextSize);
                hTask.hDisplayClient.setTextFont(oldTextFont);
            end
        end % END function PostDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            
            % get current time
            currTime = GetSecs;
            
            % check how much time has elapsed
            if (currTime - this.markTime) >= this.countdownInterval
                
                % count down
                this.countdown = this.countdown-1;
                
                % reset mark time
                this.markTime = GetSecs;
                
                % if countdown is at zero, move on; otherwise, play sound
                if this.countdown == 0
                    hTask.hPreface.finish;
                else
                    if hTask.params.useSound
%                         hTask.hSound.play('countdown');
                    end
                end
            end
        end % END function PhaseFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hPreface.finish;
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
end % END classdef PrefaceCountdown