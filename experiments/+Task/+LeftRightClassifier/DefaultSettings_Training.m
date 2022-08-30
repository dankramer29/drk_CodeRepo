function DefaultSettings_Training(obj)

% get global defaults
args = {};
if ~isempty(obj.hTask.hFramework) && isa(obj.hTask.hFramework,'Framework.Interface') 
    if obj.hTask.hFramework.options.enableSync
        args = [args {'sync'}];
    end
    if obj.hTask.hFramework.options.taskDisplayRefresh
        args = [args {'extrefresh'}];
    end
end
Task.Common.DefaultSettings(obj,args{:});

% font settings
obj.user.fontSize = 250; % font size of the operation string
obj.user.fontFamily = 'Courier'; % font of the operation string
obj.user.fontBrightness = 250;
obj.user.fontColor = [0.5 0.5 0.5]; % color of the operation string

% block settings
obj.user.blockSize = [150 4000]; % width, height
obj.user.blockBrightness = 255; % 0-255

% switch lower(this.cTrialParams.cue_word{wrdID(kk)})
%    case 'left'
%        obj.user.blockPosition = [sz(6)-sz(6) sz(8)-(sz(8)/2)]; % Display block on left side
%    case 'right'
%        obj.user.blockPosition = [sz(6) sz(8)-(sz(8)/2)]; % Display block on right side
%    otherwise
%        error('Unknown word "%s"',user.cue_word{wrdID(kk)});
%end

%{
if strcmpi(this.cTrial.cue_blocks{cngID(kk)},'Left')
    obj.user.blockPosition = [sz(6)-sz(6) sz(8)-(sz(8)/2)]; % Display block on left side
else
    % obj.user.blockPosition = [sz(6) sz(8)-(sz(8)/2)]; % Display block on right side
end
%}

% define block position
obj.user.block_names = {'Left','Right'}; % names of blocks to display
obj.user.block_rgb = {[1 1 1],[1 1 1]}; % position of blocks

% set up conditions to distribute and pairwise equality checks
obj.user.conditionsToDistribute = {'cue_words','cue_blocks','cue_modality','response_modality','cue_congruency'}; % fields that contain values to be distributed
obj.user.allowedEqualIDs = nan(length(obj.user.conditionsToDistribute));

% trial data
obj.trialDataConstructor = @Task.LeftRightClassifier.TrialData;

% keyboard
obj.keys.response = {{},{'y','n','space'}};

% trial params
obj.trialParamsFcn = @Task.LeftRightClassifier.createTrialParams;

% save date
PrintDate = datetime('now')+seconds(5);

% define patient identifier
Pnumber = 'P045';

% title screen
pidx=1;
obj.prefaceDefinitions{pidx} = {@Task.Common.PrefaceTitle,...
    'Name','Title',...
    'titleString','Left/Right Classifier Task - Training',...
    'subtitleString', sprintf('%s - %s',Pnumber, PrintDate),...
    'durationTimeout',Inf};

% phases
obj.phaseDefinitions{1} = {@Task.Common.PhaseITI,...
    'Name','ITI',...
    'drawFixationPoint',false,...
    'durationTimeout',@(x)2+1*rand};
obj.phaseDefinitions{2} = {@Task.LeftRightClassifier.PhaseCue,...
    'Name','Cue',...
    'durationTimeout',1};
obj.phaseDefinitions{3} = {@Task.LeftRightClassifier.PhaseDelay,...
    'Name','Delay',...
    'durationTimeout',@(x)2+1*rand};
obj.phaseDefinitions{4} = {@Task.LeftRightClassifier.PhaseAction,...
    'Name','Action',...
    'drawFixationPoint',true,...
    'durationTimeout',3};

% summary
obj.summaryDefinitions = {};%@Task.Common.PhaseDelayKeypressContinue,...
    %'Name','Delay',...
    %'durationTimeout',Inf};