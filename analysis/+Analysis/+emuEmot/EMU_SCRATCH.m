%EMU SCRATCH PAD

%% this is all scratch pad stuff for now.


%%plotting
xx=SdiffID{2};

figure
imagesc(S2); axis xy; colorbar;



%%
dataC = dataF(behavioralIndex(300):behavioralIndex(303),1);
    [filtData, params, bandfilter] = Analysis.BasicDataProc.dataPrep(dataC, 'needsCombfilter', 0, 'fs', fs); %calls this function for my basic processing steps
%% set up basic plotting
tt = filtData.dataSpec.tplot;
ff = filtData.dataSpec.f;

S = filtData.dataSpec.dataZ;

figure

imagesc(tt, ff, S); axis xy;

%% compare pspectrum and work out why so streaky

figure
dataTempN = normalize(dataTemp,2);
imagesc(tplot, ff, dataTempN); axis xy;
colorbar
figure
sPspectrumDb = 10*log10(sPspectrum);
sn=normalize(sPspectrumDb,2);
imagesc(t, f(1:615), sn(1:615,:)); axis xy;
ax=gca;
ax.YTick= [0:20:150];
colorbar


%%
%this works, take it and noramlize it and it looks pretty close to my
%output, just more muted maybe

 zz=trialDataTemp(shLAdj:shLAdj+trialLengthAdj,1,ii);
 zzz=trialDataGolay(:,1,ii);
 zzzz=trialDataGaus(:,1,ii);
% figure
% plot(zz)
% hold on
% plot(zzz)


jj=3;
[s, f, t] = pspectrum(zzzz, 500, "spectrogram", TimeResolution= .200, OverlapPercent=95);
sn=normalize(s,2);

 [filtData, params, bandfilter] = Analysis.BasicDataProc.dataPrep(zzzz, 'needsCombfilter', 0, 'fs', fs); %calls this function for my basic processing steps
%% set up basic plotting
tt = filtData.dataSpec.tplot;
ff = filtData.dataSpec.f;

S = filtData.dataSpec.dataZ;
tplot = linspace(0,tt(end),length(zz));
figure
subplot(3,1,1)
imagesc(tt, ff, S); axis xy; colorbar;
subplot(3,1,2)
imagesc(t, f(1:615), sn(1:615,:)); axis xy; colorbar;
ax=gca;
ax.YTick= [0:20:150];
subplot(3,1,3)
plot(tplot,zz)
hold on
plot(tplot,zzz)
plot(tplot,zzzz)



tt=itiDataFiltT.time;
ff=itiDataFiltT.freq;

for ii = 1:10
     S= itiDataFiltT.iti.ch69.specDzscore(:,:,ii);
     figure
imagesc(tt, ff, S); axis xy; colorbar;
end

 S = mean(itiDataFiltT.iti.ch69.specDzscore(:,:,:),3);
 






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

S = emotionTaskLFP.byemotion.ch97.image.specDzscore{2}(:, :, :);

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

%%





%% sig clusters
%THINGS TO DO, WILL NEED TO RUN THE CLUSTER PERMUTATION AGAINST ALL SORTS
%OF THINGS, AND WILL NEED TO THINK ABOUT WHAT GOES INTO IT BECAUSE WILL
%CREATE 1 MILLION PLOTS AND SIG CLUSTERS. ALSO ADD AN FF AND TT INTO THE
%COMPARE SO YOU CAN PLOT THEM FOR REAL. MAYBE RUN THROUGH CLUSTERS TO SEE
%IF ANY ARE RELEVANT JUST TO MARK THOSE FIGURES.

%% troubleshooting sig testing

%this attempt removes spurious trials that have some high noise for some
%reason THIS DOES NOT WORK, THERE MIGHT BE A WAY TO GET THE ACTUAL STD, BUT
%RIGHT NOW STD1 IS GIVING A STD OF 1, PROBABLY BECAUSE IT'S NORMALIZED?
%%


%RIGHT NOW I AM TRYING TO RE RUN IT WITH AN ITI SPECIFICALLY FOR THE
%EMOTIONS.
S1 = itiDataStitch.EmotionTask.(channelName{1});
S2 = emotionTaskLFP.byemotion.(channelName{1}).image.specD{3};
figure
imagesc(normalize(mean(S1, 3),2)); axis xy; colorbar;


for ii = 82:100
    imagesc(normalize(S1(:, :, ii),2)); axis xy; colorbar;
    
end

testT = stats.cluster_permutation_Ttest_gpu3d( S2, S1, 'xshuffles', 100);


figure
subplot (3,1,1)
imagesc(normalize(mean1,2)); axis xy;
colorbar
subplot (3, 1,2)
imagesc(normalize(mean2,2)); axis xy;colorbar;
subplot (3, 1, 3)
imagesc(thresh_binary); axis xy; colorbar;

