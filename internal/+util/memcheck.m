function varargout = memcheck(varargin)
%MEMCHECK evaluate available physical memory.
%
% USAGE:
% In general, if there are no left-hand-side arguments, a message will be 
% printed to the screen with the requested information.
%
% AVAIL = UTIL.MEMCHECK;
% [AVAIL,TOTAL] = UTIL.MEMCHECK;
% Return the number of bytes of available and total memory (no message
% printed to the screen).
%
% WILLFIT = UTIL.MEMCHECK(SZ,CLS)
% Returns logical TRUE/FALSE indicating whether data of size SZ and class
% CLS will fit in memory.
%
% [WILLFIT,NUM] = UTIL.MEMCHECK(SZ,CLS)
% Returns the number NUM of data of size SZ and class CLS that will
% fit in memory.
%
% [WILLFIT,NUM] = UTIL.MEMCHECK(SZ,CLS,DIM)
% Specify a dimension over which to evaluate the number of "data points"
% that will fit in memory. A data point replaces the specified dimension
% with singleton dimension.
%
% [WILLFIT,NUM,BLOCKIDX] = UTIL.MEMCHECK(SZ,CLS,DIM)
% Returns an Mx2 matrix BLOCKIDX where each row contains the start/end
% indices for contiguous blocks of "data points" that would fit in memory.
% Data points consider the specified dimension as singleton.
%
% UTIL.MEMCHECK(...,'MULT[IPLE]',VALUE)
% Constrain number of data points NUM to be a multiple of VALUE.
%
% UTIL.MEMCHECK(...,'ASSERT')
% Throw an error if data will not fit in memory.
%
% UTIL.MEMCHECK(...,'TOTALUTIL[IZATION]',VAL)
% Specify maximum amount of total physical memory to be utilized. VAL can
% be a number of bytes (101-Inf, note the '101'), percentage (1-100, note
% the '1'), or fraction (0-1).
%
% UTIL.MEMCHECK(...,'AVAILABLEUTIL[IZATION]',VAL)
% Specify maximum amount of available memory can be used to store the
% indicated data. AvailableMemory = TotalMemory - UsedMemory. TotalMemory
% is given by total physical memory multiplied by the TotalUtilization
% parameter above. VAL can be a number of bytes (101-Inf, note the '101'),
% percentage (1-100, note the '1'), or fraction (0-1).
%
% UTIL.MEMCHECK(...,'MINIMUMFREE',VAL)
% Specify the minimum amount of memory that must remain unused. VAL can be
% a number of bytes (101-Inf, note the '101'), percentage (1-100, note the
% '1'), or fraction (0-1). If VAL is a percentage or fraction, it will be
% interpreted as a percentage or fraction of total physical memory.
%
% UTIL.MEMCHECK(...,'Q[UIET]')
% Suppress all output.

% check mac / linux
if ~ispc
    
    % warning('Cannot check memory usage on Mac or Linux systems');
    varargout = arrayfun(@(x)true,1:nargout,'UniformOutput',false);
    return;
end

% get memory info
[~,s] = memory;

% check for verbosity input
FlagVerbose = true;
idx = strncmpi(varargin,'quiet',1);
if any(idx)
    FlagVerbose = false;
    varargin(idx) = [];
end

% memory utilization
TotalUtilization = 0.95; % default total memory usage
idx = strncmpi(varargin,'TotalUtilization',5);
if any(idx)
    TotalUtilization = varargin{circshift(idx,1,2)};
    if TotalUtilization > 100 % convert from bytes to fraction
        TotalUtilization = TotalUtilization / s.PhysicalMemory.Total;
    elseif TotalUtilization > 1 % convert from percentage to fraction
        TotalUtilization = TotalUtilization / 100;
    end
    if TotalUtilization > 1
        error('Cannot request memory utilization > 100% (requested %.2f%%)',100*TotalUtilization);
    end
    varargin(idx|circshift(idx,1,2)) = [];
end
AvailableUtilization = 1; % default available memory usage (available is constrained by TotalUtilization)
idx = strncmpi(varargin,'AvailableUtilization',5);
if any(idx)
    AvailableUtilization = varargin{circshift(idx,1,2)};
    if AvailableUtilization > 100 % convert from bytes to fraction
        AvailableUtilization = AvailableUtilization / s.PhysicalMemory.Available;
    elseif AvailableUtilization > 1 % convert from percentage to fraction
        AvailableUtilization = AvailableUtilization / 100;
    end
    if AvailableUtilization > 1
        error('Cannot request memory utilization > 100% (requested %.2f%%)',100*AvailableUtilization);
    end
    varargin(idx|circshift(idx,1,2)) = [];
end
MinimumFreeBytes = 0; % default minimum free memory requirement
idx = strcmpi(varargin,'MinimumFree');
if any(idx)
    MinimumFree = varargin{circshift(idx,1,2)};
    if MinimumFree > 100 % already in bytes
        MinimumFreeBytes = MinimumFree;
    else
        if MinimumFree > 1 % convert from percentage to bytes
            MinimumFree = MinimumFree / 100;
        end
        MinimumFreeBytes = MinimumFree*s.PhysicalMemory.Available;
    end
    if MinimumFreeBytes > s.PhysicalMemory.Available
        error('Cannot request free memory > available memory (%d bytes available, requested %d bytes)',s.PhysicalMemory.Available,MinimumFreeBytes);
    end
    varargin(idx|circshift(idx,1,2)) = [];
