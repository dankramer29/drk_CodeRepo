function Endpoint2D(fw,varargin)
taskName = 'CenterOut';
if ~isempty(varargin),taskName=varargin{1};end

% Taken from Framework.Config.NoPredictor
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

% internal parameters
fw.runName              = taskName;

% define DOFs
fw.nVarsPerDOF          = [2 2];

% GUIs
fw.guiConstructor       = {@Framework.GUI.Default};%,@Framework.GUI.DataBrowser};
fw.guiConfig            = {[]};%,[]};

% Predictors
fw.predictorConstructor = @Framework.Predictor.Decoder;
fw.predictorConfig      = @Predictor.DecoderConfig.Keck;

% Task
fw.taskConstructor      = str2func(sprintf('@Task.%s.Task',taskName));
fw.taskConfig           = str2func(sprintf('Task.%s.%s',taskName,parameterName));
fw.taskDisplayRefresh   = true;

% Sync
fw.enableSync           = true; % remember to change this in task also
fw.syncConstructor      = @Framework.Sync.ExternalControl;
fw.syncConfig           = @(x)x;

% Eye Tracker
fw.enableEyeTracker     = false;
fw.eyeConstructor       = @Framework.EyeTracker.PupilNetwork; %MJ - change this line to be PupilNetwork to incorporate
fw.eyeConfig            = @Framework.EyeTracker.Config.Rancho;

% Video
fw.videoConstructor     = @Framework.Video.Dummy;
fw.videoConfig          = @(x)x;

% Neural parameters
if strcmpi(fw.type,'PRODUCTION')
    fw.neuralConstructor    = @Framework.NeuralSource.Blackrock;
    fw.neuralConfig         = {@Framework.NeuralSource.Config.Keck,'record','lfp','spike','gridmap',{'C:\Users\BLX\Desktop\gridmap.map'}};
elseif strcmpi(fw.type,'DEVELOPMENT')
    fw.neuralConstructor    = @Framework.NeuralSource.Rand;
    fw.neuralConfig         = {@Framework.NeuralSource.Config.RandData};
end
