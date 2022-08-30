classdef PhaseRespond < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        hResponsive
    end
    
    methods
        function this = PhaseRespond(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:})
        end % END function PhaseRespond
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useSync
                tag = sprintf('tr%03dph%02d',hTask.cTrial,hTask.hTrial.phaseIdx);
                sync(hTask.hFramework,@high,'tag',tag);
                comment(hTask,'Sending sync high',3);
            end
            
            % Set up Responsive object to handle Keyboard input
            this.hResponsive = Experiment2.Responsive(hTask,'editresponses',true);
            if ~hTask.cTrialParams.catch
                rsp = {'y','n'};
            else
                rsp = {'c'};
            end
            this.hResponsive.addExpectedResponse('response',rsp,0.25,0.75);
            this.hResponsive.addExpectedResponse('dontknow',{'x'},0.25,0.75);
            this.hResponsive.expectInput;
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            % check for keyboard inputs
            [done,name,str] = this.hResponsive.checkResponseInputs;
            if ~done,return;end
            
            % process inputs
            if any(strcmpi(name,{'response','dontknow'}))
                
                % determine whether correct response
                if any(strcmpi(str,{'y','n','x'}))
                    hTask.hTrial.TrialData.tr_response = str;
                end
                hTask.hTrial.TrialData.calculateSuccess(hTask);
                
                % update user
                exstr = 'SUCCESS';
                if isnan(hTask.hTrial.TrialData.ex_success)
                    exstr = 'DONTKNOW';
                elseif ~hTask.hTrial.TrialData.ex_success
                    exstr = 'FAILURE';
                end
                comment(hTask,sprintf('Recorded response "%s" (%s)',util.aschar(hTask.hTrial.TrialData.tr_response),exstr));
                
                % move on
                hTask.hTrial.advance;
            end
        end % END function PhaseFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
              % During Response phase shows no cue
%             % present cue
%             switch lower(hTask.cTrialParams.cue_modality)
%                 case 'text'
%                     drawText(hTask.hDisplayClient,hTask.cTrialParams.cue_word,'center','center',hTask.params.user.fontBrightness*hTask.cTrialParams.cue_rgb);
%                 case 'color'
%                     drawRect(hTask.hDisplayClient,hTask.params.user.blockPosition,hTask.params.user.blockSize,hTask.params.user.blockBrightness*hTask.cTrialParams.cue_rgb);
%                 otherwise
%                     error('Unknown cue modality "%s"',hTask.cTrialParams.cue_modality);
%             end
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
end % END classdef PhaseRespond