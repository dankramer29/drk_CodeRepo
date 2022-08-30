function DefaultSettings(obj)

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

% enable stimulation
obj.useStimulation = true;
obj.stimConfig = @(x)x;
if strcmpi(env.get('type'),'PRODUCTION')
    obj.stimConstructor = @Experiment2.Stim.BlackrockStimulator;
else
    obj.stimConstructor = @Experiment2.Stim.FakeStimulator;
end
   
% shape settings
obj.user.shapeSize = 100;
obj.user.shapeColor = 255*[1 0 0];
obj.keys.response = {{},{'space'}};
% font settings
obj.user.fontSize = 250; % font size of the operation string
obj.user.fontFamily = 'Courier'; % font of the operation string
obj.user.fontBrightness = 250;
obj.user.fontColor = [0.5 0.5 0.5]; % color of the operation string
% trial data
obj.trialDataConstructor = @Task.StimParameterSweep.TrialData;

% limiting measures
% limits for a) interphase delay = 100 microsecond
% b)amplitude = 10000 microAmpere
% c)pulsewidth = 1000 micro second
% d)frequency = 333 Hz
% e)duration = 5 seconds
% f)charge density = 10 microColumb/cm2/phase
% g)charge per phase = 10 microColumb/phase
% f) charge rate = 6.66 milliColumb/s
% control number of trials (one entry for each balance-condition option)
limits = [100 10000 1000 333 5 10 10 6.67]; 
obj.trialParamsFcn{1} = @Task.StimParameterSweep.createTrialParams;
obj.trialParamsFcn{2} = limits;
if strcmpi(env.get('type'),'PRODUCTION')
    obj.trialParamsFcn{3} = obj.hTask.hFramework.hNeuralSource.hGridMap{1,1};
else
    obj.trialParamsFcn{3} = [];
end
obj.trialParamsFcn{4} = obj.parameterFcn(find(obj.parameterFcn == '_',1,'last')+1:end);
% save date
PrintDate = datetime('now')+seconds(5);

% define patient identifier
Pnumber = 'P045';

% title screen
pidx=1;
obj.prefaceDefinitions{pidx} = {@Task.Common.PrefaceTitle,...
    'Name','Title',...
    'titleString','Stim Parameter Sweep Task',...
    'subtitleString', sprintf('%s - %s',Pnumber, PrintDate),...
    'durationTimeout',1000};

% countdown
pidx=pidx+1;
obj.prefaceDefinitions{pidx} = {@Task.Common.PrefaceCountdown,...
    'Name','Countdown',...
    'countdownStartValue',3,...
    'countdownInterval',1.5,...
    'durationTimeout',1000};

% phases
obj.phaseDefinitions{1} = {@Task.StimParameterSweep.PhaseITI,...
    'Name','ITI',...
    'drawFixationPoint',false,...
    'durationTimeout',Inf};
% obj.phaseDefinitions{2} = {@Task.StimParameterSweep.PhaseCheckpoint,...
%     'Name','Checkpoint',...
%     'durationTimeout',Inf};
% obj.phaseDefinitions{3} = {@Task.StimParameterSweep.PhaseCue,...
%     'Name','Cue',...
%     'durationTimeout',1.0};
obj.phaseDefinitions{2} = {@Task.StimParameterSweep.PhaseStimulate,...
    'Name','Stimulate',...
    'durationTimeout',1.0};
% obj.phaseDefinitions{4} = {@Task.StimParameterSweep.PhaseRespond,...
%     'Name','Respond',...
%     'durationTimeout',Inf};

% summary
obj.summaryDefinitions{1} = {@Task.Common.SummaryScore,...
    'Name','Score',...
    'durationTimeout',1000};
obj.summaryDefinitions{2} = {@Task.Common.SummaryReward,...
    'Name','Reward',...
    'durationTimeout',1000};