classdef TaskObjectInterface < handle & util.StructableHierarchy
    
    properties
        hTask                   % handle to Task object managing this TaskObjectInterface object
        id                      % the task's id for this object
    end
    
    properties(Access=private)
        lhTrial                 % listener handles for trial events
    end % END properties(Access=private)
    
    properties(Abstract)
        type
    end % END properties(Abstract)
    
    methods
        function this = TaskObjectInterface(parent,id)
            this.hTask = parent;
            this.id = id;
            
            % initialize trial listeners
            this.lhTrial.StageEnd = addlistener(this.hTask.hTrial,'StageEnd',@(h,evt)CleanupFcn(this));
        end % END function TaskObjectInterface
        
        function CleanupFcn(this)
        end % END function CleanupFcn
        
        function delete(this)
            if isstruct(this.lhTrial)
                listenerNames = fieldnames(this.lhTrial);
                for m=1:length(listenerNames)
                    delete(this.lhTrial.(listenerNames{m}));
                end
            end
            this.lhTrial = [];
        end % END function delete
        
        function skip = structableSkipFields(this,varargin)
            skip = {'hTask','lhTrial'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this,varargin)
            st = [];
        end % END function structableManualFields
        
    end % END methods
    
    methods(Abstract)
        update(this);
        draw(this);
        toStruct(this);
        st = getState(this);
        setState(this,st);
    end % END methods(Abstract)
    
end % END classdef TaskObjectInterface