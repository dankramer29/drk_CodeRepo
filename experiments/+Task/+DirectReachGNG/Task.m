classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    % Direct Reach

    %To run:
    % fw = Framework.Interface(@Framework.Config.NoPredictor,'DirectReach');
    % start(fw)
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'Direct Reach GNG Task';
    end % END properties(Constant)
    
    %****************%
    % PUBLIC METHODS %
    %****************%
    methods
        
        function this = Task(fw,cfg)
            this = this@Framework.Task.Interface(fw);
            this = this@Experiment2.TaskInterface(cfg);
        end % END function Task
        
        function TaskStartFcn(this,evt,varargin)
        end % END function TaskStartFcn
        
        function PrefaceStartFcn(this,evt,varargin)
            comment(this,'Starting preface');
            
            % create trial params just for the preface
            % params is from Experiment2.Parameters and trialParamsFcn is a
            % function call to Task.DirectReach.createTrailParameters.
            % this.params.user contains the obj.user variables set in the
            % DirectReach parameters file. And the last argument of feval
            % is nothing? also loads DefaultSettings from Common.
            % ultimately this passes those variables to cTrailParams
            tp = feval(this.params.trialParamsFcn{1},this.params.user,this.params.trialParamsFcn{2:end});
            this.cTrialParams = tp;
        end % END function PrefaceStartFcn
        
        function TrialStartFcn(this,evt,varargin)
            
            %show when components are run
            %fprintf('Task: TrialStartFcn has been called\n')
            
            numTrialsRemaining = length(this.TrialParams) - this.cTrial + 1;
            secondsRemaining = numTrialsRemaining*this.hStage.duration;
            
            % save information to trial data struct
            comment(this,sprintf('trial %d/%d (%s minutes); current time: %s; loc: %d, color: %s, GNG: %d',...
                this.cTrial,length(this.TrialParams),...
                util.hms(secondsRemaining,'mm:ss'),...
                datestr(now,'HH:MM:SS'),...
                this.cTrialParams.targetID,...
                this.cTrialParams.colorName,...
                this.cTrialParams.gng));
        end % END function TrialStartFcn
        
        function TrialAbortFcn(this,evt,varargin)
            this.hKeyboard.showKeypress;
        end % END function TrialAbortFcn
        
        function TaskEndFcn(this,evt,varargin)
            numUnknown = nnz(isnan([this.TrialData(1:this.nTrials).ex_success]));
            numCorrect = nnz([this.TrialData(1:this.nTrials).ex_success]==true);
            numKnown = this.nTrials-numUnknown;
            comment(this,sprintf('%d trials, %d/%d (%2.0f%%) correct, %d unknown',this.nTrials,numCorrect,numKnown,100*numCorrect/numKnown,numUnknown));
        end % END function TaskEndFcn
        
        function drawFixationPoint(this)
            user = this.params.user;
            pos = this.hDisplayClient.normPos2Client([0 0]);
            diam = this.hDisplayClient.normScale2Client(user.fixationScale);
            fix_color = [1 1 1];
            this.hDisplayClient.drawOval(pos,diam,fix_color*user.fixationBrightness)
        end % END function drawFixationPoint
        
        function drawFixationPointGNG(this)
            user = this.params.user;
            pos = this.hDisplayClient.normPos2Client([0 0]);
            diam = this.hDisplayClient.normScale2Client(user.fixationScale);
            if this.cTrialParams.gng
                fix_color = [0 1 0]; %green
            else 
                fix_color = [1 0 0]; %red
            end
            this.hDisplayClient.drawOval(pos,diam,fix_color*user.fixationBrightness)
        end % END function drawFixationPointGNG
        
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