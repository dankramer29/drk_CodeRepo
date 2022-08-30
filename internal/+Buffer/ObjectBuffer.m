classdef ObjectBuffer
    %ObjectBuffer Object Properties and Methods.
    %
    % Implements a last-in, first-out buffer for variables of any class.
    %
    % ObjectBuffer properties (read-only)
    %   numEntries          - Number of elements buffered
    %   entryClass          - Class of the objects being buffered
    %
    % ObjectBuffer methods
    % Constructor:
    %   @ObjectBuffer/ObjectBuffer
    %
    % General:
    %   add                 - add element to the ObjectBuffer
    %   get                 - get element(s) from the ObjectBuffer
    %   size                - get actual size of the buffer
    %   empty               - remove all elements but leave initialized
    
    properties(GetAccess='public',SetAccess='private')
        entryClass
    end % END properties(GetAccess='public',SetAccess='private')
    
    properties(Dependent,SetAccess='private')
        numEntries                  % how many elements added
    end % END properties(Dependent)
    
    properties(Access='private')
        fullBuffer = cell(2e6,1);     % support 24+ hours of commands at 20 Hz
        bufferIdx = 0;
    end % END properties(Access='private')
    
    methods
        function val = get.numEntries(this)
            val = this.bufferIdx;
        end % END function get.numEntries
        
        function this = ObjectBuffer(varargin)
            %OBJECTBUFFER Construct ObjectBuffer object.
            %
            %    B = OBJECTBUFFER returns an unitialized and empty
            %    ObjectBuffer object in B.

        end % END function ObjectBuffer
        
        function this = add(this,new)
            %ADD Insert new values into the buffer
            %
            %    B = ADD(B,NEW) adds the object in NEW to the ObjectBuffer 
            %    object B, and returns the updated buffer.  If B.isempty ==
            %    1, B.entryClass will be set to the class of the initial
            %    object, and all subsequent additions must be of the same 
            %    class.
            
            % first time call: init
            if this.isempty
                this.entryClass=class(new);
                this.bufferIdx=1; % how many vectors added
                this.fullBuffer{this.bufferIdx}=new;
            else
                % check data class
                if ~isa(new,this.entryClass)
                    error('ObjectBuffer:add','Data class mismatch: expected class ''%s'', but found ''%s''',this.entryClass,class(new));
                end
                
                % add data
                this.bufferIdx=this.bufferIdx+1; % update index to current cell
                if this.bufferIdx>length(this.fullBuffer) % add new cells if needed
                    this.fullBuffer=cat(1,this.fullBuffer,cell(1e6,1));
                end
                this.fullBuffer{this.bufferIdx}=new; % add new object to buffer
            end
        end % END function add
        
        function objs = get(this,varargin)
            %GET Retrieve data from the buffer
            %
            %    DATA = GET(B) retrieves the entire buffer.
            %
            %    DATA = GET(B,AMOUNT) retrieves the most recent AMOUNT entries
            %    in the buffer.  If AMOUNT is larger than B.numEntries, only
            %    B.numEntries entries are returned.
            
            % user-specified amount
            amount = this.numEntries;
            if nargin>=2
                amount = min(amount,varargin{1});
            end
            objs = this.fullBuffer(this.bufferIdx-amount+1:this.bufferIdx);
        end % END function get
        
        function [m,n] = size(this)
            % SIZE Return the 2-dimensional size of the buffer
            %
            %    [M,N] = SIZE(B) returns the size of the ObjectBuffer B
            %    accounting for the orientation mode ('r' for Row or 'c'
            %    for Column).  The values [M,N] indicate the size of the
            %    matrix returned by the command DATA = GET(B).
            
            m = this.bufferIdx;
            n = 1;
        end % END function size
        
        function val = isempty(this)
            val = this.bufferIdx==0;
        end % END function isempty
        
        function this = empty(this)
            %EMPTY Empty all contents of the buffer
            %
            %    B = EMPTY(B) empties the contents of the ObjectBuffer B, but
            %    does not change the NumScalarsPerEntry property.  Returns the updated
            %    ObjectBuffer object.
            
            % reset the buffer to empty
            this.bufferIdx = 0;
        end % END function empty
    end % END methods(Access='public')
end % END classdef ObjectBuffer