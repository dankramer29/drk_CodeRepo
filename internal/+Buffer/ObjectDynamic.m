classdef ObjectDynamic < handle
    %ObjectDynamic Object properties and methods.
    %
    % Implements a last-in, first-out buffer for variables of any class.
    %
    % ObjectDynamic properties (read-only)
    %   numEntries          - Number of elements buffered
    %   entryClass          - Class of the objects being buffered
    %
    % ObjectDynamic methods
    % Constructor:
    %   +Buffer/@ObjectDynamic/ObjectDynamic
    %
    % General:
    %   add                 - add element to the ObjectDynamic
    %   get                 - get element(s) from the ObjectDynamic
    %   size                - get actual size of the buffer
    %   isempty             - numEntries property equals zero
    %   empty               - remove all elements but leave initialized
    
    properties(GetAccess='public',SetAccess='private')
        numEntries = 0;
        entryClass
    end % END properties(GetAccess='public',SetAccess='private')
    
    properties(Access='private')
        fullBuffer=cell(1e6,1);
    end % END properties(Access='private')
    
    methods
        function this = ObjectDynamic(varargin)
            %OBJECTDYNAMIC Construct ObjectDynamic object.
            %
            %    B = OBJECTDYNAMIC returns an unitialized and empty
            %    ObjectDynamic object in B.

        end % END function ObjectDynamic
        
        function add(this,new)
            %ADD Insert new values into the buffer
            %
            %    ADD(B,NEW) adds the object in NEW to the 
            %    ObjectDynamic object B.  If B.isempty==1, 
            %    B.entryClass will be set to the class of the initial 
            %    object, and all subsequent additions must be of the same 
            %    class.
            
            % get size of incoming data
            if min(size(new))>1
                error('Buffer:ObjectDynamic:add','Cannot add array (only vectors)');
            end
            n=length(new);
            
            % first time call: init
            if this.isempty
                this.fullBuffer{1:n}=new{:};
                this.numEntries=n; % how many vectors added
                this.entryClass=class(new);
            else
                % check data class
                if ~isa(new,this.entryClass)
                    error('Buffer:ObjectDynamic:add','Data class mismatch: expected class ''%s'', but found ''%s''',this.entryClass,class(new));
                end
                
                % add data
                if (this.numEntries+n)>length(this.fullBuffer) % add new cells if needed
                    this.fullBuffer=cat(1,this.fullBuffer,cell(1e6,1));
                end
                this.fullBuffer{this.numEntries+(1:n)}=new{:}; % add new object to buffer
                this.numEntries=this.numEntries+n; % update index to current cell
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
            objs = this.fullBuffer(this.numEntries-amount+1:this.numEntries);
        end % END function get
        
        function [m,n] = size(this)
            % SIZE Return the 2-dimensional size of the buffer
            %
            %    [M,N] = SIZE(B) returns the size of the ObjectDynamic B
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
            %    EMPTY(B) empties the contents of the ObjectDynamic B, but
            %    does not change the NumScalarsPerEntry property.
            
            % reset the buffer to empty
            this.numEntries = 0;
        end % END function empty
    end % END methods(Access='public')
end % END classdef ObjectDynamic