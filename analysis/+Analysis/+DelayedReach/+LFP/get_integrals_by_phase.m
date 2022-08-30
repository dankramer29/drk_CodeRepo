function [integrals_in_phases] = get_integrals_by_phase(accum_integrals, phase_starts_stops)
    % phase_starts_stops = [start_phase_1 stop_phase_1; start_phase_2 stop_phase_2; etc]
    
    
    num_phases = size(phase_starts_stops, 1);
    num_cells = numel(accum_integrals);
    integrals_in_phases = cell(1, num_phases);
    for ph = 1:num_phases
        phase_ints = [];
        for i = 1:num_cells
            cell_vals = accum_integrals{i};
            if ~isempty(cell_vals)
                start_check = cell_vals(:,1) >= phase_starts_stops(ph,1);
                stop_check = cell_vals(:,2) <= phase_starts_stops(ph,2);
                eq_check = cell_vals(:,1) ~= cell_vals(:,2);
                full_check = start_check & stop_check & eq_check;
                phase_ints = [phase_ints; cell_vals(full_check, 3)];
            end
        end %end accum_integrals loop through
        integrals_in_phases{1, ph} = phase_ints;
    end %end phase loop
end % end function

    