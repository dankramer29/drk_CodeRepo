function activations = spectrogram_activations(specgrams, fbins, all_tr_avg, phases, f_range)
    % returns a matrix of activation values calculated by comparing the 2
    % given phases in the given frequency range. Will have an activation
    % value for every timebin in the second phase, for every channel

    tspf = fbins{1, phases(2)};
    f_indx = tspf > 0 & tspf < 500;
    t_specs_m = specgrams{1, phases(2)}(:,f_indx,:,:);
    t_specs_r = mean(specgrams{1, phases(1)}(:,f_indx,:,:), 1);
    t_specs_r = repmat(t_specs_r, [size(t_specs_m, 1) 1 1 1]);

    s_rest = size(t_specs_r, 4);
    s_move = size(t_specs_m, 4);
    s_all = s_rest + s_move;

    % all trial avg 

    % fbins x chs
    alltavg = reshape(all_tr_avg, [1 size(all_tr_avg) 1]); %needs to be 3d for next step

    del_move_specs = cat(4, t_specs_r, t_specs_m) ...
        ./ repmat(alltavg, [size(t_specs_m,1) 1 1 s_all]); %psdXchXtrials
    indx_move = logical(zeros(1, s_all)'); indx_move(s_rest+1:end) = 1;
    indx_rest = logical(zeros(1, s_all)'); indx_rest(1:s_rest) = 1;
    f_indx_hfb = tspf(f_indx) >= f_range(1) & tspf(f_indx) <= f_range(2);
    hfb_specgrams = squeeze(sum(del_move_specs(:, f_indx_hfb, :, :), 2)); % -> time x channels x trials
    % summed normalized power in HFB
    % specs_cmpr.del_move_specs = del_move_specs;
    % specs_cmpr.indx_move = indx_move;
    % specs_cmpr.indx_rest = indx_rest;
    t_var = var(hfb_specgrams, 0, 3); %variance of trial dimension (0 if for N-1)
    t_mean_diff = mean(hfb_specgrams(:,:,indx_move), 3) - mean(hfb_specgrams(:, :, indx_rest),3);
    % difference of means of each trial condition time X channels

    activations = ((t_mean_diff.^3) ...
            ./ (abs(t_mean_diff) .* t_var)) ...
            .* ((s_move * s_rest) / (s_all^2)); % time X channels