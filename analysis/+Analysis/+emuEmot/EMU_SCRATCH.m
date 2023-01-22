%EMU SCRATCH PAD

%% this is all scratch pad stuff for now.

dataC = dataF(behavioralIndex(300):behavioralIndex(303),1);
    [filtData, params, bandfilter] = Analysis.BasicDataProc.dataPrep(dataC, 'needsCombfilter', 0, 'fs', fs); %calls this function for my basic processing steps
%% set up basic plotting
tt = filtData.dataSpec.tplot;
ff = filtData.dataSpec.f;

S = filtData.dataSpec.dataZ;

figure

imagesc(tt, ff, S); axis xy;
%%
%this works, take it and noramlize it and it looks pretty close to my
%output, just more muted maybe

[s, f, t] = pspectrum(dataC, 500, "spectrogram", TimeResolution= .200, OverlapPercent=95);


sn=normalize(s,2);

subplot(1,2,1)
imagesc(tt, ff, S); axis xy;
subplot(1,2,2)
imagesc(t, f(1:615), sn(1:615,:)); axis xy;
ax=gca;
ax.YTick= [0:20:150];

subplot(4,1,1)
imagesc(t, f, s); axis xy;
subplot(4,1,2)
imagesc(t, f, sqrt(s)); axis xy;
subplot(4,1,3)
imagesc(t, f, 10*log10(sqrt(s))); axis xy;
subplot(4,1,4)
imagesc(t, f, normalize(sqrt(s))); axis xy;




figure
spectrogram(dataC*sqrt(2), 100, 95, [1:100], 500, "power", "yaxis");
figure
spectrogram(dataC, 'yaxis');

[trum, ft] = pspectrum(dataC, 500);

trumDB = 10*log10(trum);
figure
plot(ft, trumDB)




%% set up plotting once obtained nwbLFPchProc above
tt = filtData.dataSpec.tplot(1:size(emotionTaskLFP.byemotion.ch69.image.specDzscore{1}, 2));
ff = filtData.dataSpec.f;

S = emotionTaskLFP.byemotion.ch69.image.specDzscore{1}(:, :, 2);

SS1 = emotionTaskLFP.byemotion.ch69.image.specDzscore{1};
SS2 = emotionTaskLFP.byidentity.ch69.image.specDzscore{2};

SS1m = mean(SS1, 3);
SS2m = mean(SS2, 3);
SSt = SS1m-SS2m;

figure
imagesc(tt, ff, SS1(:,:,1)); axis xy;
figure
imagesc(tt, ff, SS1m); axis xy;
figure
imagesc(tt, ff, SS2m); axis xy;
figure
imagesc(tt, ff, SSt); axis xy;


figure
imagesc(tt, ff, S); axis xy;

for ii = 1:9
    S = SS(: , : , ii);
    figure
    imagesc(tt, ff, S); axis xy;
end

figure
S = dataTemp(:, 1:1000, 1);
tt = tplot(1:1000);
imagesc(tt, ff, S); axis xy

%%
% for the test output in nwbLFPchProc NEXT THING TO CHECK IS DIFFERENT
% CHANNELS? ALSO IS THE Z SCORING DOING TOO MUCH? PROBABLY AND PROBABLY CAN
% Z SCORE FOR JUST THE CHUNKS, DOUBLE CHECK IN THE STUFF YOU JUST DID THAT
% IT Z SCORED ONLY ACROSS EACH TRIAL INSTEAD OF ACROSS ALL OF THE DATA
% WHERE ONE LARGE OUTPUT WOULD REALLY DOMINATE.

%NO IDEA WHAT IS HAPPENING, THE PROCESSING IS REALLY JUST DOING CHRONUX.
%AT THIS POINT, LOOK BACK THROUGH YOUR OWN FILTERING PROCESS AND THEN TRY
%THE RAW DATA
        [dataTempM, tplotTemp, ff]=mtspecgramc(dataM, params.win, params); %time by freq, need to ' to plot with imagesc


tt = filtDataTemp.dataSpec.tplot;
ff = filtDataTemp.dataSpec.tplot;
Stest = filtDataTemp.dataSpec.dataZ;

xx= nback.byidentity.ch77.image.specDzscore{1};
StestM = nanmean(nback.byidentity.ch77.image.specDzscore{1}, 3);

figure

imagesc(tt, ff, StestM); axis xy

for ii = 1:18
    figure
    imagesc(tt, ff, xx(:,:,ii)); axis xy
end


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


%% noise rejection

macroCARch = macrowiresCAR(chInterest, :);

%% shuffle baseline



%% sig clusters
%THINGS TO DO, WILL NEED TO RUN THE CLUSTER PERMUTATION AGAINST ALL SORTS
%OF THINGS, AND WILL NEED TO THINK ABOUT WHAT GOES INTO IT BECAUSE WILL
%CREATE 1 MILLION PLOTS AND SIG CLUSTERS. ALSO ADD AN FF AND TT INTO THE
%COMPARE SO YOU CAN PLOT THEM FOR REAL. MAYBE RUN THROUGH CLUSTERS TO SEE
%IF ANY ARE RELEVANT JUST TO MARK THOSE FIGURES.

S1 = nbackCompare.ch77.id2.emotionTaskMean;
S1 = normalize(S1,2);
S2 = nbackCompare.ch77.id2.identityTaskMean;
S2 = normalize(S2,2);
tt=emotionTaskLFP.time;
ff=emotionTaskLFP.freq;


figure
imagesc(tt, ff, nbackCompare.ch77.id2.identityTasksigclust)

figure

subplot(3,1,1)
imagesc(tt,ff,S1); axis xy
subplot(3,1,2)
imagesc(tt,ff,S2); axis xy
subplot(3,1,3)
imagesc(tt,ff,S1-S2); axis xy


