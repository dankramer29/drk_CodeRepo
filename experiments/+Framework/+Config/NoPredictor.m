function NoPredictor(fw,varargin)

fw.output = env.get('output');%'D:\';

% look for task name
taskName = '';
for kk=1:length(varargin)
    nm = sprintf('Task.%s.Task',varargin{kk});
    if util.existp(nm,'class')==8
        taskName = varargin{kk};
        varargin(kk) = [];
        break;
    end
end
assert(~isempty(taskName),'Must provide a valid task name');

% look for parameter file
parameterName = '';
for kk=1:length(varargin)
    if ~isempty(strfind(varargin{kk},'Parameter'))
        pm = varargin{kk};
    else
        pm = sprintf('Parameters_%s',varargin{kk});
    end
    if util.existp(sprintf('Task.%s.%s',taskName,pm),'file')==2
        parameterName = pm;
        varargin(kk) = [];
        break;
    end
end
if isempty(parameterName)
    fullpath = which(sprintf('Task.%s.Task',taskName));
    taskpath = fileparts(fullpath);
    parameterFiles = dir(fullfile(taskpath,'Parameter*.m'));
    assert(~isempty(parameterFiles),'No parameter files found for task ''%s''',taskName);
    if length(parameterFiles)==1
        num = 1;
    else
        for kk=1:length(parameterFiles)
            fprintf('%2d.\t%s\n',kk,parameterFiles(kk).name);
        end
        num = input('Enter the number of a parameter file >> ');
        assert(isnumeric(num),'Invalid selection');
    end
    [~,parameterName] = fileparts(parameterFiles(num).name);
end
assert(~isempty(parameterName),'Could not find a valid parameters file for task ''%s''',taskName);
assert(isempty(varargin),'Unknown inputs');

% run fast to avoid issues with asynchronous timing
fw.timerPeriod          = 0.05;
fw.timerTimerFcn        = @timerFcn_lean;
fw.headless             = true;

% internal parameters
fw.enablePredictor      = false;
fw.runName              = taskName;

% GUIs
fw.guiConstructor       = {@Framework.GUI.Default};
fw.guiConfig            = {[]};

% Task
fw.taskConstructor      = str2func(sprintf('Task.%s.Task',taskName));
fw.taskConfig           = str2func(sprintf('Task.%s.%s',taskName,parameterName));
fw.taskDisplayRefresh   = true;

% Sync
fw.enableSync           = false; % remember to change this in task also
fw.syncConstructor      = @Framework.Sync.ExternalControl;
fw.syncConfig           = @(x)x;

% Video
fw.enableVideo          = false;
if strcmpi(fw.type,'PRODUCTION')
    fw.videoConstructor = @Framework.Video.RemoteWebcam;
    fw.videoConfig = @Video.Config.Rancho;
elseif strcmpi(fw.type,'DEVELOPMENT')
    fw.videoConstructor     = @Framework.Video.Dummy;
    fw.videoConfig          = @(x)x;
end

% Neural parameters
if strcmpi(fw.type,'PRODUCTION')
    fw.neuralConstructor    = @Framework.NeuralSource.Blackrock;
    fw.neuralConfig         = {@Framework.NeuralSource.Config.Keck,'record','lfp','gridmap',{'Z:\archive\keck\P045\20200212-PH2\20200218\gridmap.p045Stim.map'}};
elseif strcmpi(fw.type,'DEVELOPMENT')
    fw.neuralConstructor    = @Framework.NeuralSource.Rand;
    fw.neuralConfig         = {@Framework.NeuralSource.Config.RandData};
end