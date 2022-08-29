classdef Interface < handle
    
    methods(Abstract)
        register(this,name,filename);
        play(this,name);
    end % END methods
    
end % END classdef Interface