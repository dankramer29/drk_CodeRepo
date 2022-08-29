taskpath = 'C:\Users\Mike\Documents\Data\P015\20180130\Task\';
fileID   = '*CenterOut.mat';
FileList = ls(fullfile(taskpath, fileID));
%numfiles  = size(FileList,1);
GridMapObj = GridMap('C:\Users\Mike\Documents\Data\P015\gridmap.map');
DtClass = 'single';
fn = '20180130-132729-132950-CenterOut.mat';
fp = fullfile(taskpath, fn);

   
taskObjT2 = FrameworkTask(fp);
nsT2 = taskObjT2.getNeuralDataObject('NSP1', 'ns3');
nsT2 = nsT2{1};
targetsT2 = arrayfun(@(x)x.obj_target{1, 1}.targetCurrentIdx, taskObjT2.trialdata)';
targetsT2 = targetsT2(1:48);
targetsT2(21) = [];


phase_times = [taskObjT2.phaseTimes]; %2nd column is neural time of effector showing
% eff_show_times  = phase_times(1:48, 2);
eff_show_times  = round(phase_times(1:48, 2),3); %rounding fixes missaligned last sample of ND_C and ND_total
%can include the 48th trial if stop time is when the effector hits the target (just under 180s)
eff_show_times(21) = []; % #21 is a bad trial
num_trials = length(eff_show_times);
duration = 1;
duration_mat = duration * ones(num_trials, 1);
procwin_A = [eff_show_times-duration duration_mat]; % 1 sec of data prior to effector show
procwin_B = [eff_show_times duration_mat]; % 1 sec of data after effector show


end_frames = arrayfun(@(x) x.et_targetEnter{1}, taskObjT2.trialdata);
end_frames = end_frames(1:48)';
end_frames(21) = [];
end_neural_time = arrayfun(@(x) taskObjT2.data.neuralTime(x), end_frames);
end_neural_time = round(end_neural_time, 3); %rounding fixes missaligned last sample of ND_C and ND_total
procwin_C = [end_neural_time-duration duration_mat];

trial_starts = phase_times(1:48, 1);
trial_starts(21) = [];
new_trial_durations = end_neural_time - procwin_A(:,1);
procwin_total = [procwin_A(:,1) new_trial_durations];

LocationNames = {'Amygdala', 'HeadHippocampus', 'TailHippocampus'};
HemisphereNames = {'Left', 'Right'};

[channels, channel_key] = Analysis.DelayedReach.LFP.get_channels_for_location(GridMapObj, LocationNames, HemisphereNames);



[ND_A, RelT_A, ~] = proc.blackrock.broadband(...
    nsT2, 'PROCWIN', procwin_A, DtClass, 'CHANNELS', channels,...
    'Uniformoutput', true);

[ND_B, RelT_B, ~] = proc.blackrock.broadband(...
    nsT2, 'PROCWIN', procwin_B, DtClass, 'CHANNELS', channels,...
    'Uniformoutput', true);

[ND_C, RelT_C, ~] = proc.blackrock.broadband(...
    nsT2, 'PROCWIN', procwin_C, DtClass, 'CHANNELS', channels,...
    'Uniformoutput', true);

[ND_total, RelT_total, ~] = proc.blackrock.broadband(...
    nsT2, 'PROCWIN', procwin_total, DtClass, 'CHANNELS', channels);

row = 1;
trial_num = 3;
figure
subplot(4,1,1)
plot(RelT_A, ND_A(:, row, trial_num))
ts = sprintf('Window A %s Ch %d Trial %d', channel_key(row), channels(row), trial_num);
title(ts)

subplot(4,1,2)
plot(RelT_B, ND_B(:, row, trial_num))
ts = sprintf('Window B %s Ch %d Trial %d', channel_key(row), channels(row), trial_num);
title(ts)

subplot(4,1,3)
plot(RelT_C, ND_C(:, row, trial_num))
ts = sprintf('Window C %s Ch %d Trial %d', channel_key(row), channels(row), trial_num);
title(ts)

subplot(4,1,4)
plot(RelT_total{trial_num}, ND_total{trial_num}(:, row))
ts = sprintf('Window Total %s Ch %d Trial %d', channel_key(row), channels(row), trial_num);
title(ts)

% for i = 1:47
%     if ND_C(end,1,i) ~= ND_total{i}(end,1)
%         fprintf('Trial # %d \n', i)
%     end
% end
% 
% % ND_total will have 1 sample past ND_C end point, or ND_C will have 1
% % sample past ND_total end point
% % Trial # 1 
% % Trial # 6 
% % Trial # 7 
% % Trial # 11 
% % Trial # 13 
% % Trial # 15 
% % Trial # 17 
% % Trial # 19 
% % Trial # 25 
% % Trial # 31 
% % Trial # 34 
% % Trial # 36 
% % Trial # 46 
% 
% for i = 1:47
%     total = ND_total{i};
%     sub = ND_A(:,:,i);
%     for c = 1:60
%         if sub(1,c) ~= total(1,c)
%             fprintf('Trial # %d Channel %d\n', i, c)
%         end
%     end
% end
% % all starting starting samples are the same though, so something about the
% % duration of procwin_total or starting value of procwin_c is the problem
% % and it might be a rounding error, but I can't find the pattern to fix it.
% % 

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
[pa_A, fb_A, tb_A] = Analysis.DelayedReach.LFP.multiSpec(ND_A,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
    'gpuflag', gpuflag);

