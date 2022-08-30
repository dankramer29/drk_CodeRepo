%% Movement initiation in Amygdala

% Amygdala associated with movement initiation

% Get neural data 1 second before the effector showed ('wait'), and neural data 1
% second after the effector showed ('move'), for the channels in the left
% and right amygdala.
%
%    Will reference time from when the effector showed for each trial. 

taskpath = 'C:\Users\Mike\Documents\Data\P015\20180130\Task\';
fn = '20180130-132729-132950-CenterOut.mat';
fp = fullfile(taskpath, fn);
taskObj = FrameworkTask(fp);
ns = taskObj.getNeuralDataObject('NSP1', 'ns3');
ns = ns{1};
TaskString = string(regexp(taskObj.taskString, '\d*-(.*)', 'tokens'));
dtclass = 'single';
GridMapObj = GridMap('C:\Users\Mike\Documents\Data\P015\gridmap.map');

ChanIdx = cell2mat(gridMapObj.GridChannelIndex);
targets = arrayfun(@(x)x.obj_target{1, 1}.targetCurrentIdx, taskObj.trialdata)';




phase = 2;
timing = 1.000;
pre_time = timing;
post_time = timing;
Locations = {'Amygdala'};
Hemispheres = {'Left', 'Right'};

[channels, channel_key] = Analysis.DelayedReach.LFP.get_channels_for_location(GridMapObj, Locations, Hemispheres);
% ONLY USING TRIALS 1:47 DUE TO CUT-OFF
[nd_wait, relT_wait, nd_move, relT_move] = Analysis.DelayedReach.LFP.pre_post_neural_data(taskObj, ns, phase, pre_time, post_time, channels);
% adjust target list
targets = targets(1:47);
% relT_wait: 0-0.9995, relT_move: 0-0.9995
relT_move = relT_move + 1;


% Make Spectrograms
%Initialize Chronux Parameters
MovingWin     = [0.25 0.01]; %[WindowSize StepSize]
Tapers        = [5 9]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass         = [0 200]; %frequency range of the output data
TrialAve      = 0; %Average later
Fs            = ns.Fs;
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, ...
    'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
gpuflag       = true;

% [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(NeuralData,1), MovingWin, DtClass);
[spec_wait, FreqBins, TimeBins_wait] = Analysis.DelayedReach.LFP.multiSpec(nd_wait,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', dtclass,...
    'gpuflag', gpuflag);

[spec_move, ~, TimeBins_move] = Analysis.DelayedReach.LFP.multiSpec(nd_move,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', dtclass,...
    'gpuflag', gpuflag);

clear MovingWin Tapers Pad FPass TrialAve Fs gpuflag DtClass tdelay_avg

%TimeBins wait and move same prob as relT, both 0.1255-0.8755
TimeBins_move = TimeBins_move + 1;

nd_combined = [nd_wait; nd_move];
relT_combined = [relT_wait; relT_move];

possible_targets = 1:8;
% for each spectrogram array, get the average power for each target (1:8),
% scale it by 10*log10(), and take the wait average - move average. Returns
% 3 time x freq x chan x possible_targets arrays. (difference, group 1,
% group 2)
[spec_diff, spec_target_avg_wait, spec_target_avg_move] = Analysis.DelayedReach.LFP.get_avg_and_diff(spec_wait, spec_move, targets, possible_targets);
% Analysis.DelayedReach.LFP.P015_move_initiate.

%% All frequencies all channels separate figs for wait, move, and diffs

% plot each channel all targs wait - move
stt = '(1s pre-move) - (1s post-move)';
t = ' pre-post';
% plots spectrogram average for each target for each channel in the area
% of the figure where the target appeared in the trials.
Analysis.DelayedReach.LFP.plot_spec_target_avg(spec_diff, TimeBins_wait, FreqBins, channels, channel_key, 'AddText', stt, 'TitleMod', t)
Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)

% plot each channel all targs wait
stt = '1s pre effector show';
t = ' wait';
Analysis.DelayedReach.LFP.plot_spec_target_avg(spec_target_avg_wait, TimeBins_wait, FreqBins, channels, channel_key, 'AddText', stt, 'TitleMod', t)
Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)

