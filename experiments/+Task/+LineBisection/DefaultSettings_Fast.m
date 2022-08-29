function DefaultSettings_Fast(obj)

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

% shape settings
obj.user.shapeSize = 100;
obj.user.shapeColor = 255*[1 0 0];

% trial data
obj.trialDataConstructor = @Task.LineBisection.TrialData_Fast;

% keyboard
obj.keys.symbol = {{},obj.user.symbols};
obj.keys.bisector = {{},{'LeftArrow','UpArrow','DownArrow','RightArrow'}};

% trial params
obj.trialParamsFcn = @Task.LineBisection.createTrialParams;

% title screen
pidx=1;
obj.prefaceDefinitions{pidx} = {@Task.Common.PrefaceTitle,...
    'Name','Title',...
    'titleString','Line Bisection Task',...
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
    'drawFixationPoint',false,...
    'durationTimeout',0.5};
obj.phaseDefinitions{2} = {@Task.LineBisection.PhaseShowBisector,...
    'Name','ShowBisector',...
    'durationTimeout',1000.0};

% summary
obj.summaryDefinitions{1} = {@Task.Common.SummaryScore,...
    'Name','Score',...
    'durationTimeout',1000};
obj.summaryDefinitions{2} = {@Task.Common.SummaryReward,...
    'Name','Reward',...
    'durationTimeout',1000};