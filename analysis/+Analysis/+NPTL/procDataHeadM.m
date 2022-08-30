function [dataHoldMove] = procDataHeadM(R, ns5File, varargin)
%procDataHeadM Process the BCI data to break it up into times when it is
%hovering and when it isnt for the center out (GT) task.
%  R details - each row is a ms
% Input
%     R - R struct file, 
%     ns5File - the name of the file path for the file you want
%     
% Output
%     dataHoldMove - has 6 outputs
%%TIMES
% Remember: currently epoch is 300ms
% Hold=300ms before hover period is achieved (11)
% Move=300ms starting 200 ms after the target appears
% TransHold=300ms starting 200ms prior to hold state (hold is 500 ms, so it's 700ms before click state of 11) into 100 ms of hold state
% TransMove=300ms starting 100ms before the target appears (state 3)
%%
% TO DO:
%    
% 
%     Example:
% Open task and run with dataProc done for whole trial, so doesn't take forever
%
% 
% BASICdataProc.m
% Also run the data open and load the data file in, or that takes forever
%
% OR
%
% %Task open
% ns5file='C:\Users\kramdani\Dropbox\My PC (Cerebro2)\Documents\Data\t5.2019.03.18_HeadMoveData\Data\NS5_block10Head\10_cursorTask_Complete_t5_bld(010).ns5';
% %should be lateral grid
% load('C:\Users\kramdani\Dropbox\My PC (Cerebro2)\Documents\Data\t5.2019.03.18_HeadMoveData\Data\R_structs\R_block_10.mat')
% R=R(1:64);
%         
%         [dataHoldMove]=Analysis.NPTL.procDataHeadM(R, ns5file, 'Spectrogram', true);
%
% Blackrock gridlayout
%   NaN     2     1     3     4     6     8    10    14   NaN
%     65    66    33    34     7     9    11    12    16    18
%     67    68    35    36     5    17    13    23    20    22
%     69    70    37    38    48    15    19    25    27    24
%     71    72    39    40    42    50    54    21    29    26
%     73    74    41    43    44    46    52    62    31    28
%     75    76    45    47    51    56    58    60    64    30
%     77    78    82    49    53    55    57    59    61    32
%     79    80    84    86    87    89    91    94    63    95
%    NaN    81    83    85    88    90    92    93    96   NaN

% THINGS TO DO FOR PROCESSING: FIRST PASS. SO MAIN THING TO DO IS TO PLOT THEM ALL
%     RUN A CORRELATION AT THE DIFFERENT ELECTRODES ACROSS THE GRID
%         MAKE SURE TO OUTPUT THAT RAW DATA TO RUN IT BETWEEN THE GRIDS AS WELL
%     LOOK AT THE CHANGES IN EACH BAND DURING CHANGES IN FIRING RATE.
[varargin, data] = util.argkeyval('data',varargin, []); %check if the data has already been extracted    
[varargin, dProc] = util.argkeyval('dProc',varargin, []); %check if the data has already processed, which you can do with BASICdataProc.m

[varargin, fs] = util.argkeyval('fs',varargin, 30000); %original sample rate
[varargin, downSample] = util.argkeyval('downSample',varargin, 2000); %the new downsample rate

[varargin, epoch] = util.argkeyval('epoch',varargin, 500); %the epoch for all times, in ms
[varargin, spkWin] = util.argkeyval('spkWin',varargin, 20); %the window to average spikes over, in ms
%These are the times to take around the events (state==5, click state,
%state==4 hover state (300ms), state==3 move state; state==2 target
%appears, state==1 new trial.
%trial = 1 to 3, to center on the out target, goes 5 to 1 to 3 quickly, so 1 to 3 is best place to center, either side for the whole trial, should include all transitions
%
%holdPre = 4 to 5, hold to acquire, holdPre amount before that transition (then minus the epoch)
%
%transHold = 3 to 4, move to hold, transition to hold, transHold before (then plus the epoch)
%
%movePost = 2 to 3 and 1 to 3, moving to target, movePost after that (then plus the epoch)
%
%transMove = 4 to 5 (since other is prep to move), includes just hold to move transition, transMove after that (then plus epoch)
%
%prep = 1 to 2, target appears, prep before or after that (then plus the epoch) 
%
%prepMove= 2 to 3, go cue appears, prepMove before, (then plus epoch)

[varargin, trial] = util.argkeyval('trial',varargin, 1000); %trial on either side
[varargin, holdPre] = util.argkeyval('holdPre',varargin, 0); %holdPre (then minus the epoch)
[varargin, transHold] = util.argkeyval('transHold',varargin, -100); %transHold before the Hold starts (then plus epoch)
[varargin, movePost] = util.argkeyval('movePost',varargin, 200); %time after a target appears (then plus epoch)
[varargin, transMove] = util.argkeyval('transMove',varargin, 0); %time before a target appears, transition to state 3
[varargin, prep] = util.argkeyval('prep',varargin, 100); %time before a target appears (then plus epoch)
[varargin, prepMove] = util.argkeyval('prepMove',varargin, -100); %time before a target appears (then plus epoch)

[varargin, bufferT] = util.argkeyval('bufferT',varargin, 300); %the buffer window in ms to process data around your desired time of interest (so will take bufferT s before and bufferT after the epoch). This is to allow sufficient ramp up and plotting before and after
[varargin, channel] = util.argkeyval('channel',varargin, [1 96]); %which channels you want, default is whole grid
[varargin, trialNum] = util.argkeyval('channel',varargin, [1, size(R,2)]); %which trials you want, default is all.
[varargin, perc] = util.argkeyval('channel',varargin, 95); %what percentile of the most active channels you want. THIS LIMITS HOW MANY CHANNELS ARE INCLUDED, HIGHER PERCENTILE MEANS LESS CHANNELS ARE DISPLAYED
[varargin, grid] = util.argkeyval('grid', varargin, 1); %0= both, 1 = lateral, 2 = medial

[varargin, Spectrogram] = util.argkeyval('Spectrogram',varargin, true); %if doing Spectrogram or not
[varargin, classicBand]= util.argkeyval('classicBand', varargin, [1 4; 4 8; 8 13; 13 30; 30 50; 50 200]);

[varargin, plotData] = util.argkeyval('plotData',varargin, true); %amount to plot before the epoch.  Will error if longer than the bufferT.  Only applies to the spectrogram and bandpassed dataolmk,
[varargin, plotPre] = util.argkeyval('plotPre',varargin, 100); %amount to plot before the epoch.  Will error if longer than the bufferT.  Only applies to the spectrogram and bandpassed dataolmk,
[varargin, plotPost] = util.argkeyval('plotPost',varargin, 400); %amount to plot after the epoch.

%% PREP ACTIVITY
%convert R to a struct PROBABLY THIS TO UNWIELDY AND WILL NEED TO BREAK
%R UP
if ~isa(R, 'struct')
    R=[R{:}];
end

%% OPEN DATA
%convert to readable for the channels
ch=['c:0', num2str(channel(1,1)), ':', num2str(channel(1,2))];
if isempty(data)
    ns5=openNSx('read', ns5File, ch); %Open the file
    data=double(ns5.Data{end})';
end

%make sure data is columns=channels and rows are time
if size(data, 1)<size(data,2)
    data=data';
end

%gridlayout per idx to channel FOR NOW, ONLY ADJUSTING THE CHANNELS IN
%CORRELATION, EASIER TO KEEP TRACK OF WHICH CHANNEL IS WHICH
idxch2el=[78,88,68,58,56,48,57,38,47,28,37,27,36,18,45,17,46,8,35,16,24,7,26,6,25,5,15,4,14,3,13,2,77,67,76,66,75,65,74,64,73,54,63,53,72,43,62,55,61,44,52,33,51,34,41,42,31,32,21,22,11,23,10,12,96,87,95,86,94,85,93,84,92,83,91,82,90,81,89,80,79,71,69,70,59,60,50,49,40,39,30,29,19,20,1,9];


lblN={'DeltaOrSpike', 'Theta', 'Alpha', 'Beta', 'Gamma', 'HighGamma'};
lblP={'MaxStart', 'MaxStartCILow', 'MaxStartCIHigh', 'MaxPeak', 'MaxPeakCILow',...
    'MaxPeakCIHigh', 'MinStart', 'MinStartCILow', 'MinStartCIHigh', 'MinPeak',...
    'MinPeakCILow',    'MinPeakCIHigh'};
idxL=1;
for ii=1:length(lblN)
    for jj=1:length(lblP)
        Peak(idxL).Runs___________=strcat(lblN{ii}, lblP{jj});
        idxL=idxL+1;
    end
end


%create an iti, idle time is 3 seconds prior to start, end .5 seconds early
%to prevent anticipation
%THE TRIAL IS NOT ALWAYS THE FIRST ONE IF IT'S .isSuccessful ONLY, THIS IS
%A WORK AROUND
meanTrialTime=floor(mean(double([R.trialLength])));
firstTrial=double(R(1).trialNum);
preTrialTime=meanTrialTime*firstTrial*30; %subtract this to get to around the beginning, add another second to be sure, multiply by 30 fs
itiD=data(double(R(1).firstCerebusTime(1,1))-(30000*3)-300-preTrialTime:double(R(1).firstCerebusTime(1,1))-300-preTrialTime, :);%also subtract the 10ms offset, or 300 samples


dataClassBand=[];
[specTempHoldI, ~,~,~, dataClassBand]=Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(itiD, fs, downSample), 'Spectrogram', Spectrogram, 'doBandFilterBroad', true, 'itiProc', true, 'classicBand', classicBand);
if isempty(dataClassBand)
    for ii=3:length(lblN)
        dataClassBand.(lblN{ii})=[];
    end
end

lblB=fields(dataClassBand);%for naming things later

tI=specTempHoldI.dataSpec.tplot;
fI=specTempHoldI.dataSpec.f;


%Spike times to set up for plotting
tSpkHold=linspace(holdPre-epoch, 0, floor(abs(epoch)/spkWin)); %t=0 is state 11 starting, prior to click to click (state 3 to 11, 11 being click state )
tSpkTransHold=linspace(transHold-epoch, transHold, floor(abs(epoch)/spkWin)); %t=0 is hold state
tSpkMove=linspace(movePost, movePost+epoch, floor(abs(epoch)/spkWin)); %t=0 is when the new target appears
tSpkTransMove=linspace(transMove, transMove+epoch, floor(abs(epoch)/spkWin)); %t=0 is when a new target appears
tSpkEndPoint=linspace(-epoch, epoch, floor(abs(epoch)/spkWin)+1);
tGen=linspace(0, epoch, floor(abs(epoch)/spkWin)); %generic 300ms for easy comparison of epochs

%% gather the data up
holdData=[]; moveData=[];

idx1=2; trl=1; fl=1;
rState=double([R.state]);
rCP=double([R.cursorPosition]); %1 and 3 are position, 2 and 4 are velocity for grid task, and it's derivative of cp in grid task or row 1:2 of xp
rFCT=double([R.firstCerebusTime])+10*30; %There is a 10ms offset from ns5 and firstCerebusTime, unknown why, but verified. difference between row 1 and 2 is 6ms, lastcerebrustime is 29 and 35ms respectively for row 1/2
rMinA=double([R.minAcausSpikeBand]);
if isempty(cell2mat(strfind(fields(R), 'spikeRaster')))
    threshMultiplier = -4.5;
    RMSvals = channelRMS( R );
    thresholds = RMSvals.*threshMultiplier;
    thresholds = thresholds'; % make column vector
    for iTrial = 1 : numel( R )
        R(iTrial).spikeRaster = R(iTrial).minAcausSpikeBand < repmat( thresholds, 1, size( R(iTrial).minAcausSpikeBand, 2 ) );
    end
end
if ~isempty(cell2mat(strfind(fields(R), 'spikeRaster2')))
    rSpkAll(1:96,:)=double([R.spikeRaster]);
    rSpkAll(97:192,:)=double([R.spikeRaster2]);
else
    rSpkAll=double([R.spikeRaster]);
end
%choose your grid to evaluate, depends on the ns5. 
if grid==1
    rSpk=rSpkAll(1:96,:);
    rMinA=rMinA(1:96,:);
elseif grid==2
    rSpk=rSpkAll(971:192, :);
    rMinA=rMinA(97:192,:);
else
    rSpk=rSpkAll(1:192, :);
    rMinA=rMinA(1:192,:);
end



%% spikes, all channels
%smooth the spikes
[spk, spkRate, spkRateSmooth, tm] = Analysis.BasicDataProc.spikeRate(rSpk, 'win', spkWin);
% Outputs:l,
%         spk-  converts raster to NaNs and 1s for plotting
%         spkRate- spikes summed over a window
%         spkRateSmooth- smoothed spikes with convolve
%         tm- a time vector for plotting to match spikes
spikeCh.spk=spk; %flip them all to match the lfp data, so columns are channels
spikeCh.spkRate=spkRate;
spikeCh.spkRateSmooth=spkRateSmooth;
spikeCh.tm=tm;

%% find active channels and get rid of noisey channels

[msM] = Analysis.BasicDataProc.activeSpkCh(spkRateSmooth, 'perc', 60);

% find the channels most active, then choose between highest spike rates
% (mean) or highest variability (std), or the modulation (highest to
% lowest)

%[msM] = Analysis.BasicDataProc.activeSpkCh(moveSmooth, 'perc', perc);
%which one to pick to look at the channels
spikeCh.meanstdSpkPerc=msM;
%choose the modDSPk, can also choose mean and ste changes, but likely will
%pick up noisey channels
ChSpk=msM.modDSpk;

%% prep all the data.

preTrialSt=2; %start 2 seconds before the trial
preTrialEnd=2; %start 2 seconds after the trial
trialSt=rFCT(1)-fs*preTrialSt;
trialEnd=rFCT(end)+fs*preTrialEnd;
if isempty(dProc)
    dataTrials=data(trialSt:trialEnd,:);
    tT=tic;
    [DataAll, params, CBPowerAll]=Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(dataTrials, fs, downSample), 'Spectrogram', Spectrogram, 'dataClassBand', dataClassBand, 'doBandFilterBroad', true);
    toc(tT)
