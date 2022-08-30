classdef Dynamic < handle
    %Dynamic Object Properties and Methods.
    %
    % Implements a last-in, first-out buffer which is efficient (fast
    % adds) at both small and large capacities.  Uses a cell array to avoid
    % the need to find contiguous blocks of memory.  Internally, entries
    % are stored as columns; the value of the MODE parameter only
    % re-orients incoming or requested data.
    %
    % Dynamic properties (read-only)
    %   numEntries          - Number of elements buffered
    %   numScalarsPerEntry  - Vector numScalarsPerEntry at each buffer location
    %
    % Dynamic methods
    % Constructor:
    %   Buffer.Dynamic
    %
    % General:
    %   Buffer.Dynamic.add      - add element to the Dynamic
    %   Buffer.Dynamic.get      - get element(s) from the Dynamic
    %   Buffer.Dynamic.size     - get actual size of the buffer
    %   Buffer.Dynamic.isempty  - numEntries property equals zero
    %   Buffer.Dynamic.empty    - remove all elements but leave initialized
    
    properties(GetAccess='public',SetAccess='private')
        numEntries = 0;             % current numEntries, i.e., how many elements added
        numScalarsPerEntry = 0;     % size of vector added each call to buffer
        mode = 'c';                 % add rows 'r' or columns 'c' (default)
    end % END properties(GetAccess='public',SetAccess='private')
    
    properties(Access='private')
        fullBuffer                  % buffer
        chunkNumEntries             % numEntries of each chunk
        chunkSizeMinimum = 1000;    % minimum number of elements in each cell
        frameIdx = 0;
    end % END properties(Access='private')
    
    methods(Access='public')
        function d = Dynamic(varargin)
            %DYNAMIC Construct Dynamic object.
            %
            %    D = DYNAMIC returns an unitialized and empty
            %    Dynamic object in D.
            %
            %    D = DYNAMIC(MODE) initializes the object to add 
            %    columns (MODE='c'; default) or rows (MODE='r').

            if nargin>0
                d.mode=varargin{1};
            end
        end % END function Dynamic
        
        function add(this,new)
            %ADD Insert new values into the buffer
            %
            %    ADD(D,NEW) adds entries in NEW to the Dynamic 
            %    object D.  If D.isempty==TRUE, D.numScalarsPerEntry will
            %    be set to the number of rows (D.mode=='c') columns 
            %    (D.mode=='r') in NEW, and all subsequent additions must be
            %    consistently sized.  If D.isempty == FALSE, the number of 
            %    rows (D.mode=='c') or columns (D.mode=='r') must be equal 
            %    to D.numScalarsPerEntry.
            
            % get size of incoming data accounting for orientation
            [m,n]=size(new);
            if this.mode~='c'
                new=new';
                [m,n]=size(new);
            end
            csm=this.chunkSizeMinimum;
            
            % first time call: init
            if isempty(this.fullBuffer)
                this.numEntries=n; % update numEntries - total number of vectors added
                this.numScalarsPerEntry=m; % numScalarsPerEntry of each vector
                if n<csm % append to new buffer with zeros
                    this.frameIdx=n; % how many vectors added
                    this.fullBuffer={[new zeros(m,csm-n)]};
                else % new data exceeds threshold, so just add it and move on
                    this.fullBuffer={new};
                    this.fullBuffer{end+1}=zeros(m,csm);
                    this.frameIdx=0;
                    this.chunkNumEntries=n;
                end
            else % purely to append
                
                % check data size
                if m~=this.numScalarsPerEntry
                    error('Buffer:Dynamic:add','Data size mismatch: expected %d scalars per entry, but found %d',this.numScalarsPerEntry,m);
                end
                
                % add data
                this.fullBuffer{end}(:,this.frameIdx+(1:n))=new; % add data to buffer
                this.numEntries=this.numEntries+n; % update numEntries
                this.frameIdx=this.frameIdx+n; % update index to current cell
                if this.frameIdx>=csm % add new cell if needed
                    this.fullBuffer{end+1}=zeros(m,csm);
                    this.chunkNumEntries(end+1)=this.frameIdx;
                    this.frameIdx=0;
                end
            end
        end % END function add
        
        function data = get(this,varargin)
            %GET Retrieve data from the buffer
            %
            %    DATA = GET(D) retrieves the entire buffer.
            %
            %    DATA = GET(D,AMOUNT) retrieves the most recent AMOUNT entries
            %    in the buffer.  If AMOUNT is larger than D.numEntries, only
            %    D.numEntries entries are returned.
            
            % check for empty buffer
            if this.isempty
                data = [];
                return;
            elseif nargin==1
                data = cat(2,this.fullBuffer{:});
                data(:, (end-(this.chunkSizeMinimum-this.frameIdx)+1) : end) = [];
                if this.mode~='c'
                    data=data';
                end
                return;
            else
                % user-specified amount
                amount = this.numEntries;
                if nargin>=2
                    amount = min(amount,varargin{1});
                end
                
                % pre-allocate return matrix
                data = zeros(this.numScalarsPerEntry,amount);
                
                % start at the end and move backwards, taking as much as
                % needed from each chunk.
                currChunk = length(this.fullBuffer);
                while amount>0
                    % the last cell is only partially full so handle differently
                    if currChunk==length(this.fullBuffer)
                        currChunkAmount = min(amount,this.frameIdx); % how much to grab from current cell
                        idx=(this.frameIdx-currChunkAmount+1):this.frameIdx; % indices corresponding to that amount
                    else
                        currChunkAmount = min(amount,this.chunkNumEntries(currChunk));
                        idx=(this.chunkNumEntries(currChunk)-currChunkAmount+1):this.chunkNumEntries(currChunk);
                    end
                    
                    % get the data
                    data( :, (amount-currChunkAmount+1):amount ) = this.fullBuffer{currChunk}(:,idx);
                    
                    % update for next iteration
                    amount = amount-currChunkAmount;
                    currChunk = currChunk - 1;
                end
                
                % transpose for column mode
                if this.mode~='c'
                    data=data';
                end
            end
        end % END function get
        
        function [m,n] = size(this)
            % SIZE Return the 2-dimensional size of the buffer
            %
            %    [M,N] = SIZE(D) returns the size of the Dynamic D
            %    accounting for the orientation mode ('r' for Row or 'c'
            %    for Column).  The values [M,N] indicate the size of the
            %    matrix returned by the command DATA = GET(D).
            
            n = this.numEntries;
            m = this.numScalarsPerEntry;
            if this.mode~='c'
                m = this.numEntries;
                n = this.numScalarsPerEntry;
            end
        end % END function size
        
        function val = isempty(d)
            % ISEMPTY Return whether numEntries>0
            
            val = d.numEntries==0;
        end % END function isempty
        
        function empty(this)
            %EMPTY Empty all contents of the buffer
            %
            %    EMPTY(D) empties the contents of the Dynamic D, but
            %    does not change the numScalarsPerEntry property.
            
            % reset the buffer to empty
            this.frameIdx = 0;
            this.numEntries = 0;
            this.fullBuffer = [];
        end % END function empty
        
        function d = double(this)
            d = double(get(this));
        end % END function double
    end % END methods(Access='public')
end % END classdef Buffer