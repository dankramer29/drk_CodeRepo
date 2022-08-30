
%% SCRATCH PAD FOR NPTL STUFF
%GET DATA FROM THE NS5 FILES AT STANFORD
% ns5file='C:\Users\dankr\Documents\Data\LateralBlocks-selected\3_cursorTask_Complete_t5_bld(003)004.ns5';
% %ns5=openNSx('read', ns5file, 'c:01:12'); 
% load('C:\Users\dankr\Documents\Data\92519_NPTL_TrialData\R_stream_CL.mat')
% Rr=R(1:10); %get the first 64 channels that go with the trial 3 section
% %data=ns5.Data{1,1};
% %dsData=Analysis.NPTL.downSample(data, 30000, 2000);

% %GridTask USE EVAL_NEWR
%ns5file='C:\Users\kramdani\Dropbox\My PC (Cerebro2)\Documents\Data\121218_b7_NPTL_COData\LateralGrid_121218_b7\7_cursorTask_Complete_t5_bld(007)008.ns5';
%load('C:\Users\kramdani\Dropbox\My PC (Cerebro2)\Documents\Data\121218_b7_NPTL_COData\cursorTaskR_T5.mat')

%head move task
ns5file='C:\Users\kramdani\Dropbox\My PC (Cerebro2)\Documents\Data\t5.2019.03.18_HeadMoveData\Data\NS5_block10Head\10_cursorTask_Complete_t5_bld(010).ns5';
% %should be lateral grid
load('C:\Users\kramdani\Dropbox\My PC (Cerebro2)\Documents\Data\t5.2019.03.18_HeadMoveData\Data\R_structs\R_block_10.mat')
R=R(1:64);
%optional
ns5=openNSx('read', ns5file, 'c:01:96'); 
if isa(ns5.Data, 'cell')
    data=double(ns5.Data{end})';
else
    data=double(ns5.Data)';
end


%GET DATA FROM THE NS5 FILES AT STANFORD
ns5file='C:\Users\dankr\Documents\Data\LateralBlocks-selected\3_cursorTask_Complete_t5_bld(003)004.ns5';
%ns5=openNSx('read', ns5file, 'c:01:12'); 
load('C:\Users\dankr\Documents\Data\92519_NPTL_TrialData\R_stream_CL.mat')
Rr=R(1:10); %get the first 64 channels that go with the trial 3 section
%data=ns5.Data{1,1};
%dsData=Analysis.NPTL.downSample(data, 30000, 2000);



%% to obtain the cursor position and the spike rates

trialNum=[1 20]; %change here for how many trials you want to look at
ch=[3];
%go through each channel
for jj=1:length(ch)
    cp=[]; cpTrial=[]; spikeRaw=[]; id1=1; spk=[]; spkRate=[]; spkRateSmooth=[]; tm=[];
    for ii=trialNum(1):trialNum(2)
        cp=[cp R(ii).cursorPosition(1:2,:)];
        spikeRaw=[spikeRaw double(R(ii).spikeRaster(ch(jj),:))];
        cpTrial{id1}=R(ii).cursorPosition(1:2,:);
        id1=id1+1;
    end
    
    %% to look at spikes (from what I understand about the R so far)
    [spk, spkRate, spkRateSmooth, tm] = Analysis.BasicDataProc.spikeRate(spikeRaw);
    
    ch{jj}.spk=spk; %etc
    ch{jj}.spkRate=spkRate;
    ch{jj}.spkRateSmooth;
    ch{jj}.tm=tm;
    
end

%grid task dots
gridDots=[R.posTarget];
plot(gridDots(1,:), gridDots(2,:), 's', 'MarkerEdgeColor', 'c');

%% for then plotting together
set(0, 'DefaultAxesFontSize', 22)

figure
subplot(5,3,[1:9])
hold on

dots=[409 0; 289 -289; 0 -409; -289 -289; -409 0; -289 289; 0 409; 289 289]; %dots in order starting at 0, plot below to verify with colors or to vary the colors
plot(dots(:,1),dots(:,2),'o');

N=100;
C=linspecer(N);
figure
idx=1;
for ii=1:length(PosTarget)
    hold on
    plot(PosTarget(ii, 1), PosTarget(ii, 2), 'o', 'MarkerEdgeColor', C(idx,:), 'MarkerFaceColor', C(idx,:));
    idx=idx+5;
end


dots=[0,0;0,-409;-409,0;0,409;409,0;289,289;289,-289;-289,289;-289,-289];
plot(dots(:,1),dots(:,2),'o');


