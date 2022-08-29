classdef ObjectQueue < handle
    %ObjectQueue Object Properties and Methods.
    %
    % Implements a FIFO or LIFO queue for variables of any class.
    %
    % ObjectQueue properties (read-only)
    %   numEntries          - Number of elements buffered
    %   entryClass          - Class of the objects being buffered
    %
    % ObjectQueue methods
    % Constructor:
    %   @ObjectQueue/ObjectQueue
    %
    % General:
    %   add                 - add element to the ObjectQueue
    %   get                 - get element(s) from the ObjectQueue
    %   size                - get actual size of the buffer
    %   isempty             - numEntries property equals zero
    %   empty               - remove all elements but leave initialized
    
    properties(GetAccess='public',SetAccess='private')
        numEntries                  % how many elements added
        entryClass
        mode = 'FIFO';              % may be FIFO or LIFO (first in, last out)
        capacity = 2e6;
        busy = false;
    end % END properties(GetAccess='public',SetAccess='private')
    
    properties(Access='private')
        fullBuffer
        bufferStart = nan;
        bufferEnd = nan;
    end % END properties(Access='private')
    
    methods
        function val = get.numEntries(this)
            if isnan(this.bufferEnd)
                val = 0;
            else
                val = this.bufferEnd-this.bufferStart+1;
            end
        end % END function get.numEntries
        
        function this = ObjectQueue(varargin)
            %OBJECTQUEUE Construct ObjectQueue object.
            %
            %    B = OBJECTQUEUE returns an unitialized and empty
            %    ObjectQueue object in B.
            %
            %    B = OBJECTQUEUE(CAPACITY) specifies the total capacity of
            %    the queue (default is 2e6).
            %
            %    B = OBJECTQUEUE(CAPACITY,MODE) initializes the buffer to 
            %    FIFO (default) or LIFO mode.
            
            if nargin>0
                this.capacity = varargin{1};
            end
            if nargin>1
                if strcmpi(varargin{2},'FIFO')
                    this.mode='FIFO';
                elseif strcmpi(varargin{2},'LIFO')
                    this.mode='LIFO';
                else
                    error('ObjectQueue:ObjectQueue','Unrecognized mode ''%s'' (expecting ''FIFO'' or ''LIFO'')',varargin{2});
                end
            end
            this.fullBuffer=cell(1,this.capacity);
        end % END function ObjectQueue
        
        function add(this,new)
            %ADD Insert new values into the buffer
            %
            %    B = ADD(B,NEW) adds the object in NEW to the ObjectQueue
            %    object B, and returns the updated buffer.  If B.isempty ==
            %    1, B.entryClass will be set to the class of the initial
            %    object, and all subsequent additions must be of the same
            %    class.
            
            % hack lock
            this.busy = true;
            
            % first time call: init
            if this.isempty
                this.entryClass=class(new);
                this.bufferStart=1; % starting index of buffer
                this.bufferEnd=1; % ending index of buffer
                this.fullBuffer{1}=new;
            else
                % check data class
                if ~isa(new,this.entryClass)
                    error('Buffer:ObjectQueue:add','Data class mismatch: expected class ''%s'', but found ''%s''',this.entryClass,class(new));
                end
                
                % add data
                this.bufferEnd=this.bufferEnd+1; % update index to current cell
                if this.bufferEnd>length(this.fullBuffer) % wrap around to beginning
                    this.bufferEnd=1;
                end
                if this.bufferEnd==this.bufferStart % we've filled it up
                    if strcmpi(this.mode,'FIFO') % don't add anything else
                        if this.bufferEnd==1 % reset buffer end pointer
                            this.bufferEnd=length(this.fullBuffer);
                        else
                            this.bufferEnd=this.bufferEnd-1;
                        end
                        return; % return without adding anything
                    elseif strcmpi(this.mode,'LIFO') % overwrite oldest entry
                        this.bufferStart=this.bufferStart+1;
                    end
                end
                this.fullBuffer{this.bufferEnd}=new; % add new object to buffer
            end
            this.numEntries = this.numEntries + 1;
            
            % free up the lock
            this.busy = false;
        end % END function add
        
        function objs = get(this,varargin)
            %GET Retrieve and remove data from the buffer
            %
            %    DATA = GET(B) retrieves the oldest (FIFO) or most recent
            %    (LIFO) entry in the buffer
            %
            %    DATA = GET(B,AMOUNT) retrieves the oldest (FIFO) or most
            %    recent (LIFO) AMOUNT entries in the buffer.  If AMOUNT is
            %    larger than B.numEntries, only B.numEntries entries are
            %    returned.
            
            if this.busy
                objs=[];
                return;
            end
            
            if this.isempty
                objs=[];
                return;
            end
            
            % user-specified amount
            amount = this.numEntries;
            if nargin>=2
                amount = min(amount,varargin{1});
            end
            
            % ordered list of indices into buffer elements
            if this.bufferStart<=this.bufferEnd
                idx = this.bufferStart:this.bufferEnd;
            elseif this.bufferStart>this.bufferEnd
                idx = [this.bufferStart:length(this.fullBuffer) 1:this.bufferEnd];
            end
            
            % set up indices for what to return, and update buffer start/end
            if strcmpi(this.mode,'FIFO')
                idx = idx(1:amount);
                if amount==this.numEntries
                    this.bufferStart = nan;
                    this.bufferEnd = nan;
                else
                    this.bufferStart = this.bufferStart + amount;
                    if this.bufferStart > length(this.fullBuffer) % check wrap-around
                        this.bufferStart = this.bufferStart - length(this.fullBuffer);
                    end
                end
            elseif strcmpi(this.mode,'LIFO')
                idx = idx(end-amount+1:end);
                if amount==this.numEntries
                    this.bufferStart = nan;
                    this.bufferEnd = nan;
                else
                    this.bufferEnd = this.bufferEnd - amount;
                    if this.bufferEnd < 0 % check wrap-around
                        this.bufferEnd = length(this.fullBuffer) + this.bufferEnd;
                    end
                end
            end
            if numel(idx)==1
                objs = this.fullBuffer{idx};
            else
                objs = this.fullBuffer(idx);
            end
        end % END function get
        
        function [m,n] = size(this)
            % SIZE Return the 2-dimensional size of the buffer
            %
            %    [M,N] = SIZE(B) returns the size of the ObjectQueue B
            %    accounting for the orientation mode ('r' for Row or 'c'
            %    for Column).  The values [M,N] indicate the size of the
            %    matrix returned by the command DATA = GET(B).
            
            if this.bufferStart<this.bufferEnd
                m = this.bufferEnd - this.bufferStart + 1;
            else
                m = length(this.fullBuffer) - (this.bufferEnd - this.bufferStart) + 1;
            end
            n = 1;
        end % END function size
        
        function val = isempty(this)
            val = this.numEntries==0;
        end % END function isempty
        
        function empty(this)
            %EMPTY Empty all contents of the buffer
            %
            %    B = EMPTY(B) empties the contents of the ObjectQueue B, but
            %    does not change the NumScalarsPerEntry property.  Returns the updated
            %    ObjectQueue object.
            
            % reset the buffer to empty
            this.bufferStart = nan;
            this.bufferEnd = nan;
        end % END function empty
    end % END methods(Access='public')
end % END classdef ObjectQueue