%EMU SCRATCH PAD

%% check spectrogram
params = struct;
params.Fs = fs;   % in Hz
params.fpass = [1 200];     % [minFreqz maxFreq] in Hz
params.tapers = [5 9]; %second number is 2x the first -1, and the tapers is how many ffts you do.
params.pad = 1;
%params.err = [1 0.05];
params.err=0;
params.trialave = 0; % average across trials
params.win = [.2 0.005];   % size and step size for windowing continuous data

[dataTempM, tplot, ff]=chronux.ct.mtspecgramc(testData, params.win, params); %time by freq, need to ' to plot with imagesc



dataTemp=permute(dataTempM, [2,1,3]); %flip to make it freq x time x channel

dataDb=10*log10(dataTemp);     


for ii=1:size(dataTemp,3)
    baseTemp=dataDb(:,:,ii);
    [a, b]=proc.basic.zScore(baseTemp, 'z-score', 2); %get the z score mean and std
    dataFinalZ(:,:,ii)=(baseTemp-a)./b;
end

% THERE IS SOMETHING WEIRD GIVING NANS ON CERTAIN TRIALS, FOR INSTANCE 1
% AND 9 ARE JUST BLANK
tr=9;
close all
figure
imagesc(tplot, ff, dataTemp(:,:,tr)); axis xy;
figure
imagesc(tplot, ff, dataDb(:,:,tr)); axis xy;
figure
imagesc(tplot, ff, dataFinalZ(:,:,tr)); axis xy;


%%

