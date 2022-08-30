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
        hitInfo
        hitRegistered = false
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
            
            % set the gain in the ideal agent so the cursor makes it to the
            % target center (values determined by trial and error)
            fw.hPredictor.hDecoder.idealAgent.K = [0.25 -0.79];
            
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
            if strcmpi(this.hStage.name,'trial')
                if isprop(this.hStage.phases{this.hStage.phaseIdx},'PhaseOrder') && this.hStage.phases{this.hStage.phaseIdx}.PhaseOrder==2
                    s = this.hTarget{end}.getState;
                else
                    s = this.hTarget{this.cTrialParams.targetID}.getState;
                end
            else
                s = nan(1,length(this.hTarget{end}.stateIdxHitTest));
            end
        end % END function getTarget
        
        function registerHit(this,effectorID)
            this.hitRegistered = true;
        end % END function registerHit
        
        function applyObjectProfile(this,obj,prf)
            obj.color = prf.color;
            obj.scale = prf.scale;
            obj.brightness = prf.brightness;
        end % END function applyObjectProfile
        
        function TaskStartFcn(this,evt,varargin)
        end % END function TaskStartFcn
        
        function TaskUpdateFcn(this,evt,varargin)
        end % END function TaskUpdateFcn
        
        function TaskEndFcn(this,evt,varargin)
            fprintf('Score: %d\n',this.stats.score);
        end % END function TaskEndFcn
        
        function TrialStartFcn(this,evt,varargin)
            
            d = this.hFramework.hPredictor.hDecoder;
            if ~d.BufferData
                d.BufferData = 1;
                d.msgName('Buffering on');
                set(d.guiProps.guihandles.toggleBuffer,'Value',get(d.guiProps.guihandles.toggleBuffer,'Max'));
                set(d.guiProps.guihandles.toggleBuffer,'BackgroundColor','green');
                set(d.guiProps.guihandles.toggleBuffer,'String','Buffering Enabled');
            end
            
            comment(this,sprintf('Starting trial %d',this.nTrials+1));
            this.hitInfo = [];
            this.hitRegistered = false;
        end % END function TrialStartFcn
        
        function PrefaceStartFcn(this,evt,varargin)
        end % END function PrefaceStartFcn
        
        function PrefaceEndFcn(this,evt,varargin)
            
            % enable effector and target
            cellfun(@(x)x.setVisible,this.hTarget);
            cellfun(@(x)x.setVisible,this.hEffector);
        end % END function prefaceEndFcn
        
        function SummaryStartFcn(this,evt,varargin)
            
            % disable effector and target
            cellfun(@(x)x.setInvisible,this.hTarget);
            cellfun(@(x)x.setInvisible,this.hEffector);
            
            % stop buffering
            d = this.hFramework.hPredictor.hDecoder;
            d.BufferData = 0;
            d.msgName('Buffering paused');
            set(d.guiProps.guihandles.toggleBuffer,'Value',get(d.guiProps.guihandles.toggleBuffer,'Min'));
            set(d.guiProps.guihandles.toggleBuffer,'BackgroundColor','red');
            set(d.guiProps.guihandles.toggleBuffer,'String','Buffering Paused');
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