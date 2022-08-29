% 01    02    03    04    05    06    07    08    09    10    
% 17    18    19    20    21    22    23    24    25    26    
% 33    34    35    36    37    38    39    40    41    42    
% 
% 
% L head hippo 1-10 (1-10)- 
% R head hippo 11-20 (17-26)
% L amygdala 21-30 (33-42)
% 
% 
% Bank D is reference.
% TotalChanArray = cell2mat(gridMapObj.GridInfo.Channels)';
TotalChanArray = [1:10 17:26 33:42 ]; % all channels recording neural data

RecordingDay = 2; 
RecordingType = 1;
env.set('Data', '\\striatum\Data\neural\working')


if RecordingDay == 1
    taskObj = FrameworkTask('\\striatum\Data\neural\working\P019\20180406\Task\20180406-123800-124257-DelayedReach.mat'); 
elseif RecordingDay == 2
    if RecordingType == 1
        taskObj = FrameworkTask('\\striatum\Data\neural\working\P019\20180410\Task\20180410-100230-102903-DelayedReach.mat'); % Second Day
    elseif RecordingType == 2
        env.set('Data', 'C:\Users\Mike\Documents\Data');
        taskObj = FrameworkTask('C:\Users\Mike\Documents\Data\P019\Task\20180410-100230-102903-DelayedReach.mat');
    end
end

ns = taskObj.getNeuralDataObject('NSP1', 'ns3');
ns = ns{1};
TaskString = string(regexp(taskObj.taskString, '\d*-(.*)', 'tokens'));

% gridMapObj = GridMap('\\striatum\Data\neural\incoming\unsorted\keck\angulo\P015\gridmap.map');
% % gridMapObj.GridInfo: Location names and hemispheres, channel list out of
% % total channels (x/90). gridMapObj.GridChannelIndex: each column has column
% % vector of channel #s out of recorded channels (x/60).
% GInfo = gridMapObj.GridInfo;
% ChanIdx = cell2mat(gridMapObj.GridChannelIndex);
% % LocationNames = {'Amygdala', 'HeadHippocampus', 'TailHippocampus'};
% % HemisphereNames = {'Left', 'Right'};
% % 
% % [channels, channel_key] = Analysis.DelayedReach.LFP.get_channels_for_location(GridMapObj, LocationNames, HemisphereNames);

Targets = arrayfun(@(x)x.tr_prm.targetID,taskObj.trialdata)';
phase_times = [taskObj.phaseTimes];
trial_times = [taskObj.trialTimes];
phase_times(:,end+1) = phase_times(:,1) + trial_times(:,2); % trial start + trial duration = trial end
phase_times_relT = phase_times - phase_times(:,1); % phase times relative to start time (phase 1)
phase_names = [taskObj.phaseNames];

DtClass = 'single';
% %Just return relative times not neural data
% [~, RelTCheck, ~] = proc.blackrock.broadband(...
%    ns, DtClass, 'CHANNELS', TotalChanArray, 'Uniformoutput', true);

%% Day 2 Specific
% screensaver came on during trial # 59, 60 on the second day of recording
if RecordingDay == 2 && length(Targets) == 64
    Targets(59:60,:) = [];
    phase_times(59:60,:) = [];
    trial_times(59:60,:) = [];
    phase_times_relT(59:60,:) = [];
end


%% Extract Voltage Neural Data
[ND, RelT, ~] = proc.blackrock.broadband(...
    ns, 'PROCWIN', trial_times, DtClass, 'CHANNELS', TotalChanArray);

% [ND, RelT, ~] = proc.blackrock.broadband(...
%     ns, DtClass, 'CHANNELS', TotalChanArray);

RelT_phase_idx = Analysis.DelayedReach.LFP.match_relative_times(RelT, phase_times_relT);

%% Align Trials, Clip to Equal Lengths
% takes 6 seconds before and 3 seconds after phase #4
pre_samples = ns.Fs * 6; % 6 seconds of samples
post_samples = ns.Fs * 3; % 3 seconds of samples
phase = 5; %action phase start
VertLineCoords = 6;

trial_nd_cell = cell(1,length(RelT));
trial_relt_cell = cell(1,length(RelT));

for tr = 1:length(RelT)
    start_idx = RelT_phase_idx(tr, phase) - pre_samples;
    stop_idx = RelT_phase_idx(tr, phase) + post_samples;
    trial_nd_cell{1,tr} = ND{1, tr}(start_idx:stop_idx, :);
    trial_relt_cell{1,tr} = RelT{1, tr}(start_idx:stop_idx, :);
end


