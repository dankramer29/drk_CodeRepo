function [pvals_targ, signific_targ, sort_rsqrs] = bs_activation_tuning(spectrums_sum_poi, spectrums_sum_bp, targets)
% bootstrap shuffle between target groups
% take all trials for 2 phases (PhaseOI and BaseP), along with target list
% for those trials (psd normalized to mean over all trials). Shuffle the
% target list, sort all trials by that target list, and take the new mean
% psd for each target. 

% calculate the activation for each new target mean, get a
% distribution of shuffled activations for each target, and show that a
% given activation for a target falls at a significant level compared to
% random trials. 

% takes ch x trials for two groups. Should be sum of psd in a chosen
    % frequency range, already normalized

    num_trials = length(targets);
    num_perms = 10000;
    first_dim = size(spectrums_sum_poi, 1);
    targ_act_dist = zeros(first_dim, 8, num_perms);
    rsqrs = zeros(first_dim, num_perms);

    parfor i = 1:num_perms
        t = targets;
        new_targets = t(randperm(num_trials));
        targ_act_dist(:, :, i) = Analysis.DelayedReach.LFP.activations_by_targ(spectrums_sum_poi, spectrums_sum_bp, new_targets);
        [~, rsqrs(:,i)] = Analysis.DelayedReach.LFP.check_gauss_tuning(targ_act_dist(:,:,i));
    end
    sort_targ_act_dist = sort(targ_act_dist, 3);
    actual_targ_activations = Analysis.DelayedReach.LFP.activations_by_targ(spectrums_sum_poi, spectrums_sum_bp, targets);

    pvals_targ = zeros(first_dim, 8);
    signific_targ = zeros(first_dim, 8);

    for c = 1:first_dim
        for t = 1:8
            actual = actual_targ_activations(c, t); 
            if actual < 0 %sign negative
                [found, indx] = find(sort_targ_act_dist(c,t,:) < actual, 1, 'last');
                if isempty(found)
                    indx = 1;
                end
            elseif actual > 0 %sign positive
                [found, indx] = find(sort_targ_act_dist(c,t,:) > actual, 1, 'first');
                if isempty(found)
                    indx = num_perms - 1;
                end
                indx = num_perms - indx;
            end
            pvals_targ(c,t) = indx / num_perms;
            signific_targ(c,t) = pvals_targ(c,t) < 0.05;
        end
    end
    
    sort_rsqrs = sort(rsqrs, 2);
    
%     rsqr_sig = sort_rsqrs(:,round(num_perms * .95));
%     rsqr_sig = sort_rsqrs(round(num_perms * .05));
end
        
