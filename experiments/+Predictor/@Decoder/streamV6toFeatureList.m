function FeatureList=streamV6toFeatureList(V6SPIKES)

% FeaureList is a Struct that contains info on the features used for the
% decoder.  Features Include:

% type : {'Event' , 'Continuous}
% channel : Cerebus channel 
% unit : if event, specified the unit number (0 = unsorted)
% bandpass : bandpass freq if filtered

nChannels=length(STREAMDATA.STREAM.SPIKES.channels);

for i=1:nChannels
    FeatureList(i).type='event';
    FeatureList(i).channel=STREAMDATA.STREAM.SPIKES.channels(i);
    FeatureList(i).unit=STREAMDATA.STREAM.SPIKES.subs(i,2);
    FeatureList(i).bandpass=[];
end

