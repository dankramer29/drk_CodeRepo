classdef PhaseShowGroup < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseShowGroup(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowGroup
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                tag = sprintf('tr%03dph%02d',hTask.cTrial,hTask.hTrial.phaseIdx);
                sync(hTask.hFramework,@pulse,0.3,'tag',tag);
            end
        end % END function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            hTask.drawFixationPoint;
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            hTask.showGroup;
        end % END function PostDrawFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hTrial.advance;
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
end % END classdef PhaseShowGroup