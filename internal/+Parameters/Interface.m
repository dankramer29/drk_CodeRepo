classdef Interface < handle & util.Structable & util.StructableHierarchy
    % INTERFACE Superclass for Parameters objects
    %
    %  The Parameters packet supports flexible objects that can load
    %  parameters associated with certain topics, validate incoming values,
    %  and provide help messages. Valid parameters must be defined in topic
    %  files found elsewhere in the Parameters package.
    
    properties(Abstract,Access=protected)
        state
    end % END properties(Abstract,Access=protected)
    
    methods(Abstract)
        push(this,varargin);
        pop(this,varargin);
        ok = check(this,varargin);
        str = disp(this);
        str = help(this,prop);
    end % END methods(Abstract)
    
    methods
        function this = Interface(varargin)
            % INTERFACE Construct an Interface object
            %
            %  PARAM = INTERFACE
            %  Construct an empty Interface object
            %
            %  PARAM = INTERFACE(@CFG)
            %  Provide one or more configuration function handles to
            %  initialize the Interface object.
            
            % check for config file or function handle
            cfg_idx = cellfun(@(x)isa(x,'function_handle'),varargin);
            if any(cfg_idx)
                
                % pull out and remove from varargin
                cfg = varargin{cfg_idx};
                
                % convert from string to function handle
                if ischar(cfg) && exist(cfg,'file')==2
                    cfg = str2func(cfg);
                end
                
                % make sure it's a function handle
                assert(isa(cfg,'function_handle'),'Must provide function handle to full path to config function');
                
                % execute the configuration function
                feval(cfg,this);
            end
        end % END function Interface
    end % END methods
end % END classdef Interface