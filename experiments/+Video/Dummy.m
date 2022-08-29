classdef Dummy < handle & Video.Interface & Utilities.Structable & Utilities.StructableHierarchy
    % DUMMY Gutless shell of a video object
    
    properties
    end % END properties
    
    methods
        function this = Dummy(varargin)
            % DUMMY Construct a dummy video object
            %
            %   V = DUMMY
            %   Construct a dummy video object
            
        end % END function Interface
        
        function initialize(this)
            % INITIALIZE initialize the dummy video object
            %
            %   INITIALIZE(THIS)
            %   Initialize the dummy video object
            
            this.setStatus(Video.Status.OFF);
        end % END function initialize
        
        function record(this)
            % RECORD start dummy recording
            %
            %   RECORD(THIS)
            %   Start recording from the dummy video object (but not
            %   really).
            
            this.setStatus(Video.Status.RECORDING);
        end % END function startRecording
        
        function stop(this)
            % STOP stop recording from the dummy object
            %
            %   STOP(THIS)
            %   Stop the fake recording
            
            this.setStatus(Video.Status.OFF);
        end % END function stopRecording
        
        function skip = structableSkipFields(this)
            skip1 = structableSkipFields@Video.Interface(this);
            skip = [{} skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Video.Interface(this);
            st = Utilities.catstruct(st,st1);
        end % END function structableManualFields
    end % END methods
    
end % END classdef Dummy