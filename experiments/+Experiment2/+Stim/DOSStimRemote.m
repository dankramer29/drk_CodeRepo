classdef DOSStimRemote < handle & StimServer.Client & Experiment2.Stim.Interface
    
    properties
    end % END properties
    
    methods
        function this = DOSStimRemote(cfg,varargin)
            
            % run the superclass constructor
            this = this@StimServer.Client(varargin{:});
            
            % run the config
            feval(cfg,this);
        end % END function Sound
    end % END methods
    
end % END classdef DOSStimRemote