%% will plot trials xx:yy to see what it looks like
% figure
% hold on
% dots=[0,0;0,-409;-409,0;0,409;409,0;289,289;289,-289;-289,289;-289,-289];
% plot(dots(:,1),dots(:,2),'o');
% xx=13; yy=16;
% for jj=xx:yy
%     plot(cpTrial{jj}(1,:), cpTrial{jj}(2,:))
% end
%%
%will plot 8 trials at a time
% for jj=0:7
%     figure
%     hold on
%     plot(dots(:,1),dots(:,2),'o');
%     for ii=1:8
%         plot(cpTrial{jj*8+ii}(1,:), cpTrial{jj*8+ii}(2,:))
%     end
% end
% title(['cursor position trials ', num2str(trialNum(1)), ' to ', num2str(trialNum(2))]);

%CONSIDER NOW PLOTTING EACH TRIAL RASTER PLOT?



subplot(5,3,[10:12])

plot(spk, '.')
hold on
plot(tm, spkRateSmooth)
title('Raster plot');
ylim([0 max(spkRateSmooth)]);

%to do next, need to see the time of the movements to see changes in spike
%rates, probably do a stimulus lock of some kind
%plot multiple channels next to each other I think



subplot(3,1,3)
%will place lfp here




figure
hold on
for ii=1:length(spikeCh)
    plot(spikeCh{1,ii}.spkRateSmoothHold{1}(2,:), spikeCh{1,ii}.spkRateSmoothHold{1}(1,:));
end

figure
hold on
for ii=1:length(meanstdSpkPer.meanSpkPerc)
    plot(tm,spkRateSmooth(meanstdSpkPer.meanSpkPerc(ii), :))
end

figure
hold on
for ii=1:length(meanstdSpkPer.stdSpkPerc)
    plot(tm,spkRateSmooth(meanstdSpkPer.stdSpkPerc(ii), :))
end


figure
hold on
for ii=1:length(transHoldSmooth)
    plot(transHoldSmooth{ii}(7,:))
end


%for comparing the lowpass filters on the power
    for ii=1:length(lblB)
        
        %run the filters and make power
        tempClassicBandT=filtfilt(bandfilterBroad.(lblB{ii}), dataM).^2; 
        xx(:,ii)=tempClassicBandT;
        %lowpass to smooth the data.  This can be a variable pass, based on what "window" you want to smooth over
        tempClassicBand1(:, ii)=lowpass(tempClassicBandT, 1, fs);
        tempClassicBand10t(:, ii)=lowpass(tempClassicBandT, 10, fs);
        tempClassicBand20t(:, ii)=lowpass(tempClassicBandT, 20, fs);
        tt=0:1/fs:(length(tempClassicBandT)-1)/fs; %time in seconds
        figure
        hold on
        plot(tt,xx(:,ii))
        plot(tt,tempClassicBand1(:,ii))
        plot(tt,tempClassicBand10t(:,ii))
        plot(tt,tempClassicBand20t(:,ii))
        %tempCBC(ii,:,:)=tempClassicBand; %build the filtered data into 3d matrix and make 3rd dimmension channels, so now freq x time x channels
    end

meanSpkMove=mean(chMoveSpk{1});
steSpkMove=std(chMoveSpk{1})/sqrt(length(chMoveSpk{1}));

meanSpkHold=mean(chHoldSpk{1});
steSpkHold=std(chHoldSpk{1})/sqrt(length(chHoldSpk{1}));

spkWin=0.02; %window in seconds to average spikes over, in seconds
holdPre=0; %time before transition to 11, 
transHoldPre=-400;
movePre=200;
transMovePre=-100;
%spike timing for each situation

tSpkHold=linspace(holdPre-epochH, 0, floor(abs(epochH)/spkWin)); %t=0 is state 11 starting, prior to click to click (state 3 to 11, 11 being click state )
tSpkTransHold=linspace(transHoldPre-epochTH, transHoldPre, floor(abs(epochTH)/spkWin)); %t=0 is hold state
tSpkMove=linspace(movePre, movePre+epochM, floor(abs(epochM)/spkWin)); %t=0 is when the new target appears
tSpkTransMove=linspace(transMovePre, transMovePre+epochTM, floor(abs(epochTM)/spkWin)); %t=0 is when a new target appears


%plotting the spk rates
N=36;
C=linspecer(N); 

figure
hold on
set(gca,'FontSize', 22)
H=shadedErrorBar(tGen, meanSpkHold, steSpkHold);
H.mainLine.LineWidth=4; 
H.patch.FaceColor=C(2,:);
H.patch.EdgeColor=C(1,:);
H.mainLine.Color=C(1,:);
H.edge(1).Color=C(1,:);
H.edge(2).Color=C(1,:);


