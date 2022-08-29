classdef Circular < handle
    % CIRCULAR Circular buffer
    %
    %   Implements a last-in, first-out circular buffer, with static 
    %   capacity but fast get and set operations.  Internally, entries are
    %   stored as columns; the value of the MODE parameter only re-orients
    %   incoming or requested data.
    
    properties(GetAccess='public',SetAccess='private')
        numEntries = 0; % number of elements buffered
        numScalarsPerEntry = 0; % number of scalars in each buffer element
        capacity = 0; % fixed number of entry slots available
        mode = 'c'; % add rows 'r' or columns 'c' (default)
    end % END properties(GetAccess='public',SetAccess='private')
    
    properties(Access='private')
        fullBuffer % buffer
        bufferIdx % buffer index
    end % END properties(Access='private')
    
    methods
        function this = Circular(cap,varargin)
            % CIRCULAR Construct Circular object.
            %
            %   C = CIRCULAR(CAP)
            %   Construct a Circular object with capacity CAP and returns 
            %   it in C.
            %
            %   C = CIRCULAR(CAP,MODE)
            %   Construct a Circular object to add columns (MODE='c'; 
            %   default) or rows (MODE='r').
            
            this.capacity = floor(cap);
            if nargin>1
                this.mode=varargin{1};
            end
        end % END function Circular
        
        function add(this,new)
            % ADD Insert new entries into the buffer
            %
            %   ADD(C,NEW) adds the entries in NEW to the Circular object 
            %   C.  If C.isempty, C.numScalarsPerEntry will be set to the 
            %   number of rows (mode=='c') or columns (mode=='r') in NEW, 
            %   and all subsequent additions must be consistently sized.
            %   If ~C.isempty, the number of rows (mode=='c') or columns 
            %   (mode=='r') must be equal to C.numScalarsPerEntry.  If the
            %   number of columns (mode=='c') or rows (mode=='r') in NEW is
            %   greater than C.capacity, a sufficient number of entries 
            %   starting at the first index will be deleted so that NEW 
            %   will fit into the Circular object.
            
            % get size of incoming data accounting for orientation
            [m,n]=size(new);
            if this.mode=='r' % convert rows to columns for internal use
                new=new';
                [m,n]=size(new);
            end
            
            % maximum addable size is this.capacity
            cap=this.capacity;
            if n>cap
                new=new(:,(n-cap+1):n);
                n=cap;
            end
            
            % first time call: init
            if this.isempty
                this.numEntries=n; % number of entries added
                this.numScalarsPerEntry=m; % number of scalars in each entry
                this.fullBuffer=[new zeros(m,cap-n)];
                this.bufferIdx=n; % buffer index: point to last element
            else % subsequent calls: append data
                % check data size
                if m~=this.numScalarsPerEntry
                    error('Buffer:Circular:add','Data size mismatch: expected %d scalars per entry, but found %d instead',this.numScalarsPerEntry,m);
                end
                
                % add data
                dx=this.bufferIdx;
                if (dx+n)<=cap
                    this.fullBuffer(:,dx+(1:n))=new; % add to end
                    this.bufferIdx=dx+n;
                else
                    this.fullBuffer(:,dx+(1:(cap-dx)))=new(:,1:(cap-dx)); % add to end
                    this.fullBuffer(:,1:(n-(cap-dx)))=new(:,(cap-dx+1):end); % add from begin
                    this.bufferIdx=n-(cap-dx);
                end
                this.numEntries=min(this.numEntries+n,cap);
            end
        end % END function add
        
        function data = get(this,varargin)
            % GET Retrieve data from the buffer
            %
            %   DATA = GET(C) retrieves the entire buffer.
            %
            %   DATA = GET(C,AMOUNT) retrieves the most recent AMOUNT 
            %   entries in the buffer.  If AMOUNT is larger than 
            %   C.numEntries, only C.numEntries entries will be returned.
            
            % check for empty buffer
            if this.isempty
                data = [];
                return;
            end
            
            % user-specified amount
            amount = this.numEntries;
            if nargin>=2
                amount = min(amount,varargin{1});
            end
            
            % find indices to the left of current index
            lhs_amount = min(amount,this.bufferIdx);
            lhs = floor((this.bufferIdx-lhs_amount+1) : (this.bufferIdx));
            
            % find indices to the right of current index
            rhs_amount = (amount-lhs_amount);
            rhs = floor((this.capacity-rhs_amount+1) : this.capacity);
            
            % right-hand first (earlier); then left-hand (later)
            data = this.fullBuffer(:,[rhs lhs]);
            
            % flip if row mode requested
            if this.mode~='c'
                data=data';
            end
            
        end % END function get
        
        function data = getAndClear(this,varargin)
            % GETANDCLEAR Retrieve data from the buffer and empty the buffer
            %
            %   DATA = GETANDCLEAR(C) retrieves the entire buffer and 
            %   clears the data from the buffer.
            %
            %   DATA = GETANDCLEAR(C,AMOUNT) retrieves the most recent 
            %   AMOUNT entries in the buffer.  If AMOUNT is larger than 
            %   C.numEntries, only C.numEntries entries will be returned.
            %   The entire buffer is cleared.
            
            data = get(this,varargin{:});
            empty(this);
            
        end % END function getAndClear
        
        function [m,n] = size(this)
            % SIZE Return the 2-dimensional size of the buffer
            %
            %   [M,N] = SIZE(C) returns the size of the Circular C
            %   accounting for the orientation mode ('r' for Row or 'c'
            %   for Column).  The values [M,N] indicate the size of the
            %   matrix returned by the command DATA = GET(C).
            
            n = this.numEntries;
            m = this.numScalarsPerEntry;
            if this.mode~='c'
                m = this.numEntries;
                n = this.numScalarsPerEntry;
            end
        end % END function size
        
        function val = isempty(c)
            % ISEMPTY Return logical value indicating numEntries>0
            
            val = c.numEntries==0;
        end % END function isempty
        
        function empty(this)
            % EMPTY Empty all contents of the buffer (but leave initialized).
            %
            %   EMPTY(C) empties the contents of the Circular C,
            %   but does not change numScalarsPerEntry or DataClass 
            %   properties.
            
            % reset the buffer to empty
            this.numEntries = 0;
            
        end % END function clear
        
        function d = double(this)
            d = double(get(this));
        end % END function double
    end % END methods(Access='public')
end % END classdef Buffer