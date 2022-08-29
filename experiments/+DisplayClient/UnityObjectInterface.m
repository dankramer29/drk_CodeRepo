classdef UnityObjectInterface < handle
    
    properties
        resource                % resource identifier (mainly used for Unity client)
    end % END properties
    
    methods
        function CreateFcn(this)
            this.resource = this.hTask.hDisplayClient.getResource(this.defaultShape);
            this.hTask.hDisplayClient.createObject(this);
        end % END function CreateFcn
        
        function UpdateFcn(~)
        end % END function UpdateFcn
    end % END methods
    
end % END classdef UnityObjectInterface