H=shadedErrorBar(tGen, meanSpkMove, steSpkMove);
H.mainLine.LineWidth=4; 
H.patch.FaceColor=C(12,:);
H.patch.EdgeColor=C(13,:);
H.mainLine.Color=C(13,:);
H.edge(1).Color=C(13,:);
H.edge(2).Color=C(13,:);


%create an iti
itiD=data(5, R(1).firstCerebusTime(1,1)-(30000*3):R(1).firstCerebusTime(1,1)-15000);

[specTempHoldI] =Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(itiD, fs, downSample), 'Spectrogram', Spectrogram, 'dataClassBand', dataClassBand, 'DoBandFilterBroad', true);

itiNM=specTempHoldI.data;
tI=specTempHoldI.tplot;
fI=specTempHoldI.f;
iti=mean(specTempHoldI.data,2);
iti=repmat(iti, 1, size(Hh,2));



%compare the spectrograms
Hh=perCh.ch5.specHold;
Mm=perCh.ch5.specMove;
Th=perCh.ch5.specTransHold;
Tm=perCh.ch5.specTransMove;
HhMm=Hh-Mm;

HhTh=Hh-Th;

HhTm=Hh-Tm;

MmTh=Mm-Th;

MmTm=Mm-Tm;

ThTm=Th-Tm;

HhI=Hh-iti;
MmI=Mm-iti;
ThI=Th-iti;
TmI=Tm-iti;

f=specTempHold.f; tp=specTempHold.tplot;

figure
set(gca,'FontSize', 22)
imagesc(tp, f, HhMm); axis xy;
title('Hold - Move')
colorbar

figure
set(gca,'FontSize', 22)
imagesc(tp, f,HhTh); axis xy;
title('Hold - Transition to hold')

figure
set(gca,'FontSize', 22)
imagesc(tp, f, HhTm); axis xy;
title('Hold - Transition to move')

figure
set(gca,'FontSize', 22)
imagesc(tp, f, MmTh); axis xy;
title('Move - Transition to hold')

figure
set(gca,'FontSize', 22)
imagesc(tp, f, MmTm); axis xy;
title('Move - Transition to move')

figure
set(gca,'FontSize', 22)
imagesc(tp, f, ThTm); axis xy;
title('Transition to hold - transition to move')

figure
set(gca,'FontSize', 22)
imagesc(tp, f, HhI); axis xy;
title('Hold - iti')

figure
set(gca,'FontSize', 22)
imagesc(tp, f, MmI); axis xy;
title('Move - iti')

figure
set(gca,'FontSize', 22)
imagesc(tp, f, TmI); axis xy;
title('Transition to Move - iti')

figure
set(gca,'FontSize', 22)
imagesc(tp, f, ThI); axis xy;
title('Transition to Hold - iti')


