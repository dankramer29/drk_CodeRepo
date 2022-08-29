function ch_activations_targ = activations_by_targ(spectrums_sum_poi, spectrums_sum_bp, targets)
    % takes ch x trials for two groups. Should be sum of psd in a chosen
    % frequency range, already normalized
    
    ch_activations_targ = zeros(size(spectrums_sum_poi, 1), 8);
    for t = 1:8
        indx_t = targets == t;
        ch_activations_targ(:,t) = Analysis.DelayedReach.LFP.fband_activation(...
            spectrums_sum_poi(:, indx_t), spectrums_sum_bp(:, indx_t));
    end