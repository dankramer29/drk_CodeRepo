function featdef = processBLcFeatdef(numPhysicalChannels,lagPerArray)
numFeats = sum(numPhysicalChannels);
nsp = nan(numFeats,1);
channel = nan(numFeats,1);
dataset_channel = nan(numFeats,1);
lag = nan(numFeats,1);
for kk=1:sum(numPhysicalChannels)
    channel(kk) = kk;
    nsp(kk) = find(cumsum(numPhysicalChannels)>=channel(kk),1,'first');
    dataset_channel(kk) = kk;
    if nsp(kk)>1
        channel(kk) = channel(kk) - numPhysicalChannels(nsp(kk)-1);
    end
    lag(kk) = lagPerArray{nsp};
end
feature = (1:numFeats)';
featdef = table(feature,nsp,channel,dataset_channel,lag);