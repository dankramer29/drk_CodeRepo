env.set('Data', 'D:\1_Year\Neuro_SP\Task Recording\Data'); %consider setting the default for this PC to this location
taskObj =  FrameworkTask('D:\1_Year\Neuro_SP\Task Recording\Data\P010\20170830\Task\20170830-133354-133456-DelayedReach.mat');
ns = taskObj.getNeuralDataObject('AllGrids', 'ns3');
ns = ns{1};

%%

TotalChanArray = [1:10 17:26 33:42 49:58 65:74 81:90 97:104 113:120]; % all channels recording neural data
TaskString = string(regexp(taskObj.taskString, '\d*-(.*)', 'tokens'));

%gridMapObj = GridMap('D:\1_Year\Neuro_SP\Task Recording\Data\P010\20170830\AllGrids\P010_map.csv');

Targets = arrayfun(@(x)x.tr_prm.targetID,taskObj.trialdata)';


DtClass = 'single';
%%

StartTimes = taskObj.trialTimes;


[NeuralData, RelativeTimes, FeatureDef] = proc.blackrock.broadband(...
    ns, 'PROCWIN', StartTimes, DtClass, 'CHANNELS', TotalChanArray,...
    'Uniformoutput', true);

%% Make Spectrograms
%Initialize Chronux Parameters
MovingWin     = [0.5 0.05]; %[WindowSize StepSize]
Tapers        = [5 9]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass         = [0 200]; %frequency range of the output data
TrialAve      = 0; %Average later
Fs            = ns.Fs;
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
gpuflag       = true;

% [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(NeuralData,1), MovingWin, DtClass);
[PowerArray, FreqBins, TimeBins] = Analysis.DelayedReach.LFP.multiSpec(NeuralData, 'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass, 'gpuflag', gpuflag);

