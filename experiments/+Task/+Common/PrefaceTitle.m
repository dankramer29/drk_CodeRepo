classdef PrefaceTitle < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        titleString = 'Task';
        subtitleString
        textColor = [255 255 255]
    end
    
    methods
        function this = PrefaceTitle(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PrefaceTitle
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                hTask.expectInput({'next','RightArrow'},{'skip','escape'});
            end
        end % END Function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            if hTask.params.useDisplay
                hTask.hDisplayClient.setTextSize(96);
                hTask.hDisplayClient.setTextFont('Times');
                [~,~,bnd] = drawText(hTask.hDisplayClient,this.titleString,'center','center',this.textColor,60);
                if ~isempty(this.subtitleString)
                    drawText(hTask.hDisplayClient,this.subtitleString,'center',bnd(4)+(bnd(4)-bnd(2))+10,this.textColor,60);
                end
            end
        end % END function PostDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                [next,skip] = hTask.hKeyboard.check('next','skip');
                if ~isempty(next)
                    hTask.hPreface.advance;
                elseif ~isempty(skip)
                    hTask.hPreface.advance('Countdown');
                end
            end
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                hTask.resetInput('next','skip');
            end
            % if hTask.params.useSync
            %     sync(hTask.hFramework,@low);
            % end
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
end % END classdef PrefaceTitle