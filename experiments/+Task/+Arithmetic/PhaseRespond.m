classdef PhaseRespond < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        hResponsive
    end
    
    methods
        function this = PhaseRespond(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseRespond
        
        function StartFcn(this,evt,hTask,varargin)
            comment(hTask,'Waiting for response');
            
            % Set up Responisve object to handle Keyboard input
            this.hResponsive = Experiment2.Responsive(hTask,'editresponses',true);
            if strcmpi(hTask.cTrialParams.catch,'none')
                rsp = {sprintf('%d',hTask.cTrialParams.answer)};
            else
                rsp = {'c'};
            end
            this.hResponsive.addExpectedResponse('response',rsp,0.25,0.75);
            this.hResponsive.addExpectedResponse('dontknow',{'x'},0.25,0.75);
            this.hResponsive.expectInput;
            
            % play the sound
            if hTask.params.useSound
                hTask.hSound.play('respond');
            end
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            
            % check for keyboard inputs
            [done,name,str] = this.hResponsive.checkResponseInputs;
            if ~done,return;end
            
            % process inputs
            if any(strcmpi(name,{'response','dontknow'}))
                
                % determine whether correct response
                if strcmpi(str,'c') || strcmpi(str,'x')
                    hTask.hTrial.TrialData.tr_response = str;
                else
                    hTask.hTrial.TrialData.tr_response = str2double(str);
                end
                hTask.hTrial.TrialData.calculateSuccess(hTask);
                
                % update user
                exstr = 'SUCCESS';
                if isnan(hTask.hTrial.TrialData.ex_success)
                    exstr = 'DONTKNOW';
                elseif ~hTask.hTrial.TrialData.ex_success
                    exstr = 'FAILURE';
                end
                comment(hTask,sprintf('Recorded response ''%s'' (%s)',util.aschar(hTask.hTrial.TrialData.tr_response),exstr));
                
                % move on
                hTask.hTrial.advance;
            end
        end % END function PhaseFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            comment(hTask,'No response!');
            hTask.hTrial.advance;
        end % END function TimeoutFcn
        
        function EndFcn(this,evt,hTask,varargin)
            this.hResponsive.resetInput;
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
end % END classdef PhaseRespond