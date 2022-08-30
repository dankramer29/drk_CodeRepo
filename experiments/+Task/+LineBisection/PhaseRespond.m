classdef PhaseRespond < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseRespond(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseRespond
        
        function StartFcn(this,evt,hTask,varargin)
            comment(hTask,'Waiting for response');
            
            % notify the task to expect input
            hTask.expectInput({'symbol',hTask.cTrialParams.symbol,0.25,0.75},{'dontknow','x',0.25,0.25},'echo',false);
            
            % play the sound
            if hTask.params.useSound
                hTask.hSound.play('respond');
            end
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            
            % check for response
            [sym,dnk] = hTask.hKeyboard.check('symbol','dontknow');
            if ~isempty(sym)
                if length(sym.anykeys)>1
                    comment(hTask,'Detected multiple keypresses but expected only one - please try again!',1);
                    return;
                end
                hTask.hTrial.TrialData.tr_responseSymbol = sym.anykeys{1};
            elseif ~isempty(dnk)
                if length(dnk.anykeys)>1
                    comment(hTask,'Detected multiple keypresses but expected only one - please try again!',1);
                    return;
                end
                hTask.hTrial.TrialData.tr_responseSymbol = 'x';
            end
            
            % if response provided, check success and move on
            if ~isempty(hTask.hTrial.TrialData.tr_responseSymbol)
                hTask.hTrial.TrialData.calculateSuccess(hTask);
                exstr = 'SUCCESS';
                if isnan(hTask.hTrial.TrialData.ex_success)
                    exstr = 'DONTKNOW';
                elseif ~hTask.hTrial.TrialData.ex_success
                    exstr = 'FAILURE';
                end
                comment(hTask,sprintf('Recorded response ''%s'' (%s)',util.aschar(hTask.hTrial.TrialData.tr_responseSymbol),exstr));
                hTask.hTrial.advance;
            end
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
            hTask.resetInput('symbol','dontknow');
        end % END function EndFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            comment(hTask,'No response!');
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
end % END classdef PhaseRespond