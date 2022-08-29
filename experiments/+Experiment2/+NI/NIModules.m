classdef NIModules < handle & NI.Client & Experiment2.NI.Interface
    methods
        function this = NIModules(cfg,varargin)
            this = this@NI.Client(varargin{:});
            feval(cfg,this);
        end % END function NIModules
    end % END methods
end % END classdef NIModules