classdef Dummy < handle & Framework.Predictor.Interface & util.Structable & util.StructableHierarchy
    
    properties
        isTrained
    end % END properties
    
    methods
        
        function val = get.isTrained(~)
            val = false;
        end % END function get.isTrained
        
        function this = Dummy(fw,~)
            this = this@Framework.Predictor.Interface(fw);
        end % END function Dummy
        
        function prediction = Predict(~,state,~,~,~)
            prediction = state;
        end % END function Predict
        
        function enablePredictor(~)
        end % END function enablePredictor
        
        function disablePredictor(~)
        end % END function disablePredictor
        
        function setAssistLevel(~,~)
        end % END function setAssistLevel
        
        function val = getAssistLevel(~)
            val = 0;
        end % END function getAssistLevel
        
        function dc = getTrialData(~)
            dc = [];
        end % END function getTrialData
        
        function skip = structableSkipFields(this)
            skip = structableSkipFields@Framework.Predictor.Interface(this);
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Framework.Predictor.Interface(this);
        end % END function structableManualFields
    end % END methods
    
end % END classdef Dummy