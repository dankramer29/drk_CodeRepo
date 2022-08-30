classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    % l33t
    % Spencer Kellis
    % skellis@vis.caltech.edu
    %
    % This task explores numbers vs language in the context of l33t-speak.
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'l33t task';
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
            
            % set the font family and size
            this.hDisplayClient.setTextSize(this.params.user.fontSize);
            this.hDisplayClient.setTextFont(this.params.user.fontFamily);
            this.hDisplayClient.pref('TextEncodingLocale','UTF-8');
        end % END function TaskStartFcn
        
        function PrefaceStartFcn(this,evt,varargin)
            comment(this,'Starting preface');
            
            % create trial params just for the preface
            tp = feval(this.params.trialParamsFcn{1},this.params.user,this.params.trialParamsFcn{2:end});
            this.cTrialParams = tp(1);
        end % END function PrefaceStartFcn
        
        function TrialStartFcn(this,evt,varargin)
            numTrialsRemaining = length(this.TrialParams) - this.cTrial;
            secondsRemaining = numTrialsRemaining*this.hStage.duration;
            
            % save information to trial data struct
            switch lower(this.cTrialParams.response_type)
                case 'word', rspstr = sprintf('''%s''',this.cTrialParams.word);
                case 'number', rspstr = sprintf('%d',this.cTrialParams.response);
                case 'numberword', rspstr = sprintf('%d',this.cTrialParams.response);
                otherwise, error('Unknown response type ''%s''',this.cTrialParams.response_type);
            end
            comment(this,sprintf('trial %d/%d (%d remaining, %s minutes) l33t: %s; response: %s',...
                this.cTrial,length(this.TrialParams),numTrialsRemaining,...
                util.hms(secondsRemaining,'mm:ss'),...
                this.cTrialParams.l33t,rspstr));
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
        
        function presentCue(this)
            str = upper(this.cTrialParams.l33t);
            clr = this.params.user.fontColor;
            drawText(this.hDisplayClient,str,'center','center',clr);
        end % END function presentCue
        
        function str = processInstructionString(this,str)
            str = strrep(str,'@WORD@',sprintf('%s',this.cTrialParams.word));
            str = strrep(str,'@NUMBERS@',sprintf('%s',util.vec2str(this.cTrialParams.numbers)));
            str = strrep(str,'@WORDRESPONSE@',sprintf('%s',this.cTrialParams.word));
            str = strrep(str,'@NUMBERRESPONSE@',sprintf('%d',feval(this.params.user.numberTrialSuccessFcn,this.cTrialParams.word,this.cTrialParams.l33t,this.cTrialParams.letters,this.cTrialParams.numbers)));
            str = strrep(str,'@MATHSTRING@',sprintf('%s',util.vec2str(this.cTrialParams.numbers,'[%g]','+')));
        end % END function processInstructionString
        
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