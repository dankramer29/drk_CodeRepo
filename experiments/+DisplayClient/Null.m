classdef Null < handle & DisplayClient.Interface & util.Structable
    
    properties
    end % END properties
    
    methods
        function this = Null(parent,varargin)
            this.hTask = parent;
        end % END function PsychToolbox
        
        function refresh(~)
        end % END function refresh
        
        function r = getResource(~,~)
            r = '';
        end % END function getResource
        
        function returnResource(~,~)
        end % END function returnResource
    end % END methods
    
end % END classdef PsychToolbox