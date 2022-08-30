classdef ExternalControl < handle & Framework.Sync.Interface & util.StructableHierarchy & util.Structable
    
    properties(SetAccess='private',GetAccess='public')
        state % the logical pulse state (true = high, false = low)
        stopwatch % mark start of time measurement
        timer % count elapsed time on stopwatch
        neuralCommentId = 1024;
    end % END properties(SetAccess='private',GetAccess='public')
    
    methods
        function this = ExternalControl(fw,varargin)
            this = this@Framework.Sync.Interface(fw);
        end % END function ExternalControl
        
        function initialize(this)
            registerBuffer(this.hFramework,'sync','r');
            this.state = false;
            this.stopwatch = tic;
            this.timer = inf;
        end % END function initialize
        
        function start(~)
        end % END function start
        
        function update(this)
            if toc(this.stopwatch)>=this.timer
                comment(this,'Sync pulse end',3);
                this.state = ~this.state;
                this.timer = inf;
            end
            add(this.hFramework.buffers,'sync',this.state);
        end % END function update
        
        function stop(this)
            this.state = false;
        end % END function stop
        
        function status = pulse(this,type,len)
            if nargin<2||isempty(type)
                type = 'time';
            end
            if nargin<3||isempty(len)
                if strncmpi(type,'time',2)
                    len = 0.25;
                elseif strncmpi(type,'frames',2)
                    len = 5;
                end
            end
            if this.state
                status = false;
                comment(this,'Sync already high',5);
                return;
            else
                status = true;
                this.state = true;
                if strncmpi(type,'frames',2)
                    len = len*this.hFramework.options.timerPeriod;
                end
                comment(this,sprintf('Sync pulse begin (%.2 seconds)',len),3);
                this.stopwatch = tic;
                this.timer = len;
            end
        end % END function pulse
        
        function high(this)
            comment(this,'Sync high',3);
            this.state = true;
            this.stopwatch = tic;
            this.timer = inf;
        end % END function high
        
        function low(this)
            comment(this,'Sync low',3);
            this.state = false;
            this.stopwatch = tic;
            this.timer = inf;
        end % END function low
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Framework.Sync.Interface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Framework.Sync.Interface(this);
            st = util.catstruct(st,st1);
        end
    end % END methods
end % END classdef ExternalControl