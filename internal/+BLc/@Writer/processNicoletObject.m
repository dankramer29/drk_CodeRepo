function [Fs,NumDataPoints,DataChannels,bytesPerN] = processNicoletObject(this,src)

% infer common data sampling rate
Fs = nan(1,length(src.segments)); % only process majority-common sampling rates
for ss=1:length(src.segments)
    tmpFs = median(src.segments(ss).samplingRate);
    assert(length(tmpFs)==1,'Require common sampling rate among all data channels');
    Fs(ss) = tmpFs;
end
Fs = unique(Fs);
assert(numel(Fs)==1,'Multiple sampling rates detected but unsupported');

% choose largest channel subset satisfying (1) present in all segments; (2) common sampling rate
DataChannels = src.segments(1).chName(src.segments(1).samplingRate==Fs);
NumDataPoints = nan(1,length(src.segments));
for ss=1:length(src.segments)
    idxChannelsInSegment = ismember(DataChannels,src.segments(ss).chName);
    DataChannels(~idxChannelsInSegment) = [];
    idxDataChannelsInSegment = ismember(src.segments(ss).chName,DataChannels);
    idxCommonSamplingRate = ismember(src.segments(ss).samplingRate(idxDataChannelsInSegment),Fs);
    DataChannels(~idxCommonSamplingRate) = [];
    NumDataPoints(ss) = src.segments(ss).duration*Fs;
end
assert(~isempty(DataChannels),'No channels left to process');
assert(sum(NumDataPoints)>0,'No data points left to process');

% get dimensions of a single frame
try
    idxChannelsInSegment = find(ismember(src.segments(1).chName,DataChannels));
    idxChannelsInSegment = idxChannelsInSegment(this.indexChannelToWrite);
    data = src.getdata(1, [1 1], idxChannelsInSegment);
catch ME
    util.errorMessage(ME);
    keyboard
end
info = whos('data');
bytesPerN = round(1.5*info.bytes);