classdef BlackrockStimulator < handle & Blackrock.Stimulator2.Interface & Experiment2.Stim.Interface
    methods
        function this = BlackrockStimulator(cfg,varargin)
            this = this@Blackrock.Stimulator2.Interface(varargin{:});
            feval(cfg,this);
        end % END function BlackrockStimulator
    end % END methods
end % END classdef BlackrockStimulator