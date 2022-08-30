classdef PhaseShowCode < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseShowCode(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowCode
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                tag = sprintf('tr%03dph%02d',hTask.cTrial,hTask.hTrial.phaseIdx);
                sync(hTask.hFramework,@high,'tag',tag);
                comment(hTask,'Sending sync high',3);
            end
            
            % notify the task to expect input
            hTask.expectInput({'next','RightArrow',0.25,1.0},'echo',false);
            
            % set the font family and size
            hTask.hDisplayClient.setTextSize(hTask.params.user.fontSize);
            hTask.hDisplayClient.setTextFont(hTask.params.user.fontFamily);
            hTask.hDisplayClient.setTextStyle('normal');
            
            % advance the code
            [av,ln,cd] = hTask.hCodeRunner.step;
            comment(hTask,sprintf('Line: %d, remaining: %d, code: %s',ln,av,cd));
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            
            % check for response
            next = hTask.hKeyboard.check('next');
            if ~isempty(next)
                if length(next.anykeys)>1
                    comment(hTask,'Detected multiple keypresses but expected only one - please try again!',1);
                    return;
                end
                if hTask.hCodeRunner.avail>0
                    hTask.hTrial.advance;
                else
                    hTask.hTrial.advance('Respond');
                end
            end
        end % END function PhaseFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            
            % draw the code on screen
            drawText(hTask.hDisplayClient,...
                strjoin(hTask.hCodeRunner.code,'\n'),...
                600,...
                300,...
                hTask.params.user.fontColor);
            
            % draw a pointer to the current line
            curr_line = hTask.hCodeRunner.line - 2;
            height_per_line = 100;
            pos = [500 275 + curr_line*height_per_line];
            diam = 50;
            hTask.hDisplayClient.drawOval(pos,diam,[0.5 0.5 0.5]*150)
        end % END function PostDrawFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            if hTask.hCodeRunner.avail>0
                hTask.hTrial.advance;
            else
                hTask.hTrial.advance('Respond');
            end
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
end % END classdef PhaseShowCode