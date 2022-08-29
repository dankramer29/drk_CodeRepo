classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    % SPATIALATTENTIONARITHMETIC
    % Spencer Kellis
    % skellis@vis.caltech.edu
    %
    % This task is intended to explore the association between arithmetic
    % and spatial attention.  The idea is that addition biases attention
    % toward the right, and subtraction biases attention toward the left.
    % Under this premise, responses times should be slower when the correct
    % answer is on the opposite side.
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'Spatial attention arithmetic task';
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
            
            % calculate actual positions of the answers
            res = this.params.user.displayresolution;
            for kk=1:length(this.TrialParams)
                
                % construct the operation string and determine its position
                this.hDisplayClient.setTextFont(this.params.user.operationFontFamily);
                this.hDisplayClient.setTextSize(this.params.user.operationFontSize);
                this.hDisplayClient.setTextStyle('normal');
                str = sprintf('%d %s %d',this.TrialParams(kk).number1,this.opfcn2sym(this.TrialParams(kk).operator),this.TrialParams(kk).number2);
                [~,~,bounds] = drawText(this.hDisplayClient,str,'center','center',[0 0 0]);
                tw = ceil(bounds(3)-bounds(1));
                th = ceil(bounds(4)-bounds(2));
                strPos = [res(1)/2-tw/2; res(2)/2+th/2];
                this.TrialParams(kk).operationString = str;
                this.TrialParams(kk).operationPosition = strPos; 
                this.TrialParams(kk).operationBounds = bounds;
                
                % loop over quadrants to compute the position for each
                this.TrialParams(kk).quadrantPosition = cell(1,length(this.params.user.quadrants));
                for nn=1:length(this.params.user.quadrants)
                    
                    % calculate size of the answer/distractor
                    this.hDisplayClient.setTextSize(this.TrialParams(kk).fontsize(nn));
                    if strcmpi(this.TrialParams(kk).quadrant,this.params.user.quadrants{nn}) % answer quadrant
                        [~,~,bounds] = drawText(this.hDisplayClient,num2str(this.TrialParams(kk).answer),'center','center',[0 0 0]);
                    elseif ~strcmpi(this.TrialParams(kk).quadrant,this.params.user.quadrants{nn}) % distractor quadrant
                        [~,~,bounds] = drawText(this.hDisplayClient,num2str(this.TrialParams(kk).distractor),'center','center',[0 0 0]);
                    end
                    symbolHeight = ceil(bounds(4)-bounds(2));
                    symbolWidth = ceil(bounds(3)-bounds(1));
                    
                    % determine the bounding box of the quadrant
                    % bounding boxes in PTB-style: [left top right bottom]
                    % with origin at top-left of screen
                    switch lower(this.params.user.quadrants{nn})
                        case 'left'
                            area = [this.params.user.quadrantMargin/2 % left
                                this.params.user.quadrantMargin/2 % top
                                res(1)/2-this.params.user.quadrantMargin/2 % right
                                res(2)-this.params.user.quadrantMargin/2]; % bottom
                        case 'right'
                            area = [res(1)/2+this.params.user.quadrantMargin/2 % left
                                this.params.user.quadrantMargin/2
                                res(1)-this.params.user.quadrantMargin/2
                                res(2)-this.params.user.quadrantMargin/2];
                        case 'top'
                            area = [this.params.user.quadrantMargin/2
                                this.params.user.quadrantMargin/2
                                res(1)-this.params.user.quadrantMargin/2
                                res(2)/2-this.params.user.quadrantMargin/2];
                        case 'bottom'
                            area = [this.params.user.quadrantMargin/2
                                res(2)/2+this.params.user.quadrantMargin/2
                                res(1)-this.params.user.quadrantMargin/2
                                res(2)-this.params.user.quadrantMargin/2];
                        otherwise
                            error('Unknown quadrant ''%s''',this.params.user.quadrants{nn});
                    end
                    
                    % calculate where the center of the number should be
                    % coordinates in PTB-style: origin at top-left
                    switch lower(this.TrialParams(kk).justify{nn})
                        case 'left'
                            posX = area(1) + symbolWidth/2;
                            posY = area(2) + (area(4)-area(2))/2;
                        case 'right'
                            posX = area(3) - symbolWidth/2;
                            posY = area(2) + (area(4)-area(2))/2;
                        case 'top'
                            posX = area(1) + (area(3)-area(1))/2;
                            posY = area(2) + symbolHeight/2;
                        case 'bottom'
                            posX = area(1) + (area(3)-area(1))/2;
                            posY = area(4) - symbolHeight/2;
                        case 'middle'
                            posX = area(1) + (area(3)-area(1))/2;
                            posY = area(2) + (area(4)-area(2))/2;
                    end
                    
                    % save the position
                    this.TrialParams(kk).quadrantPosition{nn} = [posX posY];
                end
                
                % construct the answer string and determine its position
                idx = strcmpi(this.params.user.quadrants,this.TrialParams(kk).quadrant);
                assert(any(idx),'Could not identify answer quadrant');
                str = sprintf('%d',this.TrialParams(kk).answer);
                pos = this.TrialParams(kk).quadrantPosition{idx};
                this.hDisplayClient.setTextSize(this.TrialParams(kk).fontsize(idx));
                [~,~,bounds] = drawText(this.hDisplayClient,str,pos(1),pos(2),[0 0 0]);
                tw = ceil(bounds(3)-bounds(1));
                th = ceil(bounds(4)-bounds(2));
                pos = [pos(1)-tw/2; pos(2)+th/2];
                this.TrialParams(kk).answerFontSize = this.TrialParams(kk).fontsize(idx);
                this.TrialParams(kk).answerString = str;
                this.TrialParams(kk).answerPosition = pos;
                this.TrialParams(kk).answerBounds = bounds;
                
                % construct the distractor string and determine its position
                idx = ~idx;
                assert(any(idx),'Could not identify distractor quadrant');
                str = sprintf('%d',this.TrialParams(kk).distractor);
                pos = this.TrialParams(kk).quadrantPosition{idx};
                this.hDisplayClient.setTextSize(this.TrialParams(kk).fontsize(idx));
                [~,~,bounds] = drawText(this.hDisplayClient,str,pos(1),pos(2),[0 0 0]);
                tw = ceil(bounds(3)-bounds(1));
                th = ceil(bounds(4)-bounds(2));
                pos = [pos(1)-tw/2; pos(2)+th/2];
                this.TrialParams(kk).distractorFontSize = this.TrialParams(kk).fontsize(idx);
                this.TrialParams(kk).distractorString = str;
                this.TrialParams(kk).distractorPosition = pos;
                this.TrialParams(kk).distractorBounds = bounds;
            end
            
            % set the font family and size
            this.hDisplayClient.setTextSize(this.params.user.operationFontSize);
            this.hDisplayClient.setTextFont(this.params.user.operationFontFamily);
            this.hDisplayClient.setTextStyle('normal');
        end % END function TaskStartFcn
        
        function PrefaceStartFcn(this,evt,varargin)
            
            % create trial params just for the preface
            tp = feval(this.params.trialParamsFcn{1},this.params.user,this.params.trialParamsFcn{2:end});
            this.cTrialParams = tp;
            
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
            
            % save information to trial data struct
            comment(this,sprintf('trial %d/%d (%s minutes) arith: %s = %d, distractor: %d, response: %s',...
                this.cTrial,length(this.TrialParams),...
                util.hms(secondsRemaining,'mm:ss'),...
                this.cTrialParams.operationString,this.cTrialParams.answer,...
                this.cTrialParams.distractor,...
                this.cTrialParams.response));
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
        
        function sym = opfcn2sym(this,op)
            switch lower(func2str(op))
                case 'plus',sym='+';
                case 'minus',sym='-';
                case 'times',sym='*';
                case 'rdivide',sym='/';
                otherwise
                    error('Unknown operator ''%s''',func2str(op));
            end
        end % END function opfcn2sym
        
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



% % HOW TO DETERMINE NUMBER OF SYMBOLS BASED ON PIXEL SIZE OF LINE
% % bounding boxes for single and two symbols
% normBoundsRect_1sym = Screen('TextBounds',this.hDisplayClient.win,this.TrialParams(kk).symbol);
% normBoundsRect_2sym = Screen('TextBounds',this.hDisplayClient.win,sprintf('%s%s',this.TrialParams(kk).symbol,this.TrialParams(kk).symbol));
% 
% % calculate width of first (no space/separation)
% width_firstSym = normBoundsRect_1sym(3) - normBoundsRect_1sym(1);
% 
% % calculate width of two (two symbols with separation)
% width_2sym = normBoundsRect_2sym(3) - normBoundsRect_2sym(1);
% width_perAdditionalSym = width_2sym - width_firstSym;
% 
% % count how many will fit
% numSymbols = 1 + floor((this.TrialParams(kk).lineLength - width_firstSym)/width_perAdditionalSym);
% assert(numSymbols>0,'Problem counting number of symbols in the line');
% 
% % generate the strong
% str = arrayfun(@(x)this.TrialParams(kk).symbol,1:numSymbols,'UniformOutput',false);
% str = strjoin(str,'');