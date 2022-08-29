classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    % STROOP
    % Dan Kramer (drk_431@usc.edu)
    % Roberto Martin del Campo Vera (mart737@usc.edu)
    %
    % This task is intended to explore neural activity associated
    % reading/naming colors congruently or otherwise.
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'Stroop task';
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
            this.hDisplayClient.pref('TextEncodingLocale','UTF-8');
            
            % set task font/size
            this.hDisplayClient.setTextSize(this.params.user.fontSize);
            this.hDisplayClient.setTextFont(this.params.user.fontFamily);
            this.hDisplayClient.setTextStyle('normal');
        end % END function TaskStartFcn
        
        function PrefaceStartFcn(this,evt,varargin)
        end % END function PrefaceStartFcn
        
        function TrialStartFcn(this,evt,varargin)
            numTrialsRemaining = length(this.TrialParams) - this.cTrial + 1;
            secondsRemaining = numTrialsRemaining*this.hStage.duration;
            
            % print asterisk next to correct answer
            cue_word = this.cTrialParams.cue_word;
            cue_color = this.cTrialParams.cue_color;
            switch lower(this.cTrialParams.response_modality)
                case 'text'
                    cue_word = sprintf('*%s',cue_word);
                case 'color'
                    cue_color = sprintf('*%s',cue_color);
                otherwise
                    error('Unknown response modality "%s"',this.cTrialParams.response_modality);
            end
            
            % print out to the screen
            comment(this,sprintf('trial %d/%d (%s minutes); current time: %s; text: %s, color: %s, response: %s',...
                this.cTrial,length(this.TrialParams),...
                util.hms(secondsRemaining,'mm:ss'),...
                datestr(now,'HH:MM:SS'),...
                cue_word,...
                cue_color,...
                this.cTrialParams.answer));
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