% spectrogram script

%% inputs to change CHANGE pwr, relt, f, featdef accordingly
TimesToAnalyze = LProcWin;
DebugName = 'LSpectrogram';
%ChanArray = [1:10 17:26 33:42 49:58 65:74 81:90 97:104 113:120];  doesnt work: 'channels',ChanArray
RemoveChannels = [11:16 27:32 43:48 59:64 75:80 91:96 105:112 121:128];
UniformOutput = true;
%% if nothing has been initialized yet

% taskObj = FrameworkTask('C:\Users\Mike\Documents\Data\P010\20170830\Task\20170830-133354-133456-DelayedReach.mat');
% ns = taskObj.getNeuralDataObject('allgrids', 'ns3');
% ns = ns{1};

%% initialize some things

% pre-process info from Blackrock.NSx objects
ns = util.ascell(ns);
[numArrays,numPhysicalChannels,fs,idxLargestPacket] = proc.helper.processNSxInputs(ns);

params = Parameters.Dynamic(@Parameters.Config.BasicAnalysis);
lag = arrayfun(@(x)0,1:numArrays,'UniformOutput',false);
debug = Debug.Debugger(DebugName);
tag = proc.helper.getCacheTag(taskObj,mfilename);

% from proc.task.specgram (142:150)
cachearg = 'none';
if params.dt.cachewrite && params.dt.cacheread
    cachearg = 'both';
elseif params.dt.cachewrite
    cachearg = 'write';
elseif params.dt.cacheread
    cachearg = 'read';
end
gpuarg = false;
if params.cp.gpu
    gpuarg = true;
end
pararg = false;
if params.cp.parallel
    pararg = true;
end

%% calculate frequency powers for all channels

% spencer inputs to blackrock.specgram:
% just give trial times and normalized window, procwin as described above. 
[Lpwr,Lrelt,Lf,Lfeatdef] = proc.blackrock.specgram(ns,...
    'movingwin',params.spc.movingwin,...  %obj.spc.movingwin = [0.5 0.25]; set in BasicAnalysis
    'chr',params.chr,... % see below but set in BasicAnalysis
    'procwin',TimesToAnalyze,... % set your own
    'lag',lag,... % lag = taskObj.getLag([],'file_mean'); gives default of 0.1 until we get the photodiode working
    'cache',cachearg,...% depends on other settings from cache see proc.task.specgram (142:150)
    'gpu',gpuarg,...% params.cp.gpu and checked and set when making BasicAnalysis params
    'parfor',pararg,... % true if params says so params.cp.parallel (BasicAnalysis sets to true)
    'UniformOutput',UniformOutput,...
    'tag',tag,...% tag = proc.helper.getCacheTag(taskObj,mfilename); some hash format spencer uses to make and check the cache
    params.dt.class,...% single if obj.cp.gpu has gpu, else double. Set by BasicAnalysis params.
    debug); % debugger set by you
%   [...] = SPECGRAM(...,'CHR',CHRONUX_PARAMS)
%   Specify the set of chronux parameters as a struct (see Chronux
%   documentation). Default values are tapers [5 9], pad 0, fpass [0 200],
%   and trialave false.

% remove unused channels
Lpwr(:,:,RemoveChannels,:) = [];

%% Plot each channel's spectrogram for each trial

NumTrials = size(Lpwr,4);
PlotRows = ceil(NumTrials/2);
ChanArray = [1:10 17:26 33:42 49:58 65:74 81:90 97:104 113:120];

for Chan = 1:size(Lpwr,3)
    ChanStr = num2str(ChanArray(Chan));
    FigName = ['Channel ' ChanStr];
    f = figure('Name', FigName, 'Position', [1280 0 1280 1440]);
    for TrialNum = 1:NumTrials
        TrialStr = num2str(TrialNum);
        ax = subplot(PlotRows,2,TrialNum);
        imagesc(Lrelt,Lf,10*log10(Lpwr(:,:,Chan,TrialNum)')); axis xy;
        TStr = ['Channel ' ChanStr ' Left Location Trial # ' TrialStr];
        title(TStr)
    end
end

%%
% keys = {'L_Amyg', 'L_H_Hippo', 'L_T_Hippo', 'R_Amyg', 'R_H_Hippo', 'R_T_Hippo', 'L_Par', 'R_Par'};
% values = {'1:10', '17:26', '33:42', '49:58', '65:74', '81:90', '97:104', '113:120'};
% 
% figName2 = ['Separate Channels in ' leadName];
% f2 = figure('Name', figName2, 'Position', [1280 0 1280 1440]);
%     
% for i = 1:length(keys)
%     leadName = keys{i};
%     channels = str2num(values{i});    
%     for i = 1:length(channels)
%         ch = num2str(i);
%         tStr = ['Channel ' ch];
%         ax = subplot(length(channels),1,i);
%         
%         plot(x_range, Data(i,:))
%         ax.YLim = [-500 500];
%         title(tStr)
%         %drawnow

%%
% Initialize Chronux Parameters
MovingWin = [0.5 0.05]; %[WindowSize StepSize]

Tapers = [5 9]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad = 1; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass = [0 100]; %frequency range
TrialAve = 0; %we do the averaging upfront
Chr = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve); 
Chr.Fs = ns.Fs;

%% 
% Left target location spectro

Data = LChanAvg;
LPwr = chronux_gpu.ct.mtspecgramc(Data,MovingWin,Chr);
LRelT = Lpwr(:,;
LFreq = size(LPwr,2);

for Trial = 1:size(LPwr,3)
    TrialStr = num2str(Trial);
    FigName = ['Trial ' TrialStr];
    figure('Name', FigName, 'Position', [1280 0 1000 1000]);
    imagesc(LRelT,LFreq,10*log10(LPwr(:,:,Trial)')); axis xy;
    TStr = ['All Channels Averaged ' 'Left Location (7) Trial # ' TrialStr];
    title(TStr)
end

%%
% Right target location spectro
