%% Analyze Center-Out Trials
%
%%
plotfigs = false;
%% Find Assist Level = 1

env.set('Data', 'C:\Users\Mike\Documents\Data')
taskpath = 'C:\Users\Mike\Documents\Data\P015\20180130\Task\';
fileID   = '*CenterOut.mat';
FileList = ls(fullfile(taskpath, fileID));
%numfiles  = size(FileList,1);
GridMapObj = GridMap('C:\Users\Mike\Documents\Data\P015\gridmap.map');
TotalChanArray = cell2mat(gridMapObj.GridInfo.Channels)';
DtClass = 'single';

% AssistLvl = zeros(numfiles, 1);
% for f = 1:numfiles
%     fn = fullfile(taskpath, FileList(f, :));
%     taskObj = FrameworkTask(fn);
%     AssistLvl(f) = taskObj.predictor.hDecoder.runtimeParams.assistLevel;
% end
% searchresults = table(FileList, AssistLvl);

%%
% 2 task files
% - 20180130-132729-132829-CenterOut.mat
% - 20180130-132729-132950-CenterOut.mat
%% First Dataset
% 20180130-132729-132829-CenterOut.mat
% "Warning Found 0 trials"

% fn = '20180130-132729-132829-CenterOut.mat';
% fp = fullfile(taskpath, fn);
%    
% taskObjT1 = FrameworkTask(fp);
% nsT1 = taskObjT1.getNeuralDataObject('NSP1', 'ns3');
% nsT1 = nsT1{1};
% 
% targetsT1 = arrayfun(@(x)x.obj_target{1, 1}.targetCurrentIdx, taskObjT1.trialdata)';

%% Second Dataset
% 20180130-132729-132950-CenterOut.mat
% 55 trials. 

fn = '20180130-132729-132950-CenterOut.mat';
fp = fullfile(taskpath, fn);

   
taskObjT2 = FrameworkTask(fp);
nsT2 = taskObjT2.getNeuralDataObject('NSP1', 'ns3');
nsT2 = nsT2{1};

TaskString = string(regexp(taskObjT2.taskString, '\d*-(.*)', 'tokens'));
targetsT2 = arrayfun(@(x)x.obj_target{1, 1}.targetCurrentIdx, taskObjT2.trialdata)';

trialtimes = [taskObjT2.trialTimes];
phase_times = [taskObjT2.phaseTimes];
phase_times(:,end+1) = phase_times(:,1) + trialtimes(:,2);
phase_times_relT = phase_times - phase_times(:,1);
tstarts = [taskObjT2.phaseTimes(:,1)];

tmove = [taskObjT2.phaseTimes(:,2)];
tdelay = tmove - tstarts;
tdelay_avg = mean(tdelay); % 1.0621

clear fn fp taskpath tstarts tmove tdelay 
% col1 = start times, col2 = duration
%%
% some variation in trial duration. Need to set time duration to capture
% most of the trials
% timeavg = mean(trialtimes(:,2)); %3.3742
% timestd = std(trialtimes(:,2)); %0.0649
% [l, u] = bounds(trialtimes(:,2)); %2.9707 - 3.5500
% bins = l:0.01:u;
% [h, hbins] = hist(trialtimes(:,2), bins);

%%
% Plotting and examining the bins (cant get bin edges otherwise?) shows
% that all but 1 trial are less than 3.44s long. And 3.44s is ~1 stdev
% above the mean, but contains ~98% of the trials
if plotfigs
hist(trialtimes(:,2), bins)


sum(trialtimes(:,2) <= 3.44)
NumStDev = (3.44 - timeavg) / timestd; %1.0149
end
Procwin = [trialtimes(:,1) 3.44*ones(length(trialtimes),1)];
clear trialtimes

%% Finding a bad trial
% trial numer 21, the 3rd trial for target #4, might be throwing off
% significance calculations later on. Going to exclude it.
% tar4 = targetsT2 == 4;
% tar4_nd = NeuralData(:, :, tar4);
% plot(RelativeTimes, squeeze(tar4_nd(:, 36, :))) % 36 is an example
% channel
% find(targetsT2 == 4)
% ans =
% 
%      2
%      9
%     21
%     28
%     33
%     47
% plot(RelativeTimes, squeeze(NeuralData(:, 36, 21))) % showing that trial
% 21 is the culprit
%% recording error
% using the above times causes an error, as the recording cut off at
% 180.010s, just short of 180.256 of trial 48
Procwin = Procwin(1:48,:);

%%
% using 48th trial, it gets clamped. Based on samples in the NeuralData
% output (6389), it seems to shorten all the trials by the same amount
% (uniform output = true). So try to exclude the 48th.
Procwin = Procwin(1:47,:);
targetsT2 = targetsT2(1:47);

