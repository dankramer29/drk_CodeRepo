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
            
            % set the font size
            hTask.hDisplayClient.setTextSize(hTask.params.user.operationFontSize);
            hTask.hDisplayClient.setTextFont(hTask.params.user.operationFontFamily);
            if hTask.params.useSync
                sync(hTask.hFramework,@high);
            end
        end % END function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            
            % draw the text
            drawText(hTask.hDisplayClient,...
                hTask.cTrialParams.operationString,...
                hTask.cTrialParams.operationPosition(1),...
                hTask.cTrialParams.operationPosition(2),...
                hTask.params.user.operationFontColor,...
                [],[],[],[],[],...
                hTask.cTrialParams.operationBounds);
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