classdef TrialData < handle & Experiment2.TrialDataInterface & util.Structable & util.StructableHierarchy
    
    properties
        
        % trial info
        tr_prm % struct with parameters for this trial
        tr_responseLoc % the subject's mouse click location
        tr_box % pixel value box for expected response location
        tr_dnkBox % screen center pixel value box for 'don't know' response
        
        % neural data info
        neu_filenames % filenames of the NSP recordings associated with this trial
        
        % event time info
        et_trialStart % frame id when trial starts
        et_trialCompleted % frame id when trial finishes
        et_phase % one entry for each phase, containing frame id
        et_phaseDuration % requested phase duration
        
        % trial exit info
        ex_success % whether trial finished successfully
        response_dist
        target_rad 
    end % END properties
    
    methods
        
        function this = TrialData(hTrial,varargin)
            this = this@Experiment2.TrialDataInterface(hTrial);
        end % END function TrialData
        
        function TrialStartFcn(this,evt,hTask,varargin)
            
            % trial parameters
            this.tr_prm = hTask.cTrialParams;
            
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
        
        function finalize(this,hTask)
            this.neu_filenames = getRecordedFilenames(hTask.hFramework.hNeuralSource);
            this.et_trialCompleted = hTask.hFramework.frameId;
        end % END function finalize
        
        function calculateSuccessImagined(this,hTask,varargin)
            this.ex_success = true;
        end % END function calculateSuccessImagined
        
        function calculateSuccessGNG(this,hTask,varargin)
            this.ex_success = false;
        end % END function calculateSuccessGNG
        
        
        function calculateSuccessActive(this,hTask,varargin)
            %[fixL, fixU, fixR, fixB] = deal(this.tr_dnkBox{:});
            
            %tmp = cell(1,4);
            %[tmp{:}] = arrayfun(@(x)x,this.tr_dnkBox,'UniformOutput',false);
            
            fixL = this.tr_dnkBox(1);
            fixU = this.tr_dnkBox(2);
            fixR = this.tr_dnkBox(3);
            fixB = this.tr_dnkBox(4);
            
            %[xL, yU, xR, yB] = deal(this.tr_box{:});
            xL = this.tr_box(1);
            yU = this.tr_box(2);
            xR = this.tr_box(3);
            yB = this.tr_box(4);
            
            %[mx, my] = deal(this.tr_responseLoc{:});
            %[mx, my] = deal(this.tr_responseLoc{:});
            mx = this.tr_responseLoc(1);
            my = this.tr_responseLoc(2);
            
            [tr_x, tr_y] = RectCenter(this.tr_box);
            x_dist = abs(mx - tr_x);
            y_dist = abs(my - tr_y);
            this.response_dist = sqrt((x_dist^2)+(y_dist^2));
            this.target_rad = xR - tr_x;
            
            if mx > fixL && mx < fixR && my > fixU && my < fixB
                this.ex_success = nan;
            else
                this.ex_success = this.response_dist < this.target_rad*2;
                %this.ex_success = mx > xL && mx < xR && my > yU && my < yB;
            end
        end % END function calculateSuccessActive
        
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