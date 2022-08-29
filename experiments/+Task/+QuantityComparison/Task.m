classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    % QUANTITYCOMPARISON
    % Spencer Kellis
    % skellis@vis.caltech.edu
    %
    % This task is intended to explore the representation of quantities
    % such as numerical magnitude, size of shapes, number of symbols,
    % brightness of an object, etc.  Under the hypothesis that comparison
    % evokes spatial attention, the subject will be cued to a specific
    % comparison, e.g. 'greater-than'.  Then, the correct answer will be
    % displayed in different quadrants of the screen.  Reaction times
    % should be faster if the answer is in the quadrant associated with the
    % spatial bias.
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'Quantity comparison task';
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
            
            % calculate actual positions of the symbols
            res = this.params.user.displayresolution;
            for kk=1:length(this.TrialParams)
                
                % construct the prompt string and determine its position
                this.hDisplayClient.setTextSize(this.params.user.promptFontSize);
                this.hDisplayClient.setTextFont(this.params.user.promptFontFamily);
                this.hDisplayClient.setTextStyle('normal');
                str = this.promptfn2string(this.TrialParams(kk).prompt,this.TrialParams(kk).quantity);
                [~,~,bounds] = drawText(this.hDisplayClient,str,'center','center',[0 0 0]);
                tw = ceil(bounds(3)-bounds(1));
                th = ceil(bounds(4)-bounds(2));
                pos = [res(1)/2-tw/2; res(2)/2-th/2];
                this.TrialParams(kk).promptString = str;
                this.TrialParams(kk).promptPosition = round(pos);
                this.TrialParams(kk).promptFontFamily = this.params.user.promptFontFamily;
                this.TrialParams(kk).promptFontSize = this.params.user.promptFontSize;
                this.TrialParams(kk).promptFontColor = this.params.user.promptFontColor;
                this.TrialParams(kk).promptFontBrightness = this.params.user.promptFontBrightness;
                
                % loop over quadrants to compute the position for each
                this.TrialParams(kk).quadrantPosition = cell(1,length(this.params.user.quadrant));
                for nn=1:length(this.params.user.quadrant)
                    
                    % determine the bounding box of the quadrant
                    % bounding boxes in PTB-style: [left top right bottom]
                    % with origin at top-left of screen
                    switch lower(this.params.user.quadrant{nn})
                        case 'left'
                            area = [this.params.user.quadrantMargin/2 % left
                                this.params.user.quadrantMargin/2 % top
                                res(1)/2-this.params.user.quadrantMargin/2 % right
                                res(2)-this.params.user.quadrantMargin/2]; % bottom
                        case 'right'
                            area = [res(1)/2+this.params.user.quadrantMargin/2 % left
                                this.params.user.quadrantMargin/2 % top
                                res(1)-this.params.user.quadrantMargin/2 % right
                                res(2)-this.params.user.quadrantMargin/2]; % bottom
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
                            error('Unknown quadrant ''%s''',this.params.user.quadrant{nn});
                    end
                    
                    % calculate size of the symbol for this quadrant
                    switch this.TrialParams(kk).symbol
                        case {'char','text'}
                            
                            % defaults
                            params.fontFamily = this.params.user.symbolFontFamily;
                            params.fontSize = this.params.user.symbolFontSize;
                            params.fontColor = this.params.user.symbolFontColor;
                            params.fontBrightness = this.params.user.symbolFontBrightness;
                            number = randi(10,1)-1;
                            params.string = num2str(number);
                            
                            % update defaults to measured quantity
                            if strcmpi(this.TrialParams(kk).answerQuadrant,this.params.user.quadrant{nn}) % answer quadrant
                                switch this.TrialParams(kk).quantity
                                    case 'magnitude'
                                        params.string = num2str(this.TrialParams(kk).answerValue);
                                    case 'size'
                                        params.fontSize = this.TrialParams(kk).answerValue;
                                    case 'brightness'
                                        params.fontBrightness = this.TrialParams(kk).answerValue;
                                    otherwise
                                        error('Unknown quantity ''%s''',this.TrialParams(kk).quantity);
                                end
                            elseif strcmpi(this.TrialParams(kk).distractorQuadrant,this.params.user.quadrant{nn}) % distractor quadrant
                                switch this.TrialParams(kk).quantity
                                    case 'magnitude'
                                        params.string = num2str(this.TrialParams(kk).distractorValue);
                                    case 'size'
                                        params.fontSize = this.TrialParams(kk).distractorValue;
                                    case 'brightness'
                                        params.fontBrightness = this.TrialParams(kk).distractorValue;
                                    otherwise
                                        error('Unknown quantity ''%s''',this.TrialParams(kk).quantity);
                                end
                            end
                            
                            % calculate text height/width
                            this.hDisplayClient.setTextSize(params.fontSize);
                            [~,~,bounds] = drawText(this.hDisplayClient,params.string,'center','center',[0 0 0]);
                            symbolHeight = ceil(bounds(4)-bounds(2));
                            symbolWidth = ceil(bounds(3)-bounds(1));
                            
                            % calculate where the center of the number should be
                            % coordinates in PTB-style: origin at top-left
                            switch lower(this.TrialParams(kk).justify{nn})
                                case 'left'
                                    posX = area(1) + symbolWidth/2;
                                    posY = area(2) + (area(4)-area(2))/2 - symbolHeight/2;
                                case 'right'
                                    posX = area(3) - symbolWidth/2;
                                    posY = area(2) + (area(4)-area(2))/2 - symbolHeight/2;
                                case 'top'
                                    posX = area(1) + (area(3)-area(1))/2 - symbolWidth/2;
                                    posY = area(2) + symbolHeight/2;
                                case 'bottom'
                                    posX = area(1) + (area(3)-area(1))/2 - symbolWidth/2;
                                    posY = area(4) - symbolHeight/2;
                                case 'middle'
                                    posX = area(1) + (area(3)-area(1))/2 - symbolWidth/2;
                                    posY = area(2) + (area(4)-area(2))/2 - symbolHeight/2;
                            end
                            params.position = round([posX posY]);
                        case 'shape'
                            
                            % defaults
                            params.type = this.params.user.symbolShapeType;
                            params.size = this.params.user.symbolShapeSize;
                            params.color = this.params.user.symbolShapeColor;
                            params.brightness = this.params.user.symbolShapeBrightness;
                            %params.other = this.params.user.symbolOtherArguments;
                            
                            % update defaults to measured quantity
                            if strcmpi(this.TrialParams(kk).answerQuadrant,this.params.user.quadrant{nn}) % answer quadrant
                                switch this.TrialParams(kk).quantity
                                    case 'size'
                                        params.size = this.TrialParams(kk).answerValue;
                                    case 'brightness'
                                        params.brightness = this.TrialParams(kk).answerValue;
                                    otherwise
                                        error('Unknown quantity ''%s''',this.TrialParams(kk).quantity);
                                end
                            elseif strcmpi(this.TrialParams(kk).distractorQuadrant,this.params.user.quadrant{nn}) % distractor quadrant
                                switch this.TrialParams(kk).quantity
                                    case 'size'
                                        params.size = this.TrialParams(kk).distractorValue;
                                    case 'brightness'
                                        params.brightness = this.TrialParams(kk).distractorValue;
                                    otherwise
                                        error('Unknown quantity ''%s''',this.TrialParams(kk).quantity);
                                end
                            end
                            
                            % calculate where the center of the number should be
                            % coordinates in PTB-style: origin at top-left
                            switch lower(this.TrialParams(kk).justify{nn})
                                case 'left'
                                    posX = area(1);
                                    posY = area(2) + (area(4)-area(2))/2;
                                case 'right'
                                    posX = area(3);
                                    posY = area(2) + (area(4)-area(2))/2;
                                case 'top'
                                    posX = area(1) + (area(3)-area(1))/2;
                                    posY = area(2);
                                case 'bottom'
                                    posX = area(1) + (area(3)-area(1))/2;
                                    posY = area(4);
                                case 'middle'
                                    posX = area(1) + (area(3)-area(1))/2;
                                    posY = area(2) + (area(4)-area(2))/2;
                            end
                            params.position = round([posX posY]);
                    end
                    
                    % save the parameters
                    if strcmpi(this.TrialParams(kk).answerQuadrant,this.params.user.quadrant{nn}) % answer quadrant
                        this.TrialParams(kk).answerParams = params;
                    elseif strcmpi(this.TrialParams(kk).distractorQuadrant,this.params.user.quadrant{nn})
                        this.TrialParams(kk).distractorParams = params;
                    end
                end
            end
            
            % set the font family and size
            this.hDisplayClient.setTextSize(this.params.user.promptFontSize);
            this.hDisplayClient.setTextFont(this.params.user.promptFontFamily);
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
            comment(this,sprintf('trial %d/%d (%s minutes) response: %s',...
                this.cTrial,length(this.TrialParams),...
                util.hms(secondsRemaining,'mm:ss'),...
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
        
        function drawSymbol(this,symbol,params)
            switch lower(symbol)
                case {'char','text'}
                    this.hDisplayClient.setTextFont(params.fontFamily);
                    this.hDisplayClient.setTextSize(params.fontSize);
                    drawText(this.hDisplayClient,...
                        params.string,...
                        params.position(1),...
                        params.position(2),...
                        params.fontBrightness*params.fontColor);
                case 'shape'
                    drawShapes(this.hDisplayClient,...
                        round(params.position),...
                        params.size,...
                        params.brightness*params.color,...
                        params.type);%,...
                        %params.other{:});
            end
        end % END function drawSymbol
        
        function str = promptfn2string(this,prompt,quantity)
            switch lower(func2str(prompt))
                case 'gt'
                    switch lower(quantity)
                        case 'magnitude'
                            str = 'Larger Value';
                        case 'size'
                            str = 'Larger Size';
                        case 'quantity'
                            str = 'More Symbols';
                        case 'brightness'
                            str = 'Brighter';
                        otherwise
                            error('Unknown quantity ''%s''',quantity);
                    end
                case 'lt'
                    switch lower(quantity)
                        case 'magnitude'
                            str = 'Smaller Value';
                        case 'size'
                            str = 'Smaller Size';
                        case 'quantity'
                            str = 'Fewer Symbols';
                        case 'brightness'
                            str = 'Darker';
                        otherwise
                            error('Unknown quantity ''%s''',quantity);
                    end
                case 'eq'
                    switch lower(quantity)
                        case 'magnitude'
                            str = 'Same Value';
                        case 'size'
                            str = 'Same Size';
                        case 'quantity'
                            str = 'Same Amount';
                        case 'brightness'
                            str = 'Same Brightness';
                        otherwise
                            error('Unknown quantity ''%s''',quantity);
                    end
                otherwise
                    error('Unknown operator ''%s''',func2str(prompt));
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



% % DETERMINING NUMBER OF SYMBOLS BASED ON PIXEL SIZE OF LINE
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