else
    DataAll=dProc.DataAllTemp;
    lblTemp=fields(dProc.DataAllTemp.ClassicBand.Power);
    for ii=1:length(lblTemp)
        CBPowerAll(:,ii,:)=dProc.DataAllTemp.ClassicBand.Power.(lblTemp{ii});
        CBAngleAll(:,ii,:)=dProc.DataAllTemp.ClassicBand.Angle.(lblTemp{ii});
    end
end

 %%   
    %THERE IS A 275 MS DIFF BETWEEN SPECT AND BAND FILTERED TIME, NEED TO
    %SORT THROUGH IT. CHECKED AGAIN ON 9/2/20 AND IT'S 102.5
    %currently tcB each bin is .5ms and tSpec bins are 5ms (with current spec
%settings and CB settings
%%
%specT=DataAll.dataSpec.tplot; %timing for spectrogram
specT=DataAll.dataSpec.tplot; %timing for spectrogram
tSpec=specT*1000-preTrialSt*1000; %convert to ms and move the timing to match that in the R based on how much before trial one has been taken
classBandT=DataAll.ClassicBand.t; %timing for bandfiltered data
tcB=classBandT*1000-preTrialSt*1000; %convert to ms and move the timing to match that in the R based on how much before trial one has been taken


%conversion of tSpec for the different times needed. 
tSpecEpoch=epoch+bufferT*2; %for spectrograms, including the buffer
tSpecDiff=tSpec(2)-tSpec(1);
tSpecEpoch=round(tSpecEpoch/tSpecDiff);%this is checked, so if epoch is 500 ms +buffer of 300ms on either end, it's 5ms per bin, it's 220 bins (*5ms a bin, is 1100ms)
tCbEpoch=epoch;
tCbDiff=tcB(2)-tcB(1);
tCbEpoch=round(tCbEpoch/tCbDiff); %this is checked, so if epoch is 500 ms, it's 0.5ms per bin, and 1000 bins 
tMEpoch=epoch;
tMDiff=tm(2)-tm(1);
tMEpoch=round(tMEpoch/tMDiff);
%%

%get the states hovering
idxTr=1; idxH=1; idxTH=1; idxMO=1; idxTM=1; idxPr=1; idxPM=1; idxTHe=1; idxCheck=1;
for ii=500:length(rState)-trial %start 500ms in, should be all garbage but some weird number things and end before length of trial
    
    %% Get the whole trial
    if rState(ii)==3 && rState(ii-1)==2 && rState(ii-2)==1 %3 is move, 2 is target but is 1 ms, and 1 is trial start
        rTrialEnd(idxTr,1)=ii;
        TrialCP{idxTr}=rCP(:,ii-trial:ii+trial);
        TrialSpk{idxTr}=spk(ii-trial:ii+trial, :); %take all the channels at once
        TrialFCT(idxTr, :)=rFCT(1,ii);
        tempSt=find(tSpec>=ii-trial); tempEnd=tempSt(1)+(trial*2)/tSpecDiff;
        TrialDataSpAllCh{idxTr}=DataAll.dataSpec.data(:, tempSt(1):tempEnd(1), :);
        TrialDataSpAll(:, :, :, idxTr)=DataAll.dataSpec.data(:, tempSt(1):tempEnd(1), :); %4d freq x time x ch x trials.

        tempSt=find(tcB>=ii-trial); tempEnd=round(tempSt(1)+(trial*2)/tCbDiff);
        TrialCBAll{idxTr}=CBPowerAll(tempSt(1):tempEnd(end), :, :);
        TrialDataUnFilt(:, :, idxTr)=DataAll.dataBasicFilter(tempSt(1):tempEnd(1), :); %data by channels by trial, this if for finding spec peaks
        %TrialData{idxTr}=data(TrialFCT(idxTr, 1)+((holdPre-epoch-bufferT)*30):TrialFCT(idxTr, end)+((bufferT)*30),:); %add the buffer for processing and plotting
        tempSt=find(tm>=ii-trial); tempEnd=round(tempSt(1)+(trial*2)/tMDiff); 
        TrialSmooth{idxTr}=spkRateSmooth(tempSt(1):tempEnd(end),:); 
        %get spikes averaged across the channels, for each trial
        tempSt=[]; tempEnd=[];
        TrialDataSpChMean(:,:,idxTr)=nanmean((TrialDataSpAllCh{idxTr}),3); %mean across all channels
        TrialBandDataChMean(:,:,idxTr)=nanmean(TrialCBAll{idxTr},3); %mean across all channels
        TrialSmoothChMean(:,idxTr)=nanmean(TrialSmooth{idxTr},2);   %mean across all channels
        %%find maxima and minima of the spikes and band data for each trial,
        %%this is too compare within each trial.
        TrialBandPeaksChMean(:,:,idxTr)=Analysis.BasicDataProc.specChange(TrialBandDataChMean(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,idxTr)); %remove the buffered ends for this analysis.
        TrialSpkPeaksChMean(:,idxTr)=Analysis.BasicDataProc.specChange(TrialSmoothChMean(:,idxTr));
        for jj=1:length(ChSpk)
            bychTrialSpk{jj}(:, idxTr)=TrialSmooth{idxTr}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
            bychTrialData{jj}(:,:,idxTr)=TrialDataSpAllCh{idxTr}(:,:,ChSpk(jj)); %load a 3d matrix for time x freq x trial by channel for spectral data
            bychTrialBandData{jj}(:,:,idxTr)=TrialCBAll{idxTr}(:,:,ChSpk(jj));
        end
        
        idxTr=idxTr+1;
    end
    %% Hold state after moving
    %holdPre = 4 to 5, hold to acquire, holdPre amount before that transition (then minus the epoch)
    if rState(ii)==5 && rState(ii-1)==4 %5 is the click state, 4 is the hover state
        rHoldEnd(idxH,1)=ii;
        holdCP{idxH}=rCP(:,ii+holdPre-epoch:ii);
        holdSpk{idxH}=spk(ii+holdPre-epoch:ii, :); %take all the channels at once
        holdFCT(idxH, :)=rFCT(1,ii);
        tempSt=find(tSpec>=ii+holdPre-epoch-bufferT); tempEnd=tempSt(1)+tSpecEpoch;
        holdDataSpAllCh{idxH}=DataAll.dataSpec.data(:, tempSt(1):tempEnd(1), :);
        tempSt=find(tcB>=ii+holdPre-epoch); tempEnd=tempSt(1)+tCbEpoch;
        holdCBAll{idxH}=CBPowerAll(tempSt(1):tempEnd(end), :, :);
        %holdData{idxH}=data(holdFCT(idxH, 1)+((holdPre-epoch-bufferT)*30):holdFCT(idxH, end)+((bufferT)*30),:); %add the buffer for processing and plotting
        
        tempSt=find(tm>=ii+holdPre-epoch); tempEnd=tempSt(1)+tMEpoch;
        holdSmooth{idxH}=spkRateSmooth(tempSt(1):tempEnd(end),:);
        %get spikes averaged across the channels, for each trial
        tempSt=[]; tempEnd=[];
        holdDataSpChMean(:,:,idxH)=nanmean((holdDataSpAllCh{idxH}),3); %mean across all channels
        holdBandDataChMean(:,:,idxH)=nanmean(holdCBAll{idxH},3); %mean across all channels
        holdSmoothChMean(:,idxH)=nanmean(holdSmooth{idxH},2);   %mean across all channels
        %%find maxima and minima of the spikes and band data for each trial,
        %%this is too compare within each trial.
        holdBandPeaksChMean(:,:,idxH)=Analysis.BasicDataProc.specChange(holdBandDataChMean(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,idxH)); %remove the buffered ends for this analysis.
        holdSpkPeaksChMean(:,idxH)=Analysis.BasicDataProc.specChange(holdSmoothChMean(:,idxH));
        for jj=1:length(ChSpk)
            bychHoldSpk{jj}(:, idxH)=holdSmooth{idxH}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
            bychHoldData{jj}(:,:,idxH)=holdDataSpAllCh{idxH}(:,:,ChSpk(jj)); %load a 3d matrix for time x freq x trial by channel for spectral data
            bychHoldBandData{jj}(:,:,idxH)=holdCBAll{idxH}(:,:,ChSpk(jj));
        end
        
        idxH=idxH+1;
        
        
        %also get the transition to move
        rTransMoveEnd(idxTM,1)=ii;
        transMoveCP{idxTM}=rCP(:,ii+transMove:ii+transMove+epoch);
        transMoveSpk{idxTM}=spk(ii+transMove:ii+transMove+epoch, :); %take all the channels at once
        transMoveFCT(idxTM, :)=rFCT(1,ii);
        tempSt=find(tSpec>=ii+transMove-bufferT); tempEnd=tempSt(1)+tSpecEpoch;
        transMoveDataSpAllCh{idxTM}=DataAll.dataSpec.data(:, tempSt(1):tempEnd(end), :);
        tempSt=find(tcB>=ii+transMove); tempEnd=tempSt(1)+tCbEpoch;
        transMoveCBAll{idxTM}=CBPowerAll(tempSt(1):tempEnd(end), :, :);
        %transMoveData{idxTM}=data(transMoveFCT(idxTM, 1)+((transMovePre-epoch-bufferT)*30):transMoveFCT(idxTM, end)+((bufferT)*30),:); %add the buffer for processing and plotting
        tempSt=find(tm>=ii+transMove); tempEnd=tempSt(1)+tMEpoch;
        transMoveSmooth{idxTM}=spkRateSmooth(tempSt(1):tempEnd(end),:);
        %get spikes averaged across the channels, for each trial
        tempSt=[]; tempEnd=[];
        transMoveDataSpChMean(:,:,idxTM)=nanmean((transMoveDataSpAllCh{idxTM}),3); %mean across all channels
        transMoveBandDataChMean(:,:,idxTM)=nanmean(transMoveCBAll{idxTM},3); %mean across all channels
        transMoveSmoothChMean(:,idxTM)=nanmean(transMoveSmooth{idxTM},2);   %mean across all channels
        %%find maxima and minima of the spikes and band data for each trial,
        %%this is too compare within each trial.
        transMoveBandPeaksChMean(:,:,idxTM)=Analysis.BasicDataProc.specChange(transMoveBandDataChMean(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,idxTM)); %remove the buffered ends for this analysis.
        transMoveSpkPeaksChMean(:,idxTM)=Analysis.BasicDataProc.specChange(transMoveSmoothChMean(:,idxTM));
        for jj=1:length(ChSpk)
            bychTransMoveSpk{jj}(:, idxTM)=transMoveSmooth{idxTM}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
            bychTransMoveData{jj}(:,:,idxTM)=transMoveDataSpAllCh{idxTM}(:,:,ChSpk(jj)); %load a 3d matrix for time x freq x trial by channel for spectral data
            bychTransMoveBandData{jj}(:,:,idxTM)=transMoveCBAll{idxTM}(:,:,ChSpk(jj));
        end
        
        idxTM=idxTM+1;
        
        %% Move state after go cue
        %movePost = 2 to 3 and 1 to 3, moving to target, movePost after that (then plus the epoch)
    elseif rState(ii)==3 && rState(ii-1)==2  %3 is move, 2 is when the target first appears 
        rMoveOutEnd(idxMO,1)=ii;
        moveOutCP{idxMO}=rCP(:,ii+movePost:ii+movePost+epoch);
        moveOutSpk{idxMO}=spk(ii+movePost:ii+movePost+epoch, :); %take all the channels at once
        moveOutFCT(idxMO, :)=rFCT(1,ii);
        tempSt=find(tSpec>=ii+movePost-bufferT); tempEnd=tempSt(1)+tSpecEpoch;
        moveOutDataSpAllCh{idxMO}=DataAll.dataSpec.data(:, tempSt(1):tempEnd(end), :);
        tempSt=find(tcB>=ii+movePost); tempEnd=tempSt(1)+tCbEpoch;
        moveOutCBAll{idxMO}=CBPowerAll(tempSt(1):tempEnd(end), :, :);
        %moveOutData{idxMO}=data(moveOutFCT(idxMO, 1)+((moveOutPre-epoch-bufferT)*30):moveOutFCT(idxMO, end)+((bufferT)*30),:); %add the buffer for processing and plotting
        tempSt=find(tm>=ii+movePost); tempEnd=tempSt(1)+tMEpoch;
        moveOutSmooth{idxMO}=spkRateSmooth(tempSt(1):tempEnd(end),:);
        %get spikes averaged across the channels, for each trial
        tempSt=[]; tempEnd=[];
        moveOutDataSpChMean(:,:,idxMO)=nanmean((moveOutDataSpAllCh{idxMO}),3); %mean across all channels
        moveOutBandDataChMean(:,:,idxMO)=nanmean(moveOutCBAll{idxMO},3); %mean across all channels
        moveOutSmoothChMean(:,idxMO)=nanmean(moveOutSmooth{idxMO},2);   %mean across all channels
        %%find maxima and minima of the spikes and band data for each trial,
        %%this is too compare within each trial.
        moveOutBandPeaksChMean(:,:,idxMO)=Analysis.BasicDataProc.specChange(moveOutBandDataChMean(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,idxMO)); %remove the buffered ends for this analysis.
        moveOutSpkPeaksChMean(:,idxMO)=Analysis.BasicDataProc.specChange(moveOutSmoothChMean(:,idxMO));
        for jj=1:length(ChSpk)
            bychMoveOutSpk{jj}(:, idxMO)=moveOutSmooth{idxMO}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
            bychMoveOutData{jj}(:,:,idxMO)=moveOutDataSpAllCh{idxMO}(:,:,ChSpk(jj)); %load a 3d matrix for time x freq x trial by channel for spectral data
            bychMoveOutBandData{jj}(:,:,idxMO)=moveOutCBAll{idxMO}(:,:,ChSpk(jj));
        end
        
        idxMO=idxMO+1;
        
        %%  Prep to move transition state
        rprepMoveEnd(idxPM,1)=ii;
        prepMoveCP{idxPM}=rCP(:,ii+prepMove:ii+prepMove+epoch);
        prepMoveSpk{idxPM}=spk(ii+prepMove:ii+prepMove+epoch, :); %take all the channels at once
        prepMoveFCT(idxPM, :)=rFCT(1,ii);
        tempSt=find(tSpec>=ii+prepMove-bufferT); tempEnd=tempSt(1)+tSpecEpoch;
        prepMoveDataSpAllCh{idxPM}=DataAll.dataSpec.data(:, tempSt(1):tempEnd(end), :);
        tempSt=find(tcB>=ii+prepMove); tempEnd=tempSt(1)+tCbEpoch;
        prepMoveCBAll{idxPM}=CBPowerAll(tempSt(1):tempEnd(end), :, :);
        %prepMoveData{idxPM}=data(prepMoveFCT(idxPM, 1)+((prepMovePre-epoch-bufferT)*30):prepMoveFCT(idxPM, end)+((bufferT)*30),:); %add the buffer for processing and plotting
        tempSt=find(tm>=ii+prepMove); tempEnd=tempSt(1)+tMEpoch;
        prepMoveSmooth{idxPM}=spkRateSmooth(tempSt(1):tempEnd(end),:);
        %get spikes averaged across the channels, for each trial
        tempSt=[]; tempEnd=[];
        prepMoveDataSpChMean(:,:,idxPM)=nanmean((prepMoveDataSpAllCh{idxPM}),3); %mean across all channels
        prepMoveBandDataChMean(:,:,idxPM)=nanmean(prepMoveCBAll{idxPM},3); %mean across all channels
        prepMoveSmoothChMean(:,idxPM)=nanmean(prepMoveSmooth{idxPM},2);   %mean across all channels
        %%find maxima and minima of the spikes and band data for each trial,
        %%this is too compare within each trial.
        prepMoveBandPeaksChMean(:,:,idxPM)=Analysis.BasicDataProc.specChange(prepMoveBandDataChMean(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,idxPM)); %remove the buffered ends for this analysis.
        prepMoveSpkPeaksChMean(:,idxPM)=Analysis.BasicDataProc.specChange(prepMoveSmoothChMean(:,idxPM));
        for jj=1:length(ChSpk)
            bychPrepMoveSpk{jj}(:, idxPM)=prepMoveSmooth{idxPM}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
            bychPrepMoveData{jj}(:,:,idxPM)=prepMoveDataSpAllCh{idxPM}(:,:,ChSpk(jj)); %load a 3d matrix for time x freq x trial by channel for spectral data
            bychPrepMoveBandData{jj}(:,:,idxPM)=prepMoveCBAll{idxPM}(:,:,ChSpk(jj));
        end
        
        idxPM=idxPM+1;

        %%Transition to hold state
        %this will capture all hold states that are succesful
    elseif rState(ii)==4 && rState(ii-1)==3 && sum(rState(ii:ii+transHold+epoch)==5)>0%3 is move, 4 is hover
        rTransHoldEnd(idxTH,1)=ii;
        transHoldCP{idxTH}=rCP(:,ii+transHold:ii+transHold+epoch);
        transHoldSpk{idxTH}=spk(ii+transHold:ii+transHold+epoch, :); %take all the channels at once
        transHoldFCT(idxTH, :)=rFCT(1,ii);
        tempSt=find(tSpec>=ii+transHold-bufferT); tempEnd=tempSt(1)+tSpecEpoch;
        transHoldDataSpAllCh{idxTH}=DataAll.dataSpec.data(:, tempSt(1):tempEnd(end), :);
        tempSt=find(tcB>=ii+transHold); tempEnd=tempSt(1)+tCbEpoch;
        transHoldCBAll{idxTH}=CBPowerAll(tempSt(1):tempEnd(end), :, :);
        %transHoldData{idxTH}=data(transHoldFCT(idxTH, 1)+((transHoldPre-epoch-bufferT)*30):transHoldFCT(idxTH, end)+((bufferT)*30),:); %add the buffer for processing and plotting
        tempSt=find(tm>=ii+transHold); tempEnd=tempSt(1)+tMEpoch;
        transHoldSmooth{idxTH}=spkRateSmooth(tempSt(1):tempEnd(end),:);
        %get spikes averaged across the channels, for each trial
        tempSt=[]; tempEnd=[];
        transHoldDataSpChMean(:,:,idxTH)=nanmean((transHoldDataSpAllCh{idxTH}),3); %mean across all channels
        transHoldBandDataChMean(:,:,idxTH)=nanmean(transHoldCBAll{idxTH},3); %mean across all channels
        transHoldSmoothChMean(:,idxTH)=nanmean(transHoldSmooth{idxTH},2);   %mean across all channels
        %%find maxima and minima of the spikes and band data for each trial,
        %%this is too compare within each trial.
        transHoldBandPeaksChMean(:,:,idxTH)=Analysis.BasicDataProc.specChange(transHoldBandDataChMean(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,idxTH)); %remove the buffered ends for this analysis.
        transHoldSpkPeaksChMean(:,idxTH)=Analysis.BasicDataProc.specChange(transHoldSmoothChMean(:,idxTH));
        for jj=1:length(ChSpk)
            bychTransHoldSpk{jj}(:, idxTH)=transHoldSmooth{idxTH}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
            bychTransHoldData{jj}(:,:,idxTH)=transHoldDataSpAllCh{idxTH}(:,:,ChSpk(jj)); %load a 3d matrix for time x freq x trial by channel for spectral data
            bychTransHoldBandData{jj}(:,:,idxTH)=transHoldCBAll{idxTH}(:,:,ChSpk(jj));
        end
        
        %record the length of the move states after the endpoint
        length3state(idxTH,:)=rState(ii:ii+500)==4; 
        
        idxTH=idxTH+1;          
        
        
        
        %% Prep state
    elseif rState(ii)==2 && rState(ii-1)==1 && rState(ii+1)==2 %2 is target appears, 1 is end of last trial, at center, and the extra 2 is to not capture trials where it returns to center
        rPrepEnd(idxPr,1)=ii;
        prepCP{idxPr}=rCP(:,ii+prep:ii+prep+epoch);
        prepSpk{idxPr}=spk(ii+prep:ii+prep+epoch, :); %take all the channels at once
        prepFCT(idxPr, :)=rFCT(1,ii);
        tempSt=find(tSpec>=ii+prep-bufferT); tempEnd=tempSt(1)+tSpecEpoch;
        prepDataSpAllCh{idxPr}=DataAll.dataSpec.data(:, tempSt(1):tempEnd(end), :);
        tempSt=find(tcB>=ii+prep); tempEnd=tempSt(1)+tCbEpoch;
        prepCBAll{idxPr}=CBPowerAll(tempSt(1):tempEnd(end), :, :);
        %prepData{idxPr}=data(prepFCT(idxPr, 1)+((prepPre-epoch-bufferT)*30):prepFCT(idxPr, end)+((bufferT)*30),:); %add the buffer for processing and plotting
        tempSt=find(tm>=ii+prep); tempEnd=tempSt(1)+tMEpoch;
        prepSmooth{idxPr}=spkRateSmooth(tempSt(1):tempEnd(end),:);
        %get spikes averaged across the channels, for each trial
        tempSt=[]; tempEnd=[];
        prepDataSpChMean(:,:,idxPr)=nanmean((prepDataSpAllCh{idxPr}),3); %mean across all channels
        prepBandDataChMean(:,:,idxPr)=nanmean(prepCBAll{idxPr},3); %mean across all channels
        prepSmoothChMean(:,idxPr)=nanmean(prepSmooth{idxPr},2);   %mean across all channels
        %%find maxima and minima of the spikes and band data for each trial,
        %%this is too compare within each trial.
        prepBandPeaksChMean(:,:,idxPr)=Analysis.BasicDataProc.specChange(prepBandDataChMean(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,idxPr)); %remove the buffered ends for this analysis.
        prepSpkPeaksChMean(:,idxPr)=Analysis.BasicDataProc.specChange(prepSmoothChMean(:,idxPr));
        for jj=1:length(ChSpk)
            bychPrepSpk{jj}(:, idxPr)=prepSmooth{idxPr}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
            bychPrepData{jj}(:,:,idxPr)=prepDataSpAllCh{idxPr}(:,:,ChSpk(jj)); %load a 3d matrix for time x freq x trial by channel for spectral data
            bychPrepBandData{jj}(:,:,idxPr)=prepCBAll{idxPr}(:,:,ChSpk(jj));
        end
        
        idxPr=idxPr+1;
        
    elseif rState(ii)==11 || rState(ii)==6 %check for any weird trials
        rCheck(1,idxCheck)=ii;
        idxCheck=idxCheck+1;
    end
       
    
end

%% PCA
%output is: 
%     Per Trial
%     PCA of spikes in the time (rows) and by the first 25 PCs (only
%     returns rows-1 PCs)
%       Peaks for the time period in this order Max Start, Max, Min start, Min
%       Then same for the different bands, across all channels
%     Averaged across all trials
%       PCA of the spikes across all trials
%       PCA of the bands across all trials
holdPCA=Analysis.BasicDataProc.pcaSpkBand(holdSmooth, holdCBAll, lblB);
moveOutPCA=Analysis.BasicDataProc.pcaSpkBand(moveOutSmooth, moveOutCBAll, lblB);
transHoldPCA=Analysis.BasicDataProc.pcaSpkBand(transHoldSmooth, transHoldCBAll, lblB);
transMovePCA=Analysis.BasicDataProc.pcaSpkBand(transMoveSmooth, transMoveCBAll, lblB);
prepPCA=Analysis.BasicDataProc.pcaSpkBand(prepSmooth, prepCBAll, lblB);
prepMovePCA=Analysis.BasicDataProc.pcaSpkBand(prepMoveSmooth, prepMoveCBAll, lblB);




%%
tmBF=1000/downSample; %size of each bin
tmSF=epoch/size(holdSmooth{1},1); %size of each bin
bandNum=size(bychMoveOutBandData{1},2);
%go through each channel and pull the spike/lfp bandpassed data
for jj=1:length(ChSpk) %run through relevant channels    
    chstr=['ch', num2str(ChSpk(jj))];
    perCh.(chstr).meansteSpkMove(:,1)=nanmean(bychMoveOutSpk{jj},2);   
    perCh.(chstr).meansteSpkMove(:,2)=nanstd(bychMoveOutSpk{jj}, [], 2)/sqrt(size(bychMoveOutSpk{1},2));
    peaksTemp=Analysis.BasicDataProc.specChange(bychMoveOutSpk{jj}); %get the peaks   
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp, 'binSize', tmSF); %get the means and CI, remember this is mean and CI of the peaks themselves, not a mean/CI of the signal and then finding the peak of that. 
    for mm=1:length(ciTemp); Peak(mm).(strcat(chstr, 'Move', 'Spike'))=ciTemp(mm); end %load into peaks
    
    perCh.(chstr).meansteBandMove(:, 1:bandNum)=nanmean(bychMoveOutBandData{jj},3);
    perCh.(chstr).meansteBandMove(:, bandNum+1:bandNum*2)=nanstd(bychMoveOutBandData{jj}, [] ,3)/sqrt(size(bychMoveOutBandData{jj},3));    
    peaksTemp=Analysis.BasicDataProc.specChange(bychMoveOutBandData{jj}(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,:)); %remove the buffered ends for this analysis.
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp, 'binSize', tmBF);
    for  ii=1:size(ciTemp); Peak(ii).(strcat(chstr, 'Move', 'Band'))=ciTemp(ii);    end
    %%
    perCh.(chstr).meansteSpkHold(:,1)=nanmean(bychHoldSpk{jj}, 2);
    perCh.(chstr).meansteSpkHold(:,2)=nanstd(bychHoldSpk{jj}, [], 2)/sqrt(size(bychHoldSpk{1},2));
    peaksTemp=Analysis.BasicDataProc.specChange(bychHoldSpk{jj});    
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp,  'binSize', tmSF); %get the CI 
    for mm=1:length(ciTemp); Peak(mm).(strcat(chstr, 'Hold', 'Spike'))=ciTemp(mm); end %load into peaks
        
    perCh.(chstr).meansteBandHold(:, 1:bandNum)=nanmean(bychHoldBandData{jj},3);
    perCh.(chstr).meansteBandHold(:, bandNum+1:bandNum*2)=nanstd(bychHoldBandData{jj},[] ,3)/sqrt(size(bychHoldBandData{jj},3));
    peaksTemp=Analysis.BasicDataProc.specChange(bychHoldBandData{jj}(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,:)); %remove the buffered ends for this analysis.
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp, 'binSize', tmBF);
    for  ii=1:size(ciTemp); Peak(ii).(strcat(chstr, 'Hold', 'Band'))=ciTemp(ii);    end
    %%
    perCh.(chstr).meansteSpkTransMove(:,1)=nanmean(bychTransMoveSpk{jj},2);   
    perCh.(chstr).meansteSpkTransMove(:,2)=nanstd(bychTransMoveSpk{jj}, [], 2)/sqrt(size(bychTransMoveSpk{1},2));
    peaksTemp=Analysis.BasicDataProc.specChange(bychTransMoveSpk{jj}); %get the peaks   
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp, 'binSize', tmSF); %get the means and CI, remember this is mean and CI of the peaks themselves, not a mean/CI of the signal and then finding the peak of that. 
    for mm=1:length(ciTemp); Peak(mm).(strcat(chstr, 'TransMove', 'Spike'))=ciTemp(mm); end %load into peaks
    
    perCh.(chstr).meansteBandTransMove(:, 1:bandNum)=nanmean(bychTransMoveBandData{jj},3);
    perCh.(chstr).meansteBandTransMove(:, bandNum+1:bandNum*2)=nanstd(bychTransMoveBandData{jj}, [] ,3)/sqrt(size(bychTransMoveBandData{jj},3));    
    peaksTemp=Analysis.BasicDataProc.specChange(bychTransMoveBandData{jj}(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,:)); %remove the buffered ends for this analysis.
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp, 'binSize', tmBF);
    for  ii=1:size(ciTemp); Peak(ii).(strcat(chstr, 'TransMove', 'Band'))=ciTemp(ii);    end
    %%
    perCh.(chstr).meansteSpkTransHold(:,1)=nanmean(bychTransHoldSpk{jj}, 2);
    perCh.(chstr).meansteSpkTransHold(:,2)=nanstd(bychTransHoldSpk{jj}, [], 2)/sqrt(size(bychTransHoldSpk{1},2));
    peaksTemp=Analysis.BasicDataProc.specChange(bychTransHoldSpk{jj});    
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp,  'binSize', tmSF); %get the CI 
    for mm=1:length(ciTemp); Peak(mm).(strcat(chstr, 'TransHold', 'Spike'))=ciTemp(mm); end %load into peaks
        
    perCh.(chstr).meansteBandTransHold(:, 1:bandNum)=nanmean(bychTransHoldBandData{jj},3);
    perCh.(chstr).meansteBandTransHold(:, bandNum+1:bandNum*2)=nanstd(bychTransHoldBandData{jj},[] ,3)/sqrt(size(bychTransHoldBandData{jj},3));
    peaksTemp=Analysis.BasicDataProc.specChange(bychTransHoldBandData{jj}(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,:)); %remove the buffered ends for this analysis.
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp, 'binSize', tmBF);
    for  ii=1:size(ciTemp); Peak(ii).(strcat(chstr, 'TransHold', 'Band'))=ciTemp(ii);    end
    %%
    perCh.(chstr).meansteSpkPrep(:,1)=nanmean(bychPrepSpk{jj}, 2);
    perCh.(chstr).meansteSpkPrep(:,2)=nanstd(bychPrepSpk{jj}, [], 2)/sqrt(size(bychPrepSpk{1},2));
    peaksTemp=Analysis.BasicDataProc.specChange(bychPrepSpk{jj});    
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp,  'binSize', tmSF); %get the CI 
    for mm=1:length(ciTemp); Peak(mm).(strcat(chstr, 'Prep', 'Spike'))=ciTemp(mm); end %load into peaks
        
    perCh.(chstr).meansteBandPrep(:, 1:bandNum)=nanmean(bychPrepBandData{jj},3);
    perCh.(chstr).meansteBandPrep(:, bandNum+1:bandNum*2)=nanstd(bychPrepBandData{jj},[] ,3)/sqrt(size(bychPrepBandData{jj},3));
    peaksTemp=Analysis.BasicDataProc.specChange(bychPrepBandData{jj}(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,:)); %remove the buffered ends for this analysis.
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp, 'binSize', tmBF);
    for  ii=1:size(ciTemp); Peak(ii).(strcat(chstr, 'Prep', 'Band'))=ciTemp(ii);    end
    %%
    perCh.(chstr).meansteSpkPrepMove(:,1)=nanmean(bychPrepMoveSpk{jj}, 2);
    perCh.(chstr).meansteSpkPrepMove(:,2)=nanstd(bychPrepMoveSpk{jj}, [], 2)/sqrt(size(bychPrepMoveSpk{1},2));
    peaksTemp=Analysis.BasicDataProc.specChange(bychPrepMoveSpk{jj});    
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp,  'binSize', tmSF); %get the CI 
    for mm=1:length(ciTemp); Peak(mm).(strcat(chstr, 'PrepMove', 'Spike'))=ciTemp(mm); end %load into peaks
        
    perCh.(chstr).meansteBandPrepMove(:, 1:bandNum)=nanmean(bychPrepMoveBandData{jj},3);
    perCh.(chstr).meansteBandPrepMove(:, bandNum+1:bandNum*2)=nanstd(bychPrepMoveBandData{jj},[] ,3)/sqrt(size(bychPrepMoveBandData{jj},3));
    peaksTemp=Analysis.BasicDataProc.specChange(bychPrepMoveBandData{jj}(downSample*bufferT/1000+1:end-downSample*bufferT/1000,:,:)); %remove the buffered ends for this analysis.
    ciTemp=Analysis.BasicDataProc.maxminCI(peaksTemp, 'binSize', tmBF);
    for  ii=1:size(ciTemp); Peak(ii).(strcat(chstr, 'PrepMove', 'Band'))=ciTemp(ii);    end
    
    %SPECTROGRAM mean across trials for that channel
    perCh.(chstr).specHold=nanmean(bychHoldData{jj}, 3);
    perCh.(chstr).specMove=nanmean(bychMoveOutData{jj}, 3);
    perCh.(chstr).specTransHold=nanmean(bychTransHoldData{jj}, 3);
    perCh.(chstr).specTransMove=nanmean(bychTransMoveData{jj}, 3);
    perCh.(chstr).specPrep=nanmean(bychPrepData{jj}, 3);
    perCh.(chstr).specPrepMove=nanmean(bychPrepMoveData{jj}, 3);

    
    %when ready to run the clusters
    %[ mnd1, mnd2, ~, ~, sigclust, rlab ] = stats.cluster_permutation_Ttest_gpu3d( S, Sbase, 'alph', 0.00024 );

