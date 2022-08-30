classdef SpikeTimestamp < handle
    %SpikeTimestamp Object properties and methods
    %
    % Implements a buffer for spike timestamps.
    %
    % SpikeTimestamp properties (read-only)
    %   isEmpty             - numEntries property equals zero
    %
    % SpikeTimestamp methods
    % Constructor:
    %   +Buffer/@SpikeTimestamp/SpikeTimestamp
    %
    % General:
    %   +Buffer/@SpikeTimestamp/add     - add element to the SpikeTimestamp
    %   +Buffer/@SpikeTimestamp/get     - get element(s) from the SpikeTimestamp
    %   +Buffer/@SpikeTimestamp/size    - get actual size of the buffer
    %   +Buffer/@SpikeTimestamp/empty   - remove all elements but leave initialized
    
    properties(GetAccess='public',SetAccess='private')
        numUnits = 0;           % number of units with buffered timestamps
    end % END properties(GetAccess='public',SetAccess='private')
    
    properties(Access='private')
        fullBuffer              % buffer
    end % END properties(Access='private')
    
    methods
        function this = SpikeTimestamp(numUnits)
            %SPIKETIMESTAMP Construct SpikeTimestamp object.
            %
            %    S = SPIKETIMESTAMP(NUMUNITS) constructs a 
            %    SpikeTimestamp object with space for NUMUNITS units
            %    and returns it in S.
            
            this.numUnits = numUnits;
            this.fullBuffer = cell(this.numUnits,1);
            
        end % END function SpikeTimestamp
        
        function add(this,newNeuralEvent,totalOffset,newFrameSamples)
            %ADD Insert new entries into the buffer
            %
            %    ADD(S,NEW,WIN_OFFSET,FRAME) adds the entries in NEW to the 
            %    SpikeTimestamp object S.  WIN_OFFSET is the number 
            %    of samples in WIN+OFFSET seconds.  FRAME is the number of
            %    samples in the current frame of data (i.e., the number of 
            %    samples since the end of the last frame).
            
            for kk=1:this.numUnits
                buf=this.fullBuffer{kk}; % save out to simple array
                new=double(newNeuralEvent{kk}); % save out to simple array
                
                new=new(new~=0); % weird problem encountering zero timestamps
                new=new+newFrameSamples; % offset the new timestamps
                buf=cat(1,buf(:),new(:)); % append the new timestamps
                
                buf=buf-totalOffset; % align "zero" to start of newest (WIN+OFFSET) sec
                buf(buf<=0)=[]; % delete old timestamps
                buf(buf>totalOffset)=[]; % delete extraneous large timestamps
                
                % put back into the buffer
                if(isempty(buf))
                    this.fullBuffer{kk} = [];
                else
                    this.fullBuffer{kk} = buf;
                end
            end
            
        end % END function add
        
        function data = get(this)
            %GET Retrieve raw timestamps from the buffer
            %
            %    DATA = GET(S) retrieves all timestamps in the buffer S.
            
            data = this.fullBuffer;
        end % END function get
        
        function data = getCounts(this)
            %GETCOUNTS Retrieve timestamp counts from the buffer
            %
            %    DATA = GETCOUNTS(S) retrieves timestamp counts for each
            %    unit in buffer S.
            
            data = cellfun('nnz',this.fullBuffer);
        end % END function getCounts
        
        function [m,n] = size(this)
            % SIZE Return the 2-dimensional size of the buffer
            %
            %    [M,N] = SIZE(C) returns the size of the SpikeTimestamp C
            %    accounting for the orientation mode ('r' for Row or 'c'
            %    for Column).  The values [M,N] indicate the size of the
            %    matrix returned by the command DATA = GET(C).
            
            n = 1;
            m = this.numUnits;
        end % END function size
        
        function empty(this)
            %EMPTY Empty all contents of the buffer (but leave initialized).
            %
            %    EMPTY(C) empties the contents of the SpikeTimestamp C,
            %    but does not change numScalarsPerEntry or DataClass 
            %    properties.
            
            % reset the buffer to empty
            this.fullBuffer = cell(this.numUnits,1);
        end % END function empty
    end % END methods
end % END classdef Buffer