%%
% so now each trial is 6880 samples = 3.44 sec. 6389 = 3.195s. Shortening
% to that amount shortens a large proportion of trials, only to keep 1 more.
%% Get raw voltage of all trials with a fixed duration
[NeuralData, RelativeTimes, ~] = proc.blackrock.broadband(...
    nsT2, 'PROCWIN', Procwin, DtClass, 'CHANNELS', TotalChanArray,...
    'Uniformoutput', true);

%% Remove bad trials
NeuralData(:, :, 21) = []; % see finding a bad trial above
targetsT2(21) = [];
% NeuralData = 6880 samples x 60 channels x 46 trials
clear ProcWin NumStDev 

%% Check Raw Voltages Visually
if plotfigs
Analysis.DelayedReach.LFP.plotNeuralDataTrials(NeuralData, targetsT2, RelativeTimes, TaskString, 'VertLineCoords', move_start)
Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)
end
% channel 1, 8, 10 seem to have lots of noise (60hz waves?) on every trial
clear TaskString

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
[PowerArray, FreqBins, TimeBins] = Analysis.DelayedReach.LFP.multiSpec(NeuralData,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
    'gpuflag', gpuflag);

tbin_find = find(TimeBins < tdelay_avg, 1, 'last'); % 17th timebin = 1.0505, 18th = 1.1005
move_start = tdelay_avg;
clear MovingWin Tapers Pad FPass TrialAve Fs gpuflag DtClass tdelay_avg

%% Select Left and Right Target Trials

%  Left Targets = 8, 7, 6
LTTrialsIdx = targetsT2 == 6 | targetsT2 == 7 | targetsT2 == 8;
fprintf('# L Target Trials: %d\n', sum(LTTrialsIdx))

%  Right Targets = 2, 3, 4
RTTrialsIdx = targetsT2 == 2 | targetsT2 == 3 | targetsT2 == 4;
fprintf('# R Target Trials: %d\n', sum(RTTrialsIdx))

%% Index and Average by Trial
% *Take trials for L targets and average*
LTSpecs = PowerArray(:, :, :, LTTrialsIdx);
LTAvgSpecs = mean(LTSpecs, 4);

% *Take trials for R targets and average*
RTSpecs = PowerArray(:, :, :, RTTrialsIdx);
RTAvgSpecs = mean(RTSpecs, 4);

%%
darkr = [150 50 50] ./ 256; 
darkb = [50 50 150] ./ 256;
r_idx = randperm(60, 10);
for c = 1:10
    figure('NumberTitle', 'off', 'position', [-1919 121 1920 1083])
    ld = squeeze(NeuralData(:, r_idx(c), LTTrialsIdx));
    rd = squeeze(NeuralData(:, r_idx(c), RTTrialsIdx));
    subplot(2, 1, 1)

    hold on
    for lt = 1:size(ld, 2)
       ht = plot(RelativeTimes, ld(:,lt) , 'Color', darkb, 'LineWidth', 0.2, 'LineStyle', ':');
    end
    h1 = plot(RelativeTimes, mean(ld, 2), 'Color', [0 0 0], 'LineWidth', 0.7);
    ts = sprintf('Channel %d Left Trials', r_idx(c));
    title(ts)
    legend([h1], {'LT Avg'})
    ylim([-150 150])
    hold off
    
    subplot(2, 1, 2)
    
    hold on
    for lt = 1:size(ld, 2)
        plot(RelativeTimes, rd(:,lt) , 'Color', darkr, 'LineWidth', 0.2, 'LineStyle', ':')
    end
    h2 = plot(RelativeTimes, mean(rd, 2), 'Color', [0 0 0], 'LineWidth', 0.7);
    ts = sprintf('Channel %d Right Trials', r_idx(c));
    title(ts)
    legend([h2], {'RT Avg'})
    ylim([-150 150])
    hold off
end

%%
ThetaLogical  = FreqBins > 4  & FreqBins < 8;
AlphaLogical  = FreqBins > 8  & FreqBins < 12;
BetaLogical   = FreqBins > 12 & FreqBins < 30;
LGammaLogical = FreqBins > 30 & FreqBins < 80;
HGammaLogical = FreqBins > 80 & FreqBins < 200;
FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
clear ThetaLogical AlphaLogical BetaLogical LGammaLogical HGammaLogical
%% Take trial averages and average by frequency range
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
    
%%
% Show the noisy channels and clean channels from same electrode

if plotfigs
    
