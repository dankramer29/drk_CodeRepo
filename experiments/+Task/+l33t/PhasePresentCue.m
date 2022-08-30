classdef PhasePresentCue < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        count % how many times the cue has been presented (for sound)
    end
    
    methods
        function this = PhasePresentCue(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhasePresentCue
        
        function StartFcn(this,evt,hTask,varargin)
            this.count = 0;
            if hTask.params.useSync
                sync(hTask.hFramework,@high);
            end
        end % END function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            hTask.drawFixationPoint;
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            hTask.presentCue;
            this.count = this.count+1;
        end % END function PostDrawFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hTrial.advance;
        end % END function TimeoutFcn
        
        function EndFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                sync(hTask.hFramework,@low);
            end
        end % END function EndFcn
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Experiment2.PhaseInterface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Experiment2.PhaseInterface(this);
        end % END function structableManualFields
    end % END methods
end % END classdef PhasePresentCue