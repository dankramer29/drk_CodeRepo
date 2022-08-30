function [spec_diff, spec_target_avg_wait, spec_target_avg_move] = get_avg_and_diff(spec_wait, spec_move, trial_targets, target_options)
    
    num_targ_options = length(target_options);
    s = size(spec_wait);
    spec_target_avg_wait = zeros(s(1), s(2), s(3), num_targ_options);
    spec_target_avg_move = zeros(s(1), s(2), s(3), num_targ_options);
    spec_diff = zeros(s(1), s(2), s(3), num_targ_options);
    
    for t = 1:num_targ_options
        targ = target_options(t);
        targ_indx = trial_targets == targ;
        spec_target_avg_wait(:,:,:,t) = 10*log10(squeeze(mean(spec_wait(:,:,:,targ_indx), 4)));
        spec_target_avg_move(:,:,:,t) = 10*log10(squeeze(mean(spec_move(:,:,:,targ_indx), 4)));
        spec_diff(:,:,:,t) = spec_target_avg_wait(:,:,:,t) - spec_target_avg_move(:,:,:,t);
    end
end % end func get_avg_and_diff