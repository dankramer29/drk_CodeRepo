classdef PhaseCue < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
        cmdCreated
        cmdValidated
    end
    
    methods
        function this = PhaseCue(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseCue
        
        function StartFcn(this,evt,hTask,varargin)
            this.cmdValidated = false;
            this.cmdCreated = false;
            
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
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            
            if ~hTask.cTrialParams.catch
                
                % abort trial if command could not be created
                if ~this.cmdCreated
                    hTask.hTrial.abort(true,false);
                    return;
                end
                
                % validate the created command
                try
%                     hTask.hStimulator.validate(hTask.stimCommand,hTask.hFramework.hNeuralSource.hGridMap);
                    this.cmdValidated = true;
                catch ME
                    util.errorMessage(ME);
                    hTask.hTrial.abort(true,false);
                end
            end
            
            % show the cue
            if this.cmdValidated || hTask.cTrialParams.catch
                pos = hTask.hDisplayClient.normPos2Client([0 0]);
                diam = hTask.hDisplayClient.normScale2Client(0.1);
                hTask.hDisplayClient.drawOval(pos,diam,[100 100 100]);
            end
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
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
end % END classdef PhaseCue