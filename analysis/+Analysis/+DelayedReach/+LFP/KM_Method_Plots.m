%% Plot a channel's tuning
td = P012.RIP.Ph34.tuning.HZ_76_100;
ch = 8;

targs = 1:8;
fr = td.fit_data.fit_result{ch,1};
sh_pwer = td.fit_data.shifts.shifted_power(ch,:);
sh_trgs = td.fit_data.shifts.shifted_targets(ch,:);
sh_x = td.fit_data.shifts.shift_amt(ch,1);
sh_y = td.fit_data.shifts.shift_amt(ch,2);
rsqr = td.fit_data.gof.rsquare(ch,1);
excl = td.fit_data.gof.excluded(ch,:);

ydata = sh_pwer+ sh_y; %shift y data back to original values

figure
scatter(targs, ydata, 'filled');
hold on
p2 = plot(fr, 'k');
p2.YData = p2.YData + sh_y; %shift the gauss curve same amount as scatter data
set(gca, 'XTickLabel', sh_trgs)
legend([p2], {'Gaussian Fit'})
xlabel('Target Number')
ylabel('Average Activation HFB 76-100Hz')
ts = sprintf('Ch %d', ch);
title(ts)
fig_anno = sprintf('r^{2} = %0.3f', rsqr);
anno = annotation('textbox',...
        [0.7778 0.7113 0.1030 0.0628],...
        'VerticalAlignment','middle',...
        'String',fig_anno,...
        'HorizontalAlignment','center',...
        'FitBoxToText', 'on');

%%
temp_activs = FB_act;
temp_sigs = FB_sbs;
temp_fbrange = temp_fband;
temp_ts = sprintf('HFB [%d %d] activation P012 %s vs %s - %s', ...
    temp_fbrange(1), temp_fbrange(2), phase_names{phases(2)}, phase_names{phases(1)}, spec_grid);
FB_fig = figure('Name', temp_ts, 'NumberTitle', 'off');
temp_weights = temp_activs;% .* temp_sigs;
%pt specific brain coords as 'cortex' (a freesurfer thing)
%pt grid electrodes as 'elecmatrix'

Analysis.DelayedReach.LFP.plot_gauss_activation(temp_weights, elecmatrix, cortex);
hold on
plot3(elecmatrix(:,1)*1.01, elecmatrix(:,2), elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
title(temp_ts);
set(gcf, 'color', 'w')

clear temp_*
%% Plot a channel's spectrum for 2 phases
%phases = [2 5];

for chan = 2%1:length(chan_range)
    chan_as_record = table2array(sub_chaninfo(chan,1));
    chan_label = table2array(sub_chaninfo(chan,2));
    ph_names = phase_names(phases);

    title_str = sprintf('Ch %d %s - %s vs %s Normalized Spectra', chan_as_record, chan_label{1}, ph_names{1}, ph_names{2});

    bar_colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880];
    figure
    hold on
    %miti = log(mean(spectrums_cavg{1,1}(:,chan,:),3));
    for p = 1:length(phases)%num_phase
%         m_ph = mean(spectrums_cavg{1, phases(p)}(:,chan,:), 3);
        m_ph = mean(spectrums_cavg{1, phases(p)}(:,chan,targets==7), 3);
        plot(spectrums_cavg_fbins{1,p}, log(m_ph), ...
            'Color', bar_colors(phases(p),:), 'LineWidth', 0.25, 'LineStyle', '-')
%         plot(spectrums_cavg_fbins{1,p}, m_ph, ...
%             'Color', bar_colors(phases(p),:), 'LineWidth', 0.25, 'LineStyle', '-')
    end
    ax = gca;
%     plot([LFB_range(1) LFB_range(2); LFB_range(1) LFB_range(2)], [ax.YLim(1) ax.YLim(1); ax.YLim(2) ax.YLim(2)], 'k:')
%     plot([HFB_range(1) HFB_range(2); HFB_range(1) HFB_range(2)], [ax.YLim(1) ax.YLim(1); ax.YLim(2) ax.YLim(2)], 'k:')
    hold off
    xlabel('Frequency (Hz)')
    ylabel('log(spectrum power)')
    title(title_str)
    legend(ph_names)
