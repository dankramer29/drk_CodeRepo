classdef PhaseShowBisector < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        timer
    end
    
    methods
        function this = PhaseShowBisector(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowBisector
        
        function StartFcn(this,evt,hTask,varargin)
            comment(hTask,'Waiting for response');
            if hTask.params.useSync
                tag = sprintf('tr%03dph%02d',hTask.cTrial,hTask.hTrial.phaseIdx);
                sync(hTask.hFramework,@high,'tag',tag);
            end
            
            % notify the task to expect input
            hTask.expectInput({'bisector',hTask.cTrialParams.response,0.25,0.75},{'dontknow','x',0.25,0.25},'echo',false);
            
            % set the font size
            hTask.hDisplayClient.setTextSize(hTask.cTrialParams.symbolSize);
            hTask.hDisplayClient.setTextFont(hTask.params.user.fontFamily);
            hTask.hDisplayClient.setTextStyle('bold');
            
            % start the timer
            this.timer = tic;
            hTask.hTrial.TrialData.tr_timerBisector = nan;
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            
            % check for response
            [resp,dnk] = hTask.hKeyboard.check('bisector','dontknow');
            if ~isempty(resp)
                if length(resp.anykeys)>1
                    comment(hTask,'Detected multiple keypresses but expected only one - please try again!',1);
                    return;
                end
                hTask.hTrial.TrialData.tr_responseBisector = resp.anykeys{1};
                hTask.hTrial.TrialData.tr_timerBisector = toc(this.timer);
            elseif ~isempty(dnk)
                if length(dnk.anykeys)>1
                    comment(hTask,'Detected multiple keypresses but expected only one - please try again!',1);
                    return;
                end
                hTask.hTrial.TrialData.tr_responseBisector = 'x';
                hTask.hTrial.TrialData.tr_timerBisector = toc(this.timer);
            end
            
            % if response provided, check success and move on
            if ~isempty(hTask.hTrial.TrialData.tr_responseBisector)
                if hTask.hTrial.phaseIdx == length(hTask.hTrial.phaseNames)
                    hTask.hTrial.TrialData.calculateSuccess(hTask);
                    exstr = 'SUCCESS';
                    if isnan(hTask.hTrial.TrialData.ex_success)
                        exstr = 'DONTKNOW';
                    elseif ~hTask.hTrial.TrialData.ex_success
                        exstr = 'FAILURE';
                    end
                    
                    comment(hTask,sprintf('Recorded response ''%s'' (%s)',util.aschar(hTask.hTrial.TrialData.tr_responseBisector),exstr));
                    hTask.hTrial.advance;
                else
                    comment(hTask,sprintf('Recorded response ''%s''',util.aschar(hTask.hTrial.TrialData.tr_responseBisector)));
                    hTask.hTrial.advance;
                end
            end
        end % END function PhaseFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            
            % calculate bisector start and end point
            if strcmpi(hTask.cTrialParams.lineOrientation,'horizontal')
                st = [hTask.cTrialParams.bisectorPosition(1); hTask.cTrialParams.bisectorPosition(2)];
                lt = [hTask.cTrialParams.bisectorPosition(1); hTask.cTrialParams.bisectorPosition(3)];
            elseif strcmpi(hTask.cTrialParams.lineOrientation,'vertical')
                st = [hTask.cTrialParams.bisectorPosition(2); hTask.cTrialParams.bisectorPosition(1)];
                lt = [hTask.cTrialParams.bisectorPosition(3); hTask.cTrialParams.bisectorPosition(1)];
            end
            
            % draw the bisector
            Screen('DrawLine',hTask.hDisplayClient.win,...
                hTask.params.user.bisectorColor,...
                st(1),st(2),lt(1),lt(2),...
                hTask.params.user.bisectorSize);
            
            % draw the text string
            drawText(hTask.hDisplayClient,...
                hTask.cTrialParams.string,...
                hTask.cTrialParams.linePosition(1),...
                hTask.cTrialParams.linePosition(2),...
                hTask.params.user.fontColor,[],[],[],[],[],...
                hTask.cTrialParams.textBounds);
        end % END function PostDrawFcn
        
        function EndFcn(this,evt,hTask,varargin)
            hTask.resetInput('bisector','dontknow');
            if hTask.params.useSync
                sync(hTask.hFramework,@low);
            end
        end % END function EndFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
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
end % END classdef PhaseShowBisector