function RelT_phase_idx = match_relative_times(RelT, phase_times_relT)
    assert(isequal(length(RelT), size(phase_times_relT, 1)), 'relative time arrays do not match')
    
    RelT_phase_idx = NaN(size(phase_times_relT));
    
    for tr = 1:length(RelT)
        for ph = 1:size(phase_times_relT, 2)
            time_val = phase_times_relT(tr, ph);
            if any(RelT{1, tr} == time_val)
                RelT_phase_idx(tr, ph) = find(RelT{1, tr} == time_val, 1, 'first');
            else
                low_idx = find(RelT{1, tr} < time_val, 1, 'last');
                high_idx = low_idx + 1;
                %make sure index is valid
                if low_idx == length(RelT{1, tr}) && ((time_val - RelT{1, tr}(low_idx)) < 0.0010)
                    RelT_phase_idx(tr, ph) = low_idx;
                    break
                elseif low_idx == length(RelT{1, tr}) && ((time_val - RelT{1, tr}(low_idx)) > 0.0010)
                    fprintf('Trial %d, Phase %d time given (%d) exceeds RelT (%d)', tr, ph, time_val, RelT{1, tr}(low_idx))
                    break
                end %end if time_val > RelT(end)
                
                if (time_val - RelT{1, tr}(low_idx) < RelT{1, tr}(high_idx) - time_val)
                    RelT_phase_idx(tr, ph) = low_idx;
                elseif (RelT{1, tr}(high_idx) - time_val < time_val - RelT{1, tr}(low_idx))
                    RelT_phase_idx(tr, ph) = high_idx;
                else
                    ld = time_val - RelT{1, tr}(low_idx);
                    hd = RelT{1, tr}(high_idx) - time_val;
                    fprintf('Trial %d, Phase %d lowd = %d, hid = %d | equal diff!\n', tr, ph, ld, hd)
                    RelT_phase_idx(tr, ph) = low_idx;
                end %end finding the next closest index
            end %end finding the closest index
        end %end checking each phase time
    end %end trial loop
    
    
    