end

% constrain number-to-fit to be a multiple of something
Multiple = 1;
idx = find(strncmpi(varargin,'multiple',4));
if any(strncmpi(varargin,'multiple',4))
    Multiple = varargin{idx+1};
    varargin(idx+(0:1)) = [];
end

% whether to generate error if not possible
FlagAssert = false;
idx = strcmpi(varargin,'assert');
if any(idx)
    FlagAssert = true;
    varargin(idx) = [];
end

% check system resources
TotalMemoryBytes = TotalUtilization*s.PhysicalMemory.Total;
AvailableMemoryBytes = AvailableUtilization*(TotalMemoryBytes - MinimumFreeBytes - (s.PhysicalMemory.Total-s.PhysicalMemory.Available));

% generate outputs
if nargin==0
    
    % no inputs - return available/total memory
    if nargout==0
        if FlagVerbose
            fprintf('%s available memory (%s total).\n',byteString(AvailableMemoryBytes),byteString(TotalMemoryBytes));
        end
    else
        if nargout>0
            varargout{1} = AvailableMemoryBytes;
        end
        if nargout>1
            varargout{2} = TotalMemoryBytes;
        end
    end
    return;
else
    
    % inputs provided
    assert(length(varargin)>=2,'Must provide at least size SZ and class CLS');
    sz = varargin{1}; % size
    cl = varargin{2}; % class or bytes per element
    if ischar(cl)
        tmp = ones(1,1,cl);
        info = whos('tmp');
        cl = info.bytes;
    end
    if length(varargin)>2
        dim = varargin{3};
    else
        dim = nan;
    end
    
    % calculate number of bytes needed
    RequestedMemoryBytesFull = prod(sz)*cl;
    fit = RequestedMemoryBytesFull <= AvailableMemoryBytes;
    RequestedMemoryBytesPoint = prod(sz(setdiff(1:length(sz),dim)))*cl;
    MaxSimultaneousPoints = floor(AvailableMemoryBytes / RequestedMemoryBytesPoint);
    NumSimultaneousPoints = floor(MaxSimultaneousPoints / Multiple) * Multiple;
    
    % check fit and assert if needed
    if ~fit && FlagAssert
        bt1 = byteString(RequestedMemoryBytesFull);
        bt2 = byteString(AvailableMemoryBytes);
        error('Requested data would require %s memory (specified limit was %s)',bt1,bt2);
    end
    
    % print to screen if no output
    if nargout==0
        if FlagVerbose
            [btavail,un] = byteString(AvailableMemoryBytes);
            [btreq,un] = byteString(NumSimultaneousPoints*RequestedMemoryBytesFull,un);
            [bttot,un] = byteString(TotalMemoryBytes,un);
            fprintf('%d will fit in memory: use %.1f %s memory of %.1f %s available / %.1f %s total.\n',NumSimultaneousPoints,btreq,un,btavail,un,bttot,un);
        end
    end
    
    % number of simultaneous points that will fit in memory
    if nargout>0
        varargout{1} = fit;
    end
    if nargout>1
        varargout{2} = NumSimultaneousPoints;
    end
    
    % point-boundaries to sequentially process blocks (sized to fit in
    % memory) of the full requested data
    if nargout>2
        
        % identify the dimension
        if isnan(dim)
            cells = [1 1];
        else
            NumTotalPoints = sz(dim);
            cells(:,1) = 1 : NumSimultaneousPoints : NumTotalPoints;
            cells(:,2) = [cells(2:end,1)-1; NumTotalPoints];
        end
        varargout{3} = cells;
    end
end


function varargout = byteString(bytes,varargin)
%BYTESTRING convert bytes into KB/MB/GB/TB and produce readable string.
%
% Usage: 
% byteString(NUM)
% Print bytes to screen in readable format.
%
% STR = byteString(NUM)
% Return the string instead of printing to screen.
%
% [VAL,UNITS] = byteString(NUM)
% Return VAL and its units instead of embedding in string.
%
% ... = byteString(...,UNITS)
% Force a certain unit: 'B', 'KB', 'MB', 'GB', or 'TB'.

if nargin>1
    UnitString = varargin{1};
    switch upper(UnitString)
        case 'B', NumCuts = 0;
        case 'KB', NumCuts = 1;
        case 'MB', NumCuts = 2;
        case 'GB', NumCuts = 3;
        case 'TB', NumCuts = 4;
        otherwise, error('Unrecognized unit string ''%s''',UnitString);
    end
else
    NumCuts = floor(log(bytes)/log(1024));
    switch NumCuts
        case 0, UnitString = 'B';
        case 1, UnitString = 'KB';
        case 2, UnitString = 'MB';
        case 3, UnitString = 'GB';
        case 4, UnitString = 'TB';
        otherwise, error('Number of bytes out of practical range (divisible by 1024 %d times)',NumCuts);
    end
end
bytes = bytes/(1024^NumCuts);

if nargout==0
    fprintf('%.1f %s',bytes,UnitString);
end
if nargout==1
    varargout{1} = sprintf('%.1f %s',bytes,UnitString);
end
if nargout==2
    varargout{1} = bytes;
    varargout{2} = UnitString;
end