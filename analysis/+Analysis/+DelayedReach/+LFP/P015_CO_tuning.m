env.set('Data', 'C:\Users\Mike\Documents\Data')
taskpath = 'C:\Users\Mike\Documents\Data\P015\20180130\Task\';
fileID   = '*CenterOut.mat';
FileList = ls(fullfile(taskpath, fileID));
%numfiles  = size(FileList,1);
GridMapObj = GridMap('C:\Users\Mike\Documents\Data\P015\gridmap.map');
TotalChanArray = cell2mat(GridMapObj.GridInfo.Channels)';
DtClass = 'single';
% Get Channels from GridMap
GInfo = GridMapObj.GridInfo;
ChanIdx = cell2mat(GridMapObj.GridChannelIndex);

fn = '20180130-132729-132950-CenterOut.mat';
fp = fullfile(taskpath, fn);

   
taskObjT2 = FrameworkTask(fp);
nsT2 = taskObjT2.getNeuralDataObject('NSP1', 'ns3');
nsT2 = nsT2{1};

TaskString = string(regexp(taskObjT2.taskString, '\d*-(.*)', 'tokens'));
targetsT2 = arrayfun(@(x)x.obj_target{1, 1}.targetCurrentIdx, taskObjT2.trialdata)';

trial_times = [taskObjT2.trialTimes];
phase_times = [taskObjT2.phaseTimes];
phase_times(:,end+1) = phase_times(:,1) + trial_times(:,2);
phase_times_relT = phase_times - phase_times(:,1);
phase_names = [taskObjT2.phaseNames];

%% Remove bad trials

% Recording cut off before the end of trial #48
targetsT2 = targetsT2(1:47);
trial_times = trial_times(1:47, :);
phase_times = phase_times(1:47, :);
phase_times_relT = phase_times_relT(1:47, :);

% see finding a bad trial in P015_CO_LvR.m
targetsT2(21) = [];
trial_times(21, :) = [];
phase_times(21, :) = [];
phase_times_relT(21, :) = [];

% trial #1 first phase is 0.22 s after trial start. All others are ~1.1s
% after trial start.
targetsT2(1) = [];
trial_times(1, :) = [];
phase_times(1, :) = [];
phase_times_relT(1, :) = [];

% Final # Trials = 45

%% Extract Voltage Neural Data
[ND, RelT, ~] = proc.blackrock.broadband(...
    nsT2, 'PROCWIN', trial_times, DtClass, 'CHANNELS', TotalChanArray);

% Returns the relative time index for the phases of each trial
RelT_phase_idx = Analysis.DelayedReach.LFP.match_relative_times(RelT, phase_times_relT);


%% Align Trials, Clip to Equal Lengths
% takes 1 seconds before and 2 seconds after phase #2
pre_samples = nsT2.Fs * 1; % 1 seconds of samples
post_samples = nsT2.Fs * 2; % 2 seconds of samples
phase = 2; %action phase start
VertLineCoords = 1; % movment initiation, seconds from start 

trial_nd_cell = cell(1,length(RelT));
trial_relt_cell = cell(1,length(RelT));

for tr = 1:length(RelT)
    start_idx = RelT_phase_idx(tr, phase) - pre_samples;
    stop_idx = RelT_phase_idx(tr, phase) + post_samples;
    trial_nd_cell{1,tr} = ND{1, tr}(start_idx:stop_idx, :);
    trial_relt_cell{1,tr} = RelT{1, tr}(start_idx:stop_idx, :);
end


trial_nd = proc.helper.createUniformOutput(trial_nd_cell);
t_rel = 0: (1/nsT2.Fs): (pre_samples+post_samples)/nsT2.Fs;

%% Plot All Channels All Trials by Target Location
% 1 fig for each channel, 8 subplots

% Analysis.DelayedReach.LFP.plotNeuralDataTrials(trial_nd, targetsT2, t_rel, TaskString, 'VertLineCoords', VertLineCoords)

%% Make Spectrograms
%Initialize Chronux Parameters
MovingWin     = [0.5 0.05]; %[WindowSize StepSize]
Tapers        = [5 9]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass         = [0 200]; %frequency range of the output data
TrialAve      = 0; %Average later
Fs            = nsT2.Fs;
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, ...
    'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
gpuflag       = true;

% [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(NeuralData,1), MovingWin, DtClass);
[PowerArray, FreqBins, TimeBins] = Analysis.DelayedReach.LFP.multiSpec(trial_nd,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
    'gpuflag', gpuflag);
TimeBins_shift = TimeBins - TimeBins(1);

%% Plot Tuning Figures

% [targ_ph_chan_avg, TimeBins_to_phase_all, TimeBins_to_phase_avg] = Analysis.DelayedReach.LFP.check_tuning(...
%     PowerArray, TimeBins_shift, FreqBins, targetsT2, phase_times_relT, phase_names, TaskString ,'FBand', 'beta');

