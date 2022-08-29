function [meanstdSpkPerc, noiseCh, spk, spkRate, spkRateTemp, tm] = activeSpkCh(smoothSpkCh, varargin)
%activeSpkCh takes smoothed spiking data (or unsmoothed and smooth it) and
%finds the mean, std, or (and use this) the modulation depth) and takes the nth percentile that indicates most
%active (in mean case, highest spiking rates, in std case, most
%variability)
% Example
% [stdSpkPerc, meanSpkPerc, spk, spkRate, spkRateSmooth, tm] = Analysis.BasicDataProc.activeSpkCh(smoothSpkCh, 'perc', 90);
[varargin, perc]=util.argkeyval('perc',varargin, 80); %percentile to choose channels above
[varargin, chPosition]=util.argkeyval('chPosition', varargin, 2); %specify where the channels are in the matrix and change if not in the right spot.

if isa(smoothSpkCh, 'cell')     
    for ii=1:length(smoothSpkCh)
        spkRateTemp(:,:,ii)=smoothSpkCh{ii};
    end
else
    spkRateTemp=smoothSpkCh;
end

%make sure data is columns=channels and rows are time
if chPosition~=2
    spkRateTemp=permute(spkRateTemp, [2,1,3]);
end

if isempty(spkRateTemp > 1)
    warn('data not smoothed, smoothed for analysis');
    [spk, spkRate, spkRateTemp, tm] = Analysis.BasicDataProc.spikeRate(spkRateTemp);
end

meanspkRateTemp=nanmean(spkRateTemp,3);

meanSpk=nanmean(meanspkRateTemp); %mean across time for each channel (data x channel)
stdSpk=nanstd(meanspkRateTemp);
mxSpk=max(meanspkRateTemp);
mnSpk=min(meanspkRateTemp);
modDepth=mxSpk-mnSpk;

meanPerc=prctile(meanSpk, perc);
stdPerc=prctile(stdSpk, perc);
modDPerc=prctile(modDepth, perc);

meanSpkPerc=find(meanSpk > meanPerc);
stdSpkPerc=find(stdSpk > stdPerc);
modDSpkPerc=find(modDepth > modDPerc);

meanstdSpkPerc.meanSpkPerc=meanSpkPerc;
meanstdSpkPerc.stdSpkPerc=stdSpkPerc;
meanstdSpkPerc.modDSpk=modDSpkPerc;
meanstdSpkPerc.meanPerc=meanPerc;
meanstdSpkPerc.stdPerc=stdPerc;
meanstdSpkPerc.modDPerc=modDPerc;
meanstdSpkPerc.meanSpk=meanSpk;
meanstdSpkPerc.stdSpk=stdSpk;
meanstdSpkPerc.stdSpk=modDepth;




end

