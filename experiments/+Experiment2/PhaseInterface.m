classdef PhaseInterface < handle & util.StructableHierarchy
    
    properties
       durationTimeoutFcn
       phaseStartFrame
    end
    
    properties(Abstract)
        id
        Name
        durationTimeout
    end % END properties(Abstract)
    
    methods
        function this = PhaseInterface(varargin)
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
        end % END function PhaseInterface
        
        function StartFcn(this,evt,hTask,varargin)
            % STARTFCN runs when phase starts
        end % END function StartFcn
        
        function EndFcn(this,evt,hTask,varargin)
            % ENDFCN runs when phase ends
        end % END function EndFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            % PHASEFCN runs each update cycle while phase is current
        end % END function PhaseFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            % PREDRAWFCN runs before task draw function, each update cycle
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            % POSTDRAWFCN runs after task draw function, each update cycle
        end % END function PostDrawFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            % TIMEOUTFCN runs on trial timeout
        end % END function TimeoutFcn
        
        function skip = structableSkipFields(this)
            skip = {};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
        end % END function structableManualFields
        
        function dur = getDurationTimeout(this,flag_mean_value)
            if nargin<2||isempty(flag_mean_value),flag_mean_value=false;end
            dur = this.durationTimeout;
            if isa(dur,'function_handle')
                if flag_mean_value
                    dur = nanmean(arrayfun(dur,1:1000));
                else
                    dur = feval(dur);
                end
            elseif isnumeric(dur) && numel(dur)>1
                assert(any(size(dur)==1),'Duration must be 1xN vector');
                dur = dur(this.hTask.cTrial);
                if dur>50,dur=2.5;end % estimate 2.5 sec for response phases
            elseif isinf(dur)
                dur = 1000; % substitute 1000 seconds for infinite
            end
            assert(isscalar(dur),'Duration must be scalar, not "%s"',class(dur));
            if dur<0,dur=0;end % never allow negative durations
            dur = round(dur*1000)/1000; % round to nearest millisecond
        end % END function getDurationTimeout
    end % END methods
    
    methods(Abstract)
    end % END methods(Abstract)
    
end % END classdef PhaseInterface