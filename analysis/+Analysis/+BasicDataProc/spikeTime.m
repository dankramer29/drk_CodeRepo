function [spikeRaster, spikeTimeStamp, spikeMsRaster] = spikeTime(spikeRaw, varargin)
%spikeTime to get time stamps of raw voltage data
%   Detailed explanation goes here

%NEEDED:input an option to filter if it's truly raw
[varargin, rmsMethod] = util.argkeyval('rmsMethod',varargin, 1); %rmsMethod =1 means use RMS, if 0, use median
[varargin, threshMultiplier] = util.argkeyval('threshMultiplier',varargin, -4.5); %threshold multiplier
[varargin, fs] = util.argkeyval('fs',varargin, 1); %sampling rate to convert spike locations to ms



if ~rmsMethod
    noiseFiltSig=median(abs(spikeRaw)/0.6745); %divide by a factor from Quiroga et al., 2004, take the median which is supposedly a better estimate of the noise because less influenced by high spike rates or amplitudes
elseif rmsMethod
    noiseFiltSig=rms(spikeRaw);
end


thresholds=noiseFiltSig*threshMultiplier; 
spikeRaster=spikeRaw < repmat(thresholds,1,size(spikeRaw,2));

%convert to ms
spikeLoc=find(spikeRaster>0);
spikeTimeStamp=spikeLoc./(fs/1000); %convert to ms if given, otherwise don't change locations.
%make a raster where each row is a ms and spike time stamps are 1s
spikeMsRaster=zeros(round(length(spikeRaw)/(fs/1000)),1);
spikeMsRaster(round(spikeTimeStamp),1)=1;


% To Plot a raster
% spikeMsRaster(spikeMsRaster==0)=NaN;
% figure
% plot(spikeMsRaster, 'Marker', '.', 'LineStyle', 'none')

end