[pa_B, fb_B, tb_B] = Analysis.DelayedReach.LFP.multiSpec(ND_B,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
    'gpuflag', gpuflag);
[pa_C, fb_C, tb_C] = Analysis.DelayedReach.LFP.multiSpec(ND_C,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
    'gpuflag', gpuflag);

specs_total = cell(3,47);
for t = 1:47
    nd = ND_total{t};
    [pa, fb, tb] = Analysis.DelayedReach.LFP.multiSpec(nd,...
        'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
        'gpuflag', gpuflag);
    specs_total{1,t} = pa;
    specs_total{2,t} = fb;
    specs_total{3,t} = tb;
end

%%
%  Left Targets = 8, 7, 6
LTTrialsIdx = targetsT2 == 6 | targetsT2 == 7 | targetsT2 == 8;
fprintf('# L Target Trials: %d\n', sum(LTTrialsIdx))

%  Right Targets = 2, 3, 4
RTTrialsIdx = targetsT2 == 2 | targetsT2 == 3 | targetsT2 == 4;
fprintf('# R Target Trials: %d\n', sum(RTTrialsIdx))

% *Take trials for L targets and average*
LTSpecs_A = pa_A(:, :, :, LTTrialsIdx);
LTAvgSpecs_A = mean(LTSpecs_A, 4);

% *Take trials for R targets and average*
RTSpecs_A = pa_A(:, :, :, RTTrialsIdx);
RTAvgSpecs_A = mean(RTSpecs_A, 4);

% *Take trials for L targets and average*
LTSpecs_B = pa_B(:, :, :, LTTrialsIdx);
LTAvgSpecs_B = mean(LTSpecs_B, 4);

% *Take trials for R targets and average*
RTSpecs_B = pa_B(:, :, :, RTTrialsIdx);
RTAvgSpecs_B = mean(RTSpecs_B, 4);

% *Take trials for L targets and average*
LTSpecs_C = pa_C(:, :, :, LTTrialsIdx);
LTAvgSpecs_C = mean(LTSpecs_C, 4);

% *Take trials for R targets and average*
RTSpecs_C = pa_C(:, :, :, RTTrialsIdx);
RTAvgSpecs_C = mean(RTSpecs_C, 4);

% AvgSpecs_total = cell(2,47);
% for t = 1:47
%     pa = specs_total{1,t};
%     fb = 
%     [pa, fb, tb] = Analysis.DelayedReach.LFP.multiSpec(nd,...
%         'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
%         'gpuflag', gpuflag);
%     specs_total{1,t} = pa;
%     specs_total{2,t} = fb;
%     specs_total{3,t} = tb;
% end

ThetaLogical  = fb_A > 4  & fb_A < 8;
AlphaLogical  = fb_A > 8  & fb_A < 12;
BetaLogical   = fb_A > 12 & fb_A < 30;
LGammaLogical = fb_A > 30 & fb_A < 80;
HGammaLogical = fb_A > 80 & fb_A < 200;
FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
clear ThetaLogical AlphaLogical BetaLogical LGammaLogical HGammaLogical

Num_Fbands = size(FreqLog, 1);
Num_Tb = size(LTAvgSpecs_A, 1);
Num_Ch = size(LTAvgSpecs_A, 3);
LTAvgSpecs_Favg_A = zeros(Num_Tb, Num_Ch, Num_Fbands);
RTAvgSpecs_Favg_A = zeros(Num_Tb, Num_Ch, Num_Fbands);

for f = 1:5
    L_slice = LTAvgSpecs_A(:, FreqLog(f, :), :);
    R_slice = RTAvgSpecs_A(:, FreqLog(f, :), :);
    LTAvgSpecs_Favg_A(:,:,f) = squeeze(mean(L_slice, 2));
    RTAvgSpecs_Favg_A(:,:,f) = squeeze(mean(R_slice, 2));
end
clear f L_slice R_slice

Num_Fbands = size(FreqLog, 1);
Num_Tb = size(LTAvgSpecs_B, 1);
Num_Ch = size(LTAvgSpecs_B, 3);
LTAvgSpecs_Favg_B = zeros(Num_Tb, Num_Ch, Num_Fbands);
RTAvgSpecs_Favg_B = zeros(Num_Tb, Num_Ch, Num_Fbands);

for f = 1:5
    L_slice = LTAvgSpecs_B(:, FreqLog(f, :), :);
    R_slice = RTAvgSpecs_B(:, FreqLog(f, :), :);
    LTAvgSpecs_Favg_B(:,:,f) = squeeze(mean(L_slice, 2));
    RTAvgSpecs_Favg_B(:,:,f) = squeeze(mean(R_slice, 2));
