function [spikeTimeStamp, spikeMsRaster, tmSpk] = spikeTime2msTimes(spikeTime, varargin)
%outputs spikes on single ms time stamps (so downsamples) and has a time
%output for easy raster plots
%Inputs
%   spikeTimes - a spike time stamp input that has a sampling rate higher
%   than 1000 Hz
%   fs - the smapling rate
%   sessionStart- in ms, or s(will convert) when did the session start
%   sessionEnd- in ms, or s(will convert) when did the session end

%Outputs
%     spikeTimeStamps - spike times converted to ms, no change from the original
%     spikeMsRaster - spike times in an array that each row is a ms and 1s are spikes


[varargin, fs] = util.argkeyval('fs',varargin, 1); %sampling rate to convert spike locations to ms
[varargin, timeSec] = util.argkeyval('timeSec', varargin, true); %1= time in seconds, 0=time in ms
[varargin, sessionStart] = util.argkeyval('sessionStart', varargin, spikeTime(1)); %if session times known
[varargin, sessionEnd] = util.argkeyval('sessionEnd', varargin, spikeTime(end)); %if session times known


if sessionStart<spikeTime(1) 
    sessionTimeStart=sessionStart;
else
    sessionTimeStart=spikeTime(1);
end
if sessionEnd>spikeTime(end)
    sessionTimeEnd=sessionEnd;
else
    sessionTimeEnd=spikeTime(end);
end

sessionLength=sessionTimeEnd-sessionTimeStart;

%convert session length to ms if input in seconds
if timeSec==true   
    sessionLength=sessionLength*1000;
    sessionStart=sessionStart*1000;
    sessionEnd=sessionEnd*1000;
    spikeTimeStamp=spikeTime./(fs/1000); %convert to ms if given, otherwise don't change locations.
else
    spikeTimeStamp=spikeTime./(fs/1000); %convert to ms if given, otherwise don't change locations.    
end




%make a raster where each row is a ms and spike time stamps are ones
spikeMsRaster=zeros(round(sessionLength),1);

spkTemp=spikeTimeStamp-sessionStart+1;
spikeMsRaster(round(spkTemp),1)=1;

tmSpk=sessionStart:sessionEnd+1;



% To Plot a raster
% spikeMsRaster(spikeMsRaster==0)=NaN;
% figure
% plot(tmSpk(1:10000), spikeMsRaster(1:10000), 'Marker', '.', 'LineStyle', 'none')

end

