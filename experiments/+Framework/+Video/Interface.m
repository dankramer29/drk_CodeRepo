classdef Interface < handle & Framework.Component & util.StructableHierarchy
    % INTERFACE Required superclass for video objects used in the Framework
    
    methods
        function this = Interface(fw,varargin)
            % INTERFACE Constructor for Interface object
            %
            %   INTERFACE(FW)
            %   Construct the video interface object with a handle to the
            %   framework in FW.
            
            % construct the superclass Framework.Component
            this = this@Framework.Component(fw,'VIDEO');
        end % END function Interface
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Framework.Component(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Framework.Component(this);
            st = util.catstruct(st,st1);
        end % END function structableManualFields
    end % END methods
    
    methods(Abstract)
        stop(this);
        record(this);
        initialize(this);
    end % END methods(Abstract)
    
end % END classdef Interface