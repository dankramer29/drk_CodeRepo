classdef PhaseDelay < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        drawFixationPoint
        soundId
    end
    
    methods
        function this = PhaseDelay(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseDelay
        
        function StartFcn(this,evt,hTask,varargin)
            if ~isempty(this.soundId) && hTask.params.useSound
                hTask.hSound.play(this.soundId);
            end
        end % END function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
             if this.drawFixationPoint
                 hTask.drawFixationPoint;
             end
        end % END function PreDrawFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hStage.advance;
        end % END function TimeoutFcn
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Experiment2.PhaseInterface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Experiment2.PhaseInterface(this);
        end % END function structableManualFields
    end % END methods
end % END classdef PhaseDelay