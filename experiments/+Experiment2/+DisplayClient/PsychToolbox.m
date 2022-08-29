classdef PsychToolbox < handle & Experiment2.DisplayClient.Interface & DisplayClient.PsychToolbox
    methods
        function this = PsychToolbox(cfg,varargin)
            this = this@DisplayClient.PsychToolbox(varargin{:});
            
            % user config function overrides defaults
            assert(isa(cfg,'function_handle'),'Must provide a function handle');
            feval(cfg,this);
            initLoadImages(this)
        end % END function PsychToolbox
    end % END methods
end % END classdef PsychToolbox