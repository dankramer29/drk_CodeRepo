classdef ObjectCircular < handle
    %ObjectCircular Object properties and methods.
    %
    % Implements a last-in, first-out circular buffer for variables of any 
    % class.
    %
    % ObjectCircular properties (read-only)
    %   numEntries          - Number of elements buffered
    %   entryClass          - Class of the objects being buffered
    %   capacity            - Fixed number of entry slots available
    %
    % ObjectCircular methods
    % Constructor:
    %   +Buffer/ObjectCircular
    %
    % General:
    %   add                 - add element to the ObjectCircular
    %   get                 - get element(s) from the ObjectCircular
    %   size                - get actual size of the buffer
    %   isempty             - numEntries property equals zero
    %   empty               - remove all elements but leave initialized
    
    properties(GetAccess='public',SetAccess='private')
        numEntries = 0;
        capacity = 0;
        entryClass
    end % END properties(GetAccess='public',SetAccess='private')
    
    properties(Access='private')
        fullBuffer
        bufferIdx
    end % END properties(Access='private')
    
    methods
        function this = ObjectCircular(cap)
            %OBJECTCIRCULAR Construct ObjectCircular object.
            %
            %    C = OBJECTCIRCULAR(CAP) constructs a ObjectCircular object
            %    with capacity CAP and returns it in C.
            
            this.capacity = cap;
            this.fullBuffer = cell(1,cap);
        end % END function ObjectCircular
        
        function add(this,new)
            %ADD Insert new values into the buffer
            %
            %    ADD(C,NEW) adds objects in NEW to the 
            %    Buffer.ObjectCircular object C.  If NEW is a cell, 
            %    the elements of the cell array are treated as objects and
            %    multiple objects may be passed in at once.  Otherwise, new
            %    itself is treated as the object and only a single object
            %    may be passed in.  If C.isempty==TRUE, C.entryClass will 
            %    be set to the class of the initial object, and all 
            %    subsequent additions must be of the same class.  If NEW 
            %    contains more entries than will fit in the buffer, a 
            %    sufficient number of entries starting at the first index 
            %    will be deleted so that NEW will fit into the 
            %    Buffer.ObjectCircular object.
            
            % get size of incoming data
            if iscell(new)
                if min(size(new))>1
                    error('Buffer:ObjectCircular:add','Cannot add arrays of objects');
                end
                n=length(new);
            else
                n=1;
            end
            
            % check size against capacity
            cap=this.capacity;
            if n>cap
                new=new((n-cap+1):n);
                n=cap;
            end
            
            % first time call: init
            if this.isempty
                if iscell(new)
                    this.entryClass=class(new{1}); % set the class type
                    
                    % check class consistency
                    if any(~cellfun(@(x)strcmpi(class(x),this.entryClass),new))
                        error('Buffer:ObjectCircular:add','All elements in the cell array must be of class ''%s''',this.entryClass);
                    end
                    this.fullBuffer(1:n)=new(:); % add the data
                else
                    this.entryClass=class(new); % set the class type
                    this.fullBuffer(1)=new; % add the data
                end
                this.numEntries=n; % number of entries added
                this.bufferIdx=n; % buffer index: point to last index
            else % subsequent calls: append data
                if iscell(new)
                    % check class consistency
                    if any(~cellfun(@(x)strcmpi(class(x),this.entryClass),new))
                        error('Buffer:ObjectCircular:add','All elements in the cell array must be of class ''%s''',this.entryClass);
                    end
                    
                    % add data
                    dx=this.bufferIdx;
                    if (dx+n)<=cap
                        this.fullBuffer(dx+(1:n))=new(:);
                        this.bufferIdx=dx+n;
                    else
                        this.fullBuffer(dx+(1:(cap-dx)))=new(1:(cap-dx)); % add to end
                        this.fullBuffer(1:(n-(cap-dx)))=new((cap-dx+1):end); % add from begin
                        this.bufferIdx=n-(cap-dx);
                    end
                else
                    % check class consistency
                    if ~isa(new,this.entryClass)
                        error('Buffer:ObjectCircular:add','Data class mismatch: expected class ''%s'', but found ''%s''',this.entryClass,class(new));
                    end
                    
                    % add data
                    dx=this.bufferIdx;
                    if  (dx+1)<=cap
                        this.fullBuffer(dx+1)=new; % add to end
                        this.bufferIdx=dx+1;
                    else
                        this.fullBuffer{1}=new; % add to beginning
                        this.bufferIdx=1;
                    end
                end
                this.numEntries=min(this.numEntries+n,cap); % update index to current cell
            end
        end % END function add
        
        function objs = get(this,varargin)
            %GET Retrieve data from the buffer
            %
            %    OBJS = GET(B) retrieves the entire buffer.
            %
            %    OBJS = GET(B,AMOUNT) retrieves the most recent AMOUNT entries
            %    in the buffer.  If AMOUNT is larger than B.numEntries, only
            %    B.numEntries entries are returned.
            
            % check for empty buffer
            if this.isempty
                objs = [];
                return;
            end
            
            % user-specified amount
            amount = this.numEntries;
            if nargin>=2
                amount = min(amount,varargin{1});
            end
            
            % find indices to the left of current index
            lhs_amount = min(amount,this.bufferIdx);
            lhs = (this.bufferIdx-lhs_amount+1) : (this.bufferIdx);
            
            % find indices to the right of current index
            rhs_amount = (amount-lhs_amount);
            rhs = (this.capacity-rhs_amount+1) : this.capacity;
            
            % right-hand first (earlier); then left-hand (later)
            objs = this.fullBuffer([rhs lhs]);
        end % END function get
        
        function [m,n] = size(this)
            % SIZE Return the 2-dimensional size of the buffer
            %
            %    [M,N] = SIZE(B) returns the size of the ObjectCircular B
            %    accounting for the orientation mode ('r' for Row or 'c'
            %    for Column).  The values [M,N] indicate the size of the
            %    matrix returned by the command DATA = GET(B).
            
            m = this.numEntries;
            n = 1;
        end % END function size
        
        function val = isempty(this)
            val = this.numEntries==0;
        end % END function isempty
        
        function this = empty(this)
            %EMPTY Empty all contents of the buffer
            %
            %    EMPTY(B) empties the contents of the ObjectCircular B, but
            %    does not change the NumScalarsPerEntry property.
            
            % reset the buffer to empty
            this.numEntries = 0;
        end % END function empty
    end % END methods(Access='public')
end % END classdef Buffer