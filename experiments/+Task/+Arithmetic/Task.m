classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    % ARITHMETIC
    % Spencer Kellis
    % skellis@vis.caltech.edu
    %
    % This task is intended to explore neural activity associated with 
    % arithmetic operations.
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'Arithmetic task';
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
            
            % calculate actual positions of the answers
            res = this.params.user.displayresolution;
            for kk=1:length(this.TrialParams)
                
                % to be explicit
                this.TrialParams(kk).eqInfo = [];
                this.TrialParams(kk).opInfo = [];
                this.TrialParams(kk).num1Info = [];
                this.TrialParams(kk).num2Info = [];
                
                % branch on cue style (joint, separate)
                % then on cue modality (equation, symbol, text, audio)
                if strcmpi(this.params.user.cuestyle,'joint')
                    
                    % only some aspects of computation are unique
                    if strcmpi(this.TrialParams(kk).cuemodality,'equation')
                        
                        % construct the operation string and determine its position
                        this.hDisplayClient.setTextSize(this.params.user.fontSize);
                        str = sprintf('%d %s %d',this.TrialParams(kk).number1,op2sym(this.TrialParams(kk).operator),this.TrialParams(kk).number2);
                        fld = 'eqInfo';
                    elseif strcmpi(this.TrialParams(kk).cuemodality,'symbol')
                        
                        % construct operator string and determine its position
                        this.hDisplayClient.setTextSize(2*this.params.user.fontSize);
                        str = sprintf('%s',op2sym(this.TrialParams(kk).operator));
                        fld = 'opInfo';
                    end
                    
                    % common operations
                    [~,~,bounds] = drawText(this.hDisplayClient,str,'center','center',[0 0 0]);
                    tw = ceil(bounds(3)-bounds(1));
                    th = ceil(bounds(4)-bounds(2));
                    strPos = [res(1)/2-tw/2; res(2)/2+th/2];
                    
                    % save out information
                    this.TrialParams(kk).(fld) = struct('string',str,'position',strPos,'bounds',bounds);
                elseif strcmpi(this.params.user.cuestyle,'separate')
                    
                    % operator
                    if strcmpi(this.TrialParams(kk).cuemodality,'symbol')
                        
                        % construct operator string and determine its position
                        this.hDisplayClient.setTextSize(2*this.params.user.fontSize);
                        iscatch = strcmpi(this.TrialParams(kk).catch,'op');
                        str = op2sym(this.TrialParams(kk).operator,iscatch);
                        [~,~,bounds] = drawText(this.hDisplayClient,str,'center','center',[0 0 0]);
                        tw = ceil(bounds(3)-bounds(1));
                        th = ceil(bounds(4)-bounds(2));
                        pos = getStrPos(this.params.user.opposition,res,tw,th);
                        this.TrialParams(kk).opInfo = struct('string',str,'position',pos,'bounds',bounds);
                    elseif strcmpi(this.TrialParams(kk).cuemodality,'text')
                        
                        % construct operator string and determine its position
                        this.hDisplayClient.setTextSize(this.params.user.fontSize);
                        iscatch = strcmpi(this.TrialParams(kk).catch,'op');
                        str = op2text(this.TrialParams(kk).operator,iscatch);
                        [~,~,bounds] = drawText(this.hDisplayClient,str,'center','center',[0 0 0]);
                        tw = ceil(bounds(3)-bounds(1));
                        th = ceil(bounds(4)-bounds(2));
                        pos = getStrPos(this.params.user.opposition,res,tw,th);
                        this.TrialParams(kk).opInfo = struct('string',str,'position',pos,'bounds',bounds);
                    elseif strcmpi(this.TrialParams(kk).cuemodality,'audio')
                        
                        % define the operator sound name
                        iscatch = strcmpi(this.TrialParams(kk).catch,'op');
                        this.TrialParams(kk).opInfo = struct('soundname',op2sound(this.TrialParams(kk).operator,iscatch));
                    else
                        error('Unknown cue modality ''%s''',this.TrialParams(kk).cuemodality);
                    end
                    
                    % numbers
                    if strcmpi(this.TrialParams(kk).nummodality,'char')
                        this.hDisplayClient.setTextSize(this.params.user.fontSize);
                        
                        % construct strings
                        iscatch1 = strcmpi(this.TrialParams(kk).catch,'num1');
                        iscatch2 = strcmpi(this.TrialParams(kk).catch,'num2');
                        num1 = this.TrialParams(kk).number1;
                        num2 = this.TrialParams(kk).number2;
                        str1 = num2char(num1,iscatch1);
                        str2 = num2char(num2,iscatch2);
                        
                        % construct positions
                        [~,~,bounds1] = drawText(this.hDisplayClient,str1,'center','center',[0 0 0]);
                        tw1 = ceil(bounds1(3)-bounds1(1));
                        th1 = ceil(bounds1(4)-bounds1(2));
                        pos1 = getStrPos(this.params.user.numposition{1},res,tw1,th1);
                        [~,~,bounds2] = drawText(this.hDisplayClient,str2,'center','center',[0 0 0]);
                        tw2 = ceil(bounds2(3)-bounds2(1));
                        th2 = ceil(bounds2(4)-bounds2(2));
                        pos2 = getStrPos(this.params.user.numposition{2},res,tw2,th2);
                        
                        % construct info structs
                        this.TrialParams(kk).num1Info = struct('string',str1,'position',pos1,'bounds',bounds1);
                        this.TrialParams(kk).num2Info = struct('string',str2,'position',pos2,'bounds',bounds2);
                    elseif strcmpi(this.TrialParams(kk).nummodality,'audio')
                        iscatch1 = strcmpi(this.TrialParams(kk).catch,'num1');
                        iscatch2 = strcmpi(this.TrialParams(kk).catch,'num2');
                        num1 = this.TrialParams(kk).number1;
                        num2 = this.TrialParams(kk).number2;
                        this.TrialParams(kk).num1Info = struct('soundname',num2audio(num1,iscatch1));
                        this.TrialParams(kk).num2Info = struct('soundname',num2audio(num2,iscatch2));
                    else
                        error('Unknown num modality ''%s''',this.TrialParams(kk).nummodality);
                    end
                end
            end
            
            % set the font family and size
            this.hDisplayClient.setTextSize(this.params.user.fontSize);
            this.hDisplayClient.setTextFont(this.params.user.fontFamily);
            this.hDisplayClient.setTextStyle('normal');
            
            function strPos = getStrPos(pos,res,tw,th)
                % GETSTRPOS get string position
                %
                %   Given a position direction ('left', 'right', 'center',
                %   or 'random', the screen dimensions, and the size of the
                %   text bounding box, determine a location (x,y
                %   coordinates) for a string.
                assert(ischar(pos),'Posiiton must be char, not ''%s''',class(pos));
                switch lower(pos)
                    case 'left'
                        strPos = [res(1)/4-tw/2; res(2)/2+th/2];
                    case 'right'
                        strPos = [3*res(1)/4-tw/2; res(2)/2+th/2];
                    case 'center'
                        strPos = {{'center','center'}};
                    case 'random'
                        strPos = [randi(res(1)) randi(res(2))];
                        if res(1)-strPos(1) < 2*tw
                            strPos(1) = round(strPos(1) - 2*tw);
                        end
                        if res(2)-strPos(2) < 2*th
                            strPos(2) = round(strPos(2) - 2*th);
                        end
                    otherwise
                        error('unknown position string ''%s''',pos);
                end
            end % END function getStrPos
            
            function str = num2char(num,iscatch)
                if nargin<2||isempty(iscatch),iscatch=false;end
                if iscatch
                    idx = randperm(length(this.params.user.catch_char));
                    str = this.params.user.catch_char{idx(1)};
                else
                    str = sprintf('%d',num);
                end
            end % END function num2char
            
            function str = num2audio(num,iscatch)
                if nargin<2||isempty(iscatch),iscatch=false;end
                if iscatch
                    idx = randperm(length(this.params.user.catch_audio));
                    str = this.params.user.catch_audio{idx(1)};
                else
                    str = sprintf('num%d',num);
                end
            end % END function num2audio
            
            function sym = op2sym(op,iscatch)
                if nargin<2||isempty(iscatch),iscatch=false;end
                if iscatch
                    idx = randperm(length(this.params.user.catch_symbol));
                    sym = this.params.user.catch_symbol{idx(1)};
                else
                    switch lower(func2str(op))
                        case 'plus',sym='+';
                        case 'minus',sym='-';
                        case 'times',sym='*';
                        case 'rdivide',sym='/';
                        otherwise
                            error('Unknown operator ''%s''',func2str(op));
                    end
                end
            end % END function opfcn2sym
            
            function txt = op2text(op,iscatch)
                if nargin<2||isempty(iscatch),iscatch=false;end
                if iscatch
                    idx = randperm(length(this.params.user.catch_text));
                    txt = this.params.user.catch_text{idx(1)};
                else
                    switch lower(func2str(op))
                        case 'plus',txt='add';
                        case 'minus',txt='subtract';
                        case 'times',txt='multiply';
                        case 'rdivide',txt='divide';
                        otherwise
                            error('Unknown operator ''%s''',func2str(op));
                    end
                end
            end % END function opfcn2text
            
            function txt = op2sound(op,iscatch)
                if nargin<2||isempty(iscatch),iscatch=false;end
                if iscatch
                    idx = randperm(length(this.params.user.catch_audio));
                    txt = this.params.user.catch_audio{idx(1)};
                else
                    switch lower(func2str(op))
                        case 'plus',txt='add';
                        case 'minus',txt='subtract';
                        case 'times',txt='multiply';
                        case 'rdivide',txt='divide';
                        otherwise
                            error('Unknown operator ''%s''',func2str(op));
                    end
                end
            end % END function opfcn2sound
        end % END function TaskStartFcn
        
        function PrefaceStartFcn(this,evt,varargin)
            
            % generate text for subtitle
            numTrials = length(this.TrialParams);
            timeRemaining = util.hms(numTrials*this.hTrial.duration);
            which = cellfun(@(x)strcmpi(class(x),'Task.Common.PrefaceTitle'),this.hStage.phases);
            if any(which)
                assert(nnz(which)==1,'Found multiple matches for Task.Common.PrefaceTitle');
                this.hStage.phases{which}.subtitleString = sprintf('%d trials, %s minutes',numTrials,timeRemaining);
            end
        end % END function PrefaceStartFcn
        
        function TrialStartFcn(this,evt,varargin)
            numTrialsRemaining = length(this.TrialParams) - this.cTrial + 1;
            secondsRemaining = numTrialsRemaining*this.hStage.duration;
            
            % determine coherent or catch parameters
            if strcmpi(this.cTrialParams.nummodality,'char')
                num1 = this.cTrialParams.num1Info.string;
            elseif strcmpi(this.cTrialParams.nummodality,'audio')
                num1 = this.cTrialParams.num1Info.soundname;
            else
                error('unknown nummodality ''%s''',this.cTrialParams.nummodality);
            end
            if strcmpi(this.cTrialParams.nummodality,'char')
                num2 = this.cTrialParams.num2Info.string;
            elseif strcmpi(this.cTrialParams.nummodality,'audio')
                num2 = this.cTrialParams.num2Info.soundname;
            else
                error('unknown nummodality ''%s''',this.cTrialParams.nummodality);
            end
            if strcmpi(this.cTrialParams.cuemodality,'symbol') || strcmpi(this.cTrialParams.cuemodality,'text')
                op = this.cTrialParams.opInfo.string;
            elseif strcmpi(this.cTrialParams.cuemodality,'audio')
                op = this.cTrialParams.opInfo.soundname;
            else
                error('unknown nummodality ''%s''',this.cTrialParams.cuemodality);
            end
            answ = sprintf('%d',this.cTrialParams.answer);
            if ~strcmpi(this.cTrialParams.catch,'none')
                answ = 'c';
            end
            
            % save information to trial data struct
            comment(this,sprintf('trial %d/%d (%s minutes) arith: %s %s %s, response: %s',...
                this.cTrial,length(this.TrialParams),...
                util.hms(secondsRemaining,'mm:ss'),...
                num1,op,num2,answ));
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