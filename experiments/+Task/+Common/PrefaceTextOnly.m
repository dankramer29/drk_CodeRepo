classdef PrefaceTextOnly < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id % phase ID
        Name % name of this phase
        durationTimeout % amount of time to display this text
        drawFixationPoint = false;
        text % text to display
        nextPhase % string or index defining next phase
        prevPhase % string or index defining previous phase
        fontSize = 48 % font size in pt
        fontFamily = 'Times' % font family
        fontColor = [255 255 255] % font color in RGB (0-255)
        strX % x-position of left border of string bounding box
        strY % baseline of first line of text
        wrapAt % break strings into multiple lines of roughly this many characters
        vSpacing = 1.5 % vertical spacing between lines
    end
    
    methods
        function this = PrefaceTextOnly(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PrefaceTextOnly
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                hTask.expectInput({'prev','LeftArrow'},{'next','RightArrow'},{'skip','escape'});
            end
            if hTask.params.useDisplay
                hTask.hDisplayClient.setTextSize(this.fontSize);
                hTask.hDisplayClient.setTextFont(this.fontFamily);
                if isfield(hTask.params.user,'instruction_symbols')
                    this.text = Task.Common.processInstructionString(this.text,hTask.params.user.instruction_symbols);
                else
                    this.text = this.text;
                end
                res = env.get('displayresolution');
                if isempty(this.strX)
                    this.strX = 'center';
                end
                if isempty(this.strY)
                    this.strY = min(200,round(0.2*res(2)));
                end
                if isempty(this.wrapAt)
                    charWidth = 0.3*this.fontSize;
                    this.wrapAt = round(0.8*res(1)/charWidth);
                end
            end
        end % END Function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            if this.drawFixationPoint
                Task.Common.drawFixationPoint(hTask);
            end
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            if hTask.params.useDisplay
                drawText(hTask.hDisplayClient,this.text,this.strX,this.strY,this.fontColor,this.wrapAt,[],[],this.vSpacing);
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
end % END classdef PrefaceTextOnly