% [targ_ph_chan_avg, TimeBins_to_phase_all, TimeBins_to_phase_avg] = Analysis.DelayedReach.LFP.check_tuning(...
%     PowerArray, TimeBins_shift, FreqBins, targetsT2, phase_times_relT, phase_names, TaskString ,'FBand', 'low gamma');

% [targ_ph_chan_avg, TimeBins_to_phase_all, TimeBins_to_phase_avg] = Analysis.DelayedReach.LFP.check_tuning(...
%     PowerArray, TimeBins_shift, FreqBins, targetsT2, phase_times_relT, phase_names, TaskString ,'FBand', 'high gamma');

%% Sort and Average By Left or Right

%  Left Targets = 8, 7, 6
LTTrialsIdx = targetsT2 == 6 | targetsT2 == 7 | targetsT2 == 8;
fprintf('# L Target Trials: %d\n', sum(LTTrialsIdx))

%  Right Targets = 2, 3, 4
RTTrialsIdx = targetsT2 == 2 | targetsT2 == 3 | targetsT2 == 4;
fprintf('# R Target Trials: %d\n', sum(RTTrialsIdx))

% *Take trials for L targets and average*
LTSpecs = PowerArray(:, :, :, LTTrialsIdx);
LTAvgSpecs = mean(LTSpecs, 4);

% *Take trials for R targets and average*
RTSpecs = PowerArray(:, :, :, RTTrialsIdx);
RTAvgSpecs = mean(RTSpecs, 4);

ThetaLogical  = FreqBins > 4  & FreqBins < 8;
AlphaLogical  = FreqBins > 8  & FreqBins < 12;
BetaLogical   = FreqBins > 12 & FreqBins < 30;
LGammaLogical = FreqBins > 30 & FreqBins < 80;
HGammaLogical = FreqBins > 80 & FreqBins < 200;
FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
clear ThetaLogical AlphaLogical BetaLogical LGammaLogical HGammaLogical

% Take trial averages and average by frequency range
Num_Fbands = size(FreqLog, 1);
Num_Tb = size(LTAvgSpecs, 1);
Num_Ch = size(LTAvgSpecs, 3);
LTAvgSpecs_Favg = zeros(Num_Tb, Num_Ch, Num_Fbands);
RTAvgSpecs_Favg = zeros(Num_Tb, Num_Ch, Num_Fbands);

for f = 1:5
    L_slice = LTAvgSpecs(:, FreqLog(f, :), :);
    R_slice = RTAvgSpecs(:, FreqLog(f, :), :);
    LTAvgSpecs_Favg(:,:,f) = squeeze(mean(L_slice, 2));
    RTAvgSpecs_Favg(:,:,f) = squeeze(mean(R_slice, 2));
end
clear f L_slice R_slice
    
%% Calculate CIs of Left and Right group + frequency averages
fprintf('Calculating CIs for L and R groups\n')
NumSamp = 10000;
tic
[Means_CIs_Left, Means_CIs_Right] = Analysis.DelayedReach.LFP.shuffleCI(LTSpecs, RTSpecs, NumSamp, FreqBins);
toc

