classdef Interface < handle
    
    properties(Abstract)
        commentFcn
    end % END properties(Abstract)
    
    methods(Abstract)
        update(this);
        comment(this,msg,vb);
    end % END methods(Abstract)
    
    methods
        function this = Interface(cfg)
            
            % run config function
            assert(isa(cfg,'function_handle'),'Must provide function handle for config');
            feval(cfg,this);
        end % END function Interface
    end % END methods
    
end % END classdef Interface