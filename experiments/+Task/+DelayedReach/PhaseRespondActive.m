classdef PhaseRespondActive < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseRespondActive(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseRespondActive
        
        function StartFcn(this,evt,hTask,varargin)
            
            comment(hTask,'Waiting for response');
            
            %starts event log for touch screen
            tsIndex = 1;
            KbQueueCreate(tsIndex);
            KbQueueStart(tsIndex);
            
        end % END function StartFcn
 
        function PreDrawFcn(this,evt,hTask,varargin)
        end % END function PreDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            
            tsIndex = 1;
            
            %checks if mouse has been pressed, records location when
            %pressed 
            [tsPressed] = KbQueueCheck(tsIndex);
            if tsPressed
                [mx,my,~] = GetMouse(2);
                %store screen press location
                hTask.hTrial.TrialData.tr_responseLoc = [mx my];
            end
                
            % register cue rectangle parameters 
            pos = hTask.cTrialParams.target;     
            sz = hTask.params.user.targetScale;
            pos = hTask.hDisplayClient.normPos2Client(pos);
            sz = hTask.hDisplayClient.normScale2Client(sz);
            
            % Create expected response pixel bounds [LEFT(xL) TOP(yU) RIGHT(xR) BOTTOM(yB)]
            %tr_box = DisplayClient.PsychToolbox.convertToBox(pos, sz);
            %hTask.hTrial.TrialData.tr_box = num2cell(tr_box);
            hTask.hTrial.TrialData.tr_box = DisplayClient.PsychToolbox.convertToBox(pos, sz);
            
            % create location for don't know click as box at screen center
            dnkPos = hTask.hDisplayClient.normPos2Client([0 0]);
            dnkSz = sz;
            
            % Create don't know pixel bounds [LEFT(xL) TOP(yU) RIGHT(xR) BOTTOM(yB)]
            %dnkBox = DisplayClient.PsychToolbox.convertToBox(dnkPos, dnkSz);
            %hTask.hTrial.TrialData.tr_dnkBox = num2cell(dnkBox);
            hTask.hTrial.TrialData.tr_dnkBox = DisplayClient.PsychToolbox.convertToBox(dnkPos, dnkSz);
            
            % check click location success
            if ~isempty(hTask.hTrial.TrialData.tr_responseLoc)
                hTask.hTrial.TrialData.calculateSuccessActive(hTask);
                exstr = 'SUCCESS';
                if isnan(hTask.hTrial.TrialData.ex_success)
                    exstr = 'DONTKNOW';
                elseif ~hTask.hTrial.TrialData.ex_success
                    exstr = 'FAILURE';
                end
                % util.aschar is basically num2str
                comment(hTask,sprintf('Recorded response ''%s'' (%s)',util.aschar(hTask.hTrial.TrialData.tr_responseLoc),exstr));
                hTask.hTrial.advance;
            end
            
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
            tsIndex = 1;
            KbQueueStop(tsIndex);
            KbQueueRelease(tsIndex);
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
end % END classdef PhaseRespondActive