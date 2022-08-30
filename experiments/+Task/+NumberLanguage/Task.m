classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    % NUMBERLANGUAGE
    % Spencer Kellis
    % skellis@vis.caltech.edu
    %
    % This task is intended to explore representation of numbers as
    % concepts vs language in parietal cortex.
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'Number language task';
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
            this.hDisplayClient.setTextFont(this.params.user.fontFamily);
            this.hDisplayClient.setTextStyle('normal');
            this.hDisplayClient.setTextSize(this.params.user.fontSize);
        end % END function TaskStartFcn
        
        function PrefaceStartFcn(this,evt,varargin)
            comment(this,'Starting preface');
            
            % create trial params just for the preface
            tp = feval(this.params.trialParamsFcn{1},this.params.user,this.params.trialParamsFcn{2:end});
            this.cTrialParams = tp;
        end % END function PrefaceStartFcn
        
        function TrialStartFcn(this,evt,varargin)
            numTrialsRemaining = length(this.TrialParams) - this.cTrial + 1;
            secondsRemaining = numTrialsRemaining*this.hStage.duration;
            
            % save information to trial data struct
            comment(this,sprintf('trial %d/%d (%s minutes) response: %s; num: %d; cue: %s/%s; rsp: %s/%s',...
                this.cTrial,length(this.TrialParams),...
                util.hms(secondsRemaining,'mm:ss'),...
                this.cTrialParams.response,...
                this.cTrialParams.number,...
                this.cTrialParams.cue_type,this.cTrialParams.cue_subtype,...
                this.cTrialParams.rsp_type,this.cTrialParams.rsp_subtype));
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
        
        function presentNumber(this,number,type,subtype)
            count = this.hStage.phases{this.hStage.phaseIdx}.count;
            info = Task.NumberLanguage.getCueData(type,subtype);
            
            % handle the different presentation types
            flagPresent=true;
            switch type
                case 'word'
                    str = info{number+1};
                    x = this.cTrialParams.position{1};
                    y = this.cTrialParams.position{2};
                    clr = this.cTrialParams.color;
                    fn = @drawText;
                    obj = this.hDisplayClient;
                    args{1} = {str,x,y,clr};
                case 'character'
                    str = info{number+1};
                    x = this.cTrialParams.position{1};
                    y = this.cTrialParams.position{2};
                    clr = this.cTrialParams.color;
                    fn = @drawText;
                    obj = this.hDisplayClient;
                    args{1} = {str,x,y,clr};
                case 'shape'
                    pos = this.cTrialParams.position;
                    sz = this.cTrialParams.size;
                    clr = this.cTrialParams.color;
                    fn = @drawShapes;
                    obj = this.hDisplayClient;
                    args{1} = {pos,sz,clr,subtype};
                case 'image'
                    img = sprintf('%s_%d',subtype,number);
                    pos = this.cTrialParams.position;
                    sz = this.cTrialParams.size;
                    fn = @drawImage;
                    obj = this.hDisplayClient;
                    args{1} = {img,pos,sz};
                case 'object'
                    img = subtype;
                    pos = this.cTrialParams.position;
                    sz = this.cTrialParams.size;
                    fn = @drawImages;
                    obj = this.hDisplayClient;
                    args{1} = {img,pos,sz};
                case 'sound'
                    snd = sprintf('%s_%d',subtype,number);
                    fn = @play;
                    obj = this.hSound;
                    args{1} = {snd};
                    if count>0,flagPresent=false;end;
                otherwise
                    error('Unknown presentation type ''%s''',type);
            end
            if flagPresent
                for kk=1:length(args)
                    feval(fn,obj,args{kk}{:});
                end
            end
        end % END function presentNumber
        
        function str = processInstructionString(this,str)
            catchnum = max(this.params.user.numbers)+1;
            number = this.cTrialParams.number;
            
            str = strrep(str,'@CATCHNUM@',sprintf('%d',catchnum));
            str = strrep(str,'@NUMBER@',sprintf('%d',number));
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