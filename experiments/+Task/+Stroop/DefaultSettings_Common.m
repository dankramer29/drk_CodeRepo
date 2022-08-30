function DefaultSettings_Common(obj)

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

% color block settings
obj.user.blockSize = [600 300]; % width, height
obj.user.blockPosition = [(obj.user.displayresolution(1)/2)-(obj.user.blockSize(1)/20) (obj.user.displayresolution(2)/2)-(obj.user.blockSize(2)/20)]; % left, bottom
obj.user.blockBrightness = 255; % 0-255

% define colors
obj.user.color_names = {'RED','BLUE','GREEN','PURPLE','BROWN','YELLOW','WHITE','PINK'}; % names of colors to text
obj.user.color_rgb = {[1 0.0 0],[0 0 1],[0 0.5 0],[0.4627 0.1412 0.6196],[0.4196 0.2314 0.0549],[1 1 0],[1 1 1],[1.0000 0.4000 0.6000]}; % rgb values for colors to test

% set up conditions to distribute and pairwise equality checks
obj.user.conditionsToDistribute = {'cue_words','cue_colors','cue_modality','response_modality','cue_congruency'}; % fields that contain values to be distributed
obj.user.allowedEqualIDs = nan(length(obj.user.conditionsToDistribute));

% trial data
obj.trialDataConstructor = @Task.Stroop.TrialData;

% keyboard
obj.keys.response = {{},{'y','n','space'}};

% trial params
obj.trialParamsFcn = @Task.Stroop.createTrialParams;

% save date
PrintDate = datetime('now')+seconds(5);

% define patient identifier
Pnumber = 'P045';

% title screen
pidx=1;
obj.prefaceDefinitions{pidx} = {@Task.Common.PrefaceTitle,...
    'Name','Title',...
    'titleString','Stroop Task',...
    'subtitleString', sprintf('%s - %s',Pnumber, PrintDate),...
    'durationTimeout',Inf};


% phases
obj.phaseDefinitions{1} = {@Task.Common.PhaseITI,...
    'Name','ITI',...
    'drawFixationPoint',false,...
    'durationTimeout',@(x)1.5+1*rand};
obj.phaseDefinitions{2} = {@Task.Stroop.PhaseCue,...
    'Name','Cue',...
    'durationTimeout',Inf};


% summary
obj.summaryDefinitions = {};%@Task.Common.PhaseDelayKeypressContinue,...
    %'Name','Delay',...
    %'durationTimeout',Inf};