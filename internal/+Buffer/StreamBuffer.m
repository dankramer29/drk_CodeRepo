classdef StreamBuffer < handle
    %StreamBuffer Object properties and methods.
    %
    % Class to manage all buffers in the Stream Framework.
    %
    % StreamBuffer properties (read-only)
    %   numBuffers      - number of buffers currently registered
    %   bufferNames     - names of the currently registered buffers
    %
    % StreamBuffer methods
    % Constructor:
    %   +Buffer/@StreamBuffer/StreamBuffer
    %
    % General
    %   register        - register a new buffer
    %   store           - store new data in a buffer
    %   get             - read data from a buffer
    %   changeCapacity  - change capacity of a buffer
    %   reset           - reset all buffers to empty (preserving other
    %                     properties)
    %   exists          - check whether a buffer already exists
    %   numEntries      - get number of entries in a buffer
    %   isEmpty         - find out whether a buffer is empty
    
    properties(SetAccess='private',GetAccess='public')
        numBuffers = 0;
        bufferNames = cell(0,1);
        buffers = cell(0,1);
    end
    
    methods
        function this = StreamBuffer
            %STREAMBUFFER Construct StreamBuffer object.
            %
            %    S = STREAMBUFFER returns an empty StreamBuffer
            %    object in S.
            
        end % END function StreamBuffer
        
        function register(this,name,capacity,varargin)
            %REGISTER Register a new buffer with the StreamBuffer object.
            %    
            %    REGISTER(S,NAME,CAPACITY) registers a new buffer with the
            %    StreamBuffer object. The new buffer will be identified by
            %    NAME for adding and retrieving data, and will have
            %    CAPACITY data capacity.
            %
            %    REGISTER(S,NAME,CAPACITY,'Mode',MODE,'Type',TYPE) 
            %    specifies the type and mode of the buffer.  TYPE may be 
            %    'numeric' (default; Buffer.Circular), or 'object' 
            %    (Buffer.ObjectCircular). MODE is only applicable 
            %    when TYPE=='numeric' and is ignored otherwise.  In that 
            %    case, 'c' (default) indicates columns should be stored and
            %    'r' indicates that rows should be stored.
            
            % process input arguments: mode and type
            k=length(varargin);
            mode='c';
            type='numeric';
            while(k>0)
                switch(upper(varargin{k}))
                    case 'MODE', mode=varargin{k+1}; k=k-1;
                    case 'TYPE', type=varargin{k+1}; k=k-1;
                end
                k=k-1;
            end
            
            % register name, init main buffer
            this.bufferNames{end+1} = name;
            if(strcmpi(type,'cell'))
                this.buffers{end+1} = {};
            elseif(strcmpi(type,'object'))
                this.buffers{end+1} = Buffer.ObjectCircular(capacity);
            else
                this.buffers{end+1} = Buffer.Circular(capacity,mode);
            end
            
            % update number of buffers
            this.numBuffers = this.numBuffers + 1;
        end % END function register
        
        function deregister(this,name)
            %DEREGISTER Deregister a buffer from the StreamBuffer object.
            %
            %     DEREGISTER(S,NAME) deregisters the buffer from the
            %     StreamBuffer object.
            
            % check that it exists
            if(~exists(this,name))
                error('Buffer:StreamBuffer:deregister','Buffer ''%s'' does not exist',name);
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
            if(~exists(this,name))
                error('Buffer:StreamBuffer:add','Buffer ''%s'' does not exist',name);
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
            
            % check existence
            if(~exists(this,name))
                error('Buffer:StreamBuffer:get','Variable ''%s'' does not exist',name);
            end
            idx = strcmpi(this.bufferNames,name); % buffer index
            
            % user input: amount to return
            amount = 1;
            if(~isempty(varargin))
                amount = varargin{1};
            end
            
            % retrieve data
            data = get(this.buffers{idx},amount);
        end % END function get
        
        function changeCapacity(this,name,newcapacity)
            %CHANGECAPACITY change the capacity of all registered buffers
            %
            %    CHANGECAPACITY(B,NEWCAP) changes capacity of all
            %    registered buffers to NEWCAP.
            
            % check existence
            if(~exists(this,name))
                error('Buffer:StreamBuffer:get','Variable ''%s'' does not exist',name);
            end
            idx = strcmpi(this.bufferNames,name); % buffer index
            
            if(isa(this.buffers{idx},'Buffer.Circular'))
                oldData = get(this.buffers{idx});
                this.buffers{idx} = Buffer.Circular(newcapacity);
                this.buffers{idx} = add(this.buffers{idx},oldData);
            elseif(isa(this.buffers{idx},'Buffer.ObjectCircular'))
                oldData = get(this.buffers{idx});
                this.buffers{idx} = Buffer.ObjectCircular(newcapacity);
                this.buffers{idx} = add(this.buffers{idx},oldData);
            elseif(isa(this.buffers{idx},'Buffer.SpikeTimestamp'))
                this.buffers{idx} = Buffer.SpikeTimestamp(newcapacity);
                fprintf('WARNING: losing all existing data in Buffer.SpikeTimestamp!\n');
            end
        end % END function changeCapacity
        
        function reset(this)
            %RESET resets all registered buffers to empty
            %
            %    RESET(B) resets all registered buffers to empty
            
            for k=1:length(this.buffers)
                this.buffers{k} = empty(this.buffers{k});
            end
        end % END function reset
        
        function x = exists(this,name)
            %EXISTS check whether a buffer is registered
            %
            %    EXISTS(B,NAME) check whether buffer named NAME is
            %    registered.
            
            x = ~isempty(strcmpi(this.bufferNames,name));
        end % END function exists
        
        function n = numEntries(this,name)
            %NUMENTRIES get number of entries for specified buffer
            %
            %    NUMENTRIES(B,NAME) returns the number of entries for the
            %    buffer named NAME.
            
            idx = strcmpi(this.bufferNames,name);
            n = this.buffers{idx}.numEntries;
        end % END function numEntries
        
        function n = isEmpty(this,name)
            %ISEMPTY find out whether specified buffer is empty
            %
            %    ISEMPTY(B,NAME) returns whether the specified buffer is 
            %    empty.
            
            idx = strcmpi(this.bufferNames,name);
            n = this.buffers{idx}.isEmpty;
        end % END function isEmpty
        
        function data = getAll(this,name)
            % GET retrieve all data from any registered buffer
            %
            %    DATA = getAll(B,NAME) retrieves all data 
            %    stored in the buffer B.
            
            % check existence
            if(~exists(this,name))
                error('Buffer:StreamBuffer:get','Variable ''%s'' does not exist',name);
            end
            idx = strcmpi(this.bufferNames,name); % buffer index

            % retrieve data
            data = get(this.buffers{idx},this.buffers{idx}.numEntries);
        end % END function get
        
    end % END methods
    
end % END classdef StreamBuffer