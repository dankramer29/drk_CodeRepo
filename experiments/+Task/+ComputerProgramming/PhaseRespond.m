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
            
            % set up Responsive object to handle Keyboard input
            this.hResponsive = Experiment2.Responsive(hTask,'editresponses',true);
            str = sprintf('%d',hTask.cTrialParams.answer);
            this.hResponsive.addExpectedResponse('response',arrayfun(@(x)x,str,'UniformOutput',false),0.25,0.75);
            this.hResponsive.addExpectedResponse('dontknow',{'x'},0.25,0.75);
            this.hResponsive.expectInput;
            
            % play the sound
            if hTask.params.useSound
                hTask.hSound.play('respond');
            end
        end % END function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            
            % draw the code on screen
            drawText(hTask.hDisplayClient,...
                sprintf('%s = ?',hTask.cTrialParams.response_var),...
                600,...
                300,...
                hTask.params.user.fontColor);
            
        end % END function PreDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            
            % check for response
            [done,name,str] = this.hResponsive.checkResponseInputs;
            if done
                
                % assign response field
                switch name
                    case 'response'
                        hTask.hTrial.TrialData.tr_response = str2double(str);
                    case 'dontknow'
                        hTask.hTrial.TrialData.tr_response = str;
                    otherwise
                        error('Unexpected name ''%s''',name);
                end
                
                % check for correct response
                hTask.hTrial.TrialData.calculateSuccess(hTask);
                
                % update user
                exstr = 'SUCCESS';
                if isnan(hTask.hTrial.TrialData.ex_success)
                    exstr = 'DONTKNOW';
                elseif ~hTask.hTrial.TrialData.ex_success
                    exstr = 'FAILURE';
                end
                comment(hTask,sprintf('Recorded response ''%s'' (%s)',util.aschar(hTask.hTrial.TrialData.tr_response),exstr));
                
                % move to next phase
                hTask.hTrial.advance;
            end
        end % END function PhaseFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            comment(hTask,'No response!');
            hTask.hTrial.advance;O
        end % END function TimeoutFcn
        
        function EndFcn(this,evt,hTask,varargin)
            hTask.resetInput('response','dontknow');
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