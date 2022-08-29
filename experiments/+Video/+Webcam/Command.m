classdef Command < uint8
    
    enumeration
        EXIT            (0)
        INITIALIZE      (1)
        RECORD          (2)
        STOP            (3)
        ENABLE_CBMEX    (4)
        DISABLE_CBMEX   (5)
        SET_ID_STRING   (6)
        REQUEST         (7)
        SET_SUBJECT     (8)
    end % END enumeration
    
end % END classdef Command