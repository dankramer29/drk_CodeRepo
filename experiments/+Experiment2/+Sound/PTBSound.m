classdef PTBSound < handle & Experiment2.Sound.Interface & Sound.Server
    
    properties
    end % END properties
    
    methods
        function this = PTBSound(cfg,varargin)
            
            % run the superclass constructor
            this = this@Sound.Server(varargin{:});
            
            % run the config
            feval(cfg,this);
        end % END function Sound
    end % END methods
    
end % END classdef PTBSound