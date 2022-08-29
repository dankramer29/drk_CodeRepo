function DefaultSettings(obj)
% Parameters files must set the following properties:
% numberDisplay - set of numbers to display
% numberGroup - set of numbers to determine how many appear on the screen
% catchTrialFraction - add additional trials where numbers are scrambled
% balance - how to balance the trials
%    'all' - (numTrialsPerBalanceCondition) instances of each combination of (numberDisplay) and (numberGroup)
%    'display' - (numTrialsPerBalanceCondition) instances of (numberDisplay); random permutation of (numberGroup).
%    'group' - (numTrialsPerBalanceCondition) instances of (numberGroup); random permutation of (numberDisplay).
% numTrialsPerBalanceCondition - number of trials for each balance condition

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

% trial data
obj.trialDataConstructor = @Task.NumberGroups.TrialData;

% keyboard
obj.keys.response = {{},{'LeftArrow','RightArrow'}};

% trial params
obj.trialParamsFcn = @Task.NumberGroups.createTrialParams;

% title screen
pidx=1;
obj.prefaceDefinitions{pidx} = {@Task.Common.PrefaceTitle,...
    'Name','Title',...
    'titleString','Number Groups',...
    'durationTimeout',1000};

% countdown
pidx=pidx+1;
obj.prefaceDefinitions{pidx} = {@Task.Common.PrefaceCountdown,...
    'Name','Countdown',...
    'countdownStartValue',3,...
    'countdownInterval',1.5,...
    'durationTimeout',1000};

% phases
obj.phaseDefinitions{1} = {@Task.Common.PhaseITI,...
    'Name','ITI',...
    'drawFixationPoint',true,...
    'durationTimeout',2.0};
obj.phaseDefinitions{2} = {@Task.NumberGroups.PhaseShowGroupRespond,...
    'Name','ShowGroupRespond',...
    'durationTimeout',1000.0};

% summary
obj.summaryDefinitions{1} = {@Task.Common.PhaseDelayKeypressContinue,...
    'Name','Delay',...
    'durationTimeout',1000};
obj.summaryDefinitions{2} = {@Task.Common.SummaryScore,...
    'Name','Score',...
    'durationTimeout',1000};
obj.summaryDefinitions{3} = {@Task.Common.SummaryReward,...
    'Name','Reward',...
    'durationTimeout',1000};