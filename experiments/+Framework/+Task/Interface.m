classdef Interface < handle & Framework.Component & util.StructableHierarchy
    
    properties(Abstract)
        nTrials
    end % END properties
    
    methods
        function this = Interface(fw,varargin)
            this = this@Framework.Component(fw,'TASK');
        end % END function Interface
        
        function setState(this,state)
            % SETSTATE set the state of task effector(s)
            %
            %   Overload this method to use incoming state from Framework
            %   to set state of effectors in the task.
        end % END function setState
        
        function st = getState(this)
            % GETSTATE get state of task effector(s)
            %
            %   Overload this method to provide state from task Effector(s)
            %   back to the Framework.
            
            % return nan
            st = nan;
        end % END function getState
        
        function target = getTarget(this)
            % GETTARGET get state of task target(s)
            %
            %   Overload this method to provide target state from task
            %   Target(s) back to the Framework.
            
            % return nan
            target = nan;
        end % END function getTarget
        
        function refresh(this)
            % REFRESH update the display
            %
            %   Update the display
        end % END function refresh
        
        function st = getEventListeners(this)
            % GETEVENTLISTENERS get list of event listeners
            %
            %   Overload this method to provide a list of event listeners
            %   defined by the task.
        
            % default empty for all
            st.effector = {};
            st.target = {};
            st.task = {};
            st.preface = {};
            st.trial = {};
            st.summary = {};
        end % END function getEventListeners
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Framework.Component(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Framework.Component(this);
            st = util.catstruct(st,st1);
        end
    end % END methods
    
    methods(Abstract)
        start(this);
        stop(this);
        update(this);
        beat = heartbeat(this);
        st = toStruct(this);
    end % END methods(Abstract)
    
end % END classdef Interface