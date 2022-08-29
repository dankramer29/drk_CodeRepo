classdef FakeStimulator < handle & Blackrock.FakeStimulator.Interface & Experiment2.Stim.Interface
    methods
        function this = FakeStimulator(cfg,varargin)
            this = this@Blackrock.FakeStimulator.Interface(varargin{:});
            feval(cfg,this);
        end % END function BlackrockStimulator
    end % END methods
end % END classdef BlackrockStimulator