%assess spikes
for ii=1:length(transMoveSpk)
    spkT1(:, :, ii)=transMoveSpk{ii};
    figure
    imagesc(spkT1(:,:,ii)'); 
end
for ii=1:14
    for jj=1:length(msTM.modDSpk)
        spkT1(:, jj, ii)=transMoveSpk{ii}(:, msTM.modDSpk(jj));
        
    end
    figure
    imagesc(spkT1(:,:,ii)');
end



for jj=1:length(msTM.modDSpk) %channels
    figure
    hold on
    for ii=1:14 %trials
        spkTS1(:, jj, ii)=transMoveSmooth{ii}(:, msTM.modDSpk(jj));
        plot(spkTS1(:,jj,ii));
    end
    
    
end

for jj=1:length(ChSpk)
    chstr=['ch', num2str(ChSpk(jj))];%%
    figtitle=['Band filtered data ', chstr];
    figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
    set(gca,'FontSize', 22)
    sgtitle(figtitle)
    
    lblPhase={'Move'; 'Hold'; 'Transition to Move'; 'Transition to Hold'};
    
    for rr=1:6
        idxC=1;
        
        subplot(3, 2, rr)
        
        hold on
        H1=shadedErrorBar(tBand, perCh.(chstr).meansteBandMove(rr,:), perCh.(chstr).meansteBandMove(rr+6,:));
        H1.mainLine.LineWidth=2;
        H1.patch.FaceColor=C(colorShBand(idxC),:);
        H1.patch.EdgeColor=C(colorShBand(idxC)-1,:);
        H1.mainLine.Color=C(colorShBand(idxC)-1,:);
        H1.edge(1).Color=C(colorShBand(idxC)-1,:);
        H1.edge(2).Color=C(colorShBand(idxC)-1,:);
        H1.mainLine.DisplayName=lblPhase{1};
        title(lblB{rr})
        idxC=idxC+1;
        
        H2=shadedErrorBar(tBand, perCh.(chstr).meansteBandHold(rr,:), perCh.(chstr).meansteBandHold(rr+6,:));
        H2.mainLine.LineWidth=2;
        H2.patch.FaceColor=C(colorShBand(idxC),:);
        H2.patch.EdgeColor=C(colorShBand(idxC)-1,:);
        H2.mainLine.Color=C(colorShBand(idxC)-1,:);
        H2.edge(1).Color=C(colorShBand(idxC)-1,:);
        H2.edge(2).Color=C(colorShBand(idxC)-1,:);
        H2.mainLine.DisplayName=lblPhase{2};
        
        idxC=idxC+1;
        
        
        H3=shadedErrorBar(tBand, perCh.(chstr).meansteBandTransMove(rr,:), perCh.(chstr).meansteBandTransMove(rr+6,:));
        H3.mainLine.LineWidth=2;
        H3.patch.FaceColor=C(colorShBand(idxC),:);
        H3.patch.EdgeColor=C(colorShBand(idxC)-1,:);
        H3.mainLine.Color=C(colorShBand(idxC)-1,:);
        H3.edge(1).Color=C(colorShBand(idxC)-1,:);
        H3.edge(2).Color=C(colorShBand(idxC)-1,:);
        H3.mainLine.DisplayName=lblPhase{3};
        
        idxC=idxC+1;
        
        
        H4=shadedErrorBar(tBand, perCh.(chstr).meansteBandTransHold(rr,:), perCh.(chstr).meansteBandTransHold(rr+6,:));
        H4.mainLine.LineWidth=2;
        H4.patch.FaceColor=C(colorShBand(idxC),:);
        H4.patch.EdgeColor=C(colorShBand(idxC)-1,:);
        H4.mainLine.Color=C(colorShBand(idxC)-1,:);
        H4.edge(1).Color=C(colorShBand(idxC)-1,:);
        H4.edge(2).Color=C(colorShBand(idxC)-1,:);
        H4.mainLine.DisplayName=lblPhase{4};
        
        idxC=idxC+1;
        if rr==3
            legend([H1.mainLine H2.mainLine H3.mainLine H4.mainLine],{'Move', 'Hold', 'Transition to Move', 'Transition to Hold'});
        end
    end
end

for jj=1:length(ChSpk) %run through relevant channels
    tt=tic;
    for ii=1:length(moveSpk) %run through trials
        chMoveSpk{jj}(:, ii)=moveSmooth{ii}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
        dataChTemp=moveData{ii}(:, ChSpk(jj));        
        [specTempMove, params, dataFinalCBMove, ~, dataClassBand] =Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(dataChTemp, fs, downSample), 'Spectrogram', Spectrogram, 'dataClassBand', dataClassBand, 'DoBandFilterBroad', true);
        chMoveData{jj}(:,:,ii)=specTempMove.data; %load a 3d matrix for time x freq x trial by channel for spectral data
        chMoveBandData{jj}(:,:,ii)=dataFinalCBMove; %load a 3d matrix for time x freq x trial by channel for bandpassed in classic bands
        clear dataChTemp;

        chHoldSpk{jj}(:, ii)=holdSmooth{ii}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
        dataChTemp=holdData{ii}(:, ChSpk(jj));        
        [specTempHold, params, dataFinalCBHold] =Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(dataChTemp, fs, downSample), 'Spectrogram', Spectrogram, 'dataClassBand', dataClassBand, 'DoBandFilterBroad', true);
        chHoldData{jj}(:,:,ii)=specTempHold.data; %load a 3d matrix for time x freq x trial by channel for spectral data
        chHoldBandData{jj}(:,:,ii)=dataFinalCBHold; %load a 3d matrix for time x freq x trial by channel for bandpassed in classic bands
        clear dataChTemp;

        chTransMoveSpk{jj}(:, ii)=transMoveSmooth{ii}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
        dataChTemp=transMoveData{ii}(:, ChSpk(jj));        
        [specTempTransMove, params, dataFinalCBTransMove] =Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(dataChTemp, fs, downSample), 'Spectrogram', Spectrogram, 'dataClassBand', dataClassBand, 'DoBandFilterBroad', true);
        chTransMoveData{jj}(:,:,ii)=specTempTransMove.data; %load a 3d matrix for time x freq x trial by channel for spectral data
        chTransMoveBandData{jj}(:,:,ii)=dataFinalCBTransMove; %load a 3d matrix for time x freq x trial by channel for bandpassed in classic bands
        clear dataChTemp;
        
        chTransHoldSpk{jj}(:, ii)=transHoldSmooth{ii}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
        dataChTemp=transHoldData{ii}(:, ChSpk(jj));        
        [specTempTransHold, params, dataFinalCBTransHold] =Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(dataChTemp, fs, downSample), 'Spectrogram', Spectrogram, 'dataClassBand', dataClassBand, 'DoBandFilterBroad', true);
        chTransHoldData{jj}(:,:,ii)=specTempTransHold.data; %load a 3d matrix for time x freq x trial by channel for spectral data
        chTransHoldBandData{jj}(:,:,ii)=dataFinalCBTransHold; %load a 3d matrix for time x freq x trial by channel for bandpassed in classic bands
        clear dataChTemp;
    end
    toc(tt)
    
    chstr=['ch', num2str(ChSpk(jj))];
    perCh.(chstr).meansteSpkMove(:,1)=nanmean(chMoveSpk{jj},2);
    perCh.(chstr).meansteSpkMove(:,2)=nanstd(chMoveSpk{jj}, [], 2)/sqrt(size(chMoveSpk{1},2));
    perCh.(chstr).meansteSpkTransMove(:,1)=nanmean(chTransMoveSpk{jj}, 2);
    perCh.(chstr).meansteSpkTransMove(:,2)=nanstd(chTransMoveSpk{jj}, [], 2)/sqrt(size(chTransMoveSpk{1},2));
    perCh.(chstr).meansteSpkHold(:,1)=nanmean(chHoldSpk{jj}, 2);
    perCh.(chstr).meansteSpkHold(:,2)=nanstd(chHoldSpk{jj}, [], 2)/sqrt(size(chHoldSpk{1},2));
    perCh.(chstr).meansteSpkTransHold(:,1)=nanmean(chTransHoldSpk{jj}, 2);
    perCh.(chstr).meansteSpkTransHold(:,2)=nanstd(chTransHoldSpk{jj}, [], 2)/sqrt(size(chTransHoldSpk{1},2));
    
    perCh.(chstr).meansteBandMove(1:6,:)=nanmean(chMoveBandData{jj},3);
    perCh.(chstr).meansteBandMove(7:12,:)=nanstd(chMoveBandData{jj}, [] ,3)/sqrt(size(chMoveBandData{jj},3));
    perCh.(chstr).meansteBandTransMove(1:6,:)=nanmean(chTransMoveBandData{jj},3);
    perCh.(chstr).meansteBandTransMove(7:12,:)=nanstd(chTransMoveBandData{jj}, [] ,3)/sqrt(size(chTransMoveBandData{jj},3));
    perCh.(chstr).meansteBandHold(1:6,:)=nanmean(chHoldBandData{jj},3);
    perCh.(chstr).meansteBandHold(7:12,:)=nanstd(chHoldBandData{jj},[] ,3)/sqrt(size(chHoldBandData{jj},3));
    perCh.(chstr).meansteBandTransHold(1:6,:)=nanmean(chTransHoldBandData{jj},3);
    perCh.(chstr).meansteBandTransHold(7:12,:)=nanstd(chTransHoldBandData{jj},[] ,3)/sqrt(size(chTransHoldBandData{jj},3));
    
    perCh.(chstr).specMove=nanmean(chMoveData{jj}, 3);
    perCh.(chstr).specTransMove=nanmean(chTransMoveData{jj}, 3);
    perCh.(chstr).specHold=nanmean(chHoldData{jj}, 3);
    perCh.(chstr).specTransHold=nanmean(chTransHoldData{jj}, 3);
    
    %when ready to run the clusters
    %[ mnd1, mnd2, ~, ~, sigclust, rlab ] = stats.cluster_permutation_Ttest_gpu3d( S, Sbase, 'alph', 0.00024 );

