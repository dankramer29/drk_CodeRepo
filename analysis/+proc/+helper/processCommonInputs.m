function [idxAll,FlagUniformOutput,procwin,lag,dtclass] = processCommonInputs(FlagUniformOutput,procwin,lag,dtclass,numArrays,varargin)
% collect all potential inputs

% keep track of varargin indices for the inputs
idxAll = false(size(varargin));

% force uniform (matrix, uniform length) or nonuniform (cell, different length) output
idx = strcmpi(varargin,'UniformOutput');
if any(idx)
    FlagUniformOutput = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end

% get the processing windows (trials)
idx = strcmpi(varargin,'procwin');
if any(idx)
    procwin = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end
if isnumeric(procwin)
    procwin = arrayfun(@(x)procwin,1:numArrays,'UniformOutput',false);
end
assert(iscell(procwin)&&length(procwin)==numArrays,'Must provide one set of procwin per array');
assert(all(cellfun(@(x)isempty(x)||size(x,2)==2,procwin)),'Each procwin must have two columns [START LENGTH] (in seconds)');
assert(numel(unique(cellfun(@(x)size(x,1),procwin)))==1,'Each array must have the same number of procwins');

% get the lag
idx = strcmpi(varargin,'lag');
if any(idx)
    lag = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end
if isnumeric(lag)
    if isscalar(lag)
        lag = arrayfun(@(x)lag,1:numArrays,'UniformOutput',false);
    else
        lag = arrayfun(@(x)x,lag,'UniformOutput',false);
    end
end
assert(iscell(lag)&&length(lag)==numArrays&&all(cellfun(@length,lag)==1),'Must provide one lag value per electrode array');
lag = lag(:);

% get the data class
idx = cellfun(@(x)strcmpi(varargin,x),{'double','single','uint32','int32','uint16','int16','uint8','int8'},'UniformOutput',false);
idx = sum(cat(1,idx{:}))>0;
if any(idx)
    dtclass = varargin{idx};
    idxAll = idxAll|idx;
end