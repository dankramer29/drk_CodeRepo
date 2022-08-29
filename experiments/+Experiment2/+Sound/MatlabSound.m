classdef MatlabSound < handle & Experiment2.Sound.Interface & Sound.ServerMatlabAudio
    
    properties
    end % END properties
    
    methods
        function this = MatlabSound(cfg,varargin)
            
            % run superclass constructor
            this = this@Sound.ServerMatlabAudio(varargin{:});
            
            % run config
            feval(cfg,this);
        end % END function Sound
    end % END methods
    
end % END classdef PTBSound