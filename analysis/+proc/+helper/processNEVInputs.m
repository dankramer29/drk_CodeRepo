function [nv,numArrays,fs,idxLargestBlock,maxTime,minTime] = processNEVInputs(nv)
nv = util.ascell(nv);
idx_empty = cellfun(@isempty,nv);
nv(idx_empty) = [];
assert(~isempty(nv),'No valid Blackrock.NEV objects');
assert(all(cellfun(@(x)isa(x,'Blackrock.NEV'),nv)),'Must provide a cell array of valid Blackrock.NEV objects');
numArrays = length(nv);
fs = unique(cellfun(@(x)x.ResolutionTimestamps,nv));
assert(isscalar(fs),'NEV objects must have the same sampling rate');
[~,idxLargestBlock] = cellfun(@(x)max(x.RecordingBlockPacketCount),nv,'UniformOutput',false);
maxTime = cellfun(@(x,y)x.Timestamps{y}(end)/x.ResolutionTimestamps,nv,idxLargestBlock);
minTime = cellfun(@(x,y)x.Timestamps{y}(1)/x.ResolutionTimestamps,nv,idxLargestBlock);
