classdef DynamicCollection < handle
    %DynamicCollection Object properties and methods.
    %
    % Class to manage a collection of Dynamic objects.
    %
    % DynamicCollection properties (read-only)
    %   numBuffers      - number of buffers currently registered
    %   bufferNames     - names of the currently registered buffers
    %   buffers         - cell array of all the actual buffers
    %
    % DynamicCollection methods
    % Constructor:
    %   Buffer.DynamicCollection
    %
    % General
    %   register        - register a new buffer
    %   deregister      - remove a buffer
    %   add             - store new data in a buffer
    %   get             - read data from a buffer
    %   all             - read all data from all buffers
    %   reset           - reset all buffers to empty (preserving other
    %                     properties)
    %   exist           - check whether a buffer already exists
    %   numEntries      - get number of entries in a buffer
    %   isempty         - find out whether a buffer is empty
    
    properties(SetAccess='private',GetAccess='public')
        numBuffers = 0;
        bufferNames = cell(0,1);
        buffers = cell(0,1);
    end
    
    methods
        function this = DynamicCollection
            %DYNAMICCOLLECTION Construct DynamicCollection object.
            %
            %    S = DYNAMICCOLLECTION returns an empty DynamicCollection
            %    object in S.
            
        end % END function DynamicCollection
        
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
                if any(strcmpi({'c','r'},varargin{1})) % column or row
                    mode=varargin{1};
                elseif any(strcmpi({'object','numeric'},varargin{1}))
                    type=varargin{1};
                end
            end
            
            % check for duplicate
            if exist(this,name)
                error('Buffer:DynamicCollection:existingBuffer','Buffer ''%s'' already exists',name);
            end
            
            % register name, init main buffer
            this.bufferNames{end+1} = name;
            if strcmpi(type,'cell')
                this.buffers{end+1} = {};
            elseif strcmpi(type,'object')
                this.buffers{end+1} = Buffer.ObjectDynamic;
            else
                this.buffers{end+1} = Buffer.Dynamic(mode);
            end
            
            % update number of buffers
            this.numBuffers = this.numBuffers + 1;
        end % END function register
        
        function deregister(this,name)
            %DEREGISTER Remove a buffer.
            %
            %     DEREGISTER(S,NAME) deregisters the buffer from the
            %     DynamicCollection object.
            
            % check that it exists
            if ~exist(this,name)
                error('Buffer:DynamicCollection:unknownBuffer','Buffer ''%s'' does not exist',name);
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
            if ~exist(this,name)
                error('Buffer:DynamicCollection:unknownBuffer','Buffer ''%s'' does not exist',name);
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
            assert(exist(this,name),'Buffer:DynamicCollection:unknownBuffer','Buffer ''%s'' does not exist',name);
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
            for idx=1:length(this)
                data{idx} = get(this.buffers{idx},this.buffers{idx}.numEntries);
            end
            
        end % END function get
        
        function reset(this)
            %RESET resets all registered buffers to empty
            %
            %    RESET(B) resets all registered buffers to empty
            
            for k=1:length(this)
                empty(this.buffers{k});
            end
        end % END function reset
        
        function x = exist(this,name)
            %EXIST check whether a buffer is registered
            %
            %    EXIST(B,NAME) check whether buffer named NAME is
            %    registered.
            
            x = any(strcmpi(this.bufferNames,name));
        end % END function exist
        
        function n = numEntries(this,name)
            %NUMENTRIES get number of entries for specified buffer
            %
            %    NUMENTRIES(B,NAME) returns the number of entries for the
            %    buffer named NAME.
            
            idx = strcmpi(this.bufferNames,name);
            n = this.buffers{idx}.numEntries;
        end % END function numEntries
        
        function n = numScalarsPerEntry(this,name)
            %NUMSCALARSPERENTRY get number of scalars per entry for 
            %    specified buffer
            %
            %    NUMSCALARSPERENTRY(B,NAME) returns the number of scalars
            %    per entry for the buffer named NAME.  The buffer in
            %    question must be a Buffer.Dynamic, not a
            %    Buffer.ObjectDynamic, or an error will occur.
            
            idx = strcmpi(this.bufferNames,name);
            n = this.buffers{idx}.numScalarsPerEntry;
        end % END function numScalarsPerEntry
        
        function n = isempty(this,varargin)
            %ISEMPTY find out whether specified buffer is empty
            %
            %    ISEMPTY(B) returns true if all registered buffers are
            %    empty.
            %
            %    ISEMPTY(B,NAME) returns true if the specified buffer is 
            %    empty.
            
            if nargin>1
                n = false;
                idx = strcmpi(this.bufferNames,varargin{1});
                if any(idx)
                    n = logical(this.buffers{idx}.isempty);
                end
            else
                n = true;
                for k=1:length(this)
                    if ~this.buffers{k}.isempty
                        n = false;
                        break;
                    end
                end
            end
        end % END function isempty
        
        function len = length(this)
            %LENGTH returns number of registered buffers
            %
            %    LENGTH(B) returns the number of registered buffers.
            
            len = this.numBuffers;
        end % END function length
        
    end % END methods
    
end % END classdef StreamBuffer