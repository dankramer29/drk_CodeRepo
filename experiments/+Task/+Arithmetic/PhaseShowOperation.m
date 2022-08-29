classdef PhaseShowOperation < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseShowOperation(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowOperation
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                tag = sprintf('tr%03dph%02d',hTask.cTrial,hTask.hTrial.phaseIdx);
                sync(hTask.hFramework,@high,'tag',tag);
                comment(hTask,'Sending sync high',3);
            end
            
            % set the font family and size
            hTask.hDisplayClient.setTextSize(hTask.params.user.fontSize);
            hTask.hDisplayClient.setTextFont(hTask.params.user.fontFamily);
            hTask.hDisplayClient.setTextStyle('normal');
        end % END function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            
            % present the operator cue
            if strcmpi(hTask.cTrialParams.cuemodality,'equation')
                drawText(hTask.hDisplayClient,...
                    hTask.cTrialParams.eqInfo.string,...
                    hTask.cTrialParams.eqInfo.position(1),...
                    hTask.cTrialParams.eqInfo.position(2),...
                    hTask.params.user.fontColor,...
                    [],[],[],[],[],...
                    hTask.cTrialParams.eqInfo.bounds);
            elseif strcmpi(hTask.cTrialParams.cuemodality,'symbol') || strcmpi(hTask.cTrialParams.cuemodality,'text')
                drawText(hTask.hDisplayClient,...
                    hTask.cTrialParams.opInfo.string,...
                    hTask.cTrialParams.opInfo.position(1),...
                    hTask.cTrialParams.opInfo.position(2),...
                    hTask.params.user.fontColor,...
                    [],[],[],[],[],...
                    hTask.cTrialParams.opInfo.bounds);
            elseif strcmpi(hTask.cTrialParams.cuemodality,'audio')
                hTask.hSound.play(hTask.cTrialParams.opInfo.soundname);
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
end % END classdef PhaseShowOperation