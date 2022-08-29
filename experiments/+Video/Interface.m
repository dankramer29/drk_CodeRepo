classdef Interface < handle & util.StructableHierarchy
    % INTERFACE Required superclass for all Video objects
    
    properties(SetAccess=private)
        status % status of the video object
        errorId % ID of most recent error
    end % END properties
    
    methods
        function this = Interface(varargin)
            % INTERFACE Constructor for the Interface class
            %
            %   V = INTERFACE
            %   Construct an object V of the Interface class.
            
        end % END function Interface
        
        function setStatus(this,newStatus)
            % SETSTATUS set the status of the Interface object
            %
            %   SETSTATUS(THIS,NEWSTATUS)
            %   Set the status of the Interface object to NEWSTATUS.
            %   NEWSTATUS must be of type 'Video.Status'.
            
            % make sure newStatus is not empty and is correct type
            assert(~isempty(newStatus),'must provide status argument');
            assert(isa(newStatus,'Video.Status'),'invalid status ''%s''',char(newStatus));
            
            % remember the old status to compare
            oldStatus = this.status;
            
            % check for error
            if (isempty(oldStatus) || newStatus ~= oldStatus) && newStatus == Video.Status.ERROR
                fprintf('\n');
                fprintf('****************************************\n');
                fprintf('** The video module reported an error **\n');
                fprintf('****************************************\n');
                fprintf('\n');
            end
            
            % assign new status
            this.status = newStatus;
        end % END function setStatus
        
        function setErrorId(this,eid)
            % SETERRORID Set the error ID of the Interface object
            %
            %   SETERRORID(THIS,EID)
            %   Set the error ID of the Interface object to EID.
            
            this.errorId = eid;
        end % END function setErrorId
        
        function skip = structableSkipFields(~)
            skip = {};
        end % END function structableSkipFields
        
        function st = structableManualFields(~)
            st = [];
        end % END function structableManualFields
    end % END methods
    
    methods(Abstract)
        initialize(this); % initialize the Video object
        record(this); % start recording video and audio
        setNeuralSync(this,state); % enable or disable neural synchronization
        setIDString(this,str); % set the ID string of recorded files
        stop(this); % stop recording video and audio
    end % END methods(Abstract)
    
end % END classdef Interface