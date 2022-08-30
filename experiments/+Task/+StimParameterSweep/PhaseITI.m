classdef PhaseITI < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        drawFixationPoint = false;
        cmdValidated
        cmdCreated
        hResponsive
        timer
        str1
        str2
        flag_once = false;
        flag_proceed = false;
    end
    
    methods
        function this = PhaseITI(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
            
        end % END function PhaseITI
        
        function StartFcn(this,evt,hTask,varargin)
            this.timer = tic;
            this.cmdValidated = false;
            this.cmdCreated = false;
            this.str1 = [];
            this.str2 = [];
            % create command object
            if ~hTask.cTrialParams.catch
                hTask.stimCommand = Blackrock.Stimulator2.StimCommand;
                try
                    hTask.stimCommand.configureWaveform(1, ...  % waveform ID
                        hTask.cTrialParams.stimPolarity, ...
                        hTask.cTrialParams.stimPulse, ...
                        hTask.cTrialParams.stimAmplitude, ...
                        hTask.cTrialParams.stimPulseWidth, ...
                        hTask.cTrialParams.stimFrequency, ...
                        hTask.cTrialParams.stimInterphase);
                    hTask.stimCommand.electrode = hTask.cTrialParams.electrodeNumber;
                    hTask.stimCommand.duration  = hTask.cTrialParams.stimDuration;
                    this.cmdCreated = true;
                    if hTask.cTrial==1 || hTask.cTrial==numel(hTask.TrialParams)
                        hTask.hGUI.setTrialInformation(hTask.cTrial,numel(hTask.TrialParams),hTask.cTrialParams.electrodeID,...
                            hTask.cTrialParams.chargeDensity,hTask.cTrialParams.electrodeLabel,...
                            hTask.cTrialParams.stimAmplitude,hTask.cTrialParams.stimFrequency,...
                            hTask.cTrialParams.stimPulseWidth,hTask.cTrialParams.stimDuration,...
                            hTask.cTrialParams.catch);
                    else
                        hTask.hGUI.setTrialInformation((hTask.cTrial-1),numel(hTask.TrialParams),hTask.TrialParams(hTask.cTrial-1).electrodeID,...
                            hTask.TrialParams(hTask.cTrial-1).chargeDensity,hTask.TrialParams(hTask.cTrial-1).electrodeLabel,...
                            hTask.TrialParams(hTask.cTrial-1).stimAmplitude,hTask.TrialParams(hTask.cTrial-1).stimFrequency,...
                            hTask.TrialParams(hTask.cTrial-1).stimPulseWidth,hTask.TrialParams(hTask.cTrial-1).stimDuration,...
                            hTask.TrialParams(hTask.cTrial-1).catch);
                        
                    end
                catch ME
                    util.errorMessage(ME);
                end
            end
            
            % program stimulator with parameter set 1
            if this.cmdCreated
                hTask.hStimulator.configure(hTask.stimCommand);
                comment(hTask, hTask.stimCommand.toString());
            elseif hTask.cTrialParams.catch
                comment(hTask, 'catch trial');
            else
                comment(hTask, 'UNKNOWN PROBLEM -- NO STIM COMMAND CREATED!');
            end
     
            % checking keyboard inputs for pause or continue
            if ~hTask.cTrialParams.catch
                this.hResponsive = Experiment2.Responsive(hTask);
                this.hResponsive.addExpectedResponse('response',{'space'},0.25,0.5);
                this.hResponsive.expectInput;
            end
        

        end % END function StartFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            if this.drawFixationPoint
                hTask.drawFixationPoint;
            end 
        end % END function PreDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            if isempty(this.str1)&& ~strcmpi(this.str1,'space')
                [done1,~,this.str1] = this.hResponsive.checkResponseInputs;
                if done1
                    this.flag_once = true;
                    hTask.hTrial.TrialData.et_pause(1) = evt.UserData.frameId;
                end
            elseif strcmpi(this.str1,'space')&& this.flag_once
                this.hResponsive.resetInput;
                this.hResponsive.addExpectedResponse('response',{'space'},0.25,0.5);
                this.hResponsive.expectInput;
                this.flag_once = false;
            elseif strcmpi(this.str1,'space')&& ~this.flag_once
                disp('Press space key when safe to resume');
                if isempty(this.str2) && ~strcmpi(this.str2,'space')
                    [done2,~,this.str2] = this.hResponsive.checkResponseInputs;
                    if done2
                      hTask.hTrial.TrialData.et_pause(2) = evt.UserData.frameId;   
                    end
                else
                    hTask.hTrial.advance;
                end       
            end
            if toc(this.timer)>6 && ~strcmpi(this.str1,'space')
                this.flag_proceed = true;
                hTask.hTrial.advance;
            end
            % abort trial if command could not be created
            if ~this.cmdCreated
                hTask.hTrial.abort(true,false);
                return;
            end
            % display trial details on screen 2
            if this.flag_proceed || hTask.cTrialParams.catch
                if hTask.cTrial==1 || hTask.cTrial==numel(hTask.TrialParams)
                    str = [sprintf('Trial: %d/%d\n',hTask.cTrial,numel(hTask.TrialParams))...
                        sprintf('Electrode: %s (%d)\n',hTask.cTrialParams.electrodeLabel,hTask.cTrialParams.electrodeID)...
                        sprintf('Charge Density: %0.2f uC/cm2/phase\n\n',hTask.cTrialParams.chargeDensity)...
                        sprintf('Amplitude: %d mA\n',hTask.cTrialParams.stimAmplitude/1e3),...
                        sprintf('Frequency: %d Hz\n',hTask.cTrialParams.stimFrequency)...
                        sprintf('Pulse width: %d us\n',hTask.cTrialParams.stimPulseWidth)...
                        sprintf('Duration: %d ms\n',hTask.cTrialParams.stimDuration*1e3)];
                else
                    str = [sprintf('Trial: %d/%d\n',(hTask.cTrial-1),numel(hTask.TrialParams))...
                        sprintf('Electrode: %s (%d)\n',hTask.TrialParams(hTask.cTrial-1).electrodeLabel,hTask.TrialParams(hTask.cTrial-1).electrodeID)...
                        sprintf('Charge Density: %0.2f uC/cm2/phase\n\n',hTask.TrialParams(hTask.cTrial-1).chargeDensity)...
                        sprintf('Amplitude: %d mA\n',hTask.TrialParams(hTask.cTrial-1).stimAmplitude/1e3),...
                        sprintf('Frequency: %d Hz\n',hTask.TrialParams(hTask.cTrial-1).stimFrequency)...
                        sprintf('Pulse width: %d us\n',hTask.TrialParams(hTask.cTrial-1).stimPulseWidth)...
                        sprintf('Duration: %d ms\n',hTask.TrialParams(hTask.cTrial-1).stimDuration*1e3)];
                end
                if hTask.params.useDisplay
                    hTask.hDisplayClient.setTextSize(60);
                    hTask.hDisplayClient.setTextFont('Times');
                    drawText(hTask.hDisplayClient,str,'center','center',[255 255 255],60);
                end
            end
        end % END function PhaseFcn
    
        
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
end % END classdef PhaseITI