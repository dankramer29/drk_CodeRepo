classdef Unity < handle & Experiment2.DisplayClient.Interface & DisplayClient.Unity
    
    properties
    end % END properties
    
    methods
        function this = Unity(cfg,varargin)
            this = this@DisplayClient.Unity(cfg,varargin{:});
        end % END function PsychToolbox
    end % END methods
    
end % END classdef PsychToolbox