chans = [1 2 8 9 10];
figure('units', 'normalized', 'outerposition', [0 0.1 1 0.65])
for c = 1:5
    subplot_tight(2, 5, c, [0.05 0.02])
    imagesc(TimeBins, FreqBins, 10*log10(LTAvgSpecs(:,:,chans(c))')); axis xy;
    ts = sprintf('Ch %d Left Targets Avg', chans(c));
    title(ts)
    colorbar
    subplot_tight(2, 5, c+5, [0.045 0.02])
    imagesc(TimeBins, FreqBins, 10*log10(LTAvgSpecs(:,:,chans(c))')); axis xy;
    ts = sprintf('Ch %d Right Targets Avg', chans(c));
    title(ts)
    colorbar    
end

end

%% Make ITI Mean and Standard Deviation
% *Make indices*
% TrialsIdx = LTTrialsIdx | RTTrialsIdx;
% fprintf('# L + R Target Trials: %d\n', sum(TrialsIdx))
% 
% ITIidx = TimeBins < 0.50; % No real ITI
% ITISpecs = PowerArray(ITIidx, :, :, TrialsIdx);
% ITITimes = TimeBins(ITIidx);
% ITITimeAvg = mean(ITISpecs, 1); % Time average
% ITITrialAvg = mean(ITITimeAvg,4);
% ITIStd = std(ITITimeAvg, [], 4);
% 
% time = size(TimeBins, 1); % To match time length of averages -> vectorized z-score later
% ITIMeans = repmat(ITITrialAvg, [time, 1, 1]);
% ITIStDevs = repmat(ITIStd, [time, 1, 1]); 
% 
% clear ITIidx ITISpecs ITITimeAvg ITITrialAvg ITIStd time

%%
% Plot channel 2's averaged spectogram for all frequencies in the ITI phase
% as an example:
if plotfigs
    
Ch1ITIAvg = ITIMeans(:, :, 2);
figure
imagesc(ITITimes, FreqBins, 10*log10(Ch1ITIAvg)'); axis xy;

end
%% Differences of Z-Scored Left and Right Trials
%
% LeftZScores = (LTAvgSpecs - ITIMeans) ./ ITIStDevs;
% RightZScores = (RTAvgSpecs - ITIMeans) ./ ITIStDevs;
% LvRZScores = LeftZScores - RightZScores;

%% Get Channels from GridMap
%
GInfo = gridMapObj.GridInfo;
ChanIdx = cell2mat(gridMapObj.GridChannelIndex);

%% Plot Each Location Left and Right Averages and Z-Scored Differences
% channel 30 was a reference, so the spectograms are 0 for channel 30 and
% the 10*log10 is -Inf and that causes plotting problems
if plotfigs
    
numLocs = length([GInfo.Location]);

    
for l = 1:numLocs
    loc = l;
    Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
    Channels = ChanIdx(:,loc)';
    if loc == 3
        Channels(end) = [];
    end

    Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
        LvRZScores, TimeBins, FreqBins, 'Normalize', 'Channel',...
        'PlotColorBar', false)
end

end
clear LeftZScores RightZScores LvRZScores
%% Plot R vs L of Frequency Band Averages
% Removing channel 30 again. 
if plotfigs
Window = [2 1]; %100ms of time
[PercDiff, TimeStamps] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
    LTAvgSpecs, TimeBins, FreqBins, 'Window', Window);

for l = 1:numLocs
    loc = l;
    Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
        string(GInfo.Location(loc)));
    Channels = ChanIdx(:,loc)';
    TitleMod = sprintf('CenterOut - Win=[%d %d]', Window(1), Window(2));
    
    if loc == 3
        Channels(end) = [];
    end

    Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDiff, TimeStamps,...
        'TitleMod', TitleMod, 'FixYRange', true)
end

Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)

end
%%
% fprintf('Running PercDiff Window [2 1]\n')
% tic
% Window = [2 1]; %100ms of time
% [PercDiff, TimeStamps] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
%     LTAvgSpecs, TimeBins, FreqBins, 'Window', Window);
% toc
%%
% fprintf('paused before shuffle CI\n')
% pause
fprintf('waiting to calculate resampled CIs \n')
pause
% ThetaLogical  = FreqBins > 4  & FreqBins < 8;
% AlphaLogical  = FreqBins > 8  & FreqBins < 12;
% BetaLogical   = FreqBins > 12 & FreqBins < 30;
% LGammaLogical = FreqBins > 30 & FreqBins < 80;
% HGammaLogical = FreqBins > 80 & FreqBins < 200;
% FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
NumSamp = 10000;
tic
[Means_CIs_Left, Means_CIs_Right] = Analysis.DelayedReach.LFP.shuffleCI(LTSpecs, RTSpecs, NumSamp, FreqBins);
toc
%% Check mean(freqband and trials) vs mean(bootstrapped samples)
% Means_LTargs_FBands =  Means_CIs_Left{1};
% numT = 5;
% r_idx = randperm(Num_Ch, numT);
% for c = 1:numT
%     fs = sprintf('Channel %d ResampleMean vs TrueMean', r_idx(c));
%     figure('Name', fs, 'NumberTitle', 'off')
%     for f = 1:Num_Fbands
%         subplot(Num_Fbands, 1, f)
%         plot(TimeBins, Means_LTargs_FBands(:, r_idx(c), f), 'g-')
%         hold on
%         plot(TimeBins, LTAvgSpecs_Favg(:, r_idx(c), f), 'k')
%         hold off
%         legend('ResampleMean', 'TrueMean')
%     end
% end
% 'TrueMeans' are exactly the same as the mean of resampled means. Which
% makes sense, considering that any resample that generates a mean higher
% than the true mean, should be balanced by another resample with a mean
% lower. 

