classdef PhaseResponseType < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseResponseType(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseResponseType
        
        function StartFcn(this,evt,hTask,varargin)
            switch lower(hTask.cTrialParams.response_type)
                case 'word', hTask.hSound.play('responseWord');
                case 'number', hTask.hSound.play('responseNumber');
                case 'numberword', hTask.hSound.play('responseWord');
                otherwise, error('Unknown response type ''%s''',hTask.cTrialParams.response_type);
            end
            if hTask.params.useSync
                sync(hTask.hFramework,@high);
            end
        end % END function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            hTask.drawFixationPoint;
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
end % END classdef PhaseResponseType