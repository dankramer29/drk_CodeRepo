classdef Interface < handle & util.StructableHierarchy
    
    properties
        hNeuralSource
    end % END properties
    
    properties(Abstract,SetAccess='private',GetAccess='public')
        featureDefinitions % each row a feature as defined by columns
        featureCount % number of features
        dataTypes % whether event, continuous, or both
    end % END properties(SetAccess='private',GetAccess='public')
    
    methods
        function this = Interface(parent)
            
            % assign handle to parent object
            assert(isa(parent,'Framework.NeuralSource.Interface'),'Must provide a handle to Framework.NeuralSource.Interface object');
            this.hNeuralSource = parent;
        end % END function Interface
        
        function list = structableSkipFields(~)
            list = {'hNeuralSource'};
        end % END function structableSkipFields
        
        function st = structableManualFields(~)
            st = [];
        end % END function structableManualFields
        
    end % END methods
    
    methods(Abstract)
        initialize(this,data,wins)
        z = processFeatures(this,data,wins)
        def = getFeatureDefinition(this)
        close(this)
    end % END methods(Abstract)
    
end % END classdef Interface