trial_nd = proc.helper.createUniformOutput(trial_nd_cell);
% t_rel = 3:(1/2000):8;
if RecordingType == 2;
    common_avg = mean(trial_nd, 2);
    common_avg_ref = repmat(common_avg, [1 30 1]);
    trial_nd = trial_nd - common_avg_ref;
end
% Analysis.DelayedReach.LFP.plotNeuralDataTrials(trial_nd, Targets, t_rel, TaskString, 'VertLineCoords', VertLineCoords)

%% Make Spectrograms
%Initialize Chronux Parameters
MovingWin     = [0.5 0.05]; %[WindowSize StepSize]
Tapers        = [5 9]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass         = [0 200]; %frequency range of the output data
TrialAve      = 0; %Average later
Fs            = ns.Fs;
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, ...
    'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
gpuflag       = true;

% [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(NeuralData,1), MovingWin, DtClass);
[PowerArray, FreqBins, TimeBins] = Analysis.DelayedReach.LFP.multiSpec(trial_nd,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
    'gpuflag', gpuflag);
TimeBins = TimeBins - TimeBins(1);

%% Plot Tuning Figures

% [targ_ph_chan_avg, TimeBins_to_phase_all, TimeBins_to_phase_avg] = Analysis.DelayedReach.LFP.check_tuning(...
%     PowerArray, TimeBins, FreqBins, Targets, phase_times_relT, phase_names, TaskString, varargin);
%% Select Left and Right Target Trials

%  Left Targets = 8, 7, 6
LTTrialsIdx = Targets == 6 | Targets == 7 | Targets == 8;
fprintf('# L Target Trials: %d\n', sum(LTTrialsIdx))

%  Right Targets = 2, 3, 4
RTTrialsIdx = Targets == 2 | Targets == 3 | Targets == 4;
fprintf('# R Target Trials: %d\n', sum(RTTrialsIdx))

%% Index and Average by Trial
% *Take trials for L targets and average*
LTSpecs = PowerArray(:, :, :, LTTrialsIdx);
LTAvgSpecs = mean(LTSpecs, 4);

% *Take trials for R targets and average*
RTSpecs = PowerArray(:, :, :, RTTrialsIdx);
RTAvgSpecs = mean(RTSpecs, 4);

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
    
%% Mean Confidence Intervals
NumSamp = 10000;
tic
[Means_CIs_Left, Means_CIs_Right] = Analysis.DelayedReach.LFP.shuffleCI(LTSpecs, RTSpecs, NumSamp, FreqBins);
toc

% %% Plotting all channels' CIs for all frequency bands L and R means
% move_start = 2;
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
% for ch = 1:size(LTAvgSpecs, 3)
%     FigTitle = sprintf('%s-FBand-MeanCI-Channel%d',TaskString, ch);
%     figure('Name', FigTitle, 'NumberTitle', 'off', 'units', 'normalized',...
%         'outerposition', [-0.75 0.08 0.75 0.8], 'PaperPositionMode', 'auto');
%     for s = 1:size(CI_Low_LTargs_FBands, 3)
%         subplot_tight(5, 1, s, [0.035 0.045])
%         lx1 = 10*log10(LTAvgSpecs_Favg(:, ch, s));
%         lx2 = 10*log10(CI_Low_LTargs_FBands(:, ch, s));
%         lx3 = 10*log10(CI_High_LTargs_FBands(:, ch, s));
%         h1 = plot_ci(TimeBins, [lx1 lx2 lx3], 'LineColor', lb, 'MainLineColor', darkb, 'PatchColor', lb, 'PatchAlpha', 0.4);
%         hold on
% 
%         rx1 = 10*log10(RTAvgSpecs_Favg(:, ch, s));
%         rx2 = 10*log10(CI_Low_RTargs_FBands(:, ch, s));
%         rx3 = 10*log10(CI_High_RTargs_FBands(:, ch, s));
%         h2 = plot_ci(TimeBins, [rx1 rx2 rx3], 'LineColor', lr, 'MainLineColor', darkr, 'PatchColor', lr, 'PatchAlpha', 0.4);
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
%         xlim([TimeBins(1) TimeBins(end)])
%         ts = sprintf('%s - Ch%d',fband_names{s},ch);
%         title(ts);
%         if s ==1
%             legend([h1.Patch h1.Plot h2.Patch h2.Plot], {'L Trials CI', 'L Trials Mean', 'R Trials CI', 'R Trials Mean'});
% %             annotation('textbox', [VertLineCoords Ylimits(1)+1], 'String', 'effector show', 'FitBoxToText','on')
%             text(move_start, Ylimits(1)+1, 'Action Phase Start')
% 
%         end
%     end
% end
% % Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)
% clear CI_Low_LTargs_FBands CI_High_LTargs_FBands CI_Low_RTargs_FBands CI_High_RTargs_FBands