classdef Dummy < handle & Framework.Video.Interface & util.Structable & util.StructableHierarchy
    % DUMMY Gutless shell of a video object
    
    properties
    end % END properties
    
    methods
        function this = Dummy(fw,cfg)
            % DUMMY Construct a dummy video object
            %
            %   V = DUMMY
            %   Construct a dummy video object
            
            % initialize the superclass
            this = this@Framework.Video.Interface(fw);
            
            % configure
            if ~iscell(cfg),cfg={cfg};end
            feval(cfg{1},this,cfg{2:end});
        end % END function Interface
        
        function initialize(~)
            % INITIALIZE initialize the dummy video object
            %
            %   INITIALIZE(THIS)
            %   Initialize the dummy video object
            
        end % END function initialize
        
        function record(~)
            % RECORD start dummy recording
            %
            %   RECORD(THIS)
            %   Start recording from the dummy video object (but not
            %   really).
            
        end % END function record
        
        function stop(~)
            % STOP stop recording from the dummy object
            %
            %   STOP(THIS)
            %   Stop the fake recording
            
        end % END function stop
        
        function skip = structableSkipFields(this)
            skip1 = structableSkipFields@Framework.Video.Interface(this);
            skip = [{} skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Framework.Video.Interface(this);
            st = util.catstruct(st,st1);
        end % END function structableManualFields
    end % END methods
    
end % END classdef Dummy