% plot each channel all targs move
stt = '1s post effector show';
t = ' move';
Analysis.DelayedReach.LFP.plot_spec_target_avg(spec_target_avg_move, TimeBins_move, FreqBins, channels, channel_key, 'AddText', stt, 'TitleMod', t)
Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)

%test

%% Frequency bands

% Gamma
freq_range = [30 80];
anno_text = 'Gamma Band - wait';
t_mod = ' wait';
Analysis.DelayedReach.LFP.plot_spec_target_avg(spec_target_avg_wait, TimeBins_wait, FreqBins, channels, channel_key, 'AddText', anno_text, 'TitleMod', t_mod, 'FreqRange', freq_range)


freq_range = [30 80];
anno_text = 'Gamma Band - move';
t_mod = ' move';

%% Trying line plot of average power in a frequency band


% wait phase
freq_range = [29.9 80.1];
anno_text = 'Gamma Band - wait';
t_mod = ' wait';
% takes average across frequency range given (or all frequencies if none
% specified), plots the average over time. Spatially arranged to match
% target locations during the trials
Analysis.DelayedReach.LFP.plot_power_target_avg(spec_target_avg_wait, TimeBins_wait, FreqBins, channels, channel_key, 'AddText', anno_text, 'TitleMod', t_mod, 'FreqRange', freq_range)

% move phase
anno_text = 'Gamma Band - move';
t_mod = ' move';
% takes average across frequency range given (or all frequencies if none
% specified), plots the average over time. Spatially arranged to match
% target locations during the trials
Analysis.DelayedReach.LFP.plot_power_target_avg(spec_target_avg_wait, TimeBins_move, FreqBins, channels, channel_key, 'AddText', anno_text, 'TitleMod', t_mod, 'FreqRange', freq_range)

Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)

%% Beginning to middle of move phase
% 30-80Hz power drop?
fr_idx = FreqBins >= freq_range(1) & FreqBins <= freq_range(2);
gamma_avg_move = squeeze(mean(spec_target_avg_move(:, fr_idx, :, :), 2)); % average across gamma band
gamma_avg_move = squeeze(mean(gamma_avg_move, 3)); % average across trials

time_range_e1 = [1.0 1.3];
time_idx_e1 = TimeBins_move >= time_range_e1(1) & TimeBins_move <= time_range_e1(2);
time_range_e2 = [1.3 1.5];
time_idx_e2 = TimeBins_move > time_range_e2(1) & TimeBins_move <= time_range_e2(2);

gamma_avg_move_epoch1 = mean(gamma_avg_move(time_idx_e1, :), 1);
gamma_avg_move_epoch2 = mean(gamma_avg_move(time_idx_e2, :), 1);
move_gamma_epoch_diff = gamma_avg_move_epoch1 - gamma_avg_move_epoch2;
% actually shows me the opposite of what I was seeing in the target average
% plots. All the medial channels have negative difference between epoch1
% and epoch2, meaning that across all trials, the average power in the
% gamma band increases after 0.3s of movement time, bilaterally.

%%
time_idx_both_e = time_idx_e1 | time_idx_e2;
move_gamma_initial = gamma_avg_move(time_idx_both_e,:);

fs = sprintf('test L amyg');
figure('Name', fs, 'NumberTitle', 'off','position', [-1919 121 1920 1083])

for sp = 1:5
    subplot(1, 5, sp)
    plot(TimeBins_move(time_idx_both_e), move_gamma_initial(:, sp))
    xlabel('Time (s)')
    ts = sprintf('Ch %d', channels(sp));
    title(ts)
end

fs = sprintf('test R amyg');
figure('Name', fs, 'NumberTitle', 'off','position', [-1919 121 1920 1083])

for sp = 1:5
    subplot(1, 5, sp)
    plot(TimeBins_move(time_idx_both_e), move_gamma_initial(:, sp+10))
    xlabel('Time (s)')
    ts = sprintf('Ch %d', channels(sp+10));
    title(ts)
end