end

moveDataAllTrAllCh=nanmean(moveDataAllCh,3); %across all channels and trials
moveBandDataAllTrAllCh=nanmean(moveBandDataAllCh, 3); %across all channels and all trials
%find the peaks and CI
peaksTemp=Analysis.BasicDataProc.maxminCI(moveBandPeaksAllCh, 'binSize', tmBF);
for  ii=1:size(peaksTemp)
    Peak(ii).moveBandAllChAllTr=peaksTemp(ii);
end
peaksTemp=Analysis.BasicDataProc.maxminCI(moveSpkPeaksAllCh, 'binSize', tmSF); %across all channels and all trials
for  ii=1:size(peaksTemp)
    Peak(ii).moveSpkAllChAllTr=peaksTemp(ii);
end


holdDataAllTrAllCh=nanmean(holdDataSpChMean,3); %across all channels and trials
holdBandDataAllTrAllCh=nanmean(holdBandDataAllCh, 3); %across all channels and all trials
%find the peaks and CI
peaksTemp=Analysis.BasicDataProc.maxminCI(holdBandPeaksChMean, 'binSize', tmBF);
for  ii=1:size(peaksTemp)
    Peak(ii).holdBandAllChAllTr=peaksTemp(ii);
end
holdSmoothAllTrAllCh=Analysis.BasicDataProc.maxminCI(holdSpkPeaksChMean, 'binSize', tmSF); %across all channels and all trials
for  ii=1:size(holdSmoothAllTrAllCh)
    Peak(ii).holdSpkAllChAllTr=holdSmoothAllTrAllCh(ii);