%     xlim([0 spectrums_cavg_fbins{1, p}(end)])
    xlim([0 100])
    %pause
end

%% Polar plot only
    theta_deg=(0:45:360)'; %for polar plot rays
    theta=deg2rad(theta_deg);
    target_labels = {'1'; '2'; '3'; '4'; '5'; '6'; '7'; '8';};
    %figure('Name', 'Breakit', 'NumberTitle', 'off','position', [-1919 121 1920 1083])
    figure('Name', 'Breakit', 'NumberTitle', 'off','position', [0 0 1920 1080])
    r = [8:-1:1 16:-1:9 24:-1:17 32:-1:25 40:-1:33 48:-1:41 56:-1:49 64:-1:57];
    r = reshape(r, [8 8])';
    for i = i:length(chan_range)
        subplot_tight(2, 2, i, [0.08 0.08])
        chan = r(i);
        if chan ~= 4 & chan ~= 32
            if chan > 4 & chan < 32
                chan = chan - 1;
            elseif chan > 32
                chan = chan - 2;
            end
            chan_as_record = table2array(sub_chaninfo(chan,1));
            chan_label = table2array(sub_chaninfo(chan,2));
            ph_targ_avg = squeeze(spectrums_cavg_targ_LF(chan,:,:))';
            if size(ph_targ_avg, 1) < length(theta)
                ph_targ_avg(end+1,:) = ph_targ_avg(1,:); % add the first values to the end so the polar plot connects
            end
            polarplot(theta, ph_targ_avg)
            set(gca, 'ThetaDir', 'clockwise', 'ThetaZeroLocation', 'top', 'ThetaTick', theta_deg, 'ThetaTicklabel', target_labels)
            ts = sprintf('Ch%d %s', chan_as_record, chan_label{1});
            title(ts)
        elseif chan == 4
            ts = sprintf('Ch44 MP4 RM');
            title(ts)
        elseif chan == 32
            ts = sprintf('Ch72 MP32 RM');
            title(ts)
            continue
        end
    end