figure
subplot (4,1,1)
imagesc(normalize(mnd1,2)); axis xy; colorbar
title('Mean of Trial data')
colorbar
subplot (4, 1,2)
imagesc(normalize(mnd2,2)); axis xy;colorbar;
%imagesc(sd1); axis xy;colorbar;
title('Mean of shuffle data 100 epochs')
subplot (4, 1, 3)
imagesc(r_pvalue); axis xy; colorbar; colormap(inferno)
title('pvalues from a ttest')
subplot (4, 1, 4)
imagesc(thresh_binaryR); axis xy; colorbar; colormap(inferno)
title('p values below alpha 0.01')

mat=false(size(thresh_binaryR));
    mat(clustR.PixelIdxList{cl_keep(6)})=true;    
    tstat_sums(ii)=sum(abs(tstat_R(mat)));
subplot (3, 1, 3)
imagesc(mat); axis xy; colorbar; colormap(inferno)
title('tstats from a ttest')

%%
clear abEpochP abEpochN
idx1=1;
idx2=1;
for ii =1:length(chInterest)
    itiDataTest = itiDataFilt.iti.(channelName{ii}).specD;
    itiDataTest = normalize(itiDataTest,2);
    stD1 = std(itiDataTest,[],2);
    stD2 = std(stD1, [], 3);
    mn1 = mean(itiDataTest, 2);
    mn2 = mean(mn1,3);
    for jj = 1:size(itiDataTest,3)
        zz=itiDataTest(:,:,jj) >stD2*3.5;
        if nnz(zz)
            abEpochP(idx1,1) = jj;
            abEpochP(idx1,2) = chInterest(ii); 
            idx1=idx1+1;
        end
        zz=itiDataTest(:,:,jj) < std2*-3.5;
        if nnz(zz)
            abEpochN(idx2,1) = jj;
            abEpochN(idx2,2) = chInterest(ii);
            idx2=idx2+1;
        end
    end
end

%TWO THINGS TO TRY, REMOVE A BASELINE MORE THAN JUST THE CAR. ALSO REALLY
%FIGURE OUT WHAT'S HAPPENING IN THE SHUFFLED DATA. WHY IS IT SO STRONG?
figure
imagesc(normalize(mean(trialDataTemp,3),2)); axis xy; colorbar
figure
imagesc(normalize(mean(trialDataTemp2,3),2)); axis xy; colorbar

figure
plot(trialDataTemp(40,:,1))
hold on
plot(smoothdata(trialDataTemp(40,:,1), 2,'gaussian',smWin))

shlAdj = 16;
[comp] = stats.cluster_permutation_Ttest_gpu3d(S2, shuffleTrialStitch);


%%

mnd2t=nanmean(mnd2,2);
mnd2c=repmat(mnd2t,1,size(mnd1,2));

tt=emotionTaskLFP.time;
ff=emotionTaskLFP.freq;
xx= mean(itiData,3);
id = mean(dataIdentityTask,3);
em = mean(dataEmotionTask,3);

figure
imagesc(tt,ff,em); axis xy; colorbar;

tt=filtDataTemp.dataSpec.tplot;
ff=filtDataTemp.dataSpec.f;
xx=filtDataTemp.dataSpec.dataZ;
cc=9;

xx= mean(itiData,3);

idx = 1;
for ii =1:10:190
    xmean(:,:,idx) = mean(itiData(:,:,ii:ii+10),3);
    idx = idx+1;
end

yy=(xmean(:,:,1));
[mxt, ccmxt]=max(xmean,[],3);
[mnt, ccmnt]=min(xmean,[],3);

figure
subplot(2,1,1)
imagesc(tt,ff,normalize(yy, 2)); axis xy; colorbar;
subplot(2,1,2)
imagesc(tt,ff,yy); axis xy; colorbar;



figure
subplot (3,1,1)
imagesc(mnd1); axis xy; colorbar
colorbar
subplot (3, 1,2)
imagesc(mnd2); axis xy;colorbar;
subplot (3, 1, 3)
imagesc(r_pvalue); axis xy; colorbar; colormap(inferno)



figure
xx = mean(dataIdentityTask,3);
imagesc(tt,ff,xx), axis xy; colorbar
figure
imagesc(mean1); axis xy; colorbar;
figure
imagesc(thresh_binary); axis xy; colorbar;

tt=emotionTaskLFP.time;
ff=emotionTaskLFP.freq;


%%
for ii =1:5
    figure
    xx=identityTaskLFP.byidentity.ch148.image.specDzscore{1}(:,:,ii);
    imagesc(tt,ff, xx); axis xy; colorbar
end

   
xx=mean(identityTaskLFP.byidentity.ch148.image.specDzscore{1},3);
xxm=normalize(xx,2);
figure
 imagesc(tt,ff, xx); axis xy; colorbar


 for ii =1:5
    figure
    xx=itiDataFilt.iti.ch148.specDzscore(:,:,ii);
    imagesc(tt,ff, xx); axis xy; colorbar
