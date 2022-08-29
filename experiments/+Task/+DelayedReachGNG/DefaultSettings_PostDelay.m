function DefaultSettings_PostDelay(obj)
%called in DelayedReachGNG.Parameters (54)
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

% disable sound
obj.useSound = false;

% trial data
obj.trialDataConstructor = @Task.DelayedReachGNG.TrialData;

% trial params
obj.trialParamsFcn = @Task.DelayedReachGNG.createTrialParams;

% save date
PrintDate = datetime('now')+seconds(5);

% define patient identifier
Pnumber = 'P045';

% title screen
pidx=1;
obj.prefaceDefinitions{pidx} = {@Task.Common.PrefaceTitle,...
    'Name','Title',...
    'titleString','Delayed Reach Go-No-Go Task',...
    'subtitleString', sprintf('%s - %s',Pnumber, PrintDate),...
    'durationTimeout',Inf};

% % countdown
% pidx=pidx+1;
% obj.prefaceDefinitions{pidx} = {@Task.Common.PrefaceCountdown,...
%     'Name','Countdown',...
%     'countdownStartValue',3,...
%     'countdownInterval',1.5,...
%     'durationTimeout',Inf};

% phases
obj.phaseDefinitions{1} = {@Task.Common.PhaseITI,...
    'Name','ITI',... 
    'drawFixationPoint',false,...
    'durationTimeout',@(x)1};
obj.phaseDefinitions{2} = {@Task.DelayedReachGNG.PhaseFixate,...
    'Name', 'Fixate',...
    'drawFixationPoint',true,...
    'durationTimeout',@(x)2+2*rand};
obj.phaseDefinitions{3} = {@Task.DelayedReachGNG.PhaseCue,...
    'Name','Cue',...
    'durationTimeout',1.0};
obj.phaseDefinitions{4} = {@Task.DelayedReachGNG.PhaseDelay,...
    'Name','Delay',...
    'drawFixationPoint',true,...
    'durationTimeout',@(x)2+2*rand};
obj.phaseDefinitions{5} = {@Task.DelayedReachGNG.PhaseRespondGNG,...
    'Name','RespondGNG',...
    'durationTimeout',4.0};

% summary
% obj.summaryDefinitions{1} = {@Task.Common.SummaryScore,...
%     'Name','Score',...
%     'durationTimeout',1000};
% obj.summaryDefinitions{2} = {@Task.Common.SummaryReward,...
%     'Name','Reward',...
%     'durationTimeout',1000};