%% Plot CIs
% TB_shift2 = TimeBins + TimeBins(1);
% TB = TimeBins; %TimeBins; %TB_shift2
% 
% darkr = [150 50 50] ./ 256;
% lr = [228 149 144] ./ 256;
% darkb = [50 50 150] ./ 256;
% lb = [177 212 255] ./ 256;
% % darkg = [40 90 40];
% % lg = [212 255 177];
% fband_names = {'Theta 4-8' 'Alpha 8-12' 'Beta 12-30' 'Low Gamma 30-80'...
%     'High Gamma 80-200'};
% 
% % Means_LTargs_FBands =  Means_CIs_Left{1}; % Tbin x Channels x Fbands
% % Use LTAvgSpecs_Favg ; Tbin x Channels x Fbands
% CI_Low_LTargs_FBands = Means_CIs_Left{2}; % Tbin x Channels x Fbands
% CI_High_LTargs_FBands = Means_CIs_Left{3}; % Tbin x Channels x Fbands
% 
% % Means_RTargs_FBands = Means_CIs_Right{1}; % Tbin x Channels x Fbands
% % Use RTAvgSpecs_Favg ; Tbin x Channels x Fbands
% CI_Low_RTargs_FBands = Means_CIs_Right{2}; % Tbin x Channels x Fbands
% CI_High_RTargs_FBands = Means_CIs_Right{3}; % Tbin x Channels x Fbands
% 
% for ch = 1:10%60
%     [~, loc] = ind2sub([10 6], ch);
%     FigTitle = sprintf('Targ-FBand-MeanCI-Channel%d-%s%s', ch, string(GInfo.Hemisphere(loc)),...
%         string(GInfo.Location(loc)));
%     figure('Name', FigTitle, 'NumberTitle', 'off', 'units', 'normalized',...
%         'outerposition', [-0.75 0.08 0.75 0.8], 'PaperPositionMode', 'auto');
%     for s = 1:5
%         subplot_tight(5, 1, s, [0.035 0.045])
%         lx1 = 10*log10(LTAvgSpecs_Favg(:, ch, s));
%         lx2 = 10*log10(CI_Low_LTargs_FBands(:, ch, s));
%         lx3 = 10*log10(CI_High_LTargs_FBands(:, ch, s));
%         h1 = plot_ci(TB, [lx1 lx2 lx3], 'LineColor', lb, 'MainLineColor', darkb, 'PatchColor', lb, 'PatchAlpha', 0.4);
%         hold on
% 
%         rx1 = 10*log10(RTAvgSpecs_Favg(:, ch, s));
%         rx2 = 10*log10(CI_Low_RTargs_FBands(:, ch, s));
%         rx3 = 10*log10(CI_High_RTargs_FBands(:, ch, s));
%         h2 = plot_ci(TB, [rx1 rx2 rx3], 'LineColor', lr, 'MainLineColor', darkr, 'PatchColor', lr, 'PatchAlpha', 0.4);
%         
%         ax = gca;
%         Ylimits = ax.YLim;
%         Vx = [VertLineCoords; VertLineCoords];
%         Vy = Ylimits' .* ones(2, length(VertLineCoords));
%         plot(Vx, Vy, 'k--')
%         ax.YLim = Ylimits;
% 
% 
%         hold off
%         xlim([TB(1) TB(end)])
%         ts = sprintf('%s - Ch%d',fband_names{s},ch);
%         title(ts);
%         if s ==1
%             legend([h1.Patch h1.Plot h2.Patch h2.Plot], {'L Trials CI', 'L Trials Mean', 'R Trials CI', 'R Trials Mean'});
% %             annotation('textbox', [move_start Ylimits(1)+1], 'String', 'effector show', 'FitBoxToText','on')
%             text(VertLineCoords, Ylimits(1)+1, 'effector show')
% 
%         end
%     end
% end
% 
% clear CI_Low_LTargs_FBands CI_High_LTargs_FBands CI_Low_RTargs_FBands CI_High_RTargs_FBands

%% Get to Integrals


%
fprintf('calculating shuffled perc-diffs \n')
% pause
NumSamp = 10000;
t1 = tic;
[sig_perc_diffs] = Analysis.DelayedReach.LFP.shuffle_comparison(PowerArray, targetsT2, FreqBins, NumSamp, 'CompMethod', 'perc_diff');
perc_diffs = (RTAvgSpecs_Favg - LTAvgSpecs_Favg) ./ (RTAvgSpecs_Favg + LTAvgSpecs_Favg);
toc(t1) 
fprintf('end shuffle comparison\n')

%
accum_integrals = Analysis.DelayedReach.LFP.get_sig_integrals(perc_diffs, sig_perc_diffs, TimeBins_shift);

%% Code to segment into groups A B and C, 
% 1 second before effector show, 1 second after effector show, 1 second
% before trial end
phase_starts_stops = [TimeBins_shift(1) TimeBins_shift(21); TimeBins_shift(21) TimeBins_shift(41); TimeBins_shift(31) TimeBins_shift(51)];
integrals_in_phases = Analysis.DelayedReach.LFP.get_integrals_by_phase(accum_integrals, phase_starts_stops);

%%
phase_names = {'A', 'B', 'C'};
for i = 1:3
    l = min(integrals_in_phases{1,i});
    h = max(integrals_in_phases{1,i});
    b = linspace(l, h);
    figure
    hist(integrals_in_phases{1,i}, b)
    title(phase_names{i})
end

%%
% low value in phase B is -0.0341 = channel 23 fband 4
% high value in phase B is 0.896 = channel 47 fband 1
% low value in phase C is -0.1518 = channel 5 fband 1
% high value in phase C is 0.0487 = channel 53 fband 2
[ch, fb] = Analysis.DelayedReach.LFP.find_sig_int(accum_integrals, l);

% high value in phase B is 0.896 = channel 47 fband 1
phase_names = {'A', 'B', 'C'};
t = [0 1 2 2.5];
pt_rt = repmat(t, [length(phase_times_relT) 1]);
[targ_ph_chan_avg, TimeBins_to_phase_all, TimeBins_to_phase_avg] = Analysis.DelayedReach.LFP.check_tuning(...
    PowerArray, TimeBins_shift, FreqBins, targetsT2, pt_rt, phase_names, TaskString ,'FBand', 'theta', 'Channels', 47, 'Mode', 'Avg-Power');
