classdef TrialData < handle & Experiment2.TrialDataInterface & util.Structable & util.StructableHierarchy
    
    properties
        % trial info
        tr_word
        tr_l33t
        tr_response_type
        tr_numbers
        tr_letters
        tr_expectedResponse
        tr_response
        
        % neural data info
        neu_filenames       % filenames of the NSP recordings associated with this trial
        
        % event time info
        et_trialStart       % frame id when trial starts
        et_trialCompleted   % frame id when trial finishes
        et_phase            % one entry for each phase, containing frame id
        
        % trial exit info
        ex_success          % whether trial finished successfully
    end % END properties
    
    methods
        
        function this = TrialData(hTrial,varargin)
            this = this@Experiment2.TrialDataInterface(hTrial);
        end % END function TrialData
        
        function TrialStartFcn(this,evt,hTask,varargin)
            
            % trial parameters
            this.tr_word = hTask.cTrialParams.word;
            this.tr_l33t = hTask.cTrialParams.l33t;
            this.tr_response_type = hTask.cTrialParams.response_type;
            this.tr_numbers = hTask.cTrialParams.numbers;
            this.tr_letters = hTask.cTrialParams.letters;
            this.tr_expectedResponse = hTask.cTrialParams.response;
            
            % trial timing
            this.et_trialStart = evt.UserData.frameId;
            this.et_trialCompleted = nan;
            this.et_phase = nan(1,length(hTask.hTrial.phases));
            
            % default not successful
            this.ex_success = false;
        end % END function TrialStartFcn
        
        function TrialEndFcn(this,evt,hTask,varargin)
            finalize(this,hTask);
        end % END function TrialEndFcn
        
        function TrialAbortFcn(this,evt,hTask,varargin)
            finalize(this,hTask);
        end % END function TrialAbortFcn
        
        function PhaseStartFcn(this,evt,hTask,varargin)
            this.et_phase(hTask.hTrial.phaseIdx) = evt.UserData.frameId;
        end % END function PhaseStartFcn
        
        function PhaseEndFcn(this,evt,hTask,varargin)
        end % END function PhaseEndFcn
        
        function finalize(this,hTask)
            this.neu_filenames = getRecordedFilenames(hTask.hFramework.hNeuralSource);
            this.et_trialCompleted = hTask.hFramework.frameId;
        end % END function finalize
        
        function calculateSuccess(this,hTask)
            
            % check for "i don't know" vs. actual response
            if ischar(this.tr_response) && strcmpi(this.tr_response,'x')
                
                % I don't know ==> NaN
                this.ex_success = NaN;
            else
                
                % check against expected response
                switch lower(this.tr_response_type)
                    case 'word'
                        this.ex_success = this.tr_expectedResponse==this.tr_response;
                    case 'number'
                        this.ex_success = this.tr_expectedResponse==str2double(this.tr_response);
                    case 'numberword'
                        this.ex_success = this.tr_expectedResponse==str2double(this.tr_response);
                    otherwise
                        error('Unknown response type ''%s''',this.tr_response_type);
                end
            end
        end % END function calculateSuccess
        
        function skip = structableSkipFields(this)
            skip = structableSkipFields@Experiment2.TrialDataInterface(this);
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Experiment2.TrialDataInterface(this);
        end % END function structableSkipFields
        
        function delete(this)
            delete@Experiment2.TrialDataInterface(this);
        end % END function delete
    end % END methods
end % END classdef TrialData