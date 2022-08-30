classdef StructDynamic < handle
    % STRUCTDYNAMIC Dynamically-sized struct buffer
    %
    %   Implements a last-in, first-out struct buffer which is efficient 
    %   (fast adds) at both small and large capacities.
    
    properties(GetAccess='public',SetAccess='private')
        numEntries = 0;             % current numEntries, i.e., how many elements added
    end % END properties(GetAccess='public',SetAccess='private')
    
    properties(Access='private')
        fullBuffer                  % buffer
        bufferFieldNames            % fieldnames of the struct
        chunkNumEntries             % numEntries of each chunk
        chunkSizeMinimum = 1000;    % minimum number of elements in each cell
        frameIdx = 0;
    end % END properties(Access='private')
    
    methods(Access='public')
        function d = StructDynamic(varargin)
            % STRUCTDYNAMIC Construct StructDynamic object.
            %
            %    D = StructDynamic returns an unitialized and empty
            %    StructDynamic object in D.

        end % END function StructDynamic
        
        function add(this,new)
            % ADD Insert new values into the buffer
            %
            %   ADD(D,NEW)
            %   Add entries in NEW to the StructDynamic object D.  Once the
            %   first struct has been added, all subsequent structs must
            %   have the same fields.
            
            % get size of incoming data accounting for orientation
            n=length(new);
            csm=this.chunkSizeMinimum;
            
            % fieldnames of the struct
            fields = fieldnames(new(1));
            
            % create empty struct for initializing buffer chunks
            sample = struct;
            for kk=1:length(fields)
                sample.(fields{kk}) = [];
            end
            
            % first time call: init
            if isempty(this.fullBuffer)
                
                % initialize buffer field names
                this.bufferFieldNames = fields;
                
                this.numEntries=n; % update numEntries - total number of vectors added
                if n<csm % initialize array of structs
                    this.frameIdx=n; % how many vectors added
                    this.fullBuffer{1}(csm)=sample; % initialize array of structs
                    this.fullBuffer{1}(1:n)=new; % assign incoming structs
                else % new data exceeds threshold, so add it and move on
                    this.fullBuffer={new}; % assign incoming
                    this.fullBuffer{end+1}(csm)=sample; % initialize next chunk
                    this.frameIdx=0; % update frame index
                    this.chunkNumEntries=n; % update chunk entry count
                end
            else % purely to append
                
                % check consistency
                sameLength = length(fields)==length(this.bufferFieldNames);
                sameFields = all(ismember(fields,this.bufferFieldNames));
                assert(sameLength&&sameFields,'New struct(s) must have same fields as existing structs');
                
                % add data
                this.fullBuffer{end}(:,this.frameIdx+(1:n))=new; % add data to buffer
                this.numEntries=this.numEntries+n; % update numEntries
                this.frameIdx=this.frameIdx+n; % update index to current cell
                if this.frameIdx>=csm % add new cell if needed
                    this.fullBuffer{end+1}(csm)=sample; % initialize next chunk
                    this.frameIdx=0; % update frame index
                    this.chunkNumEntries(end+1)=this.frameIdx; % update chunk entry count
                end
            end
        end % END function add
        
        function data = get(this,varargin)
            % GET Retrieve data from the buffer
            %
            %   DATA = GET(D) retrieves the entire buffer.
            %
            %   DATA = GET(D,AMOUNT) retrieves the most recent AMOUNT 
            %   entries in the buffer.  If AMOUNT is larger than 
            %   D.numEntries, only D.numEntries entries are returned.
            
            % check for empty buffer
            if this.isempty
                data = [];
                return;
            elseif nargin==1
                data = cat(2,this.fullBuffer{:});
                data(:, (end-(this.chunkSizeMinimum-this.frameIdx)+1) : end) = [];
                return;
            else
                % user-specified amount
                amount = this.numEntries;
                if nargin>=2
                    amount = min(amount,varargin{1});
                end
                
                % pre-allocate return array of structs
                data(amount) = sample;
                
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
                    data( (amount-currChunkAmount+1):amount ) = this.fullBuffer{currChunk}(idx);
                    
                    % update for next iteration
                    amount = amount-currChunkAmount;
                    currChunk = currChunk - 1;
                end
            end
        end % END function get
        
        function [m,n] = size(this)
            % SIZE Return the 2-dimensional size of the buffer
            %
            %    [M,N] = SIZE(D) returns the size of the StructDynamic D
            %    accounting for the orientation mode ('r' for Row or 'c'
            %    for Column).  The values [M,N] indicate the size of the
            %    matrix returned by the command DATA = GET(D).
            
            n = this.numEntries;
            m = 1;
        end % END function size
        
        function val = isempty(d)
            % ISEMPTY Return whether numEntries>0
            
            val = d.numEntries==0;
        end % END function isempty
        
        function empty(this)
            %EMPTY Empty all contents of the buffer
            %
            %    EMPTY(D) empties the contents of the StructDynamic D, but
            %    does not change the numScalarsPerEntry property.
            
            % reset the buffer to empty
            this.frameIdx = 0;
            this.numEntries = 0;
            this.fullBuffer = [];
        end % END function empty
    end % END methods(Access='public')
end % END classdef Buffer