function [num_nsps,num_physical_channels,fs,idx_largest_section] = processBLcInputs(blc)
assert(all(cellfun(@(x)isa(x,'BLc.Reader'),blc)),'Must provide a cell array of valid BLc.Reader objects');
num_nsps = length(blc);
num_physical_channels = cellfun(@(x)x.ChannelCount,blc);
fs = unique(cellfun(@(x)x.SamplingRate,blc));
assert(isscalar(fs),'BLc.Reader objects must have the same sampling rate');
[~,idx_largest_section] = cellfun(@(x)max([x.DataInfo.NumRecords]),blc,'UniformOutput',false);