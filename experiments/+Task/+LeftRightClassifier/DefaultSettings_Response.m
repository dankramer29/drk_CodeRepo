function DefaultSettings_Response(obj)

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
set(0,'Units','pixels');
sz = get(0,'MonitorPositions');
obj.user.blockPosition = [sz(6)-sz(6) sz(8)-(sz(8)/2)]; % Left side
Left_side = [sz(6)-sz(6) sz(8)-(sz(8)/2)]; % Left side  % obj.user.blockPosition = [50 600]; % Left side
Right_side = [sz(6) sz(8)-(sz(8)/2)]; % Right side % obj.user.blockPosition = [1870 600]; % Right side
obj.user.blockBrightness = 255; % 0-255

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
Pnumber = 'P044';

% title screen
pidx=1;
obj.prefaceDefinitions{pidx} = {@Task.Common.PrefaceTitle,...
    'Name','Title',...
    'titleString','Left/Right Classifier Task - Response',...
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
    'durationTimeout',4};
%obj.phaseDefinitions{5} = {@Task.LeftRightClassifier.PhaseResponse,...
%    'Name','Response',...
%    'durationTimeout',2};

% summary
obj.summaryDefinitions = {};%@Task.Common.PhaseDelayKeypressContinue,...
    %'Name','Delay',...
    %'durationTimeout',Inf};