end

rState=double([R.state]);
rCP=double([R.cursorPosition]); %1 and 3 are position, 2 and 4 are velocity)
rSpk=double([R.spikeRaster]);
rFCT=double([R.firstCerebusTime]); %difference between row 1 and 2 is 6ms, lastcerebrustime is 29 and 35ms respectively for row 1/2
rMinA=double([R.minAcausSpikeBand]);
rMeanSqOther=double([R.meanSquaredAcaus]);
dtLength=300;
tempFCT=rFCT(2,1:dtLength)';
tempFCTadj=tempFCT-(30*10); %adjustment factor
tempSpk=rSpk(:,1:dtLength)*-100;
%tempSpk2=rSpk2(:,1:dtLength)*-100; 
tempSpk=tempSpk';
%tempSpk2=tempSpk2';
tempMeanSq=rMeanSqOther(1, 1:dtLength);
tempMinA=rMinA(1:96, 1:dtLength)';
tempHFO=data(tempFCT(1):tempFCT(end),:);
tempHFOadj=data(tempFCTadj(1):tempFCTadj(end),:);
tempHFOp=Analysis.BasicDataProc.dataPrep(tempHFO, 'Spectrogram', false, 'BandPassed', false, 'DoBandFilterBroad', false);
tempHFOpadj=Analysis.BasicDataProc.dataPrep(tempHFOadj, 'Spectrogram', false, 'BandPassed', false, 'DoBandFilterBroad', false);
bam1 = [0.95321773445431  -1.90644870937033 0.95323097500802 1 -1.90514144409761 0.90775595733389; ...
        0.97970016700443  -1.95938672569874 0.97968655878878 1 -1.95804317832840 0.96073029104793];
