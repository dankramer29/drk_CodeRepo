classdef CircularCollection < handle
    %CircularCollection Object properties and methods.
    %
    % Class to manage a collection of Buffer.Circular objects.
    %
    % CircularCollection properties (read-only)
    %   numBuffers      - number of buffers currently registered
    %   bufferNames     - names of the currently registered buffers
    %   buffers         - cell array of all the actual buffers
    %   capacity        - total capacity of each buffer
    %
    % CircularCollection methods
    % Constructor:
    %   Buffer.CircularCollection
    %
    % General
    %   register        - register a new buffer
    %   deregister      - remove a buffer
    %   add             - store new data in a buffer
    %   get             - read data from a buffer
    %   getAll          - read all data from a buffer
    %   getAllBuffers   - read all data from all buffers
    %   reset           - reset all buffers to empty (preserving other
    %                     properties)
    %   exists          - check whether a buffer already exists
    %   numEntries      - get number of entries in a buffer
    %   isempty         - find out whether a buffer is empty
    
    properties(SetAccess='private',GetAccess='public')
        numBuffers = 0;
        bufferNames = cell(0,1);
        buffers = cell(0,1);
        capacity = 100;
    end
    
    methods
        function this = CircularCollection(varargin)
            %CIRCULARCOLLECTION Construct CircularCollection object.
            %
            %    S = CIRCULARCOLLECTION returns an empty CircularCollection
            %    object in S, with capacity set to default (100).
            %
            %    S = CIRCULARCOLLECTION(CAPACITY) returns an empty
            %    CircularCollection object in S with capacity set to
            %    CAPACITY.
            
            % user-specified capacity
            if nargin>0
                this.capacity = varargin{1};
            end
            
        end % END function CircularCollection
        
        function register(this,name,varargin)
            %REGISTER Register a new buffer
            %    
            %    REGISTER(S,NAME) registers a new buffer. The 
            %    buffer will be identified by NAME for adding and 
            %    retrieving data, and will have CAPACITY data capacity.
            %
            %    REGISTER(S,NAME,INPUT) 
            %    If INPUT=='r' or INPUT=='c', the new buffer will be a 
            %    numerical buffer and INPUT will be interpreted as defining
            %    the mode ('r' for row, 'c' for column) in which new data 
            %    is added to the buffer.  If INPUT=='object', the new 
            %    buffer will be an object buffer instead of a numerical 
            %    buffer.
            %    
            
            % mode: 'c' or 'r'
            % type: 'numeric' or 'object'
            mode='c';
            type='numeric';
            if nargin>=3
                if any(strcmpi({'c','r'},varargin{1}))
                    mode=varargin{1};
                elseif any(strcmpi({'object','numeric'},varargin{1}))
                    type=varargin{1};
                end
            end
            
            % register name, init main buffer
            this.bufferNames{end+1} = name;
            if strcmpi(type,'cell')
                this.buffers{end+1} = {};
            elseif strcmpi(type,'object')
                this.buffers{end+1} = Buffer.ObjectCircular(this.capacity);
            else
                this.buffers{end+1} = Buffer.Circular(this.capacity,mode);
            end
            
            % update number of buffers
            this.numBuffers = this.numBuffers + 1;
        end % END function register
        
        function deregister(this,name)
            %DEREGISTER Remove a buffer.
            %
            %     DEREGISTER(S,NAME) deregisters the buffer from the
            %     CircularCollection object.
            
            % check that it exists
            if ~exists(this,name)
                error('Buffer:CircularCollection:unknownBuffer','Buffer ''%s'' does not exist',name);
            end
            idx = strcmpi(this.bufferNames,name);
            
            % remove it
            this.bufferNames(idx) = [];
            this.buffers(idx) = [];
            this.numBuffers = this.numBuffers - 1;
            
        end % END function deregister
        
        function add(this,name,varargin)
            %ADD put data into any registered buffer
            %
            %    ADD(B,NAME,DATA) puts the data in DATA into the 
            %    registered buffer named NAME.
            
            % must be registered already
            if ~exists(this,name)
                error('Buffer:CircularCollection:unknownBuffer','Buffer ''%s'' does not exist',name);
            end
            idx = strcmpi(this.bufferNames,name);
            
            % all ok ==> add data
            add(this.buffers{idx},varargin{:});
        end % END function add
        
        function data = get(this,name,varargin)
            %GET retrieve data from any registered buffer
            %
            %    DATA = GET(B,NAME) retrieves one (most recent) data entry
            %    stored in the buffer B.
            %
            %    DATA = GET(B,NAME,AMOUNT) retrieves AMOUNT most recent
            %    data entries stored in the buffer B.
            %
            %    DATA = GET(B,NAME,'all') retrieves all data from the
            %    buffer B.
            
            % check existence
            if ~exists(this,name)
                error('Buffer:CircularCollection:unknownBuffer','Buffer ''%s'' does not exist',name);
            end
            idx = strcmpi(this.bufferNames,name); % buffer index
            
            % user input: amount to return
            amount = 1;
            if ~isempty(varargin)
                if isnumeric(varargin{1}) % requested a specific number
                    amount = varargin{1};
                elseif ischar(varargin{1}) % requested 'all'
                    amount = this.buffers{idx}.numEntries;
                end
            end
            
            % retrieve data
            data = get(this.buffers{idx},amount);
        end % END function get
        
        function [data,names] = all(this)
            % ALL retrieve all data from all registered buffers
            %
            %    DATA = all(B) retrieves all data stored in all registered 
            %    buffers.
            
            % retrieve data into a cell array
            names = this.bufferNames;
            data = cell(this.numBuffers,1);
            for idx=1:this.numBuffers
                data{idx} = get(this.buffers{idx},this.buffers{idx}.capacity);
            end
            
        end % END function get
        
        function reset(this)
            %RESET resets all registered buffers to empty
            %
            %    RESET(B) resets all registered buffers to empty
            
            for idx=1:this.numBuffers
                this.buffers{idx} = empty(this.buffers{idx});
            end
        end % END function reset
        
        function x = exists(this,name)
            %EXISTS check whether a buffer is registered
            %
            %    EXISTS(B,NAME) check whether buffer named NAME is
            %    registered.
            
            x = any(strcmpi(this.bufferNames,name));
        end % END function exists
        
        function n = numEntries(this,name)
            %NUMENTRIES get number of entries for specified buffer
            %
            %    NUMENTRIES(B,NAME) returns the number of entries for the
            %    buffer named NAME.
            
            idx = strcmpi(this.bufferNames,name);
            n = this.buffers{idx}.numEntries;
        end % END function numEntries
        
        function n = isempty(this,name)
            %ISEMPTY find out whether specified buffer is empty
            %
            %    ISEMPTY(B,NAME) returns whether the specified buffer is 
            %    empty.
            
            idx = strcmpi(this.bufferNames,name);
            n = this.buffers{idx}.isempty;
        end % END function isempty
        
    end % END methods
    
end % END classdef StreamBuffer