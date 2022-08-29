function procwin = uniformProcwin(procwin)
% UNIFORMPROCWIN Enforce uniform processing windows
%
%   PROCWIN = UNIFORMPROCWIN(PROCWIN)
%   The input PROCWIN must be a cell array with one cell per array; each of
%   these cells should also be a cell array with one cell per processing
%   window, i.e. PROCWIN{ARRAY}{WIN}. These bottom-level cells should
%   contain the start and end of a processing window. This function will
%   modify each of the processing windows so that all arrays read the same
%   times, where these times will be the maximum of the original start
%   times and the minimum of the original end times.

% pull out meta information
procwin = util.ascell(procwin);
numArrays = length(procwin);
assert(all(cellfun(@isnumeric,procwin))&&all(cellfun(@(x)size(x,2)==2,procwin)),'Each cell of PROCWIN input must be a Kx2 matrix indicating the start/end of K processing windows');
numWins = cellfun(@(x)size(x,1),procwin);
assert(numel(unique(numWins))==1,'All %d arrays must have the same number of procwins: %s',numArrays,util.vec2str(numWins));
numWins = unique(numWins);

% identify max(min) and min(max) to set uniform windows
orig_procwin = procwin;
procwin = cellfun(@(x)nan(numWins,2),procwin,'UniformOutput',false);
for kk=1:numWins
    
    % find max start time and min length
    st = max(arrayfun(@(x)orig_procwin{x}(kk,1),1:numArrays)); % preserve start times
    len = min(arrayfun(@(x)orig_procwin{x}(kk,2),1:numArrays)); % unify lengths
    
    % make sure we're not trying to read past the original boundaries
    old_maxtime = cellfun(@sum,orig_procwin);
    new_maxtime = st+len;
    adding_time = new_maxtime>old_maxtime;
    if any(adding_time),warning('adding time...');end
    
    % reconfigure to new unified timing
    for nn=1:numArrays
        procwin{nn}(kk,:) = [st len];
    end
end