gm1 = 1;
filtD = dfilt.df2sos(bam1, gm1);
tempHFOF=filtfilthd(filtD, tempHFOp.dataBasicFilter);
tempHFOFadj=filtfilthd(filtD, tempHFOpadj.dataBasicFilter);
tempHFOFmin=Analysis.BasicDataProc.minVoltForSpike(tempHFOF);
tempHFOFminadj=Analysis.BasicDataProc.minVoltForSpike(tempHFOFadj);


tSpk=linspace(0, dtLength, dtLength);
tHFO=linspace(0, dtLength, length(tempHFOF));

figure
hold on
plot(tSpk, tempSpk(:,3), '.', 'MarkerSize', 10)
%plot(tSpk, tempSpk2(:,1), '.')
plot(tSpk, (tempMinA(:,3)-10))
plot(tSpk, tempHFOFmin(:,3))
plot(tSpk, tempHFOFminadj(:,3))

plot(tHFO, tempHFOF(:,1))
plot(tSpk, tempMeanSq(:,1))


cH=1;
trl=1;
tmp=moveSpk{trl}(:,cH)-150;
figure
plot(tSpk, tmp, '.')
hold on
plot(tHFO, moveHFO{trl}(:,cH))
plot(tSpk, moveMinA{trl}(cH,:))

