function [ch, fb] = find_sig_int(accum_integrals, val)
    
    num_cells = numel(accum_integrals);
    
    for i = 1:num_cells
        contents = accum_integrals{i};
        
        if ~isempty(contents) && any(contents(:,3) == val)
            [ch, fb] = ind2sub(size(accum_integrals), i);
        end
    end
end%end function