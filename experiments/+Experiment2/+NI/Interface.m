classdef Interface < handle
    methods(Abstract)
        initialize(this);
        start(this);
        stop(this);
    end % END methods
end % END classdef Interface