end

   
xx=mean(itiDataFilt.iti.ch148.specDzscore,3);
xxm=normalize(xx,2);
figure
 imagesc(tt,ff, xx); axis xy; colorbar



%% 

for ff=1:length(chInterest)
    ch = num2str(chInterest(ff));
    chNameStr{ff} = ['ch' ch];
end

for ff=1:3
    numstr = num2str(ff);
    idName{ff} = ['id' numstr];
end

tt=emotionTaskLFP.time;
ff=emotionTaskLFP.freq;
xx= identityTaskLFP.byidentity.ch69.image.specD{1};
S1 = mean(xx,3);
S1n = normalize(S1,2);
figure
imagesc(tt,ff,S1n); axis xy; colorbar

figure
S1d = 10*log10(dataTemp);
S1n = normalize(S1d, 2);
figure
imagesc(tplot, ff, dataFinalZ); axis xy; colorbar;


ii=1;
jj=1;
for ii = 1:3
    for jj = 1:3
        S1 = nbackCompare.(chNameStr{ii}).(idName{jj}).emotionTaskMean;
        S1 = normalize(S1,2);
        S2 = nbackCompare.(chNameStr{ii}).(idName{jj}).identityTaskMean;
        S2 = normalize(S2,2);
%         figure
%         imagesc(tt, ff, nbackCompare.(chNameStr{ii}).(idName{jj}).identityTasksigclust)

        figure

        subplot(2,1,1)
        imagesc(tt,ff,S1); axis xy
        title(chNameStr{ii}, idName{jj})
        colorbar
        subplot(2,1,2)
        imagesc(tt,ff,S2); axis xy
        title(chNameStr{ii}, idName{jj})
        colorbar
%         subplot(3,1,3)
%         imagesc(tt,ff,S1-S2); axis xy
    end
end

ch = 1;
aa=1;
bb=18;
for tr = aa:bb
S1 = identityTaskLFP.byidentity.ch69.image.specDzscore{1}(:,:,tr);
%S1 = normalize(S1,2);
figure
imagesc(tt,ff,S1); axis xy; colorbar
end
% DOUBLE CHECKED THIS, THE DIFFERENCE HERE IS THAT IF YOU NORMALIZE THEN
% MEAN IT, THE RANGE IS MUCH LOWER...
Sm = mean(identityTaskLFP.byidentity.ch69.image.specD{1}, 3); %THIS IS SD 3
Smn= normalize(Sm, 2);
figure
imagesc(tt,ff,Smn); axis xy; colorbar;colormap(inferno(100));

Sm = mean(identityTaskLFP.byidentity.ch69.image.specDzscore{1}, 3); %THIS IS 0.8
figure
imagesc(tt,ff,Sm); axis xy; colorbar;colormap(inferno(100));

tplot = filtDataTemp.dataSpec.tplot;
ff = filtDataTemp.dataSpec.f;
Sm = normalize(filtDataTemp.dataSpec.data,2);
figure
imagesc(tplot, ff, Sm); axis xy; colorbar;
figure
imagesc(tplot, ff, filtDataTemp.dataSpec.dataZ); axis xy; colorbar;


Sm = mean(nbackCompare.(chNameStr{ch}).allIdentities.identityTaskData(:,:,aa:bb),3);

figure
imagesc(tt,ff,Smn); axis xy; colorbar;colormap(inferno(100));
xx=nbackCompare.ch69.id1.identityTaskMean;
xx=normalize(xx,2);
figure
imagesc(tt,ff,xx); axis xy; colorbar;


S1= nbackCompareZ.ch77.allEmotions.emotionTasksigclust;
figure
        imagesc(tt,ff,S1); axis xy; colorbar

S1 = nbackCompare.(chNameStr{ii}).(idName{jj}).emotionTaskMean;


S1 = nbackCompareZ.(chNameStr{ii}).(idName{jj}).emotionTaskMean;

S2 = nbackCompareZ.(chNameStr{ii}).(idName{jj}).identityTaskMean;

tt=emotionTaskLFP.time;
ff=emotionTaskLFP.freq;


figure
imagesc(tt, ff, nbackCompareZ.(chNameStr{ii}).(idName{jj}).identityTasksigclust)

figure

subplot(3,1,1)
imagesc(tt,ff,S1); axis xy
subplot(3,1,2)
imagesc(tt,ff,S2); axis xy
subplot(3,1,3)
imagesc(tt,ff,S1-S2); axis xy


%% comparing wavelet

cwt(dataM, 500)

figure
dataTempPSx = normalize(dataTempPS,2);
imagesc(tplotpSpec, f(1:615), dataTempPSx(1:615,:)); axis xy;
ax=gca; colorbar
ax.YTick= [0:20:150];

figure
dataTempx = normalize(10*log10(dataTemp),2);
imagesc(tplot, ff, dataTempx); axis xy; colorbar