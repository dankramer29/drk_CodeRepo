function activations = fband_activation(dataset1, dataset2)
% datasets are channels x trials, group 1 being trials of interest and
% group 2 being baseline trials.
    fband_var = var([dataset1 dataset2], 0, 2); % 0 = N-1 normalization
    % finds variance through all trials for each channel. chX1
    mean_diff = squeeze(mean(dataset1, 2)) - squeeze(mean(dataset2, 2));
    % difference of average of trials in each group, for each channel. chX1
    activations = ((mean_diff.^3) ...
        ./ (abs(mean_diff) .* fband_var)) ...
        .* ((64 * 64) / (128^2)); % chX1


end