% Hold=300ms before hover period is achieved (11)
% Move=300ms starting 200 ms after the target appears
% TransHold=300ms starting 200ms prior to hold state (hold is 500 ms, so it's 700ms before click state of 11) into 100 ms of hold state
% TransMove=300ms starting 100ms before the target appears (state 3)
% [varargin, holdPre] = util.argkeyval('holdPre',varargin, 0); %time before transition to 11, a state of click, hovering for 500ms, in ms
% [varargin, transHoldPre] = util.argkeyval('transHoldPre',varargin, -400); %time before transition to 11, a state of click, hovering for 500ms, in ms
% [varargin, movePre] = util.argkeyval('movePre',varargin, 200); %time after a target appears, transition to state 3
% [varargin, transMovePre] = util.argkeyval('transMovePre',varargin, -100); %time before a target appears, transition to state 3

%Spikes and movement over time.re
per=200;
perSp=per/20;
allChSpk=squeeze(mean(targetSpkAll,2));
allChSpk3=allChSpk(round(size(allChSpk,1)/2-perSp)+1:round(size(allChSpk,1)/2+perSp),:);
allTrialSpk=squeeze(mean(targetSpkAll,3));
allTrialSpk3=allTrialSpk(round(size(allChSpk,1)/2-perSp)+1:round(size(allChSpk,1)/2+perSp),:);
for ii=1:size(targetCp,3)
spd(:,ii)=sqrt(targetCp(2,:,ii).^2+targetCp(4,:,ii).^2);
end
spd3=spd(-per+1:per, :);
tmTS=linspace(-1000, 1000, size(allTrialSpk,1));
tmTS3=linspace(-per, per, size(allChSpk3,1));
trials=[1:63];
chan=[1:96];
tmTcp=linspace(-1000, 1000, size(spd,1));
tmTcp3=linspace(-per, per, size(spd3,1));

figure
set(gca,'FontSize', 22) 
sgtitle('Spike changes around target appearance')

subplot(3,1,1)
imagesc(tmTS3, trials, allChSpk3'); axis xy;
title('Smooth spiking activity across all trials')
xlabel('Time (ms)');
ylabel('Trials');
colorbar

subplot(3,1,2)
imagesc(tmTcp3, trials, spd3'); axis xy;
title('Speed changes over time')
xlabel('Time (ms)');
ylabel('Trials');
colorbar

subplot(3,1,3)
imagesc(tmTS3, chan, allTrialSpk3'); axis xy;
title('Smooth spiking activity across all channels')
xlabel('Time (ms)');
ylabel('Channels');
colorbar


lblN={'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma', 'High Gamma'};
lblP={'MaxStart', 'MaxStartCILow', 'MaxStartCIHigh', 'MaxPeak', 'MaxPeakCILow',...
    'MaxPeakCIHigh', 'MinStart', 'MinStartCILow', 'MinStartCIHigh', 'MinPeak',...
    'MinPeakCILow',    'MinPeakCIHigh'};
idxL=1;
for ii=1:length(lblB)
    for jj=1:length(lblP)
        Peaks(idxL).Runs=strcat(lblB{ii}, lblP{jj});
        idxL=idxL+1;
    end
end

figure
N=100;
C=linspecer(N);
nme=fields(Peak);
betaMin=46; spkMin=10; spkMax=4;
spt=[46; 10; 4];

idx=7; jj=2;
for ii=1:numel(spt)
    loc=spt(ii);
    pk=Peak(loc).(nme{jj});
    pkCIL=Peak(loc+1).(nme{jj});
    pkCIH=Peak(loc+2).(nme{jj});
    plot(pk, ii, 's', 'MarkerSize', 10, 'LineWidth', 4, 'Color', C(idx,:))
    hold on
    yy=pkCIL:pkCIH;
    zz=zeros(size(yy))+ii;
    plot(yy, zz, 'LineWidth', 1, 'Color', C(idx-3,:))
    idx=idx+10;
    if ii<2
        jj=jj+1;
    end
end
ax=gca;
ax.YLim([0.5 numel(spt)+0.5]);
ax.YTickLabel={'Beta Minima', 'Spike Minima', 'Spike Maxima'};
legend('Beta Min', 'Spike Min', 'Spike Max')
title('Hold Timing of maxima and minima for Beta and Spikes (CI)');

idx=16;
%spk10 11 12
spkMin=Peak(10).holdSpkAllChAllTr;
spkCIminL=Peak(11).holdSpkAllChAllTr;
spkCIminH=Peak(12).holdSpkAllChAllTr;
plot(spkMin, 0, 's', 'MarkerSize', 10, 'LineWidth', 4, 'Color', C(idx,:))
hold on
yy=spkCIminL:spkCIminH;
zz=zeros(size(yy));
plot(yy, zz, 'LineWidth', 1, 'Color', C(idx-3,:))

idx=28;
spkMax=Peak(4).holdSpkAllChAllTr;
spkCImaxL=Peak(5).holdSpkAllChAllTr;
spkCImaxH=Peak(6).holdSpkAllChAllTr;
plot(spkMax, 0, 's', 'MarkerSize', 10, 'LineWidth', 4, 'Color', C(idx,:))
hold on
yy=spkCImaxL:spkCImaxH;
zz=zeros(size(yy));
plot(yy, zz, 'LineWidth', 1, 'Color', C(idx-3,:))

figure
set(gca,'FontSize', 22)
subplot(2,1,1)
hold on
plot(spikeRaw*50, '.', 'LineWidth', 2)
plot(tm, spkRate, 'LineWidth', 2)
plot(tm, spkRateSmooth, 'LineWidth', 2)
spkSpSG=smoothdata(spkRate, 'sgolay', 20);
plot(tm, spkSpSG, 'LineWidth', 2)
spkSpGa=smoothdata(spkRate, 'gaussian', 20);
plot(tm, spkSpGa, '--', 'LineWidth', 2)
legend('raster', 'spike rate 20ms sum', 'spike rate sum smoothed w convolve 10ms win',  'spike rate sum smoothed with sgolay 20ms win',  'spike rate sum smoothed with gaus 20ms win')
ax=gca;
ax.XTick=0:100:2000;
subplot(2,1,2)
hold on
plot(spikeRaw*50, '.', 'LineWidth', 2)
plot(tm, spkRate, 'LineWidth', 2)
plot(tm, spkRateSmooth, 'LineWidth', 2)
spkSmSG=smoothdata(spkRateSmooth, 'sgolay', 20);
plot(tm, spkSmSG, 'LineWidth', 2);
spkSmGa=smoothdata(spkRateSmooth, 'gaussian', 20);
plot(tm, spkSmGa, '--', 'LineWidth', 2)
legend('raster', 'spike rate 20ms sum', 'smoothed w convolve 10ms win',  'spike smooth smoothed again with sgolay 20ms win', 'spike smooth smoothed again with gaus 20ms win');
ax=gca;
ax.XTick=0:100:2000;


%%
%to look at the PCA of beta (or whatever) vs spikes per trial, for a glance
movePCA=moveOutPCA;
N=100;
C=linspecer(N);
tSpk=linspace(1, 500, size(movePCA(1).spikeSmooth,1));
tB=linspace(1, 500, size(movePCA(1).Beta,1));
fN=fields(movePCA);
figure
idxT=1;
for ii=0:6:12
    hold on
    
    idx=1;
    for jj=1:3
        bnd=movePCA(idxT).Beta(:,1:5); %trial
        spk=movePCA(idxT).spikeSmooth(:,1:5);
        subplot(6, 3, jj+ii)
        title('trial', num2str(idxT));
        for rr=1:2 %pcas, plot a single trial with rr pcs
            hold on
            plot(tSpk, spk(:,rr), 'Color', C(idx, :), 'LineWidth', 2)
            idx=idx+4;
        end
        idx=1;
        subplot(6, 3, jj+ii+3)
        title('trial', num2str(idxT));
        for rr=1:2            
            hold on
            plot(tB, bnd(:,rr), 'Color', C(idx+80, :), 'LineWidth', 2)
            idx=idx+4;
        end
        idxT=idxT+1;
        if idxT>(size(movePCA,2))
            break
        end
    end
end

%plot trial mean
%%
idxF=[5,6,9,10,13,14,17,18]; 
N=100;
C=linspecer(N);
tSpk=linspace(1, 500, size(movePCA(1).spikeSmooth,1));
tB=linspace(1, 500, size(movePCA(1).Beta,1));
fN=fields(movePCA);

figure
set(gca,'FontSize', 22)
idxC=4;
idxP=1;
pcaN=2; %number of PCs to plot, gets crowded with too many
for ii=1:2:8
    subplot(3,2,idxP);
    hold on
    for jj=1:pcaN
        
        H=shadedErrorBar(tB, movePCA(1).(fN{idxF(ii)})(:,jj), movePCA(1).(fN{idxF(ii+1)})(:,jj));
        H.mainLine.LineWidth=4;
        H.patch.FaceColor=C(idxC,:);
        H.patch.EdgeColor=C(idxC-3,:);
        H.mainLine.Color=C(idxC-3,:);
        H.edge(1).Color=C(idxC-3,:);
        H.edge(2).Color=C(idxC-3,:);
        idxC=idxC+5;
    end
    title(fN{idxF(ii)}(1:end-4))
    idxP=idxP+1;
    idxC=4;
    
    if ii==5
        xlabel('Time (ms)');
        ylabel('Arbitrary units');
    end
end
%spike means
subplot(3,2,5)
hold on
title('Smoothed Spikes');
for jj=1:pcaN
    H=shadedErrorBar(tSpk,  movePCA(1).(fN{19})(:,jj), movePCA(1).(fN{20})(:,jj)); 
    H.mainLine.LineWidth=4;
    H.patch.FaceColor=C(idxC,:);
    H.patch.EdgeColor=C(idxC-3,:);
    H.mainLine.Color=C(idxC-3,:);
    H.edge(1).Color=C(idxC-3,:);
    H.edge(2).Color=C(idxC-3,:);
    idxC=idxC+5;
end
    
 %%
 %normalize
 for ii=1:length(bychEndPointSpk)
     meanSpk(:,ii)=mean(bychEndPointSpk{ii},2); %mean across trials
 end
 [maxSpkTemp, maxSpkId]=max(meanSpk);
 normSpk=meanSpk./maxSpkTemp; %should normalize

 [~,I]=sort(maxSpkId);
 normSpkT=normSpk(:,[I]);
 
 chNum=[1:length(bychEndPointSpk)];
 figure
 imagesc(tSpkEndPoint, normSpkT'); axis xy;

 
 for jj=1:8
     for ii=1:96
     bychAllEndPointSpk{ii}(:, jj)=endPointSmooth{jj}(:, ii); 
     end
 end
    
 for ii=1:length(bychAllEndPointSpk)
     meanSpk(:,ii)=mean(bychAllEndPointSpk{ii},2); %mean across trials
 end
 [maxSpkTemp, maxSpkId]=max(meanSpk);
 normSpk=meanSpk./maxSpkTemp; %should normalize

 [~,I]=sort(maxSpkId);
 normSpkT=normSpk(:,[I]);
 
 chNum=[1:length(bychAllEndPointSpk)];
 figure
 imagesc(tSpkEndPoint, chNum , normSpkT'); axis xy;
    
 
 %% WORKING ON FINDING THE PEAK FREQUENCIES
 
 
 
 [a, b]=proc.basic.zScore(yy, 'z-score', 2); %get the z score mean and std
 zz=(yy-a)./b;
            
            
 test=zeros(size(r_pvalue));
 for ii=1:size(cl_keep,2)
     test(rw(ii), col(ii))=1;
 end
 
figure
imagesc(tt, ff, test);



