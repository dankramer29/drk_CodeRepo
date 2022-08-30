function [numArrays,numPhysicalChannels,fs,idxLargestPacket] = processNSxInputs(ns)
assert(all(cellfun(@(x)isa(x,'Blackrock.NSx'),ns)),'Must provide a cell array of valid Blackrock.NSx objects');
numArrays = length(ns);
numPhysicalChannels = cellfun(@(x)x.ChannelCount,ns);
fs = unique(cellfun(@(x)x.Fs,ns));
assert(isscalar(fs),'NSx objects must have the same sampling rate');
[~,idxLargestPacket] = cellfun(@(x)max(x.PointsPerDataPacket),ns,'UniformOutput',false);