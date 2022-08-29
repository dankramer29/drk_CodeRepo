classdef Keyboard < handle & Experiment2.Keyboard.Interface & util.Keyboard
    
    methods
        function this = Keyboard(cfg,varargin)
            this = this@Experiment2.Keyboard.Interface(cfg);
            this = this@util.Keyboard(varargin{:});
        end % END function Keyboard
    end % END methods
    
end % END classdef Keyboard