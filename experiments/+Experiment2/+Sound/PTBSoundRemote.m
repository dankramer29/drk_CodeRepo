classdef PTBSoundRemote < handle & Sound.Client & Experiment2.Sound.Interface
    
    properties
    end % END properties
    
    methods
        function this = PTBSoundRemote(cfg,varargin)
            
            % run the superclass constructor
            this = this@Sound.Client(varargin{:});
            
            % run the config
            feval(cfg,this);
        end % END function Sound
    end % END methods
    
end % END classdef PTBSoundRemote