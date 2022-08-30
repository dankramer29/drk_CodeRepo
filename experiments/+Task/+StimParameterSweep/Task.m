classdef Task < handle & Experiment2.TaskInterface & Framework.Task.Interface & util.StructableHierarchy & util.Structable
    % STIMPARAMETERSWEEP
    % Spencer Kellis
    % skellis@usc.edu
    %
    % Sweep across a set of stimulation parameters/electrodes. 
    %
    % Valid parameters to sweep:
    %
    %   * Electrode(s) (1-96)
    %   * Frequency (20-300Hz)
    %   * Amplitude (0.5-10mA)
    %   * Duration (>0, <=??)
    %
    % Modify Task.StimParameterSweep.Parameters (or create a new custom
    % Parameters file) to specify which parameters to sweep.
    %
    % When the task indicates "Waiting for response", take this time to
    % note down the patient's response(s). When finished, press the Right
    % Arrow key to continue.
    
    %*********************%
    % CONSTANT PROPERTIES %
    %*********************%
    properties(Constant)
        description = 'Stim parameter sweep task';
    end % END properties(Constant)
    
    properties
        hGUI
        stimCommand
        timer
    end % END properties
    
    %****************%
    % PUBLIC METHODS %
    %****************%
    methods
        
        function this = Task(fw,cfg)
            this = this@Framework.Task.Interface(fw);
            this = this@Experiment2.TaskInterface(cfg);
            this.hGUI = Task.StimParameterSweep.GUI(this);
            this.timer = tic;
        end % END function Task
        
        function TaskStartFcn(this,evt,varargin)
            this.hDisplayClient.pref('TextEncodingLocale','UTF-8');
            % set the font family and size
            this.hDisplayClient.setTextSize(this.params.user.fontSize);
            this.hDisplayClient.setTextFont(this.params.user.fontFamily);
            this.hDisplayClient.setTextStyle('normal');
        end % END function TaskStartFcn
        
        function PrefaceStartFcn(this,evt,varargin)
        end % END function PrefaceStartFcn
        
        function TrialStartFcn(this,evt,varargin)
            numTrialsRemaining = length(this.TrialParams) - this.cTrial + 1;
            secondsRemaining = numTrialsRemaining*this.hStage.duration;
            
            % save information to trial data struct
            comment(this,sprintf('trial %d/%d (%s minutes)',...
                this.cTrial,length(this.TrialParams),...
                util.hms(secondsRemaining,'mm:ss')));
        end % END function TrialStartFcn
        
        function TrialAbortFcn(this,evt,varargin)
            this.hKeyboard.showKeypress;
        end % END function TrialAbortFcn
        
        function TaskEndFcn(this,evt,varargin)
            numUnknown = nnz(isnan([this.TrialData(1:this.nTrials).ex_success]));
            numCorrect = nnz([this.TrialData(1:this.nTrials).ex_success]==true);
            numKnown = this.nTrials-numUnknown;
            comment(this,sprintf('%d trials, %d/%d (%2.0f%%) correct, %d unknown',this.nTrials,numCorrect,numKnown,100*numCorrect/numKnown,numUnknown))
            disp(toc(this.timer));
            try
                deleteGUI(this);
            catch ME
                errorHandler(this,ME);
            end
        end % END function TaskEndFcn
        
        function drawFixationPoint(this)
            user = this.params.user;
            pos = this.hDisplayClient.normPos2Client([0 0]);
            diam = this.hDisplayClient.normScale2Client(user.fixationScale);
            this.hDisplayClient.drawOval(pos,diam,user.fixationColor*user.fixationBrightness)
        end % END function drawFixationPoint
        
        function skip = structableSkipFields(this)
            skip1 = structableSkipFields@Experiment2.TaskInterface(this);
            skip2 = structableSkipFields@Framework.Task.Interface(this);
            skip = [{'hGUI'} skip1 skip2];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st1 = structableManualFields@Experiment2.TaskInterface(this);
            st2 = structableManualFields@Framework.Task.Interface(this);
            st = util.catstruct(st1,st2);
        end % END function structableManualFields
        
        function deleteGUI(this)
            if ~isempty(this.hGUI)
                try
                    close(this.hGUI.hFigure);
                    delete(this.hGUI);
                catch ME
                    util.errorMessage(ME);
                end
            end
        end % END function delete
    end % END methods
end % END classdef Task