end
clear f L_slice R_slice

Num_Fbands = size(FreqLog, 1);
Num_Tb = size(LTAvgSpecs_C, 1);
Num_Ch = size(LTAvgSpecs_C, 3);
LTAvgSpecs_Favg_C = zeros(Num_Tb, Num_Ch, Num_Fbands);
RTAvgSpecs_Favg_C = zeros(Num_Tb, Num_Ch, Num_Fbands);

for f = 1:5
    L_slice = LTAvgSpecs_C(:, FreqLog(f, :), :);
    R_slice = RTAvgSpecs_C(:, FreqLog(f, :), :);
    LTAvgSpecs_Favg_C(:,:,f) = squeeze(mean(L_slice, 2));
    RTAvgSpecs_Favg_C(:,:,f) = squeeze(mean(R_slice, 2));
end
clear f L_slice R_slice

%%
NumSamp = 10000;

[Means_CIs_Left_A, Means_CIs_Right_A] = Analysis.DelayedReach.LFP.shuffleCI(LTSpecs_A, RTSpecs_A, NumSamp, fb_A);
[Means_CIs_Left_B, Means_CIs_Right_B] = Analysis.DelayedReach.LFP.shuffleCI(LTSpecs_B, RTSpecs_B, NumSamp, fb_B);
[Means_CIs_Left_C, Means_CIs_Right_C] = Analysis.DelayedReach.LFP.shuffleCI(LTSpecs_C, RTSpecs_A, NumSamp, fb_C);

% Means_CIs_total = cell(2,47);
% for t = 1:47
%     pa = specs_total{1,t};
%     fb = 
%     [pa, fb, tb] = Analysis.DelayedReach.LFP.multiSpec(nd,...
%         'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
%         'gpuflag', gpuflag);
%     specs_total{1,t} = pa;
%     specs_total{2,t} = fb;
%     specs_total{3,t} = tb;
% end
%%
%% Plotting all channels' CIs for all frequency bands L and R means
fprintf('waiting to plot all channel CIs for frequency band and trial averaged L and R trials\n')


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
CI_Low_LTargs_FBands = Means_CIs_Left_A{2}; % Tbin x Channels x Fbands
CI_High_LTargs_FBands = Means_CIs_Left_A{3}; % Tbin x Channels x Fbands

% Means_RTargs_FBands = Means_CIs_Right{1}; % Tbin x Channels x Fbands
% Use RTAvgSpecs_Favg ; Tbin x Channels x Fbands
CI_Low_RTargs_FBands = Means_CIs_Right_A{2}; % Tbin x Channels x Fbands
CI_High_RTargs_FBands = Means_CIs_Right_A{3}; % Tbin x Channels x Fbands

for ch = 1:5
    [~, loc] = ind2sub([10 6], ch);
    FigTitle = sprintf('A Targ-FBand-MeanCI-Channel%d-%s', channels(ch), channel_key(ch));
    figure('Name', FigTitle, 'NumberTitle', 'off', 'units', 'normalized',...
        'outerposition', [-0.75 0.08 0.75 0.8], 'PaperPositionMode', 'auto');
    for s = 1:5
        subplot_tight(5, 1, s, [0.035 0.045])
        lx1 = 10*log10(LTAvgSpecs_Favg_A(:, ch, s));
        lx2 = 10*log10(CI_Low_LTargs_FBands(:, ch, s));
        lx3 = 10*log10(CI_High_LTargs_FBands(:, ch, s));
        h1 = plot_ci(tb_A, [lx1 lx2 lx3], 'LineColor', lb, 'MainLineColor', darkb, 'PatchColor', lb, 'PatchAlpha', 0.4);
        hold on

        rx1 = 10*log10(RTAvgSpecs_Favg_A(:, ch, s));
        rx2 = 10*log10(CI_Low_RTargs_FBands(:, ch, s));
        rx3 = 10*log10(CI_High_RTargs_FBands(:, ch, s));
        h2 = plot_ci(tb_A, [rx1 rx2 rx3], 'LineColor', lr, 'MainLineColor', darkr, 'PatchColor', lr, 'PatchAlpha', 0.4);
        
        ax = gca;
        Ylimits = ax.YLim;
        Vx = [1; 1];
        Vy = Ylimits' .* ones(2, 1);
        plot(Vx, Vy, 'k--')
        ax.YLim = Ylimits;


        hold off
        xlim([tb_A(1) tb_A(end)])
        ts = sprintf('%s - Ch%d',fband_names{s},channels(ch));
        title(ts);
        if s ==1
            legend([h1.Patch h1.Plot h2.Patch h2.Plot], {'L Trials CI', 'L Trials Mean', 'R Trials CI', 'R Trials Mean'});
%             annotation('textbox', [move_start Ylimits(1)+1], 'String', 'effector show', 'FitBoxToText','on')
            text(1, Ylimits(1)+1, 'effector show')

        end
    end
end
Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)
clear CI_Low_LTargs_FBands CI_High_LTargs_FBands CI_Low_RTargs_FBands CI_High_RTargs_FBands