%% What am I calculating?
% thought it was 95% confidence bounds, but it's actually signficance of R
% vs L comparison.
% size(samplediff); %5 x 58 x 60 x 10000. Freq bands, time bins, channels, resampled comparison values
% bins = -1.0:0.01:1.0; % range of possible RvL values
% examplesample = squeeze(samplediff(1,1,1,:));
% [counts, bincenters] = hist(examplesample, bins);
% hist(examplesample, bins)
% xlim([-1 1])
% 
% % But I was setting my low and high bounds at 5% and 95% of the entire
% % sample. 
% 
% Lfavored = sum(examplesample < 0);
% Rfavored = sum(examplesample > 0);
% % Lfavored = 5026
% % Rfavored = 4974
% % Lfavored + Rfavored = 10000
% sorted_es = sort(examplesample); %fun fact, if you give sort a dimension out of range it doesn't error, it just doesn't sort
% % sorts it low to high so 5026th value should be closest negative to 0 and
% % one past that should be positive
% % sortexamplesample(5026) % -0.3055
% % sortexamplesample(5027) % 0.3148
% low_cut = floor(0.05 * 5026); % 251
% hi_cut = floor(0.05 * Rfavored); % 248 should these just be 250? 2.5% cut-offs of 10,000?
% low_val = sorted_es(low_cut);% -0.4330
% hi_val = sorted_es(end - hi_cut);% 0.4402

%% Sort and get cut off values for every bin
% sortsample = sort(samplediff, 4);
% sig_Left = sortsample(:, :, :, 250);
% sig_Right = sortsample(:, :, :, end-250);

%% Plots of RvL difference for a given band
% if they pass the low or high cut off they are significantly in favor of R
% or L. 
% fband_names = {'Theta 4-8' 'Alpha 8-12' 'Beta 12-30' 'Low Gamma 30-80'...
%     'High Gamma 80-200'};
% 
% for ch = 1:60
%     [~, loc] = ind2sub([10 6], ch);
%     FigTitle = sprintf('FBand-RLDiff-Channel%d-%s%s', ch, string(GInfo.Hemisphere(loc)),...
%         string(GInfo.Location(loc)));
%     figure('Name', FigTitle, 'NumberTitle', 'off', 'units', 'normalized',...
%         'outerposition', [0.2 0 0.6 1], 'PaperPositionMode', 'auto');
%     for s = 1:5
%         subplot_tight(5, 1, s, [0.035 0.045])
%         plot(TimeStamps, PercDiff(s,:,ch), 'b')
%         hold on
%         plot(TimeStamps, sig_Left(s,:,ch), 'k:')
%         plot(TimeStamps, sig_Right(s,:,ch), 'k:')
%         ylim([-1 1])
%         xlim([TimeStamps(1) TimeStamps(end)])
%         ax = gca;
%         ax.XAxisLocation = 'origin';
%         ts = sprintf('%s - RLDiff-Ch%d',fband_names{s},ch);
%         title(ts);
%         hold off
%     end
%     
% end

%% Plotting all channels' CIs for all frequency bands L and R means
fprintf('waiting to plot all channel CIs for frequency band and trial averaged L and R trials\n')
pause

darkr = [150 50 50] ./ 256;
lr = [228 149 144] ./ 256;
darkb = [50 50 150] ./ 256;
lb = [177 212 255] ./ 256;
% darkg = [40 90 40];
% lg = [212 255 177];
fband_names = {'Theta 4-8' 'Alpha 8-12' 'Beta 12-30' 'Low Gamma 30-80'...
    'High Gamma 80-200'};

% Means_LTargs_FBands =  Means_CIs_Left{1}; % Tbin x Channels x Fbands
% Use LTAvgSpecs_Favg ; Tbin x Channels x Fbands
CI_Low_LTargs_FBands = Means_CIs_Left{2}; % Tbin x Channels x Fbands
CI_High_LTargs_FBands = Means_CIs_Left{3}; % Tbin x Channels x Fbands

% Means_RTargs_FBands = Means_CIs_Right{1}; % Tbin x Channels x Fbands
% Use RTAvgSpecs_Favg ; Tbin x Channels x Fbands
CI_Low_RTargs_FBands = Means_CIs_Right{2}; % Tbin x Channels x Fbands
CI_High_RTargs_FBands = Means_CIs_Right{3}; % Tbin x Channels x Fbands

