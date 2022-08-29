classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    % COMPUTERPROGRAMMING
    % Spencer Kellis
    % skellis@vis.caltech.edu
    %
    % This task is intended to explore prolonged computer arithmetic in the
    % context of learning the basics of computer programming
    properties
        hCodeRunner
    end % END properties
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'Computer Programming task';
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
            
            % set the font family and size
            this.hDisplayClient.setTextSize(this.params.user.fontSize);
            this.hDisplayClient.setTextFont(this.params.user.fontFamily);
            this.hDisplayClient.setTextStyle('normal');
        end % END function TaskStartFcn
        
        function PrefaceStartFcn(this,evt,varargin)
            
            % generate text for subtitle
            numTrials = length(this.TrialParams);
            % timeRemaining = util.hms(numTrials*this.hTrial.duration);
            which = cellfun(@(x)strcmpi(class(x),'Task.Common.PrefaceTitle'),this.hStage.phases);
            if any(which)
                assert(nnz(which)==1,'Found multiple matches for Task.Common.PrefaceTitle');
                this.hStage.phases{which}.subtitleString = sprintf('%d trials',numTrials);%, %s minutes',numTrials,timeRemaining);
            end
        end % END function PrefaceStartFcn
        
        function TrialStartFcn(this,evt,varargin)
            numTrialsRemaining = length(this.TrialParams) - this.cTrial + 1;
            secondsRemaining = numTrialsRemaining*this.hStage.duration;
            
            % create the CodeRunner object
            taskdir = fileparts(mfilename('fullpath'));
            prog = fullfile(taskdir,this.params.user.programs{this.cTrialParams.program_idx});
            this.hCodeRunner = Task.ComputerProgramming.CodeRunner(prog);
            varlist = this.params.user.strrep_vars;
            varvals = cell(1,length(varlist));
            for nn=1:length(varlist)
                if ischar(this.cTrialParams.(varlist{nn}))
                    varvals{nn} = this.cTrialParams.(varlist{nn});
                else
                    varvals{nn} = sprintf('%d',this.cTrialParams.(varlist{nn}));
                end
            end
            this.hCodeRunner.strrep(varlist,varvals);
            
            % save information to trial data struct
            comment(this,sprintf('trial %d/%d (%s minutes) response: %d',...
                this.cTrial,length(this.TrialParams),...
                util.hms(secondsRemaining,'mm:ss'),...
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
            this.hDisplayClient.drawOval(pos,diam,user.fixationColor*user.fixationBrightness)
        end % END function drawFixationPoint
        
        function drawCode(this)
            code = this.hCodeRunner.code;
            this.hDisplayClient.drawText(code);
        end % END function drawCode
        
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