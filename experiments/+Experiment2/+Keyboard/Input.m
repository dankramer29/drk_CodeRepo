classdef Input < handle & Experiment2.Keyboard.Interface & Keyboard.Input
    
    methods
        function this = Input(cfg,varargin)
            this = this@Experiment2.Keyboard.Interface(cfg);
            this = this@Keyboard.Input(varargin{:});
        end % END function Input
    end % END methods
    
end % END classdef Input