for ch = 1:60
    [~, loc] = ind2sub([10 6], ch);
    FigTitle = sprintf('Targ-FBand-MeanCI-Channel%d-%s%s', ch, string(GInfo.Hemisphere(loc)),...
        string(GInfo.Location(loc)));
    figure('Name', FigTitle, 'NumberTitle', 'off', 'units', 'normalized',...
        'outerposition', [-0.75 0.08 0.75 0.8], 'PaperPositionMode', 'auto');
    for s = 1:5
        subplot_tight(5, 1, s, [0.035 0.045])
        lx1 = 10*log10(LTAvgSpecs_Favg(:, ch, s));
        lx2 = 10*log10(CI_Low_LTargs_FBands(:, ch, s));
        lx3 = 10*log10(CI_High_LTargs_FBands(:, ch, s));
        h1 = plot_ci(TimeBins, [lx1 lx2 lx3], 'LineColor', lb, 'MainLineColor', darkb, 'PatchColor', lb, 'PatchAlpha', 0.4);
        hold on

        rx1 = 10*log10(RTAvgSpecs_Favg(:, ch, s));
        rx2 = 10*log10(CI_Low_RTargs_FBands(:, ch, s));
        rx3 = 10*log10(CI_High_RTargs_FBands(:, ch, s));
        h2 = plot_ci(TimeBins, [rx1 rx2 rx3], 'LineColor', lr, 'MainLineColor', darkr, 'PatchColor', lr, 'PatchAlpha', 0.4);
        
        ax = gca;
        Ylimits = ax.YLim;
        Vx = [move_start; move_start];
        Vy = Ylimits' .* ones(2, length(move_start));
        plot(Vx, Vy, 'k--')
        ax.YLim = Ylimits;


        hold off
        xlim([TimeBins(1) TimeBins(end)])
        ts = sprintf('%s - Ch%d',fband_names{s},ch);
        title(ts);
        if s ==1
            legend([h1.Patch h1.Plot h2.Patch h2.Plot], {'L Trials CI', 'L Trials Mean', 'R Trials CI', 'R Trials Mean'});
%             annotation('textbox', [move_start Ylimits(1)+1], 'String', 'effector show', 'FitBoxToText','on')
            text(move_start, Ylimits(1)+1, 'effector show')

        end
    end
end
Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)
clear CI_Low_LTargs_FBands CI_High_LTargs_FBands CI_Low_RTargs_FBands CI_High_RTargs_FBands

