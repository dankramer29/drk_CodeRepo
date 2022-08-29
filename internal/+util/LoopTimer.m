classdef LoopTimer < handle
    properties
        hBuffer % Buffer.Dynamic object to store loop times
        TimerLoopIteration
        TimerGlobal
        IterationNumber
    end % END properties
    
    methods
        function this = LoopTimer(varargin)
            util.argempty(varargin);
        end % END function LoopTimer
        
        function initialize(this)
            this.hBuffer = Buffer.Dynamic;
            this.TimerLoopIteration = tic;
            this.TimerGlobal = tic;
            this.IterationNumber = 0;
        end % END function initialize
        
        function iterationStart(this)
            this.IterationNumber = this.IterationNumber + 1;
            this.TimerLoopIteration = tic;
        end % END function iterationStart
        
        function iterationEnd(this)
            this.hBuffer.add(toc(this.TimerLoopIteration));
        end % END function iterationEnd
        
        function [stat,msg] = getStats(this,varargin)
            [varargin,nl] = util.argkeyval('num_left',varargin,nan);
            [varargin,msg] = util.argkeyval('msg_format',varargin,'(#TOTAL_ELAPSED#; #TOTAL_REMAINING#)');
            util.argempty(varargin);
            
            stat.num_iterations_remaining = nl;
            stat.total_elapsed = toc(this.TimerGlobal);
            stat.all_loop_times = this.hBuffer.get;
            stat.per_iteration = nanmean(stat.all_loop_times);
            stat.total_remaining = stat.per_iteration*stat.num_iterations_remaining;
            
            msg = regexprep(msg,'#TOTAL_ELAPSED#',sprintf('%s elapsed',util.hms(stat.total_elapsed)));
            msg = regexprep(msg,'#TOTAL_REMAINING#',sprintf('%s remaining',util.hms(stat.total_remaining)));
        end % END function update
    end % END methods
end % END classdef LoopTimer