classdef FIFO < handle
    % FIFO Circular buffer
    %
    %   Implements a first-in, first-out circular buffer, with static 
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
        bufferStart % buffer start index
        bufferEnd % buffer end index
    end % END properties(Access='private')
    
    methods
        function this = FIFO(cap,varargin)
            % FIFO Construct FIFO object.
            %
            %   C = FIFO(CAP)
            %   Construct FIFO object with capacity CAP and return as C.
            %
            %   C = FIFO(CAP,MODE)
            %   Construct FIFO object to add columns (MODE='c'; default)
            %   or rows (MODE='r').
            
            this.capacity = floor(cap);
            if nargin>1
                this.mode=varargin{1};
            end
        end % END function FIFO
        
        function add(this,new)
            % ADD Insert new entries into the buffer
            %
            %   ADD(C,NEW) adds the entries in NEW to the FIFO object C. 
            %   If C.isempty, C.numScalarsPerEntry will be set to the 
            %   number of rows (mode=='c') or columns (mode=='r') in NEW, 
            %   and all subsequent additions must be consistently sized.
            %   If ~C.isempty, the number of rows (mode=='c') or columns 
            %   (mode=='r') must be equal to C.numScalarsPerEntry.  If the
            %   number of columns (mode=='c') or rows (mode=='r') in NEW is
            %   greater than C.capacity, a sufficient number of entries 
            %   starting at the first index will be deleted so that NEW 
            %   will fit into the FIFO object.
            %
            %   Data in NEW is assumed to be in ascending order of time,
            %   i.e., NEW(1) is oldest and NEW(END) is newest. If NEW has
            %   more data than the current capacity of C will support,
            %   newer values will be left out (to preserve the operating
            %   principle of the FIFO buffer: older values came first).
            
            % get size of incoming data accounting for orientation
            [m,n]=size(new);
            if this.mode=='r' % convert rows to columns for internal use
                new=new';
                [m,n]=size(new);
            end
            
            % maximum addable size is [CAPACITY - DATA]
            cap=this.capacity;
            len=this.numEntries;
            if n>(cap-len)
                new=new(:,1:(cap-len));
                n=cap-len;
            end
            
            % first time call: init
            if this.isempty
                this.numEntries=n; % number of entries added
                this.numScalarsPerEntry=m; % number of scalars in each entry
                this.fullBuffer=[new zeros(m,cap-n)];
                this.bufferStart=1; % buffer starting index: point to first element
                this.bufferEnd=n; % buffer ending index: point to last element
            else % subsequent calls: append data
                % check data size
                if m~=this.numScalarsPerEntry
                    error('Buffer:FIFO:add','Data size mismatch: expected %d scalars per entry, but found %d instead',this.numScalarsPerEntry,m);
                end
                
                % add data
                dx=this.bufferEnd;
                if (dx+n)<=cap
                    this.fullBuffer(:,(dx+1):(dx+n))=new; % add to end
                    this.bufferEnd=dx+n;
                else
                    this.fullBuffer(:,dx+(1:(cap-dx)))=new(:,1:(cap-dx)); % add to end
                    this.fullBuffer(:,1:(n-(cap-dx)))=new(:,(cap-dx+1):end); % add from begin
                    this.bufferEnd=n-(cap-dx);
                end
                this.numEntries=this.numEntries+n;
                if this.numEntries>cap
                    warning('more entries than capacity');
                    keyboard
                end
                assert(this.numEntries<=cap,'Mismatched logic somehwere - more entries than capacity');
            end
        end % END function add
        
        function prepend(this,old)
            
            % corner case: if no data, add it like it was new
            if this.isempty
                this.add(old);
                return;
            end
            
            % get size of incoming data accounting for orientation
            [m,n]=size(old);
            if this.mode=='r' % convert rows to columns for internal use
                old=old';
                [m,n]=size(old);
            end
            
            % can add up to full capacity (assuming user intends this data
            % to be older than existing data)
            cap=this.capacity;
            if n>cap
                old=old(:,1:cap);
                n=cap;
            end
            
            % check data size
            if m~=this.numScalarsPerEntry
                error('Buffer:FIFO:add','Data size mismatch: expected %d scalars per entry, but found %d instead',this.numScalarsPerEntry,m);
            end
            
            % add data
            dx=this.bufferStart;
            if (dx-n-1)>0
                this.fullBuffer(:,(dx-n):(dx-1))=old; % prepend without wrapping around
                this.bufferStart=dx-n;
            else
                this.fullBuffer(:,1:(dx-1))=old(:,(n-(dx-1)+1):end); % prepend before wrapping around
                this.fullBuffer(:,(cap-(n-(dx-1))+1):cap)=old(:,1:(n-(dx-1))); % wrap around to prepend the rest at the end of the circ buf
                this.bufferStart=cap-(n-(dx-1))+1;
            end
            this.numEntries=min(this.numEntries+n,cap);
            if this.numEntries>cap
                warning('more entries than capacity');
                keyboard
            end
            assert(this.numEntries<=cap,'Mismatched logic somehwere - more entries than capacity');
        end % END function prepend
        
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
            
            % read from buffer start to amount or end of circ buff,
            % whichever comes first
            v1_amount = min(amount,this.capacity-this.bufferStart+1);
            v1 = this.bufferStart + (0:(v1_amount-1));
            
            % read from start of circ buff to amount or buffer end,
            % whichever comes first
            v2_amount = amount-v1_amount;
            v2 = 1:v2_amount;
            
            % extract data
            data = this.fullBuffer(:,[v1 v2]);
            
            % flip if row mode requested
            if this.mode~='c'
                data=data';
            end
            
            % update buffer start (remove read data)
            orig_bufstart = this.bufferStart;
            if isempty(v2)
                this.bufferStart = v1(end)+1;
                
                % account for corner case where it read right up to cap
                if this.bufferStart > this.capacity
                    this.bufferStart = 1;
                end
            else
                this.bufferStart = v2(end)+1;
            end
            if this.bufferStart < orig_bufstart && this.bufferStart > this.bufferEnd
                warning('bad logic somewhere - buffer start exceeded buffer end');
                keyboard
            end
            
            % update number of entries
            this.numEntries = this.numEntries - amount;
        end % END function get
        
        function varargout = size(this,dim)
            % SIZE Return the 2-dimensional size of the buffer
            %
            %   [M,N] = SIZE(C) returns the size of the FIFO C
            %   accounting for the orientation mode ('r' for Row or 'c'
            %   for Column).  The values [M,N] indicate the size of the
            %   matrix returned by the command DATA = GET(C).
            
            n = this.numEntries;
            m = this.numScalarsPerEntry;
            if this.mode~='c'
                m = this.numEntries;
                n = this.numScalarsPerEntry;
            end
            
            varargout = {};
            if nargin<=1||isempty(dim)
                varargout = {m,n};
            elseif nargin>=2&&~isempty(dim)
                if dim==1
                    varargout{1} = m;
                elseif dim==2
                    varargout{1} = n;
                end
            end
            assert(~isempty(varargout));
        end % END function size
        
        function val = isempty(c)
            % ISEMPTY Return logical value indicating numEntries>0
            
            val = c.numEntries==0;
        end % END function isempty
        
        function empty(this)
            % EMPTY Empty all contents of the buffer (but leave initialized).
            %
            %   EMPTY(C) empties the contents of the FIFO C,
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