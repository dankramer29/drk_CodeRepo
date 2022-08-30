function accum_integrals = get_sig_integrals(experiment_perc_diffs, sig_perc_diffs, timebins)
    
    % unpack low and high series
    sig_perc_diffs_low = sig_perc_diffs{1, 1};
    sig_perc_diffs_high = sig_perc_diffs{1, 2};
    
    assert(isequal(size(experiment_perc_diffs), size(sig_perc_diffs_low)) && isequal(size(sig_perc_diffs_low), size(sig_perc_diffs_high)), "Sizes of input arrays do not match")
    
    % pre-allocate
    num_f_bands = size(experiment_perc_diffs, 3);
    num_channels = size(experiment_perc_diffs, 2);
    % accum_integrals will have a cell for each channel/frequency band
    % combo. Each cell will contain 3 columns: the first timebin where
    % the main line crosses the threshold, the last timebin before it
    % crosses back below, and the area(integral) between the main line
    % and the threshold line during that period. 
    accum_integrals = cell(num_channels, num_f_bands);
    
    for f = 1:num_f_bands
        % copy a smaller section. Makes it easier to parfor if needed.
        sub_sig_diff_low = sig_perc_diffs_low(:,:,f);
        sub_sig_diff_high = sig_perc_diffs_high(:,:,f);
        sub_exp_diff = experiment_perc_diffs(:,:,f);
        for c = 1:num_channels
            % copy a smaller section. Makes it easier to parfor if needed.
            chan_cut_low = sub_sig_diff_low(:,c);
            chan_cut_high = sub_sig_diff_high(:,c);
            chan_diff = sub_exp_diff(:,c);
            
            % don't know how many/variable number of integrals per segment.
            freq_chan_ints_l = [];
            freq_chan_ints_h = [];
            % find where the numbers are lower than the low threshold
            if any(chan_diff < chan_cut_low)
                % index of 0 and 1 where values are lower
                low_indx = chan_diff < chan_cut_low;
                % diff = every value in the index - the preceding value.
                % x = [0 0 1 1 1 1 0 0 0 0 0 0 0 1 1 1 1 1 0 0 0 0 0]
                % we want the index of the first and last 1 in each group
                % d = diff(x);
                % d = [0 1 0 0 0 -1 0 0 0 0 0 0 1 0 0 0 0 -1 0 0 0 0]
                start_stop = diff(low_indx);
                starts = find(start_stop == 1) + 1;
                stops = find(start_stop == -1);
                % if the main line started below the threshold, we
                % have to start with the first value available
                if low_indx(1) == 1
                    starts = [1; starts];
                end
                % if the main line finishes below the threshold,
                % include the last value available
                if low_indx(end) == 1
                    stops(end + 1) = length(low_indx);
                end
                % go through the list of starts and stops and
                % calculate the integral of each group
                for i = 1:length(starts)
                    x = timebins(starts(i):stops(i));
                    % can't take an integral over a single point
                    if length(x) == 1
                        freq_chan_ints_l(i,:) = [x(1) x(end) NaN];
                        continue
                    end
                    % slice of the main line
                    y_main = chan_diff(starts(i):stops(i));
                    % slice of the threshold line
                    y_minor = chan_cut_low(starts(i):stops(i));
                    % integrals of each of those regions with respect
                    % to the origin
                    int_main = trapz(x, y_main);
                    int_minor = trapz(x, y_minor);
                    % get the integral between the two lines
                    int_diff = int_main - int_minor;
                    % store the integral value
                    freq_chan_ints_l(i, :) = [x(1) x(end) int_diff];
                end
            end % end below low cut-off integrals
            % find where the main line values are higher than the high threshold
            % follows the same methods above just 'above' rather than
            % 'below'
            if any(chan_diff > chan_cut_high)
                high_indx = chan_diff > chan_cut_high;
                start_stop = diff(high_indx);
                starts = find(start_stop == 1) + 1;
                stops = find(start_stop == -1);
                if high_indx(1) == 1
                    starts = [1; starts];
                end
                if high_indx(end) == 1
                    stops(end + 1) = length(high_indx);
                end
                for ii = 1:length(starts)
                    x = timebins(starts(ii):stops(ii));
                    if length(x) == 1
                        freq_chan_ints_h(ii,:) = [x(1) x(end) NaN];
                        continue
                    end
                    y_main = chan_diff(starts(ii):stops(ii));
                    y_minor = chan_cut_low(starts(ii):stops(ii));
                    % integrals of each of those regions
                    int_main = trapz(x, y_main);
                    int_minor = trapz(x, y_minor);
                    int_diff = int_main - int_minor;
                    freq_chan_ints_h(ii, :) = [x(1) x(end) int_diff];
                end
            end %end above high cut-off integrals
            % gather the values from below and above into the same array
            freq_chan_ints = [freq_chan_ints_l; freq_chan_ints_h];
            % gather into the appropriate cell
            accum_integrals{c, f} = freq_chan_ints;
        end %end for channel loop
    end %end for frequency band loop
            