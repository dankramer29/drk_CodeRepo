classdef PhaseCueOnly < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        hResponsive
    end
    
    methods
        function this = PhaseCueOnly(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseCueOnly
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                tag = sprintf('tr%03dph%02d',hTask.cTrial,hTask.hTrial.phaseIdx);
                sync(hTask.hFramework,@high,'tag',tag);
                comment(hTask,'Sending sync high',3);
            end
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
        end % END function PhaseFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            
            % present cue
            switch lower(hTask.cTrialParams.cue_modality)
                case 'text'
                    drawText(hTask.hDisplayClient,hTask.cTrialParams.cue_word,'center','center',hTask.params.user.fontBrightness*hTask.cTrialParams.cue_rgb);
                case 'color'
                    drawRect(hTask.hDisplayClient,hTask.params.user.blockPosition,hTask.params.user.blockSize,hTask.params.user.blockBrightness*hTask.cTrialParams.cue_rgb);
                otherwise
                    error('Unknown cue modality "%s"',hTask.cTrialParams.cue_modality);
            end
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
end % END classdef PhaseCueOnly