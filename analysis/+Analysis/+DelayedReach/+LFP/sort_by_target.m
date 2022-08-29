function targ_phase_dt = sort_by_target(dt, targets, num_phases, varargin)
    num_chans = size(dt{1}, 2);
    tot_chan_range = 1:num_chans;
    
    [varargin, ch_range, ~, ~] = util.argkeyval('Channel_Range', varargin, [tot_chan_range(1) tot_chan_range(end)]);
    
    util.argempty(varargin);
    
    %ch_idx = chans == tot_chan_range;
    ch_idx = tot_chan_range >= ch_range(1) & tot_chan_range <= ch_range(2);

    targ_phase_dt = cell(8, num_phases);

    for t = 1:8
        targ_idx = targets == t;
        for ph = 1:num_phases
            targ_phase_dt{t, ph} = dt{ph}(:, ch_idx, targ_idx);
        end
    end
end