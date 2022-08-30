classdef Interface < handle & Framework.Component & util.StructableHierarchy
    
    properties(Abstract,SetAccess='private',GetAccess='public')
        state
        neuralCommentId
    end % END properties(Abstract)
    
    methods
        function this = Interface(fw,varargin)
            this = this@Framework.Component(fw,'SYNC');
        end % END function Interface
        
        function st = getSync(this)
            st = this.state;
        end % END function getSync
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Framework.Component(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Framework.Component(this);
            st = util.catstruct(st,st1);
        end
    end % END methods
    
    methods(Abstract)
        initialize(this);
        start(this);
        update(this);
        stop(this);
    end % END methods(Abstract)
end % END classdef Interface