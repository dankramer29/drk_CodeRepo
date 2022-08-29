classdef PhaseShowSymbols_NoResponse < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        drawFixationPoint = false;
    end
    
    methods
        function this = PhaseShowSymbols_NoResponse(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowSymbols_NoResponse
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                tag = sprintf('tr%03dph%02d',hTask.cTrial,hTask.hTrial.phaseIdx);
                sync(hTask.hFramework,@high,'tag',tag);
            end
        end % END function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            if this.drawFixationPoint
                hTask.drawFixationPoint;
            end
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            
            % draw the answer
            hTask.drawSymbol(hTask.cTrialParams.symbol,hTask.cTrialParams.answerParams);
            
            % draw the distractor
            hTask.drawSymbol(hTask.cTrialParams.symbol,hTask.cTrialParams.distractorParams);
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
end % END classdef PhaseShowSymbols