%% Spectral phase comparison AND tuning plots
% 
t_subplot_order = [8 1 2 7 0 3 6 5 4]; % makes subplotting in order easier
theta_deg=(0:45:360)'; %for polar plot rays
theta=deg2rad(theta_deg); %for polar plot coordinates
target_labels = {'1'; '2'; '3'; '4'; '5'; '6'; '7'; '8';};
bar_colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880];
bc = bar_colors(1:num_phase,:);
%phases = [2 5];
for chan = 17%%length(chan_range)
    chan_as_record = table2array(sub_chaninfo(chan,1));
    chan_label = table2array(sub_chaninfo(chan,2));
    ph_names = phase_names(phases);
    figtitle = sprintf('Ch %d %s - Spectrums %s vs %s', chan_as_record, chan_label{1}, ph_names{1}, ph_names{2});
    %figure('Name', figtitle, 'NumberTitle', 'off','position', [0 121 1920 1083])
    figure('Name', figtitle, 'NumberTitle', 'off','position', [0 0 1920 1080])
    for t = 1:length(t_subplot_order)
        if t == 5
            continue %skip the rest
        end
        target = t_subplot_order(t);
        subplot_tight(3, 3, t, [0.08 0.08])
        %%%%%
        hold on
        for p = 1:length(phases)%num_phase
            m_ph = mean(spectrums_cavg_targsort{target, phases(p)}(:,chan,:), 3);
            plot(spectrums_cavg_fbins{1,p}, log(m_ph), ...
                'Color', bar_colors(phases(p),:), 'LineWidth', 0.25, 'LineStyle', '-')
        end
        ax = gca;
        plot([LFB_range(1) LFB_range(2); LFB_range(1) LFB_range(2)], [ax.YLim(1) ax.YLim(1); ax.YLim(2) ax.YLim(2)], 'k:')
        plot([HFB_range(1) HFB_range(2); HFB_range(1) HFB_range(2)], [ax.YLim(1) ax.YLim(1); ax.YLim(2) ax.YLim(2)], 'k:')
        hold off
        xlabel('Frequency (Hz)')
        ylabel('log(spectrum power)')
        ts = sprintf('Ch %d %s - Target %d', chan_as_record, chan_label{1}, target);
        title(ts)
        legend(ph_names)
        xlim([0 spectrums_cavg_fbins{1, p}(end)])
    end
        %%%%%
        figtitle = sprintf('Ch %d %s - Polar Plots', chan_as_record, chan_label{1});
        %figure('Name', figtitle, 'NumberTitle', 'off','position', [-1919 121 1920 1083])
        figure('Name', figtitle, 'NumberTitle', 'off','position', [0 0 1920 1080])
        subplot_tight(1, 2, 1, [0.08 0.08])
        ph_targ_avg = squeeze(spectrums_cavg_targ_LF(chan,:,:))';
        if size(ph_targ_avg, 1) < length(theta)
            ph_targ_avg(end+1,:) = ph_targ_avg(1,:); % add the first values to the end so the polar plot connects
        end
        polarplot(theta, ph_targ_avg)
        set(gca, 'ThetaDir', 'clockwise', 'ThetaZeroLocation', 'top', 'ThetaTick', theta_deg, 'ThetaTicklabel', target_labels)
        ts = sprintf('Ch %d %s - Avg Power Low FB', chan_as_record, chan_label{1});
        title(ts)
        legend(phase_names)
        
        subplot_tight(1, 2, 2, [0.08 0.08])
        ph_targ_avg = squeeze(spectrums_cavg_targ_HF(chan,:,:))';
        if size(ph_targ_avg, 1) < length(theta)
            ph_targ_avg(end+1,:) = ph_targ_avg(1,:); % add the first values to the end so the polar plot connects
        end
        polarplot(theta, ph_targ_avg)
        set(gca, 'ThetaDir', 'clockwise', 'ThetaZeroLocation', 'top', 'ThetaTick', theta_deg, 'ThetaTicklabel', target_labels)
        ts = sprintf('Ch %d %s - Avg Power High FB', chan_as_record, chan_label{1});
        title(ts)
        legend(phase_names)


end % end for channels

%% Plot D of Cortical Activity Supplement. Scatter of 2 phases power and means
trial_nums = 1:64;
for chan = 41:41
    figure
    subplot_tight(1, 2, 1, [0.08 0.08])
    scatter(trial_nums, LFB_trials(chan, indx_move), 'bo')
    hold on
    scatter(trial_nums, LFB_trials(chan, indx_rest), 'ko')
    plot([trial_nums(1) trial_nums(end)], [move_mean_lfb(chan) move_mean_lfb(chan)], 'b')
    plot([trial_nums(1) trial_nums(end)], [rest_mean_lfb(chan) rest_mean_lfb(chan)], 'k')
    hold off
    ts = sprintf('LFB Samples Ch: %d Phase %d vs Phase %d', chan, phases(1), phases(2));
    title(ts)
    ylabel('Sum normalized power')
    xlabel('trial #')
    xlim([1 64])
    subplot_tight(1, 2, 2, [0.08 0.08])
    scatter(trial_nums, HFB_trials(chan, indx_move), 'bo')
    hold on
    scatter(trial_nums, HFB_trials(chan, indx_rest), 'ko')
    plot([trial_nums(1) trial_nums(end)], [move_mean_lfb(chan) move_mean_lfb(chan)], 'b')
    plot([trial_nums(1) trial_nums(end)], [rest_mean_lfb(chan) rest_mean_lfb(chan)], 'k')
    hold off
    ts = sprintf('HFB Samples Ch: %d Phase %d vs Phase %d', chan, phases(1), phases(2));
    title(ts)
    ylabel('Sum normalized power')
    xlabel('trial #')
    xlim([1 64])
end

%%
move_avg = squeeze(mean(del_move_specs(:,:, indx_move), 3));
rest_avg = squeeze(mean(del_move_specs(:,:, indx_rest), 3));
figure
hold on
for ch = 1:length(chan_range)

    plot(spectrums_cavg_fbins{1, 1}(1:100), move_avg(1:100,ch), 'b')

    plot(spectrums_cavg_fbins{1, 1}(1:100), rest_avg(1:100,ch), 'b:')
