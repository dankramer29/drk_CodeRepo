MovingWin     = [0.5 0.05]; %[WindowSize StepSize]
Tapers        = [5 9]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass         = [0 200]; %frequency range of the output data
TrialAve      = 0; %Average later
Fs            = blc.SamplingRate;
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, ...
    'trialave', TrialAve, 'Fs', Fs); 
gpuflag       = true;

[OA1, ft1] = chronux_gpu.ct.mtspectrumc(trial_avg_nd{1,1}, ChrParams, [], gpuflag);
figure
plot(ft1, 10*log10(OA1(:,1)));
title('Tapers [5 9]')


Tapers = [6 11];
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, ...
    'trialave', TrialAve, 'Fs', Fs); 
[OA2, ft2] = chronux_gpu.ct.mtspectrumc(trial_avg_nd{1,1}, ChrParams, [], gpuflag);
figure
plot(ft2, 10*log10(OA2(:,1)));
title('Tapers [6 11]')

Tapers = [10 19];
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, ...
    'trialave', TrialAve, 'Fs', Fs); 
[OA3, ft3] = chronux_gpu.ct.mtspectrumc(trial_avg_nd{1,1}, ChrParams, [], gpuflag);
figure
plot(ft3, 10*log10(OA3(:,1)));
title('Tapers [10 19]')




%%
tand = trial_avg_nd;

for p = 1:5
    minL = length(trial_avg_nd{1,p});
    for t = 1:8
        tempc = tand{t, p};
        tempL = sum(~any(isnan(tempc), 2));
        minL = min(minL, tempL);
    end
    for t = 1:8
        tempc = tand{t, p};
        tand{t, p} = tempc(1:minL, :);
    end
end

%% common avg reference
common_avg = cell(size(targ_phase_dt));
targ_phase_dt_cavg = cell(size(targ_phase_dt));

for t = 1:8
    for p = 1:5
        subphase = targ_phase_dt{t,p};
        cavg = mean(subphase, 2);
        common_avg{t, p} = cavg;
        targ_phase_dt_cavg{t, p} = subphase - cavg;
    end
end

%% use common avg reference to reprocess
trial_avg_nd = cell(8, num_phase);
for i = 1:numel(targ_phase_dt_cavg)
    trial_avg_nd{i} = nanmean(targ_phase_dt_cavg{i}, 3);
end
%%
% Tapers = [3 5];
% Pad = 1;
% ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, ...
%     'trialave', TrialAve, 'Fs', Fs); 
% 
% trial_avg_spectrums = cell(8,num_phase);
% trial_avg_spectrum_fbins = cell(1,num_phase);
% 
% for t = 1:8
%     for p = 1:num_phase
%         [trial_avg_spectrums{t, p}, trial_avg_spectrum_fbins{1, p}] = chronux_gpu.ct.mtspectrumc(tand{t,p},...
%         ChrParams, [], gpuflag);
%     end
% end

 
trial_avg_spectrums = cell(8,num_phase);
% trial_avg_spectrum_fbins = cell(1,num_phase);

for t = 1:8
    for p = 1:num_phase
        trial_avg_spectrums{t, p} = squeeze(nanmean(trial_avg_specs_ph{t, p}, 1));
    end
end

%%
chan = 1;
targ = 1;
bar_colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880];
title_str = sprintf('Channel %d Target %d Averaged Spectrums', chan, targ);
figure
for p = 1:5
    plot(trial_avg_fbins{1,p}, 10*log10(trial_avg_spectrums{targ,p}(:,chan)), 'Color', bar_colors(p,:), 'LineWidth', 0.25, 'LineStyle', '-')
    hold on
end
hold off
xlabel('Frequency (Hz)')
ylabel('10*log10(spectrogram)')
title(title_str)
legend(phase_names)
%%
chan = 48;
targ = 2;
bar_colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880];
title_str = sprintf('Channel %d Target %d Averaged Spectrums', chan, targ);
figure
for p = 1:5
    plot(trial_avg_fbins{1,p}, 10*log10(trial_avg_spectrums{targ,p}(:,chan)), 'Color', bar_colors(p,:), 'LineWidth', 0.25, 'LineStyle', '-')
    hold on
