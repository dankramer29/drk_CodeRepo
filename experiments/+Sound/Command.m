classdef Command
    
    enumeration
        PLAY
        REGISTER
        SET
        GET
        STOP
    end % END enumeration
    
    methods
        function val = uint8(cmd)
            [~,names]=enumeration('Sound.Command');
            idx = strcmpi(names,char(cmd));
            if nnz(idx)
                val = uint8(find(idx));
            else
                val = nan;
            end
        end
    end % END methods
    
end % END classdef Command