classdef PriorityLevel < double
    enumeration
        SILENT (-1), % the message must never be printed.
        CRITICAL (0), % The message must always be printed.
        ERROR (1), % The message represents an error.
        WARNING (2), % The message is a warning.
        INFO (3), % The message contains information.
        HINT (4), % The message is useful but not that important.
        DEBUG (5), % The message is for debug purposes.
        INSANITY (6) % The message is superfluous and probably not useful
    end % END enumeration
    
    methods(Static)
        function p = fromAny(lvl)
            if isnumeric(lvl)
                p = Debug.PriorityLevel.fromNumber(lvl);
            elseif ischar(lvl)
                p = Debug.PriorityLevel.fromString(lvl);
            elseif isa(lvl,'Debug.PriorityLevel')
                p = lvl;
            else
                error('Unknown input class ''%s'' (will accept numeric, char, or Debug.PriorityLevel)',class(lvl));
            end
        end % END function fromAny
        function p = fromNumber(lvl)
            if isnumeric(lvl)
                switch lvl
                    case -1, p = Debug.PriorityLevel.SILENT;
                    case  0, p = Debug.PriorityLevel.CRITICAL;
                    case  1, p = Debug.PriorityLevel.ERROR;
                    case  2, p = Debug.PriorityLevel.WARNING;
                    case  3, p = Debug.PriorityLevel.INFO;
                    case  4, p = Debug.PriorityLevel.HINT;
                    case  5, p = Debug.PriorityLevel.DEBUG;
                    case  6, p = Debug.PriorityLevel.INSANITY;
                    otherwise
                        if lvl<-1
                            p = Debug.PriorityLevel.SILENT;
                        elseif lvl>6
                            p = Debug.PriorityLevel.INSANITY;
                        end
                end
            end
        end % END function fromNumber
        function p = fromString(lvl)
            if ischar(lvl)
                switch lower(lvl)
                    case {'-1','silent','quiet','none'}
                        p = Debug.PriorityLevel.SILENT;
                    case {'0','crit','critical','essential'}
                        p = Debug.PriorityLevel.CRITICAL;
                    case {'1','error'}
                        p = Debug.PriorityLevel.ERROR;
                    case {'2','warn','warning'}
                        p = Debug.PriorityLevel.WARNING;
                    case {'3','info','information'}
                        p = Debug.PriorityLevel.INFO;
                    case {'4','hint'}
                        p = Debug.PriorityLevel.HINT;
                    case {'5','debug'}
                        p = Debug.PriorityLevel.DEBUG;
                    case {'6','insanity','ludicrous'}
                        p = Debug.PriorityLevel.INSANITY;
                    otherwise
                        error('Unknown PriorityLevel level ''%s''',lvl);
                end
            end
        end % END function fromString
    end % END methods(Static)
end % END classdef PriorityLevel