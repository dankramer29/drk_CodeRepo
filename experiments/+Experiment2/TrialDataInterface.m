classdef TrialDataInterface < handle & util.StructableHierarchy
    
    properties(Access=private)
        lhTrial
    end % END properties
    
    methods
        function this = TrialDataInterface(hTrial)
            
            % initialize trial listeners
            eventsTrial = events(hTrial);
            eventsTrial( strcmpi(eventsTrial,'ObjectBeingDestroyed') ) = [];
            for m=1:length(eventsTrial)
                this.lhTrial.(eventsTrial{m}) = addlistener(hTrial,eventsTrial{m},@(~,evt)processEvents(hTrial.hTask,evt));
            end
            
            function processEvents(hTask,evt)
                switch evt.EventName
                    case 'PhaseStart',  fn = @PhaseStartFcn;
                    case 'PhaseEnd',    fn = @PhaseEndFcn;
                    case 'StageStart',  fn = @TrialStartFcn;
                    case 'StageEnd',    fn = @TrialEndFcn;
                    case 'StageAbort',  fn = @TrialAbortFcn;
                    otherwise, fn = @(x,y,z)true;
                end
                try feval(fn,this,evt,hTask); catch ME, util.errorMessage(ME); end
            end % END function processEvents
            
        end % END function TrialDataInterface
        
        function PhaseStartFcn(this,evt,hTask,varargin)
            % PHASESTARTFCN executes at the beginning of each phase
            %
            %  Overload this method to define what data should be saved at
            %  the beginning of each phase
            
        end % END function PhaseStartFcn
        
        function PhaseEndFcn(this,evt,hTask,varargin)
            % PHASEENDFCN executes at the end of each phase
            %
            %  Overload this method to define what data should be saved at
            %  the end of each phase
        end % END function PhaseEndFcn
        
        function TrialStartFcn(this,evt,hTask,varargin)
            % TRIALSTARTFCN executes at the beginning of each trial
            %
            %  Overload this method to define what data should be saved at
            %  the beginning of each trial
            
        end % END function TrialStartFcn
        
        function TrialEndFcn(this,evt,hTask,varargin)
            % TRIALENDFCN executes at the end of each trial
            %
            %  Overload this method to define what data should be saved at
            %  the end of each trial
            
        end % END function TrialEndFcn
        
        function TrialAbortFcn(this,evt,hTask,varargin)
            % TRIALABORTFCN executes when a trial aborts
            %
            %  Overload this method to define what data should be saved
            %  when a trial aborts
            
        end % END function TrialAbortFcn
        
        function delete(this)
            if isstruct(this.lhTrial)
                listenerNames = fieldnames(this.lhTrial);
                for m=1:length(listenerNames)
                    delete(this.lhTrial.(listenerNames{m}));
                end
            end
            this.lhTrial = [];
        end % END function delete
        
        function skip = structableSkipFields(~)
            skip = {'lhTrial'};
        end % END function structableSkipFields
        
        function st = structableManualFields(~)
            st = [];
        end % END function structableManualFields
    end % END methods
    
    methods(Abstract)
        st = toStruct(this);
    end % END methods(Abstract)
    
end % END classdef TrialDataInterface