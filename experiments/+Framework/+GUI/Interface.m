classdef Interface < handle & Framework.Component & util.StructableHierarchy
    
    properties(Abstract)
        hFigure
        width
        height
        name
    end % END properties(Abstract)
    
    methods
        function this = Interface(fw,varargin)
            commentName = 'GUI';
            if ~isempty(varargin)
                commentName = varargin{1};
            end
            this = this@Framework.Component(fw,commentName);
        end % END function Interface
        
        function updateRuntimeLimit(this,which,lim)
        end % END function updateRuntimeLimit
        
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
    end
    
    methods(Abstract)
        InitFcn(this);
        StartFcn(this);
        StopFcn(this);
        UpdateFcn(this);
    end % END methods(Abstract)
    
end % END classdef GUI