%% comparing to matlab mean func
% th_ltr_avg = squeeze(mean(LTAvgSpecs(:, ThetaLogical, :), 2));
% th_ltr_bs_avg = Means_LTargs_FBands(:,:,1);
% 
% mean_diff = abs(th_ltr_avg - th_ltr_bs_avg);
% imagesc(mean_diff'); axis xy;
% colorbar
% ylabel('Channels')
% xlabel('Time')
% title("mean diff 'raw' ")
% 
% figure
% imagesc(10*log10(th_ltr_avg)'); axis xy;
% colorbar
% ylabel('Channels')
% xlabel('Time')
% title('theta & L tr using mean()')
% 
% figure
% imagesc(10*log10(th_ltr_bs_avg)'); axis xy;
% colorbar
% ylabel('Channels')
% xlabel('Time')
% title('theta & L tr avg using 10k resample')
% 
% figure
% mean_diff = abs(10*log10(th_ltr_avg) - 10*log10(th_ltr_bs_avg));
% imagesc(mean_diff'); axis xy;
% colorbar
% caxis([0 0.02])
% ylabel('Channels')
% xlabel('Time')
% title("mean diff '10*log10()' ")

%% T-Stats
%

%% Generate t-stat and difference of means significance cut off
fprintf('waiting to calculate shuffled t-tests \n')
pause
NumSamp = 10000;
t1 = tic;
[sig_t_val] = Analysis.DelayedReach.LFP.shuffle_comparison(PowerArray, targetsT2, FreqBins, NumSamp, 'CompMethod', 't-test');
fprintf('end shuffle t\n')
toc(t1)

%%
fprintf('waiting to calculate shuffled perc-diffs \n')
pause
NumSamp = 10000;
t1 = tic;
[sig_perc_diffs] = Analysis.DelayedReach.LFP.shuffle_comparison(PowerArray, targetsT2, FreqBins, NumSamp, 'CompMethod', 'perc_diff');
perc_diffs = (RTAvgSpecs_Favg - LTAvgSpecs_Favg) ./ (RTAvgSpecs_Favg + LTAvgSpecs_Favg);
toc(t1) 
fprintf('end shuffle comparison\n')
%% t-stat for L v R array
% Means_LTargs_FBands : Tbin x Channels x Fbands
% Means_RTargs_FBands : Tbin x Channels x Fbands



% for i = 1:5
%     figure
%     imagesc(TimeBins, 1:60, t_vals(:,:,i)'); axis xy;
%     ts = sprintf('fbin %d t-stats', i);
%     title(ts)
%     xlabel('Time')
%     ylabel('Channels')
%     colorbar
% end
%%

% t_vals = Analysis.DelayedReach.LFP.TestFunc(LTSpecs, RTSpecs, FreqBins);
% mean_diffs = RTAvgSpecs_Favg - LTAvgSpecs_Favg;
% perc_diffs = (RTAvgSpecs_Favg - LTAvgSpecs_Favg) ./ (RTAvgSpecs_Favg + LTAvgSpecs_Favg);
% 
% sig_t_val_low = sig_t_val{1, 1};
% sig_t_val_high = sig_t_val{1, 2};
% % sig_mean_diff_low = sig_mean_diffs{1, 1};
% % sig_mean_diff_high = sig_mean_diffs{1, 2};
% 
% sig_perc_diffs_low = sig_perc_diffs{1, 1};
% sig_perc_diffs_high = sig_perc_diffs{1, 2};
%% Comparing T-Tests with Simple Mean Difference Proportion

% for c = 1:60
%     [~, loc] = ind2sub([10 6], c);
% 
%     fs = sprintf('perc-diffs Channel %d - %s - %s', c, string(GInfo.Hemisphere(loc)), string(GInfo.Location(loc)));
%     figure('Name', fs, 'NumberTitle', 'off', 'position', [-1919 121 1920 1083])
% 
%     for s = 1:5
%         subplot(5, 2, s + (s-1))
%         stlow = sig_t_val_low(:, c, s);
%         sthi = sig_t_val_high(:, c, s); 
%         atval = t_vals(:, c, s);
% 
% 
%         plot(TimeBins, atval, 'b')
%         hold on
%         plot(TimeBins, stlow, 'k:')
%         plot(TimeBins, sthi, 'k:')
%         
%         ax = gca;
%         Ylimits = ax.YLim;
%         Vx = [move_start; move_start];
%         Vy = Ylimits' .* ones(2, length(move_start));
%         plot(Vx, Vy, 'k--')
%         ax.YLim = Ylimits;
%         
% 
%         hold off
%         if s == 1
%             ts = sprintf('%s - Ch%d - ttest ',fband_names{s}, c);
%             title(ts)
%         else
%             ts = sprintf('%s - ttest',fband_names{s});
%             title(ts)
%         end
%     end 
%     for s = 1:5
%         subplot(5, 2, (s+1) + (s-1))
% %         smd_low = sig_mean_diff_low(:, c, s);
% %         smd_hi = sig_mean_diff_high(:, c, s);
% %         amd = mean_diffs(:, c, s);
%         smd_low = sig_perc_diffs_low(:, c, s);
%         smd_hi = sig_perc_diffs_high(:, c, s);
%         amd = perc_diffs(:, c, s);
% 
% 
%         plot(TimeBins, amd, 'b')
%         hold on
%         plot(TimeBins, smd_low, 'k')
%         plot(TimeBins, smd_hi, 'k')
%         
%         ax = gca;
%         Ylimits = [-1 1];
%         Vx = [move_start; move_start];
%         Vy = Ylimits' .* ones(2, length(move_start));
%         plot(Vx, Vy, 'k--')
%         ax.YLim = Ylimits;
%         
%         hold off
% 
%         if s == 1
%             ts = sprintf('%s - Ch%d - (R-L)/(R+L)',fband_names{s},c);
%             title(ts)
%         else
%             ts = sprintf('%s - RvL',fband_names{s});
%             title(ts)
%         end
%     end
% end


% mean_thresh_low = sig_mean_diffs{1, 1};
% mean_thresh_high = sig_mean_diffs{1, 2};
% 
% for c = 1:5
%     fs = sprintf('Means Channel %d', c);
% 
%     figure('Name', fs)
%     for s = 1:5
%         subplot(5, 1, s)
%         smd_low = mean_thresh_low(:, c, s);
%         smd_hi = mean_thresh_high(:, c, s);
%         amd = mean_diffs(:, c, s);
% 
% 
%         plot(TimeBins, amd, 'b')
%         hold on
%         plot(TimeBins, smd_low, 'k')
%         plot(TimeBins, smd_hi, 'k')
%         hold off
%         if s == 1
%             ts = sprintf('Means Channel %d', c);
%             title(ts)
%         end
%     end
% end

%% Plotting Location Based Mean Diffs
% Right and Left anatomical locations on 1 figure
% Rotated to show targets left bias vs right bias as left or right in each
% subplot. Limiting # channels per lead

fband_names = {'Theta 4-8Hz' 'Alpha 8-12Hz' 'Beta 12-30Hz' 'Low Gamma 30-80Hz'...
    'High Gamma 80-200Hz'};
y_range = [-0.5 0.5];
num_cols = 7;

for f = 1:5
    
    FigTitle = sprintf('%s L or R Bias - L and R Amygdala', fband_names{f});
    figure('Name', FigTitle, 'NumberTitle', 'off','position', [-1919 121 1920 1083])
    ch_range1 = 41:50;
    ch_range2 = 51:60;
    for c = 1:num_cols
        ch = ch_range1(c);
        subplot(2, num_cols, c)
        plot(TimeBins, perc_diffs(:,ch,f))
        hold on
        plot(TimeBins, sig_perc_diffs_low(:,ch,f), 'k--')
        plot(TimeBins, sig_perc_diffs_high(:,ch,f), 'k--')
        plot([TimeBins(1) TimeBins(end)], [0 0], 'k')
        view([90 -90])
        xlim([TimeBins(1) TimeBins(end)])
        ylim(y_range)
        hold off
        ts = sprintf('Ch %d', ch);
        title(ts)
    end
    for c = num_cols+1:num_cols+num_cols
        ch = ch_range2(c-num_cols);
        subplot(2, num_cols, c)
        plot(TimeBins, perc_diffs(:,ch,f))
        hold on
        plot(TimeBins, sig_perc_diffs_low(:,ch,f), 'k--')
        plot(TimeBins, sig_perc_diffs_high(:,ch,f), 'k--')
        plot([TimeBins(1) TimeBins(end)], [0 0], 'k')
        view([90 -90])
        xlim([TimeBins(1) TimeBins(end)])
        ylim(y_range)
        hold off
        ts = sprintf('Ch %d', ch);
        title(ts)
    end
    anno_str = sprintf('%s L or R Bias', fband_names{f});
    annotation('textbox', [0.48 0.95 0.15 0.05], 'String', anno_str, 'FitBoxToText', 'on', 'FontWeight', 'bold')
    annotation('textbox', [0.49 0.92 0.15 0.05], 'String', 'Left Amygdala', 'FitBoxToText', 'on')
    annotation('textbox', [0.49 0.45 0.15 0.05], 'String', 'Right Amygdala', 'FitBoxToText', 'on')

    FigTitle = sprintf('%s L or R Bias - L and R Tail Hippocampus', fband_names{f});
    figure('Name', FigTitle, 'NumberTitle', 'off','position', [-1919 121 1920 1083])
    ch_range1 = 11:20;
    ch_range2 = 31:40;
    for c = 1:num_cols
        ch = ch_range1(c);
        subplot(2, num_cols, c)
        plot(TimeBins, perc_diffs(:,ch,f))
        hold on
        plot(TimeBins, sig_perc_diffs_low(:,ch,f), 'k--')
        plot(TimeBins, sig_perc_diffs_high(:,ch,f), 'k--')
        plot([TimeBins(1) TimeBins(end)], [0 0], 'k')
        view([90 -90])
        xlim([TimeBins(1) TimeBins(end)])
        ylim(y_range)
        hold off
        ts = sprintf('Ch %d', ch);
        title(ts)
    end
    for c = num_cols+1:num_cols+num_cols
        ch = ch_range2(c-num_cols);
        subplot(2, num_cols, c)
        plot(TimeBins, perc_diffs(:,ch,f))
        hold on
        plot(TimeBins, sig_perc_diffs_low(:,ch,f), 'k--')
        plot(TimeBins, sig_perc_diffs_high(:,ch,f), 'k--')
        plot([TimeBins(1) TimeBins(end)], [0 0], 'k')
        view([90 -90])
        xlim([TimeBins(1) TimeBins(end)])
        ylim(y_range)
        hold off
        ts = sprintf('Ch %d', ch);
        title(ts)
    end
    
    annotation('textbox', [0.48 0.95 0.15 0.05], 'String', anno_str, 'FitBoxToText', 'on', 'FontWeight', 'bold')
    annotation('textbox', [0.49 0.92 0.15 0.05], 'String', 'Left Tail Hippocampus', 'FitBoxToText', 'on')
    annotation('textbox', [0.49 0.45 0.15 0.05], 'String', 'Right Tail Hippocampus', 'FitBoxToText', 'on')


    FigTitle = sprintf('%s L or R Bias - L and R Head Hippocampus', fband_names{f});
    figure('Name', FigTitle, 'NumberTitle', 'off','position', [-1919 121 1920 1083])
    ch_range1 = 1:10;
    ch_range2 = 21:30;
    for c = 1:num_cols
        ch = ch_range1(c);
        subplot(2, num_cols, c)
        plot(TimeBins, perc_diffs(:,ch,f))
        hold on
        plot(TimeBins, sig_perc_diffs_low(:,ch,f), 'k--')
        plot(TimeBins, sig_perc_diffs_high(:,ch,f), 'k--')
        plot([TimeBins(1) TimeBins(end)], [0 0], 'k')
        view([90 -90])
        xlim([TimeBins(1) TimeBins(end)])
        ylim(y_range)
        hold off
        ts = sprintf('Ch %d', ch);
        title(ts)
    end
    for c = num_cols+1:num_cols+num_cols
        ch = ch_range2(c-num_cols);
        subplot(2, num_cols, c)
        plot(TimeBins, perc_diffs(:,ch,f))
        hold on
        plot(TimeBins, sig_perc_diffs_low(:,ch,f), 'k--')
        plot(TimeBins, sig_perc_diffs_high(:,ch,f), 'k--')
        plot([TimeBins(1) TimeBins(end)], [0 0], 'k')
        view([90 -90])
        xlim([TimeBins(1) TimeBins(end)])
        ylim(y_range)
        hold off
        ts = sprintf('Ch %d', ch);
        title(ts)
    end
    
    annotation('textbox', [0.48 0.95 0.15 0.05], 'String', anno_str, 'FitBoxToText', 'on', 'FontWeight', 'bold')
    annotation('textbox', [0.49 0.92 0.15 0.05], 'String', 'Left Head Hippocampus', 'FitBoxToText', 'on')
    annotation('textbox', [0.49 0.45 0.15 0.05], 'String', 'Right Head Hippocampus', 'FitBoxToText', 'on')

end

%% Scratch work for get_sig_integrals function
% exp_perc_diffs = (RTAvgSpecs_Favg - LTAvgSpecs_Favg) ./ (RTAvgSpecs_Favg + LTAvgSpecs_Favg);
% sig_perc_diffs_low = sig_perc_diffs{1, 1};
% sig_perc_diffs_high = sig_perc_diffs{1, 2};
% 
% t = perc_diffs(:,41,2);
% tl = sig_perc_diffs_low(:,41,2);
% th = sig_perc_diffs_high(:,41,2);
% 
% plot(TimeBins, t)
% hold on
% plot(TimeBins, tl, 'k:')
% plot(TimeBins, th, 'k:')
% 
% t_indx = t < tl;
% s = diff(t_indx); % for every t_indx(n-1), returns (t_indx(n) - t_indx(n-1))
% % so 0 0 1 1 1 0 0 -> 0 1 0 0 -1 0
% % so the -1 is the proper stop index, and the 1 is one place short of the
% % proper start index
% starts = find(s == 1) + 1; %list of starts
% stops = find(s == -1); %list of stops
% % which start and stop to use, or how to store integrals of all of them
% % will be another problem. Will probably not be able to pre-allocate for
% % this.
% 
% % potentially useful:
% % g = t .* t_indx; returns the just the values you want, rather than a
% % squeezed version that t(t_indx) would give you
% 
% x = TimeBins(starts(3):stops(3)); % Timebins for the big peak in this example (3rd)
% 
% y_main = t(starts(3):stops(3)); % y values of the percent difference line
% 
% y_minor = tl(sta(3):sto(3)); % y values of the sig threshold line
% 
% % integrals of each of those regions
% int_main = trapz(x, y_main);
% int_minor = trapz(x, y_minor);
% 
% % integral of the curve that crossed the sig threshold
% int_diff = int_main - int_minor;
% % this gives a negative value. To-Do: decide if we want to store all values
% % as positive. Since we're just plotting a distribution of values, prob ok
% % to keep negative.
% darkg = [40 90 40] ./ 255;
% 
% area(x, y_main, 'FaceColor', darkg, 'EdgeColor', 'none', 'FaceAlpha', 0.5)
% area(x, y_minor, 'FaceColor', 'white', 'EdgeColor', 'none')
% plot([TimeBins(1) TimeBins(end)], [0 0], 'k')
% xlim([TimeBins(1) TimeBins(end)])
% hold off

% To-Do: this all works, but there are gaps in the corners of each plot,
% highlighting an underlying problem/question. The area between the two
% curves is different than the area between the data points we have. matlab
% draws lines connecting points, and so we get an area where the lines
% cross before our data points register. 
% we can find where the lines cross
% http://www.mathworks.com/matlabcentral/fileexchange/22441-curve-intersections?
% but since we're using this integral as data, shouldn't it be calculated
% from our actual data points?

% Spencer says either way works. Going to continue as is.

accum_integrals = Analysis.DelayedReach.LFP.get_sig_integrals(perc_diffs, sig_perc_diffs, TimeBins);


%% Getting all integral values in one list to get distribution
% All channels, all frequency bins

all_integral_vals = [];
for c = 1:(60*5)
    if isempty(accum_integrals{c})
        continue
    end
    cell_vals = accum_integrals{c};
    all_integral_vals = [all_integral_vals; cell_vals(:,3)];
end

bins = -0.2245:0.001:0.219;
% z = find(bins == 0);
% bins(z) = [];
hist(all_integral_vals, bins)
hold on
all_integral_vals = sort(all_integral_vals);
min_val = all_integral_vals(1);
nan_idx = isnan(all_integral_vals);
first_nan = find(nan_idx == 1, 1, 'first');
just_integral_vals = all_integral_vals(1:first_nan-1);
low_index = floor(0.05 * length(just_integral_vals));
high_index = ceil(0.95 * length(just_integral_vals));
low_val = just_integral_vals(low_index);
high_val = just_integral_vals(high_index);
ax = gca;
plot([low_val high_val; low_val high_val], [ax.YLim(1) ax.YLim(1); ax.YLim(2) ax.YLim(2)], 'k:')