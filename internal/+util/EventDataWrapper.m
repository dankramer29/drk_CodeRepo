classdef EventDataWrapper < event.EventData
    % EVENTDATAWRAPPER Class for attaching custom data to events
    %
    %   This class provides an intuitive interface for attaching custom 
    %   data to an event.
    %
    %   Example:
    %   >> evt = util.EventDataWrapper('key1',val1);
    %   >> notify(obj,'EventName',evt);
    %
    %   Note that 'notify' is only available from within a handle class.
    %
    %   See also NOTIFY.
    
    properties
        UserData % struct for holding custom event data
    end
    
    methods
        function this = EventDataWrapper(varargin)
            % EVENTDATAWRAPPER Constructor for EventDataWrapper class
            %
            %   THIS = EVENTDATAWRAPPER(KEY,VAL,...)
            %   Create an EventDataWrapper object with a single property,
            %   UserData, which contains fields and values given by
            %   consecutive pairs of input arguments.
            %
            %   THIS = EVENTDATAWRAPPER(EVT,KEY,VAL,...)
            %   If EVT is a struct with field UserData, EVT.UserData will
            %   be merged with the struct created by further arguments 
            %   provided to the constructor.
            
            % return immediately if no inputs
            if nargin==0,return;end
            
            % allow first input to be an existing event data object
            st.UserData = struct;
            if isstruct(varargin{1}) && isfield(varargin{1},'UserData')
                st = varargin{1};
                varargin(1) = [];
            end
            
            % create custom fields based on local input arguments
            idx = 1;
            while idx<length(varargin)
                st.UserData.(varargin{idx}) = varargin{idx+1};
                idx = idx+2;
            end
            
            % create the combined user data struct
            this.UserData = st.UserData;
        end
    end
end % END classdef EventDataWrapper