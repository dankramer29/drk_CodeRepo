function TimeBins_phase_idx = match_timebins_to_phasetimes(phase_times_relT, TimeBins)

TimeBins_phase_idx = NaN(size(phase_times_relT));
    
    for tr = 1:length(phase_times_relT)
        for ph = 1:size(phase_times_relT, 2)
            time_val = phase_times_relT(tr, ph);
            if any(TimeBins == time_val)
                TimeBins_phase_idx(tr, ph) = find(TimeBins == time_val, 1, 'first');
            else
                low_idx = find(TimeBins < time_val, 1, 'last');
                high_idx = low_idx + 1;
                %make sure index is valid
                if low_idx == length(TimeBins)
                    TimeBins_phase_idx(tr, ph) = low_idx;
                    break
%                 elseif low_idx == length(TimeBins) && ((time_val - TimeBins(low_idx)) > 0.0010)
% %                     fprintf('Trial %d, Phase %d time given (%d) exceeds TimeBins (%d)\n', tr, ph, time_val, TimeBins(low_idx))
%                     TimeBins_phase_idx(tr, ph) = low_idx;
%                     break
                end %end if time_val > TimeBins(end)
                
                if (time_val - TimeBins(low_idx) < TimeBins(high_idx) - time_val)
                    TimeBins_phase_idx(tr, ph) = low_idx;
                elseif (TimeBins(high_idx) - time_val < time_val - TimeBins(low_idx))
                    TimeBins_phase_idx(tr, ph) = high_idx;
                else
                    ld = time_val - TimeBins(low_idx);
                    hd = TimeBins(high_idx) - time_val;
                    fprintf('Trial %d, Phase %d lowd = %d, hid = %d | equal diff!\n', tr, ph, ld, hd)
                    TimeBins_phase_idx(tr, ph) = low_idx;
                end %end finding the next closest index
            end %end finding the closest index
        end %end checking each phase time
    end %end trial loop