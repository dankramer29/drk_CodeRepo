classdef Interface < handle & Framework.Component & util.StructableHierarchy
    
    properties
    end % END properties
    
    properties(Abstract)
        isTrained
    end % END properties(Abstract)
    
    methods
        function this = Interface(fw)
            this = this@Framework.Component(fw,'PREDICTOR');
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
        prediction = Predict(this,state,features,target);
        disablePredictor(this);
        enablePredictor(this);
        setAssistLevel(this,val);
        val = getAssistLevel(this);
        dc = getTrialData(this);
    end % END methods
    
end % END classdef Interface