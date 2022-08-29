classdef Component < handle & util.StructableHierarchy
    
    properties(GetAccess=public,SetAccess=private)
        hFramework
        
        frameId
        componentName
    end % END properties
    
    methods
        function val = get.frameId(this)
            val = this.hFramework.frameId;
        end % END function get.frameId
        
        function this = Component(fw,name,varargin)
            assert(isa(fw,'Framework.Interface'),'Must provide handle to object of class ''Framework.Interface'', not ''%s''',class(fw));
            this.hFramework = fw;
            this.componentName = name;
        end % END function Component
        
        function skip = structableSkipFields(~)
            skip = {'hFramework'};
        end % END function structableSkipFields
        
        function st = structableManualFields(~)
            st = [];
        end % END function structableManualFields
        
        function comment(this,msg,varargin)
            verbosityLevel = 0;
            if ~isempty(varargin),verbosityLevel=varargin{1};end
            comment(this.hFramework,this.componentName,msg,verbosityLevel);
        end % END function comment
        
        % function commentScreen(this,msg,varargin)
        % end % END function commentScreen
        % 
        % function commentNeural(this,msg,varargin)
        % end % END function commentNeural
        % 
        % function commentBuffer(this,msg,varargin)
        % end % END function commentBuffer
    end % END methods
    
    methods(Abstract)
        st = toStruct(this,varargin);
    end % END methods(Abstract)
end % END classdef Connector