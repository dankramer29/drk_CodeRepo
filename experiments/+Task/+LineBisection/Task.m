classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    % LINEBISECTION
    % Spencer Kellis
    % skellis@vis.caltech.edu
    %
    % This task is intended to explore the interaction between spatial
    % estimation and numbers.  The idea is to have the subject gauge
    % whether a marker equally bisects a line made up of characters.  The
    % characters can be digits or numbers spelled out as words end-to-end,
    % or letters without any numerical connotation.  The markers will be
    % slightly offset or equally bisecting.  Will look for a bias in the
    % responses (shifted left or right), based on the numerical value of
    % the characters in the line.
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'Line bisection task';
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
            
            % calculate actual positions of the lines
            for kk=1:length(this.TrialParams)
                
                % set the font size
                this.hDisplayClient.setTextSize(this.TrialParams(kk).symbolSize);
                this.hDisplayClient.setTextFont(this.params.user.fontFamily);
                this.hDisplayClient.setTextStyle('bold');
                
                % construct string of symbols
                str = arrayfun(@(x)this.TrialParams(kk).symbol,1:this.TrialParams(kk).lineLength,'UniformOutput',false);
                if strcmpi(this.TrialParams(kk).lineOrientation,'horizontal')
                    str = strjoin(str,'');
                elseif strcmpi(this.TrialParams(kk).lineOrientation,'vertical')
                    str = strjoin(str,'\n');
                end
                
                % determine pixels of bisector that contribute to the
                % width/height of the string+bisector (one-sided, will
                % assume equal contribution on both sides of the line)
                bisectorPixels = this.params.user.bisectorExtension;
                
                % draw the text once in order to get the actual text bounds
                [~,~,textBounds] = drawText(this.hDisplayClient,str,'center','center',[0 0 0]);
                
                % calculate the width and height of the text
                pxHeight = ceil(textBounds(4)-textBounds(2));
                pxWidth = ceil(textBounds(3)-textBounds(1));
                pxCenterX = textBounds(1) + pxWidth/2;
                pxCenterY = textBounds(2) + pxHeight/2;
                
                % determine maximum offset from the center. offsets range
                % from -1 (max left/up offset) to 1 (max right/down offset)
                if strcmpi(this.TrialParams(kk).lineOrientation,'horizontal')
                    maxHorizontalOffset = this.params.user.displayresolution(1)/2 - pxWidth/2;
                    maxVerticalOffset = this.params.user.displayresolution(2)/2 - pxHeight/2 - 2*bisectorPixels;
                elseif strcmpi(this.TrialParams(kk).lineOrientation,'vertical')
                    maxHorizontalOffset = this.params.user.displayresolution(1)/2 - pxWidth/2 - 2*bisectorPixels;
                    maxVerticalOffset = this.params.user.displayresolution(2)/2 - pxHeight/2;
                end
                
                % calculate the position of the line (text x/y define the
                % left and bottom edges of the text bounding box)
                linePosition = [...
                    pxCenterX - pxWidth/2 + this.TrialParams(kk).linePositionNorm(1)*maxHorizontalOffset;
                    pxCenterY + pxHeight/2 + this.TrialParams(kk).linePositionNorm(2)*maxVerticalOffset];
                
                % calculate the bisector position and extensions on either
                % side of the line
                if strcmpi(this.TrialParams(kk).lineOrientation,'horizontal')
                    symbolWidth = pxWidth / this.TrialParams(kk).lineLength;
                    bisectorPosition = [...
                        linePosition(1) + pxWidth/2 + this.TrialParams(kk).bisectorPositionNorm*symbolWidth; % x-pos
                        linePosition(2) - pxHeight - this.params.user.bisectorExtension; % y-pos (above line)
                        linePosition(2) + this.params.user.bisectorExtension]; % y-pos (below line)
                elseif strcmpi(this.TrialParams(kk).lineOrientation,'vertical')
                    symbolHeight = pxHeight / this.TrialParams(kk).lineLength;
                    bisectorPosition = [...
                        linePosition(2) + pxHeight/2 + this.TrialParams(kk).bisectorPositionNorm*symbolHeight; % y-pos
                        linePosition(1) + pxWidth + this.params.user.bisectorMargin + this.params.user.bisectorSize/2; % x-pos (right of line)
                        linePosition(2) - this.params.user.bisectorExtension]; % x-pos (left of line)
                end
                
                % save the results so we don't have to constantly recalculate
                this.TrialParams(kk).textBounds = textBounds;
                this.TrialParams(kk).string = str;
                this.TrialParams(kk).linePosition = linePosition;
                this.TrialParams(kk).lineDimensions = [pxWidth pxHeight];
                this.TrialParams(kk).bisectorPosition = bisectorPosition;
            end
            
            % set the font family and size
            this.hDisplayClient.setTextSize(this.params.user.fontSize);
            this.hDisplayClient.setTextFont(this.params.user.fontFamily);
            this.hDisplayClient.setTextStyle('normal');
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
            comment(this,sprintf('trial %d/%d (%s minutes) response: %s; sym: %s/%s',...
                this.cTrial,length(this.TrialParams),...
                util.hms(secondsRemaining,'mm:ss'),...
                this.cTrialParams.response,...
                this.cTrialParams.symbol,...
                this.cTrialParams.symbolType));
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