function [varargout] = check_tuning(PowerArray, TimeBins, FreqBins, Targets, phase_times_relT, varargin)
    
    [varargin, FBand, ~, FBand_found]=util.argkeyval('FBand', varargin, []);
    [varargin, FRange, ~, FRange_found]=util.argkeyval('FRange', varargin, []);
    [varargin, Channels, ~, ~]=util.argkeyval('Channels', varargin, 1:size(PowerArray,3));

    if FBand_found
        switch FBand
            case 'theta'
                flo = 4;
                fhi = 8;
            case 'alpha'
                flo = 8;
                fhi = 12;
            case 'beta'
                flo = 12;
                fhi = 30;
            case 'low gamma'
                flo = 30;
                fhi = 80;
            case 'high gamma'
                flo = 80;
                fhi = 200;
        end
        FRange_Label = sprintf('%s %d-%dHz', FBand, flo, fhi);
    end
    
    if FRange_found
        flo = FRange(1);
        fhi = FRange(2);
        FRange_Label = sprintf('%d-%dHz', flo, fhi);
    end
    
    if ~(FBand_found || FRange_found)
        fprintf('No frequency range specified, using default Low Gamma 30 - 80 Hz\n')
        flo = 30;
        fhi = 30;
        FRange_Label = 'Low Gamma 30-80Hz';
    end
                
    Logical_idx = FreqBins > flo  & FreqBins < fhi;
    
    assert((length(Channels) <= size(PowerArray, 3)), 'More channels specified than contained in input array')
    assert((length(Targets) == size(PowerArray, 4)), 'Target list does not match trials in input array')

util.argempty(varargin);

Sub_PA = PowerArray(:, Logical_idx, Channels, :);
% Sub_FreqBins = FreqBins(Logical_idx);

avg_power = squeeze(mean(Sub_PA, 2));

TimeBins_phase_idx = Analysis.DelayedReach.LFP.match_timebins_to_phasetimes(phase_times_relT, TimeBins);
    
TimeBin_idx = round(mean(TimeBins_phase_idx, 1));

%% Trying integrals
% phase_int = zeros(length(phase_times_relT), 5);
% for tr = 1:size(phase_int, 1)
%     for ph = 1:size(phase_int, 2)
%         idx_1 = TimeBin_idx(1,ph);
%         idx_2 = TimeBin_idx(1,ph+1);
%         phase_int(tr, ph) = trapz(TimeBins(idx_1:idx_2), ch1_alltrials(idx_1:idx_2, tr));
%     end
% end
% 
% ph_targ_int = zeros(8, 5);
% 
% for ta = 1:8
%     target_idx = Targets == ta;
%     ph_targ_int(ta,:) = mean(phase_int(target_idx, :), 1);
% end

%% Average Power in a Phase
ch_ph_targ_avg = zeros(8, 5, 30);
for ch = 1:30
    ch_alltrials = squeeze(avg_power(:, ch, :));
    phase_avg = zeros(length(phase_times_relT), 5);
    for tr = 1:size(phase_avg, 1)
        for ph = 1:size(phase_avg, 2)
            idx_1 = TimeBin_idx(1,ph);
            idx_2 = TimeBin_idx(1,ph+1);
            phase_avg(tr, ph) = mean(ch_alltrials(idx_1:idx_2, tr));
        end
    end

    ph_targ_avg = zeros(8, 5);

    for ta = 1:8
        target_idx = Targets == ta;
        ph_targ_avg(ta,:) = mean(phase_avg(target_idx, :), 1);
    end
    
    ch_ph_targ_avg(:,:,ch) = ph_targ_avg;
end

%%
%channels = 1:30;
num_chans = size(avg_power, 2);

t_subplot_order = [8 1 2 7 0 3 6 5 4]; % makes subplotting in order easier
theta_deg=(0:45:360)'; %for polar plot rays
theta=deg2rad(theta_deg); %for polar plot coordinates
target_labels = {'1'; '2'; '3'; '4'; '5'; '6'; '7'; '8';};
bar_colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880];

for ch = 1:num_chans
    ph_targ_avg = squeeze(ch_ph_targ_avg(:,:,ch));
    if size(ph_targ_avg, 1) < length(theta)
        ph_targ_avg(end+1,:) = ph_targ_avg(1,:); % add the first values to the end so the polar plot connects
    end

    max_val = max(ph_targ_avg(:)); %normalize all subplots for comparison
%     max_val = -10*log10(ceil(max(abs(ph_targ_avg(:))))); %normalize all subplots for comparison



    figtitle = sprintf('%s-Polar Plot-%s-Channel %d ', TaskString, FRange_Label, ch);
    figure('Name', figtitle, 'NumberTitle', 'off','position', [-1919 121 1920 1083])

    for t = 1:length(t_subplot_order)
        if t == 5
            subplot_tight(3, 3, t, [0.08 0.08])
            p = polarplot(theta, ph_targ_avg);
            set(gca, 'ThetaDir', 'clockwise', 'ThetaZeroLocation', 'top', 'ThetaTick', theta_deg, 'ThetaTicklabel', target_labels,...
                'RTick', 0:max_val/5:max_val)
            legend('ITI', 'Fix', 'Cue', 'Delay', 'Respond')
            continue %skip the rest
        end
        target = t_subplot_order(t);
        subplot_tight(3, 3, t, [0.08 0.08])
        b = bar(ph_targ_avg(target,:));
        set(b, 'FaceColor', 'flat', 'CData', bar_colors)
%         b = bar(10*log10(ph_targ_avg(target,:)));
%         for br = 1:5
%             b(br).FaceColor = bar_colors(br,:);
%         end
        ylbl = sprintf('Average %s Power', FRange_Label);
        ylabel(ylbl)
        ylim([0 max_val])
%         ylim([max_val 0])
        %xlabel('Phase')
        set(gca, 'XTickLabel', {'ITI', 'Fix', 'Cue', 'Delay', 'Respond'})
        ts = sprintf('Ch %d Target %d', 1, target);
        title(ts)
    end % end for subplots

end % end for channels

