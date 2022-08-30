classdef Interface < handle
    methods(Abstract)
        loadServer(this);
        stopServer(this);
    end % END methods
end % END classdef Interface