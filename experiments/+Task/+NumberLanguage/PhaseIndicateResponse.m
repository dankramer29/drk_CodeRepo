classdef PhaseIndicateResponse < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseIndicateResponse(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseIndicateResponse
        
        function StartFcn(this,evt,hTask,varargin)
            hTask.hSound.play(sprintf('%s_%s',hTask.cTrialParams.rsp_type,hTask.cTrialParams.rsp_subtype));
            if hTask.params.useSync
                sync(hTask.hFramework,@high);
            end
        end % END function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            Task.Common.drawFixationPoint(hTask);
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
end % END classdef PhaseIndicateResponse