function [pk, pkLoc] = psdFreqPeak(data, varargin)
%psdFreqPeak Evaluate the peaks of the PSD across all channels and all
%times to find the points of maximum power
%   THIS NEEDS WORK, THE "ALL PEAKS" PART NEEDS SOME DENOISING, BUT THE
%   CANONICAL BANDS SHOULD WORK.  


[varargin, fs] = util.argkeyval('fs',varargin, 2000); %sampling rate of the signal
[varargin, classicBand]= util.argkeyval('classicBand', varargin, [1 4; 4 8; 8 13; 13 30; 30 50; 50 200]);

%for spectrogram
params = struct;
params.Fs = fs;   % in Hz
%params.fpass = [MinFreq MaxFreq];     % [minFreqz maxFreq] in Hz
params.tapers = [5 9]; %second number is 2x the first -1, and the tapers is how many ffts you do.
params.pad = 1;
%params.err = [1 0.05];
params.err=0;
params.trialave = 0; % average across trials
params.win = [1 0.005];   % size and step size for windowing continuous data

lblN={'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma', 'HighGamma'}; %set up labeling

%make sure data is columns=channels and rows are time
if size(data, 1)<size(data,2)
    data=data';
end

dataMean=mean(data,3); %along trials
dataMeanCh=mean(dataMean,2); %along channels

%convert to spectrum
[spectBaseAllCh, ffall]=chronux.ct.mtspectrumc(dataMeanCh, params);


[spectBaseAllChP, ffallP]=chronux.ct.mtspectrumc(dataMeanCh, params);


%store all of the peaks, very noisy 
for ii=1:size(psdBaseAll, 2)
    [pk, pkLoc]=findpeaks(psdBase(:,ii));
    freqPeakAll{ii}=pkLoc; %store the peaks by channel
end

%store the peaks in the canonical bands
for ii=1:size(classicBand, 1)
    [mx, mxLoc]=max(psdBaseAllCh(:, classicBand(ii,1):classicBand(ii,2)));
    freqPeak.(lblN{ii})=mxLoc;
end



[spect, t, f]=chronux.ct.mtspecgramc(dataMeanCh, params.win, params);
end