end



if plotData
    N=100;
    C=linspecer(N);
    Analysis.NPTL.PLOTpeakCI; %script to run the 
    
   
        if Spectrogram;  win=params.win(1)*1000; %get the window of the spectrogram
        else; win=0; end;
        fDiff=holdDataAllTemp.f;
        tpDiffFull=(holdDataAllTemp.tplot)*1000-bufferT; %convert to ms, adjust 0 with the buffer, and finally move the spectrogram timing to the beginning of the window rather than the middle.
        specPlotIdx=tpDiffFull>-100 & tpDiffFull<400; %only plot -100 to 400 for an epoch of 300. There are large shifts at the beginning and end (although ramp ups should be dealt with in the data prep)
        tpDiffforPlot=tpDiffFull(specPlotIdx);
        tpHold=tpDiffforPlot-epoch-holdPre; %300ms before hover period ended 
        tpMove=tpDiffforPlot+movePost; %200ms after the target appears
        
        %% plotting
        
       
        colorSh=[2, 15, 62, 98];
        colorShBand=[2, 12, 41, 96];
        
        tSpk=linspace(0, epoch, epoch/spkWin);
        tspkHold=tSpk-epoch-holdPre; %300ms before hover period ended 
        tspkMove=tSpk+movePost; %200ms after the target appears
       
        tBand=linspace(0, epoch+bufferT*2, size(bychHoldBandData{1},1))-bufferT; %include the buffers, than adjust 0 to the buffer
        bandPlotIdx=tBand>-plotPre & tBand<plotPost; %only plot -100 to 400 for an epoch of 300. There are large shifts at the beginning and end (although ramp ups should be dealt with in the data prep)
        tbandForPlot=tBand(bandPlotIdx);
        tBandHold=tbandForPlot-epoch-holdPre; %300ms before hover period ended 
        tBandMove=tbandForPlot+movePost; %200ms after the target appears
        
        
        iti=specTempHoldI.data(:, 1:size(holdDataAllTemp.data,2), :); %match the iti side

    
    %Plot the channels    
    idxCC=1;
    
    figtitle=['Smoothed spike mean '];
    figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
    set(gca,'FontSize', 22)
    sgtitle(figtitle)
    for jj=1:length(ChSpk)
        chstr=['ch', num2str(ChSpk(jj))];
        subplot(2,1,1)
        hold on
        H2=plot(tspkMove, perCh.(chstr).meansteSpkMove(:,1));
        H2.LineWidth=2;
        H2.Color=C(idxCC,:);
        H2.DisplayName=chstr;
        title('Mean Smoothed Spike Rates Move by channel')
        legend
        
        subplot(2,1,2)
        hold on
        H2=plot(tspkHold, perCh.(chstr).meansteSpkHold(:,1));
        H2.LineWidth=2;
        H2.Color=C(idxCC,:);
        H2.DisplayName=chstr;
        title('Mean Smoothed Spike Rates Hold by channel')
        legend
        
        idxCC=idxCC+4;
        
    end
    

    %% bands
    for jj=1:length(ChSpk)
        chstr=['ch', num2str(ChSpk(jj))];%%
        figtitle=['Band filtered data ', chstr];
        figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
        set(gca,'FontSize', 22)
        sgtitle(figtitle)
        
        %lblPhase={'Move'; 'Hold'; 'Transition to Move'; 'Transition to Hold'};
        lblPhase={'Move'; 'Hold'};

        for rr=1:6
            idxC=1;            
            subplot(3, 2, rr)            
            hold on
            H1=shadedErrorBar(tbandForPlot, perCh.(chstr).meansteBandMove(bandPlotIdx, rr), perCh.(chstr).meansteBandMove(bandPlotIdx, rr+6));
            H1.mainLine.LineWidth=2;
            H1.patch.FaceColor=C(colorShBand(idxC),:);
            H1.patch.EdgeColor=C(colorShBand(idxC)-1,:);
            H1.mainLine.Color=C(colorShBand(idxC)-1,:);
            H1.edge(1).Color=C(colorShBand(idxC)-1,:);
            H1.edge(2).Color=C(colorShBand(idxC)-1,:);
            H1.mainLine.DisplayName=lblPhase{1};
            title(lblB{rr})
            idxC=idxC+1;
            
            H2=shadedErrorBar(tbandForPlot, perCh.(chstr).meansteBandHold(bandPlotIdx, rr), perCh.(chstr).meansteBandHold(bandPlotIdx, rr+6));
            H2.mainLine.LineWidth=2;
            H2.patch.FaceColor=C(colorShBand(idxC),:);
            H2.patch.EdgeColor=C(colorShBand(idxC)-1,:);
            H2.mainLine.Color=C(colorShBand(idxC),:);
            H2.edge(1).Color=C(colorShBand(idxC)-1,:);
            H2.edge(2).Color=C(colorShBand(idxC)-1,:);
            H2.mainLine.DisplayName=lblPhase{2};
            ax=gca;
            ax.XLim=[floor(tbandForPlot(1)) ceil(tbandForPlot(end))];
            
            
            idxC=idxC+1;            
            if rr==2
                legend([H1.mainLine H2.mainLine ],{'Move', 'Hold'});
            end
            if rr==5
                xlabel('Time (ms)');
                ylabel('Arbitrary units');
            end
        end
    end
        
        
   
    for jj=1:length(ChSpk)
        idxC=1;
        chstr=['ch', num2str(ChSpk(jj))];
        figtitle=['Smoothed Spike Mean and SE ', chstr, ];
        figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
        set(gca,'FontSize', 22)
        title(figtitle)
        hold on
        H1=shadedErrorBar(tSpk, perCh.(chstr).meansteSpkMove(:,1), perCh.(chstr).meansteSpkMove(:,2));
        H1.mainLine.LineWidth=4;
        H1.patch.FaceColor=C(colorSh(idxC),:);
        H1.patch.EdgeColor=C(colorSh(idxC)-1,:);
        H1.mainLine.Color=C(colorSh(idxC)-1,:);
        H1.edge(1).Color=C(colorSh(idxC)-1,:);
        H1.edge(2).Color=C(colorSh(idxC)-1,:);
        H1.mainLine.DisplayName='Move';
        idxC=idxC+1;
        
        H2=shadedErrorBar(tSpk, perCh.(chstr).meansteSpkHold(:,1), perCh.(chstr).meansteSpkHold(:,2));
        H2.mainLine.LineWidth=4;
        H2.patch.FaceColor=C(colorSh(idxC),:);
        H2.patch.EdgeColor=C(colorSh(idxC)-1,:);
        H2.mainLine.Color=C(colorSh(idxC)-1,:);
        H2.edge(1).Color=C(colorSh(idxC)-1,:);
        H2.edge(2).Color=C(colorSh(idxC)-1,:);
        H2.mainLine.DisplayName='Hold';

        idxC=idxC+1;
        legend([H1.mainLine H2.mainLine ],{'Move', 'Hold'});

    end  
    %%
    for jj=1:length(ChSpk)
        
        chstr=['ch', num2str(ChSpk(jj))];
        %set up easy plotting
        Hh=perCh.(chstr).specHold;
        Mm=perCh.(chstr).specMove;
        perCh.(chstr).HoldMove=Hh-Mm;
        perCh.(chstr).HoldIti=Hh-iti(:,:,ChSpk(jj));
        perCh.(chstr).MoveIti=Mm-iti(:,:,ChSpk(jj));
        MmHh=Mm-Hh;
        HhI=Hh-iti(:,:,ChSpk(jj));
        MmI=Mm-iti(:,:,ChSpk(jj));
        %NEED TO MAKE THESE LOOK NICER, LIKELY REMOVE THE iti ONE OR THE NO
        %ITI ONE
       
        chstr=['ch', num2str(ChSpk(jj))];
        figtitle=['Difference between epochs ', chstr, ' Heatmap ', ];
        figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
        set(gca,'FontSize', 22)
        sgtitle(figtitle)
        
        subplot(3,2,2)
        imagesc(tpHold, fDiff, HhI(:, specPlotIdx)); axis xy;
        title('Hold - ITI')
        colorbar
        ax=gca;
        ax.YTick=(0:40:round(fDiff(end)));
        
        subplot(3,2,4)
        imagesc(tpMove, fDiff, MmI(:, specPlotIdx)); axis xy;
        title('Move - ITI')
        colorbar
        ax=gca;
        ax.YTick=(0:40:round(fDiff(end)));
        

        subplot(3, 2 ,1)
        imagesc(tpHold, fDiff, Hh(:, specPlotIdx)); axis xy;
        title('Hold')
        colorbar
        ax=gca;
        ax.YTick=(0:40:round(fDiff(end)));
        
        subplot(3, 2, 3)
        imagesc(tpMove, fDiff, Mm(:, specPlotIdx)); axis xy;
        title('Move')
        colorbar
        ax=gca;
        ax.YTick=(0:40:round(fDiff(end)));
        
        subplot(3,2,[5 6])
        ax=gca;
        imagesc(tpDiffforPlot, fDiff, MmHh(:, specPlotIdx)); axis xy;
        title('Move-Hold')
        colorbar
        ax=gca;
        ax.YTick=(0:40:round(fDiff(end)));

    end
end

%%

    


end

