classdef Mode < uint8
    enumeration
        OFF (0),
        ON (1),
        VALIDATION (2)
    end % END enumeration
    
    methods
        function val = dbMessage(this)
            switch this
                case Debug.Mode.OFF, val = true;
                case Debug.Mode.ON, val = true;
                case Debug.Mode.VALIDATION, val = false;
            end
        end % END function debugPrint
        function val = dbKeyboard(this)
            switch this
                case Debug.Mode.OFF, val = false;
                case Debug.Mode.ON, val = true;
                case Debug.Mode.VALIDATION, val = false;
            end
        end % END function debugKeyboard
        function val = dbRethrow(this)
            switch this
                case Debug.Mode.OFF, val = false;
                case Debug.Mode.ON, val = false;
                case Debug.Mode.VALIDATION, val = true;
            end
        end % END function debugRethrow
        function varargout = settings(this)
            pr = dbMessage(this);
            kb = dbKeyboard(this);
            rt = dbRethrow(this);
            if nargout==3
                varargout = {pr,kb,rt};
            elseif nargout<=1
                varargout{1} = struct('print',pr,'keyboard',kb,'rethrow',rt);
            end
        end % END function settings
    end % END methods
    methods(Static)
        function p = fromAny(m)
            if isnumeric(m)
                p = Debug.Mode(m);
            elseif ischar(m)
                p = Debug.Mode.fromString(m);
            elseif isa(m,'Debug.Mode')
                p = m;
            else
                error('Unknown input class ''%s'' (will accept numeric, char, or Debug.Mode)',class(m));
            end
        end % END function fromAny
        function p = fromString(m)
            if ischar(m)
                switch lower(m)
                    case {'0','off','disable','disabled'}
                        p = Debug.Mode.OFF;
                    case {'1','on','enable','enabled'}
                        p = Debug.Mode.ON;
                    case {'2','validate','validation'}
                        p = Debug.Mode.VALIDATION;
                    otherwise
                        error('Unknown debug mode ''%s''',m);
                end
            end
        end % END function fromString
    end % END methods(Static)
end % END classdef Mode