classdef PhaseStimulate < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        isStimulating
        stimParams
    end
    
    methods
        function this = PhaseStimulate(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseStimulate
        
        function StartFcn(this,evt,hTask,varargin)
            this.isStimulating = false;
            if ~hTask.cTrialParams.catch
                try
                    hTask.hStimulator.start(hTask.stimCommand);
                    this.isStimulating = true;
                catch ME
                    util.errorMessage(ME);
                end
            end
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            if this.isStimulating || hTask.cTrialParams.catch
                str = [sprintf('Trial: %d/%d\n',hTask.cTrial,numel(hTask.TrialParams))...
                    sprintf('Electrode: %s (%d)\n',hTask.cTrialParams.electrodeLabel,hTask.cTrialParams.electrodeID)...
                    sprintf('Charge Density: %0.2f uC/cm2/phase\n\n',hTask.cTrialParams.chargeDensity)...
                    sprintf('Amplitude: %d mA\n',hTask.cTrialParams.stimAmplitude/1e3),...
                    sprintf('Frequency: %d Hz\n',hTask.cTrialParams.stimFrequency)...
                    sprintf('Pulse width: %d us\n',hTask.cTrialParams.stimPulseWidth)...
                    sprintf('Duration: %d ms\n',hTask.cTrialParams.stimDuration*1e3)];
                if hTask.params.useDisplay
                    hTask.hDisplayClient.setTextSize(60);
                    hTask.hDisplayClient.setTextFont('Times');
                    drawText(hTask.hDisplayClient,str,'center','center',[200 0 200],60);
                end
%                 pos = hTask.hDisplayClient.normPos2Client([0 0]);
%                 diam = hTask.hDisplayClient.normScale2Client(0.2);
%                 hTask.hDisplayClient.drawOval(pos,diam,[200 0 200]);
                if this.isStimulating && ~hTask.cTrialParams.catch
                    this.stimParams = hTask.cTrialParams;
                end
            end
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
            if ~hTask.cTrialParams.catch
                hTask.hStimulator.stop;
                hTask.hGUI.plotElectrodeHist();
                hTask.hGUI.plotParameterHist();
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
end % END classdef PhaseStimulate