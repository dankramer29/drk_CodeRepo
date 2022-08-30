classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'Center-out endpoint task';
    end % END properties(Constant)
    
    %*******************%
    % PUBLIC PROPERTIES %
    %*******************%
    properties
        scoreHeight
    end % END properties
    
    %****************%
    % PUBLIC METHODS %
    %****************%
    methods
        function this = Task(fw,fcnConfig)
            this = this@Framework.Task.Interface(fw);
            this = this@Experiment2.TaskInterface(fcnConfig);
            
            % set the ylimits on the Framework GUI
            for kk=1:length(this.hFramework.hGUI)
                if isa(this.hFramework.hGUI{kk},'Framework.GUI.Default')
                    setYLim(this.hFramework.hGUI{kk},[-0.5 0.5]);
                end
            end
            
            % sounds
            if this.params.useSound
                this.hSound.register('Go','digital_blip.wav');
                this.hSound.register('Timeout','nomail.wav');
                this.hSound.register('Home','spokennumbers/0.wav');
                this.hSound.register('Target1','spokennumbers/1.wav');
                this.hSound.register('Target2','spokennumbers/2.wav');
                this.hSound.register('Target3','spokennumbers/3.wav');
                this.hSound.register('Target4','spokennumbers/4.wav');
                this.hSound.register('Target5','spokennumbers/5.wav');
                this.hSound.register('Target6','spokennumbers/6.wav');
                this.hSound.register('Target7','spokennumbers/7.wav');
                this.hSound.register('Target8','spokennumbers/8.wav');
            end
            
            % initialize statistics
            this.stats.score = 0;
        end % END function Task
        
        function setState(this,state)
            this.hEffector{1}.setState(state);
        end % END function setState
        
        function s = getState(this)
            s = this.hEffector{1}.getState;
        end % END function getState
        
        function s = getTarget(this)
            s = this.hTarget{1}.getState;
        end % END function getTarget
        
        function TaskStartFcn(this,evt,varargin)
            d = this.hFramework.hPredictor.hDecoder;
            d.BufferData = 1;
            d.msgName('Buffering on');
            set(d.guiProps.guihandles.toggleBuffer,'Value',get(d.guiProps.guihandles.toggleBuffer,'Max'));
            set(d.guiProps.guihandles.toggleBuffer,'BackgroundColor','green');
            set(d.guiProps.guihandles.toggleBuffer,'String','Buffering Enabled');
            
            % font size
            this.hDisplayClient.setTextSize(54);
            this.hDisplayClient.setTextFont('Times');
            
            % set the runtime limit
            setRuntimeLimit(this.hFramework,'frame',this.params.user.frameLimit);
        end % END function TaskStartFcn
        
        function TaskEndFcn(this,evt,varargin)
            fprintf('Score: %d\n',this.stats.score);
        end % END function TaskEndFcn
        
        function TaskUpdateFcn(this,evt,varargin)
            if this.params.useDisplay && strcmpi(class(this.hStage),func2str(this.params.trialConstructor))
                msg = sprintf('Score: %d',this.stats.score);
                %displayMessage(this.hDisplayClient,msg,10,10,[0 150 150]);
                if isempty(this.scoreHeight)
                    [~,~,bnd] = drawText(this.hDisplayClient,msg,10,10,[0 0 0],60);
                    this.scoreHeight = bnd(4)-bnd(2);
                end
                displayMessage(this.hDisplayClient,msg,10,10+this.scoreHeight,[0 150 150]);
            end
        end % END function TaskUpdateFcn
        
        function TrialStartFcn(this,evt,varargin)
            comment(this,sprintf('Starting trial %d',this.nTrials+1));
        end % END function TrialStartFcn
        
        function SummaryStartFcn(this,evt,varargin)
            
            % disable effector
            this.hEffector{1}.setInvisible;
            this.hEffector{1}.setState(zeros(1,this.hEffector{1}.nStateVars));
            this.hEffector{1}.lockState;
            this.hEffector{1}.disableEvents;
            
            % disable target
            this.hTarget{1}.setInvisible;
            this.hTarget{1}.lockState; 
            this.hTarget{1}.disableEvents;
            
            % stop buffering
            d = this.hFramework.hPredictor.hDecoder;
            d.BufferData = 0;
            d.msgName('Buffering paused');
            set(d.guiProps.guihandles.toggleBuffer,'Value',get(d.guiProps.guihandles.toggleBuffer,'Min'));
            set(d.guiProps.guihandles.toggleBuffer,'BackgroundColor','red');
            set(d.guiProps.guihandles.toggleBuffer,'String','Buffering Paused');
            
            % disable the predictor
            this.hFramework.hPredictor.disablePredictor;
        end % END function SummaryStartFcn
        
        function skip = structableSkipFields(this)
            skip1 = structableSkipFields@Experiment2.TaskInterface(this);
            skip2 = structableSkipFields@Framework.Task.Interface(this);
            skip = [skip1 skip2];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st1 = structableManualFields@Experiment2.TaskInterface(this);
            st2 = structableManualFields@Framework.Task.Interface(this);
            st = util.catstruct(st1,st2);
        end % END function structableManualFields
    end % END methods
end % END classdef Task