end
hold off
xlabel('Frequency (Hz)')
ylabel('10*log10(spectrogram)')
title(title_str)
legend(phase_names)

%%
allT_iti = dt{1,1}(:,chan_range(1):chan_range(2),:);
allT_delay = dt{1,4}(:,chan_range(1):chan_range(2),:);
allT_respond = dt{1,5}(:,chan_range(1):chan_range(2),:);

% remov_chan = 32;
% allT_iti(:, remov_chan, :) = [];
% allT_delay(:, remov_chan, :) = [];
% allT_respond(:, remov_chan, :) = [];

allT_avgd = cell(1, 3);

% cavg = nanmean(allT_iti, 2);
% new_allT = allT_iti - cavg;
% allT_ph_avgd = nanmean(new_allT, 3);
% 
% allT_avgd{1, 1} = allT_ph_avgd;
% 
% cavg = nanmean(allT_delay, 2);
% new_allT = allT_delay - cavg;
% allT_ph_avgd = nanmean(new_allT, 3);
% allT_avgd{1, 2} = allT_ph_avgd;
% 
% cavg = nanmean(allT_respond, 2);
% new_allT = allT_respond - cavg;
% allT_ph_avgd = nanmean(new_allT, 3);
% allT_avgd{1, 3} = allT_ph_avgd;

allT_avgd{1,1} = nanmean(allT_iti, 3);
allT_avgd{1,2} = nanmean(allT_delay, 3);
allT_avgd{1,3} = nanmean(allT_respond, 3);


allT_avgd_specgrams = cell(1,3);
allT_avgd_spectrums = cell(1,3);
allT_avgd_fbins = cell(1,3);
allT_avgd_tbins = cell(1,3);

for p = 1:3
    [allT_avgd_specgrams{1, p}, allT_avgd_fbins{1, p}, allT_avgd_tbins{1, p}] = Analysis.DelayedReach.LFP.multiSpec(allT_avgd{1,p},...
    'spectrogram', 'Parameters', ChrParams, ...
    'gpuflag', gpuflag);
    allT_avgd_spectrums{1, p} = squeeze(nanmean(allT_avgd_specgrams{1, p}, 1));
end


chan = 48;
bc = [0 0.4470 0.7410; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880];
title_str = sprintf('Channel %d - All Trials Averaged - Spectrums', chan);
figure
for p = 1:3
    plot(allT_avgd_fbins{1,p}, 10*log10(allT_avgd_spectrums{1,p}(:,chan)), 'Color', bc(p,:), 'LineWidth', 0.25, 'LineStyle', '-')
    hold on
end
ax = gca;
plot([8 32; 8 32], [ax.YLim(1) ax.YLim(1); ax.YLim(2) ax.YLim(2)], 'k:')
plot([76 100; 76 100], [ax.YLim(1) ax.YLim(1); ax.YLim(2) ax.YLim(2)], 'k:')
hold off
xlabel('Frequency (Hz)')
ylabel('10*log10(spectrogram)')
title(title_str)
legend({'ITI', 'Delay', 'Respond'})


bc = [0 0.4470 0.7410; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880];
title_str = sprintf('All Trials Averaged - All Channel Spectrums Avgd');
figure
for p = 1:3
    plot(allT_avgd_fbins{1,p}, 10*log10(squeeze(mean(allT_avgd_spectrums{1,p}, 2))), 'Color', bc(p,:), 'LineWidth', 0.25, 'LineStyle', '-')
    hold on
end
ax = gca;
plot([8 32; 8 32], [ax.YLim(1) ax.YLim(1); ax.YLim(2) ax.YLim(2)], 'k:')
plot([76 100; 76 100], [ax.YLim(1) ax.YLim(1); ax.YLim(2) ax.YLim(2)], 'k:')
hold off
xlabel('Frequency (Hz)')
ylabel('10*log10(spectrogram)')
title(title_str)
legend({'ITI', 'Delay', 'Respond'})
