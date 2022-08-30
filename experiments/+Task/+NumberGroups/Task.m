classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    % NUMBERGROUPS
    % Spencer Kellis
    % skellis@vis.caltech.edu
    %
    % This task is intended to explore representation of numbers in
    % parietal cortex.
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'Number groups task';
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
        end % END function PrefaceStartFcn
        
        function TrialStartFcn(this,evt,varargin)
            numTrialsRemaining = length(this.TrialParams) - this.cTrial + 1;
            secondsRemaining = numTrialsRemaining*this.hStage.duration;
            
            % save information to trial data struct
            comment(this,sprintf('trial %d/%d (%s minutes) response: %s; catch %s; numdisp: %d; numgroup: %d',...
                this.cTrial,length(this.TrialParams),...
                util.hms(secondsRemaining,'mm:ss'),...
                this.cTrialParams.response,...
                sprintf('%d',this.cTrialParams.catch),...
                this.cTrialParams.numberDisplay,...
                this.cTrialParams.numberGroup));
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
        
        function showGroup(this)
            
            % handle the different presentation types
            type = 'character';
            switch type
                case 'character'
                    pos = this.cTrialParams.position;
                    clr = this.cTrialParams.color;
                    fn = @drawText;
                    obj = this.hDisplayClient;
                    args = cell(1,this.cTrialParams.numberGroup);
                    for kk=1:this.cTrialParams.numberGroup
                        if ~this.cTrialParams.catch
                            str = sprintf('%d',this.cTrialParams.numberDisplay);
                        else
                            str = sprintf('%d',this.cTrialParams.catchNum(kk));
                        end
                        args{kk} = {str,pos(1,kk),pos(2,kk),clr};
                    end
                otherwise
                    error('Unknown presentation type ''%s''',type);
            end
            for kk=1:length(args)
                feval(fn,obj,args{kk}{:});
            end
        end % END function presentNumber
        
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