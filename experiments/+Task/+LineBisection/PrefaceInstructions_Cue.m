classdef PrefaceInstructions_Cue < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        count % counting how many times cue has been presented (for sound)
        text
        nextPhase
        prevPhase
        cueIdx
    end
    
    methods
        function this = PrefaceInstructions_Cue(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PrefaceInstructions_Cue
        
        function StartFcn(this,evt,hTask,varargin)
            hTask.expectInput({'prev','LeftArrow'},{'next','RightArrow'},{'skip','escape'});
            this.count = 0;
            
            % generate trial params for this cue type
            user = hTask.params.user;
            type = user.cue_types{this.cueIdx}{1};
            subtype = user.cue_types{this.cueIdx}{2};
            number = user.numbers( randperm(length(user.numbers),1) );
            [~,~,fn] = Task.NumberLanguage.getCueData(type,subtype);
            [pos,sz,clr] = feval(fn,user,{type,subtype},number,user.cue_args{this.cueIdx}{:});
            [~,~,fn] = Task.NumberLanguage.getResponseData(user.rsp_types{1}{1},user.rsp_types{1}{2});
            response = feval(fn,user.numbers,number);
            hTask.cTrialParams = struct(...
                'number',number,...
                'cue_type',type,...
                'cue_subtype',subtype,...
                'rsp_type',user.rsp_types{1}{1},... % response type doesn't matter
                'rsp_subtype',user.rsp_types{1}{2},...
                'response',response,...
                'position',pos,...
                'size',sz,...
                'color',clr);
        end % END Function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            hTask.presentNumber(hTask.cTrialParams.number,hTask.cTrialParams.cue_type,hTask.cTrialParams.cue_subtype);
            this.count = this.count+1;
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            if hTask.params.useDisplay
                msg = hTask.processInstructionString(this.text);
                hTask.hDisplayClient.setTextSize(48);
                hTask.hDisplayClient.setTextFont('Times');
                drawText(hTask.hDisplayClient,msg,200,100,[255 255 255],65,[],[],1.5);
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
end % END classdef PrefaceInstructions_Cue