end

move_avg_alltr = squeeze(mean(move_avg, 2));
rest_avg_alltr = squeeze(mean(rest_avg, 2));
plot(spectrums_cavg_fbins{1, 1}(1:100), move_avg_alltr(1:100), 'b', 'LineWidth', 2.0)
plot(spectrums_cavg_fbins{1, 1}(1:100), rest_avg_alltr(1:100), 'b:', 'LineWidth', 2.0)

%% Polar plot of activation values
activ_vals = squeeze(sig_targ(:,4,:))';%HFB_move_mean_targ;%LFB_activation_targ;
% sig_bs = any(LFB_signific_targ, 2);
sig_bs = any(squeeze(sig_targ(:,7,:)))';
t_subplot_order = [8 1 2 7 0 3 6 5 4]; % makes subplotting in order easier
theta_deg=(0:45:360)'; %for polar plot rays
theta=deg2rad(theta_deg); %for polar plot coordinates
target_labels = {'1'; '2'; '3'; '4'; '5'; '6'; '7'; '8';};
bar_colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880];
bc = bar_colors(1:num_phase,:);
sig_chans = chan_range(sig_bs);
sig_activs = activ_vals(sig_bs, :);
for c = 1:size(sig_activs, 1)
    chan = sig_chans(c);
    chan = 2;
    chan_as_record = table2array(sub_chaninfo(chan,1));
    chan_label = table2array(sub_chaninfo(chan,2));
    figtitle = sprintf('Ch %d %s - Polar Plots', chan_as_record, chan_label{1});
    %figure('Name', figtitle, 'NumberTitle', 'off','position', [-1919 121 1920 1083])
    figure('Name', figtitle, 'NumberTitle', 'off','position', [0 0 1920 1080])
%     ph_targ_avg = abs(HFB_activation_targ(chan,:)');
    ph_targ_avg = sig_activs(c, :)';
    
    ph_targ_avg = HFB_activation_targ(2,:)';
%     ph_targ_avg = ph_targ_avg .* sig_targ(:,7,chan);
    if size(ph_targ_avg, 1) < length(theta)
        ph_targ_avg(end+1,:) = ph_targ_avg(1,:); % add the first values to the end so the polar plot connects
    end
    polarplot(theta, ph_targ_avg)
    set(gca, 'ThetaDir', 'clockwise', 'ThetaZeroLocation', 'top', 'ThetaTick', theta_deg, 'ThetaTicklabel', target_labels)
%     rlim([min(ph_targ_avg) max(ph_targ_avg)])
    rlim([0 1])
    ts = sprintf('Ch %d %s - HFB Activation', chan_as_record, chan_label{1});
    title(ts)


end
%%
% Plot activations as grid hopefully as channels were anatomically
% layed out
figure('position', [200 200 1200 600])
subplot_tight(1, 2, 1, [0.08 0.08])
LFB_a_grid = LFB_activation(chan_grid);
switch spec_grid
    case 'MP'
        LFB_a_grid(5, 1) = NaN; LFB_a_grid(1, 4) = NaN;
end
imagesc(chan_grid_x, chan_grid_y, LFB_a_grid)
ts = sprintf('%s LFB activation Phase %d move vs Phase %d rest', spec_grid, phases(2), phases(1));
title(ts)
%         caxis([min_LFB max_HFB])
caxis([-max(abs(LFB_activation)) max(abs(LFB_activation))])
colorbar

subplot_tight(1, 2, 2, [0.08 0.08])
HFB_a_grid = HFB_activation(chan_grid);
switch spec_grid
    case 'MP'
        HFB_a_grid(5, 1) = NaN; HFB_a_grid(1, 4) = NaN;
end
imagesc(chan_grid_x, chan_grid_y, HFB_a_grid)
ts = sprintf('%s HFB activation Phase %d move vs Phase %d rest', spec_grid, phases(2), phases(1));
title(ts)
%         caxis([min_LFB max_HFB])
caxis([-max(abs(HFB_activation)) max(abs(HFB_activation))])
colorbar