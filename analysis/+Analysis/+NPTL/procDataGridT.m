function [dataHoldMove] = procDataGridT(R, ns5File, varargin)
%procDataGridT Process the BCI data to break it up into times when it is
%hovering and when it isnt for the center out (GT) task.
%  R details - each row is a ms
% Input
%     R - R struct file, 
%     ns5File - the name of the file path for the file you want
%     
% Output
%     dataHoldMove - has 6 outputs
<<<<<<< HEAD
%%TIMES
% Remember: currently epoch is 300ms
% Hold=300ms before hover period is achieved (11)
% Move=300ms starting 200 ms after the target appears
% TransHold=300ms starting 200ms prior to hold state (hold is 500 ms, so it's 700ms before click state of 11) into 100 ms of hold state
% TransMove=300ms starting 100ms before the target appears (state 3)
%%
=======
>>>>>>> master
% TO DO:
%     -Need to set up the array with the gridlayout, which I need to get from spencer or someone else
%     -Find the channel names regardless of what's put in
%     -figure out how to time lock with the spiking activity? Probably what will need to happen is to plot the spiking activity as it changes around the stop/hold times and match it with the changes in beta
%     
% 
%     Example:
%         
%         [dataHoldMove]=Analysis.NPTL.procDataGridT(R, ns5file, 'Spectrogram', true);
<<<<<<< HEAD
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
=======
%LIKELY NEED THE HOVER TIME AT THE END WHICH WILL BE A DIFFERENT
    %STATE
 %THERE MIGHT BE A TIME WHERE IT ENDS WITH 4 AND THE NEXT ONE IS THE
    %SAME CONTINUOUS MOVEMENT EVEN THE R HAS PROGRESSED
    
>>>>>>> master
    
[varargin, fs] = util.argkeyval('fs',varargin, 30000); %original sample rate
[varargin, downSample] = util.argkeyval('downSample',varargin, 2000); %the new downsample rate
[varargin, ns5num] = util.argkeyval('ns5num',varargin, 3); %which cell of ns5 file you want, usually 3


<<<<<<< HEAD
[varargin, epochH] = util.argkeyval('epochH',varargin, 300); %the epoch for hold times in ms
[varargin, epochM] = util.argkeyval('epochM',varargin, 300); %the epoch for move times in ms
[varargin, epochTH] = util.argkeyval('epochTH',varargin, 300); %the epoch for transition hold (i.e. transitioning into hold) times in ms
[varargin, epochTM] = util.argkeyval('epochTM',varargin, 300); %the epoch for transition move (i.e. transitiooning into move) times in ms
[varargin, spkWin] = util.argkeyval('spkWin',varargin, 20); %the window to average spikes over, in ms

%These are the times to take around the events (state==11, click state,
%after holding for 500ms, and state==3, appearance of a new target). These
%are set up so for instance transMovePre starts 100ms prior to target
%appearing, under the assumption that shows the transition to movement.
[varargin, holdPre] = util.argkeyval('holdPre',varargin, 0); %time before transition to 11, a state of click, hovering for 500ms, in ms
[varargin, transHoldPre] = util.argkeyval('transHoldPre',varargin, -400); %time before transition to 11, a state of click, hovering for 500ms, in ms
[varargin, movePre] = util.argkeyval('movePre',varargin, 200); %time after a target appears, transition to state 3
[varargin, transMovePre] = util.argkeyval('transMovePre',varargin, -100); %time before a target appears, transition to state 3

[varargin, epochSpectrogram] = util.argkeyval('epochSpectrogram',varargin, [.3 .3]); %the epoch to run spectrogram around size (1,1) and start time after 0 (1,2) you want in seconds (staying in seconds for now, not ms)
[varargin, bufferT] = util.argkeyval('bufferT',varargin, 300); %the buffer window in ms to process data around your desired time of interest (so will take bufferT s before and bufferT after the epoch). This is to allow sufficient ramp up and plotting before and after
[varargin, channel] = util.argkeyval('channel',varargin, [1 96]); %which channels you want, default is whole grid
[varargin, trialNum] = util.argkeyval('channel',varargin, [1, size(R,2)]); %which trials you want, default is all.
[varargin, perc] = util.argkeyval('channel',varargin, 95); %what percentile of the most active channels you want. THIS LIMITS HOW MANY CHANNELS ARE INCLUDED, HIGHER PERCENTILE MEANS LESS CHANNELS ARE DISPLAYED
=======
[varargin, epochH] = util.argkeyval('epochH',varargin, .3); %the epoch for hold times in Seconds
[varargin, epochM] = util.argkeyval('epochM',varargin, .3); %the epoch for move times in Seconds
[varargin, epochTH] = util.argkeyval('epochTH',varargin, .3); %the epoch for transition hold (i.e. transitioning into hold) times in Seconds
[varargin, epochTM] = util.argkeyval('epochTM',varargin, .3); %the epoch for transition move (i.e. transitiooning into move) times in Seconds


[varargin, epoch] = util.argkeyval('epoch',varargin, [.3 .3]); %the epoch to run spectrogram around size (1,1) and start time after 0 (1,2) you want in seconds
[varargin, bufferT] = util.argkeyval('bufferT',varargin, [.3]); %the buffer window to process data around your desired time of interest (so will take .5 s before and .5 after the state==4 times). This is to allow sufficient ramp up and plotting before and after
[varargin, channel] = util.argkeyval('channel',varargin, [1 10]); %which channels you want
[varargin, trialNum] = util.argkeyval('channel',varargin, [1, size(R,2)]); %which trials you want, default is all.
>>>>>>> master
 
[varargin, MeanStd] = util.argkeyval('MeanStd',varargin, false); %choose to look at the spikes with highest mean(meaning highest spiking rates)=true or std (meaning highest variability)= false
[varargin, Spectrogram] = util.argkeyval('Spectrogram',varargin, true); %if doing Spectrogram or not

<<<<<<< HEAD
%if need to check a new R
[varargin, checkNewR] = util.argkeyval('checkNewR',varargin, true); %if want to check that movement and spikes line up
[varargin, corrCoef] = util.argkeyval('Spectrogram',varargin, true); %if want to run the correlation coefficient

[varargin, plotData] = util.argkeyval('plotData',varargin, true); %amount to plot before the epoch.  Will error if longer than the bufferT.  Only applies to the spectrogram and bandpassed dataolmk,
[varargin, plotPre] = util.argkeyval('plotPre',varargin, 100); %amount to plot before the epoch.  Will error if longer than the bufferT.  Only applies to the spectrogram and bandpassed dataolmk,
[varargin, plotPost] = util.argkeyval('plotPost',varargin, 400); %amount to plot after the epoch.
=======

[varargin, plotMean] = util.argkeyval('plotMean',varargin, true); %if you want to plot.
>>>>>>> master

%% PREP ACTIVITY
%convert R to a struct PROBABLY THIS TO UNWIELDY AND WILL NEED TO BREAK
%R UP
if ~isa(R, 'struct')
    R=[R{:}];
end

%% OPEN DATA
%convert to readable for the channels
ch=['c:0', num2str(channel(1,1)), ':', num2str(channel(1,2))];
ns5=openNSx('read', ns5File, ch); %Open the file
<<<<<<< HEAD
data=double(ns5.Data{ns5num})';

%make sure data is columns=channels and rows are time
if size(data, 1)<size(data,2)
    data=data';
end

%gridlayout per idx to channel FOR NOW, ONLY ADJUSTING THE CHANNELS IN
%CORRELATION, EASIER TO KEEP TRACK OF WHICH CHANNEL IS WHICH
idxch2el=[78,88,68,58,56,48,57,38,47,28,37,27,36,18,45,17,46,8,35,16,24,7,26,6,25,5,15,4,14,3,13,2,77,67,76,66,75,65,74,64,73,54,63,53,72,43,62,55,61,44,52,33,51,34,41,42,31,32,21,22,11,23,10,12,96,87,95,86,94,85,93,84,92,83,91,82,90,81,89,80,79,71,69,70,59,60,50,49,40,39,30,29,19,20,1,9];


%create an iti, idle time is 3 seconds prior to start, end .5 seconds early
%to prevent anticipation
itiD=data(R(1).firstCerebusTime(1,1)-(30000*6)-300:R(1).firstCerebusTime(1,1)-15000-300, :);%also subtract the 10ms offset, or 300 samples

%run a correlation coeffecient if need be
if corrCoef
    [Corr, dataClassBand] = Analysis.BasicDataProc.gridCorrCoef(itiD, 'channelOrder', idxch2el, 'plt', false);
else
    dataClassBand=[];
end

[specTempHoldI, dataClassBand] =Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(itiD, fs, downSample), 'Spectrogram', Spectrogram, 'doBandFilterBroad', true, 'dataClassBand', dataClassBand);

itiNM=specTempHoldI.data;
tI=specTempHoldI.tplot;
fI=specTempHoldI.f;
itiT=nanmean(specTempHoldI.data,2);

%Spike times to set up for plotting
tSpkHold=linspace(holdPre-epochH, 0, floor(abs(epochH)/spkWin)); %t=0 is state 11 starting, prior to click to click (state 3 to 11, 11 being click state )
tSpkTransHold=linspace(transHoldPre-epochTH, transHoldPre, floor(abs(epochTH)/spkWin)); %t=0 is hold state
tSpkMove=linspace(movePre, movePre+epochM, floor(abs(epochM)/spkWin)); %t=0 is when the new target appears
tSpkTransMove=linspace(transMovePre, transMovePre+epochTM, floor(abs(epochTM)/spkWin)); %t=0 is when a new target appears
tGen=linspace(0, epochH, floor(abs(epochH)/spkWin)); %generic 300ms for easy comparison of epochs
=======
data=double(ns5.Data{ns5num});


%TO DO: PROBABLY NEED TO CHECK THE DATA ACROSS THE ARRAY FOR COHERENCE AND
%THEN COLLAPSE IT WITH A MEAN.

epochH=epochH*1000; %convert to ms
epochM=epochM*1000; %convert to ms
epochTH=epochTH*1000;
epochTM=epochTM*1000;
bufferT=bufferT*1000;

>>>>>>> master

%% gather the data up
timeHold=[]; timeMove=[];
holdData=[]; moveData=[];

idx1=2; trl=1; fl=1;
rState=double([R.state]);
<<<<<<< HEAD
rCP=double([R.cursorPosition]); %1 and 3 are position, 2 and 4 are velocity for grid task, and it's derivative of cp in grid task or row 1:2 of xp
rSpk=double([R.spikeRaster]);
rFCT=double([R.firstCerebusTime])-10; %There is a 10ms offset from ns5 and firstCerebusTime, unknown why, but verified. difference between row 1 and 2 is 6ms, lastcerebrustime is 29 and 35ms respectively for row 1/2
rMinA=double([R.minAcausSpikeBand]);



%% spikes, all channels
%smooth the spikes
[spk, spkRate, spkRateSmooth, tm] = Analysis.BasicDataProc.spikeRate(rSpk, 'win', spkWin);
=======
rCP=double([R.cursorPosition]); %1 and 3 are position 2 and 4 are velocity)
rSpk=double([R.spikeRaster]);
rFCT=double([R.firstCerebusTime]); %difference between row 1 and 2 is 6ms, lastcerebrustime is 29 and 35ms respectively for row 1/2

%% spikes, all channels
%smooth the spikes
[spk, spkRate, spkRateSmooth, tm] = Analysis.BasicDataProc.spikeRate(rSpk);
>>>>>>> master
% Outputs:
%         spk-  converts raster to NaNs and 1s for plotting
%         spkRate- spikes summed over a window
%         spkRateSmooth- smoothed spikes with convolve
%         tm- a time vector for plotting to match spikes
<<<<<<< HEAD
spikeCh.spk=spk; %flip them all to match the lfp data, so columns are channels
spikeCh.spkRate=spkRate;
spikeCh.spkRateSmooth=spkRateSmooth;
spikeCh.tm=tm;
=======
spikeCh.spk=spk; %etc
spikeCh.spkRate=spkRate;
spikeCh.spkRateSmooth=spkRateSmooth;
spikeCh.tm=tm;
    

% find the channels most active, then choose between highest spike rates
% (mean) or highest variability (std)
[meanstdSpkPerc] = Analysis.BasicDataProc.activeSpkCh(spkRateSmooth, 'perc', 80);
spikeCh.meanstdSpkPerc=meanstdSpkPerc;


if MeanStd==true
    ChSpk=meanstdSpkPerc.meanSpkPerc;
else
    ChSpk=meanstdSpkPerc.stdSpkPerc;
end
>>>>>>> master


%find trials where the next target is the same as the last (no movement)
idxSame=1;
for ii=1:size(R,2)
    if R(ii).cuedTarget(1)==R(ii).cuedTarget(2) %indicates a new target appears, if the same at the beginning, throw out whole trial
        trialSame(idxSame, 1)=ii;
        trialSame(idxSame, 2)=R(ii).startcounter-R(1).startcounter+1; %starting point relative to the continuous data
        trialSame(idxSame, 3)=R(ii).endcounter-R(1).startcounter+1; %ending point relative to the continuous data
        idxSame=idxSame+1;
    end
end
    
<<<<<<< HEAD
targetSpk=[];

%get the states hovering
idxH=1; idxM=1; idxCheck=1; idxT=1;
for ii=2:length(rState)-1 %first trial is different than the rest
    if rState(ii+1)-rState(ii)==8 %move state to transitioning to 11
        rHoldEnd(idxH,1)=ii;
        holdCP{idxH}=rCP(:,ii+holdPre-epochH:ii);
        holdSpk{idxH}=spk(ii+holdPre-epochH:ii, :); %take all the channels at once
        holdFCT(idxH, :)=rFCT(1,ii+holdPre-epochH-bufferT:ii+bufferT); %add the buffer for processing and plotting
        holdData{idxH}=data(holdFCT(idxH, 1):holdFCT(idxH, end),:);
        tempSt=find(tm>=ii+holdPre-epochH); tempEnd=find(tm<=ii);
        holdSmooth{idxH}=spkRateSmooth(tempSt(1):tempEnd(end),:); 
        tempSt=[]; tempEnd=[];
        
        transHoldCP{idxH}=rCP(:,ii+transHoldPre-epochTH:ii+transHoldPre); %11 is after 500ms of hold, so overlap by 100
        transHoldSpk{idxH}=spk(ii+transHoldPre-epochTH:ii+transHoldPre, :);
        transHoldFCT(idxH, :)=rFCT(1,ii+transHoldPre-epochTH-bufferT:ii+transHoldPre+bufferT);
        transHoldData{idxH}=data(transHoldFCT(idxH, 1):transHoldFCT(idxH, end),:);
        tempSt=find(tm>=ii+transHoldPre-epochTH); tempEnd=find(tm<=ii+transHoldPre);
        transHoldSmooth{idxH}=spkRateSmooth(tempSt(1):tempEnd(end), :); 
        tempSt=[]; tempEnd=[];
        
        idxH=idxH+1;
    elseif rState(ii+1)-rState(ii)==-4 %6 to 2, which is "refractory" to "new target appearing"
        rMoveSt(idxM, 1)=ii;
        moveCP{idxM}=rCP(:,ii+movePre:ii+movePre+epochM); %after 200 ms after the target appears to get into a move state
        moveMinA{idxM}=rMinA(:,ii+movePre:ii+movePre+epochM); %this is to double check the data from ns5 matches R
        moveSpk{idxM}=spk(ii+movePre:ii+movePre+epochM, :);
        moveFCT(idxM, :)=rFCT(1,ii+movePre-bufferT:ii+movePre+epochM+bufferT);
        moveHFOFCT(idxM,:)=rFCT(1,ii+movePre:ii+movePre+epochM);
        tempData=data(moveHFOFCT(idxM, 1):moveHFOFCT(idxM, end), :);
        %moveHFO{idxM}=filtfilthd(filtD, tempData(:,1));
        moveData{idxM}=data(moveFCT(idxM, 1):moveFCT(idxM, end), :);
        tempSt=find(tm>=ii+200); tempEnd=find(tm<=ii+200+epochM);
        moveSmooth{idxM}=spkRateSmooth(tempSt(1):tempEnd(end), :); 
        tempSt=[]; tempEnd=[];
        
        transMoveCP{idxM}=rCP(:, ii+transMovePre:ii+transMovePre+epochTM); %transition to moving state, 100ms prior to target appearing to epochTM
        transMoveSpk{idxM}=spk(ii+transMovePre:ii+transMovePre+epochTM, :); 
        transMoveFCT(idxM, :)=rFCT(1,ii+transMovePre-bufferT:ii+transMovePre+epochTM+bufferT); 
        transMoveData{idxM}=data(transMoveFCT(idxM, 1):transMoveFCT(idxM, end), :);
        tempSt=find(tm>=ii+transMovePre); tempEnd=find(tm<=ii+transMovePre+epochTM);
        transMoveSmooth{idxM}=spkRateSmooth(tempSt(1):tempEnd(end), :); 
        tempSt=[]; tempEnd=[];
        
    
        %Make a matrix for around the target appearing.  This is to test a
        %new R
        if checkNewR
            tempSt=find(tm>=ii-1000 & tm<=ii+1000);
            if ~isempty(targetSpk)
                if length(tempSt)<size(targetSpk{idxT-1},1)
                    tempSt(end+1)=tempSt(end)+1;
                elseif length(tempSt)>size(targetSpk{idxT-1},1)
                    tempSt(end)=[];
                end
            end
            targetSpk{idxM}=spkRateSmooth(tempSt(1):tempSt(end), :);
            targetCp(:, :, idxM)=rCP(:, ii-1000:ii+1000);
            targetSpkAll(:, :, idxM)=spkRateSmooth(tempSt(1):tempSt(end), :);
            tempSt=[]; tempEnd=[];
            idxT=idxT+1;
        end

        idxM=idxM+1; 
=======

%get the states hovering
idxH=1; idxM=1; idxCheck=1;
for ii=1:length(rState)-1
    if rState(ii+1)-rState(ii)==8 %move state to transitioning to 11
        rHoldEnd(idxH,1)=ii;
        holdCP{idxH}=rCP(:,ii-epochH:ii);
        holdSpk{idxH}=spk(:,ii-epochH:ii); %take all the channels at once
        holdFCT(idxH, :)=rFCT(1,ii-epochH-bufferT:ii+bufferT); %add the buffer for processing and plotting
        holdData{idxH}=data(:, holdFCT(idxH, 1):holdFCT(idxH, end));
        tempSt=find(tm>=ii-epochH); tempEnd=find(tm<=ii);
        holdSmooth{idxH}=spkRateSmooth(:,tempSt(1):tempEnd(end)); 
        tempSt=[]; tempEnd=[];
        
        transHoldCP{idxH}=rCP(:,ii-400-epochTH:ii-400); %11 is after 500ms of hold, so overlap by 100
        transHoldSpk{idxH}=spk(:,ii-400-epochTH:ii-400);
        transHoldFCT(idxH, :)=rFCT(1,ii-400-epochTH-bufferT:ii-400+bufferT);
        transHoldData{idxH}=data(:, transHoldFCT(idxH, 1):transHoldFCT(idxH, end));
        tempSt=find(tm>=ii-400-epochTH); tempEnd=find(tm<=ii-400);
        transHoldSmooth{idxH}=spkRateSmooth(:,tempSt(1):tempEnd(end)); 
        tempSt=[]; tempEnd=[];
        
        idxH=idxH+1;
    elseif rState(ii+1)-rState(ii)==-4 %6 to 2, which is refractory to new target appearing
        rMoveSt(idxM, 1)=ii;
        moveCP{idxM}=rCP(:,ii+200:ii+200+epochM); %after 200 ms after the target appears to get into a move state
        moveSpk{idxM}=spk(:,ii+200:ii+200+epochM);
        moveFCT(idxM, :)=rFCT(1,ii+200-bufferT:ii+200+epochM+bufferT);
        moveData{idxM}=data(:, moveFCT(idxM, 1):moveFCT(idxM, end));
        tempSt=find(tm>=ii+200); tempEnd=find(tm<=ii+200+epochM);
        moveSmooth{idxM}=spkRateSmooth(:,tempSt(1):tempEnd(end)); 
        tempSt=[]; tempEnd=[];
        
        transMoveCP{idxM}=rCP(:,ii-100:ii-100+epochTM); %transition to moving state, 100ms prior to target appearing to epochTM
        transMoveSpk{idxM}=spk(:,ii-100:ii-100+epochTM); 
        transMoveFCT(idxM, :)=rFCT(1,ii-100-bufferT:ii-100+epochTM+bufferT); 
        transMoveData{idxM}=data(:, transMoveFCT(idxM, 1):transMoveFCT(idxM, end));
        tempSt=find(tm>=ii-100); tempEnd=find(tm<=ii-100+epochTM);
        transMoveSmooth{idxM}=spkRateSmooth(:,tempSt(1):tempEnd(end)); 
        tempSt=[]; tempEnd=[];

        idxM=idxM+1;
>>>>>>> master
    elseif rState(ii+1)-rState(ii)==9 || rState(ii+1)-rState(ii)<=-8 %check for any weird trials
        rCheck(1,idxCheck)=ii;
    end
end

<<<<<<< HEAD
if checkNewR
    [allChSpk,allTrialSpk] = Analysis.NPTL.checkSpikes(targetSpkAll,targetCp);
end

% find the channels most active, then choose between highest spike rates
% (mean) or highest variability (std)
[msH] = Analysis.BasicDataProc.activeSpkCh(holdSmooth, 'perc', perc);
[msTH] = Analysis.BasicDataProc.activeSpkCh(transHoldSmooth, 'perc', perc);
[msS] = Analysis.BasicDataProc.activeSpkCh(moveSmooth, 'perc', perc);
[msTM] = Analysis.BasicDataProc.activeSpkCh(transMoveSmooth, 'perc', perc);


%which one to pick to look at the channels
spikeCh.meanstdSpkPerc=msTM;
%choose the modDSPk, can also choose mean and ste changes, but likely will
%pick up noisey channels
ChSpk=msTM.modDSpk;

%go through each channel and pull the spike data
dataClassBand=[];
for jj=1:length(ChSpk) %run through relevant channels
    tt=tic;
    for ii=1:length(moveSpk) %run through trials
        chMoveSpk{jj}(:, ii)=moveSmooth{ii}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
        dataChTemp=moveData{ii}(:, ChSpk(jj));        
        [specTempMove, params, dataFinalCBMove, ~, dataClassBand] =Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(dataChTemp, fs, downSample), 'Spectrogram', Spectrogram, 'dataClassBand', dataClassBand, 'doBandFilterBroad', true);
        chMoveData{jj}(:,:,ii)=specTempMove.data; %load a 3d matrix for time x freq x trial by channel for spectral data
        chMoveBandData{jj}(:,:,ii)=dataFinalCBMove; %load a 3d matrix for time x freq x trial by channel for bandpassed in classic bands
        clear dataChTemp;
        
        chTargetSpk{jj}(:,ii)=targetSpk{ii}(:, ChSpk(jj));

        chHoldSpk{jj}(:, ii)=holdSmooth{ii}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
        dataChTemp=holdData{ii}(:, ChSpk(jj));        
        [specTempHold, params, dataFinalCBHold] =Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(dataChTemp, fs, downSample), 'Spectrogram', Spectrogram, 'dataClassBand', dataClassBand, 'doBandFilterBroad', true);
        chHoldData{jj}(:,:,ii)=specTempHold.data; %load a 3d matrix for time x freq x trial by channel for spectral data
        chHoldBandData{jj}(:,:,ii)=dataFinalCBHold; %load a 3d matrix for time x freq x trial by channel for bandpassed in classic bands
        clear dataChTemp;

        chTransMoveSpk{jj}(:, ii)=transMoveSmooth{ii}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
        dataChTemp=transMoveData{ii}(:, ChSpk(jj));        
        [specTempTransMove, params, dataFinalCBTransMove] =Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(dataChTemp, fs, downSample), 'Spectrogram', Spectrogram, 'dataClassBand', dataClassBand, 'doBandFilterBroad', true);
        chTransMoveData{jj}(:,:,ii)=specTempTransMove.data; %load a 3d matrix for time x freq x trial by channel for spectral data
        chTransMoveBandData{jj}(:,:,ii)=dataFinalCBTransMove; %load a 3d matrix for time x freq x trial by channel for bandpassed in classic bands
        clear dataChTemp;
        
        chTransHoldSpk{jj}(:, ii)=transHoldSmooth{ii}(:, ChSpk(jj)); %cells by channel, with trials by spike averages
        dataChTemp=transHoldData{ii}(:, ChSpk(jj));        
        [specTempTransHold, params, dataFinalCBTransHold] =Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(dataChTemp, fs, downSample), 'Spectrogram', Spectrogram, 'dataClassBand', dataClassBand, 'doBandFilterBroad', true);
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
    
    perCh.(chstr).meansteSpkTarget(:,1)=nanmean(chTargetSpk{jj},2);
    perCh.(chstr).meansteSpkTarget(:,2)=nanstd(chTargetSpk{jj}, [], 2)/sqrt(size(chTargetSpk{1},2));

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

 perCh.allCh.meansteSpkTarget(:,1)=nanmean(chTargetSpk{jj},2);
    perCh.allCh.meansteSpkTarget(:,2)=nanstd(chTargetSpk{jj}, [], 2)/sqrt(size(chTargetSpk{1},2));

%should be the same for all trials, so shouldn't matter, if the epoch
%changes, then have a problem.  this sets up the timing for plotting

if plotData
    if epochH+epochM+epochTM+epochTH==epochH*4
        if Spectrogram;  win=params.win(1)*1000; %get the window of the spectrogram
        else; win=0; end;
        fDiff=specTempHold.f;
        tpDiffFull=(specTempHold.tplot)*1000-bufferT; %convert to ms, adjust 0 with the buffer, and finally move the spectrogram timing to the beginning of the window rather than the middle.
        specPlotIdx=tpDiffFull>-100 & tpDiffFull<400; %only plot -100 to 400 for an epoch of 300. There are large shifts at the beginning and end (although ramp ups should be dealt with in the data prep)
        tpDiffforPlot=tpDiffFull(specPlotIdx);
        tpHold=tpDiffforPlot-epochH-holdPre; %300ms before hover period ended 
        tpMove=tpDiffforPlot+movePre; %200ms after the target appears
        tpTransHold=tpDiffforPlot-epochH+transHoldPre; %700ms before hover period ends
        tpTransMove=tpDiffforPlot+transMovePre; %100ms before the target appears.
        
        %% plotting
        
        N=100;
        C=linspecer(N);
        colorSh=[2, 15, 62, 98];
        colorShBand=[2, 12, 41, 96];
        
        tSpk=linspace(0, epochH, epochH/spkWin);
        tspkHold=tSpk-epochH-holdPre; %300ms before hover period ended 
        tspkMove=tSpk+movePre; %200ms after the target appears
        tspkTransHold=tSpk-epochH+transHoldPre; %700ms before hover period ends
        tspkTransMove=tSpk+transMovePre; %100ms before the target appears.
        
        tBand=linspace(0, epochH+bufferT*2, size(chHoldBandData{1},2))-bufferT; %include the buffers, than adjust 0 to the buffer
        bandPlotIdx=tBand>-plotPre & tBand<plotPost; %only plot -100 to 400 for an epoch of 300. There are large shifts at the beginning and end (although ramp ups should be dealt with in the data prep)
        tbandForPlot=tBand(bandPlotIdx);
        tBandHold=tbandForPlot-epochH-holdPre; %300ms before hover period ended 
        tBandMove=tbandForPlot+movePre; %200ms after the target appears
        tBandTransHold=tbandForPlot-epochH+transHoldPre; %700ms before hover period ends
        tBandTransMove=tbandForPlot+transMovePre; %100ms before the target appears.
        lblB=fieldnames(dataClassBand);
        
        iti=repmat(itiT, 1, size(specTempMove.data,2)); %match the iti side
    else
        error('epochs are different, will need to adjust to be the same')
    end
    
    %Plot the channels    
    idxCC=1;
    
    figtitle=['Smoothed spike mean '];
    figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
    set(gca,'FontSize', 22)
    sgtitle(figtitle)
    for jj=1:length(ChSpk)
        chstr=['ch', num2str(ChSpk(jj))];
        subplot(2,2,1)
        hold on
        H=plot(tspkMove, perCh.(chstr).meansteSpkMove(:,1));
        H.LineWidth=2;
        H.Color=C(idxCC,:);
        H.DisplayName=chstr;
        title('Mean Smoothed Spike Rates Move by channel')
        legend
        
        subplot(2,2,2)
        hold on
        H=plot(tspkHold, perCh.(chstr).meansteSpkHold(:,1));
        H.LineWidth=2;
        H.Color=C(idxCC,:);
        H.DisplayName=chstr;
        title('Mean Smoothed Spike Rates Hold by channel')
        legend
        
        subplot(2,2,3)
        hold on
        H=plot(tspkTransMove, perCh.(chstr).meansteSpkTransMove(:,1));
        H.LineWidth=2;
        H.Color=C(idxCC,:);
        H.DisplayName=chstr;
        title('Mean Smoothed Spike Rates TransMove by channel')
        legend
        
        subplot(2,2,4)
        hold on
        H=plot(tspkTransHold, perCh.(chstr).meansteSpkTransHold(:,1));
        H.LineWidth=2;
        H.Color=C(idxCC,:);
        H.DisplayName=chstr;
        title('Mean Smoothed Spike Rates TransHold by channel')
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
        
        lblPhase={'Move'; 'Hold'; 'Transition to Move'; 'Transition to Hold'};
        
        for rr=1:6
            idxC=1;
            
            subplot(3, 2, rr)
            
            hold on
            H1=shadedErrorBar(tbandForPlot, perCh.(chstr).meansteBandMove(rr,bandPlotIdx), perCh.(chstr).meansteBandMove(rr+6,bandPlotIdx));
            H1.mainLine.LineWidth=2;
            H1.patch.FaceColor=C(colorShBand(idxC),:);
            H1.patch.EdgeColor=C(colorShBand(idxC)-1,:);
            H1.mainLine.Color=C(colorShBand(idxC)-1,:);
            H1.edge(1).Color=C(colorShBand(idxC)-1,:);
            H1.edge(2).Color=C(colorShBand(idxC)-1,:);
            H1.mainLine.DisplayName=lblPhase{1};
            title(lblB{rr})
            idxC=idxC+1;
            
            H2=shadedErrorBar(tbandForPlot, perCh.(chstr).meansteBandHold(rr,bandPlotIdx), perCh.(chstr).meansteBandHold(rr+6,bandPlotIdx));
            H2.mainLine.LineWidth=2;
            H2.patch.FaceColor=C(colorShBand(idxC),:);
            H2.patch.EdgeColor=C(colorShBand(idxC)-1,:);
            H2.mainLine.Color=C(colorShBand(idxC),:);
            H2.edge(1).Color=C(colorShBand(idxC)-1,:);
            H2.edge(2).Color=C(colorShBand(idxC)-1,:);
            H2.mainLine.DisplayName=lblPhase{2};
            
            idxC=idxC+1;
            
            
            H3=shadedErrorBar(tbandForPlot, perCh.(chstr).meansteBandTransMove(rr,bandPlotIdx), perCh.(chstr).meansteBandTransMove(rr+6,bandPlotIdx));
            H3.mainLine.LineWidth=2;
            H3.patch.FaceColor=C(colorShBand(idxC)-1,:);
            H3.patch.EdgeColor=C(colorShBand(idxC)-1,:);
            H3.mainLine.Color=C(colorShBand(idxC),:);
            H3.edge(1).Color=C(colorShBand(idxC)-1,:);
            H3.edge(2).Color=C(colorShBand(idxC)-1,:);
            H3.mainLine.DisplayName=lblPhase{3};
            
            idxC=idxC+1;
            
            
            H4=shadedErrorBar(tbandForPlot, perCh.(chstr).meansteBandTransHold(rr,bandPlotIdx), perCh.(chstr).meansteBandTransHold(rr+6,bandPlotIdx));
            H4.mainLine.LineWidth=2;
            H4.patch.FaceColor=C(colorShBand(idxC)-1,:);
            H4.patch.EdgeColor=C(colorShBand(idxC)-1,:);
            H4.mainLine.Color=C(colorShBand(idxC),:);
            H4.edge(1).Color=C(colorShBand(idxC)-1,:);
            H4.edge(2).Color=C(colorShBand(idxC)-1,:);
            H4.mainLine.DisplayName=lblPhase{4};
            
            idxC=idxC+1;
            if rr==2
                legend([H1.mainLine H2.mainLine H3.mainLine H4.mainLine],{'Move', 'Hold', 'Transition to Move', 'Transition to Hold'});
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
        figtitle=['Smoothed spike mean and ste ', chstr];
        figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
        set(gca,'FontSize', 22)
        sgtitle(figtitle)
        subplot(2, 2, 1)
        H=shadedErrorBar(tspkMove, perCh.(chstr).meansteSpkMove(:,1), perCh.(chstr).meansteSpkMove(:,2));
        H.mainLine.LineWidth=4;
        H.patch.FaceColor=C(colorSh(idxC),:);
        H.patch.EdgeColor=C(colorSh(idxC)-1,:);
        H.mainLine.Color=C(colorSh(idxC)-1,:);
        H.edge(1).Color=C(colorSh(idxC)-1,:);
        H.edge(2).Color=C(colorSh(idxC)-1,:);
        title('Move Spike Rate')
        idxC=idxC+1;
        
        subplot(2, 2, 2)
        H=shadedErrorBar(tspkHold, perCh.(chstr).meansteSpkHold(:,1), perCh.(chstr).meansteSpkHold(:,2));
        H.mainLine.LineWidth=4;
        H.patch.FaceColor=C(colorSh(idxC),:);
        H.patch.EdgeColor=C(colorSh(idxC)-1,:);
        H.mainLine.Color=C(colorSh(idxC)-1,:);
        H.edge(1).Color=C(colorSh(idxC)-1,:);
        H.edge(2).Color=C(colorSh(idxC)-1,:);
        title('Hold Spike Rate')
        idxC=idxC+1;
        
        subplot(2, 2, 3)
        H=shadedErrorBar(tspkTransMove, perCh.(chstr).meansteSpkTransMove(:,1), perCh.(chstr).meansteSpkTransMove(:,2));
        H.mainLine.LineWidth=4;
        H.patch.FaceColor=C(colorSh(idxC),:);
        H.patch.EdgeColor=C(colorSh(idxC)-1,:);
        H.mainLine.Color=C(colorSh(idxC)-1,:);
        H.edge(1).Color=C(colorSh(idxC)-1,:);
        H.edge(2).Color=C(colorSh(idxC)-1,:);
        %this doesn't work yet
        %H.mainLine.DisplayName='Transition to move';
        %H.patch.DisplayName=[];
        %H.edge.DisplayName=[];
        title('Transition to Move Spike Rate')
        idxC=idxC+1;
        
        subplot(2, 2, 4)
        H=shadedErrorBar(tspkTransHold, perCh.(chstr).meansteSpkTransHold(:,1), perCh.(chstr).meansteSpkTransHold(:,2));
        H.mainLine.LineWidth=4;
        H.patch.FaceColor=C(colorSh(idxC),:);
        H.patch.EdgeColor=C(colorSh(idxC)-1,:);
        H.mainLine.Color=C(colorSh(idxC)-1,:);
        H.edge(1).Color=C(colorSh(idxC)-1,:);
        H.edge(2).Color=C(colorSh(idxC)-1,:);
        title('Transition to Hold Spike Rate')
    end  
    %%
    for jj=1:length(ChSpk)
        idxC=1;
        chstr=['ch', num2str(ChSpk(jj))];
        Hh=perCh.(chstr).specHold;
        Mm=perCh.(chstr).specMove;
        Th=perCh.(chstr).specTransHold;
        Tm=perCh.(chstr).specTransMove;
        perCh.(chstr).HoldMove=Hh-Mm;
        perCh.(chstr).HoldTransHold=Hh-Th;
        perCh.(chstr).HoldTransMove=Hh-Tm;
        perCh.(chstr).MoveTransHold=Mm-Th;
        perCh.(chstr).MoveTransMove=Mm-Tm;
        perCh.(chstr).TransHoldTransMove=Th-Tm;
        perCh.(chstr).HoldIti=Hh-iti(:,:,ChSpk(jj));
        perCh.(chstr).MoveIti=Mm-iti(:,:,ChSpk(jj));
        perCh.(chstr).TransHoldIti=Th-iti(:,:,ChSpk(jj));
        perCh.(chstr).TransMoveIti=Tm-iti(:,:,ChSpk(jj));
        %set up for easy plotting
        HhMm=Hh-Mm;
        HhTh=Hh-Th;
        HhTm=Hh-Tm;
        MmTh=Mm-Th;
        MmTm=Mm-Tm;
        ThTm=Th-Tm;
        HhI=Hh-iti(:,:,ChSpk(jj));
        MmI=Mm-iti(:,:,ChSpk(jj));
        ThI=Th-iti(:,:,ChSpk(jj));
        TmI=Tm-iti(:,:,ChSpk(jj));
   
        idxC=1;
        chstr=['ch', num2str(ChSpk(jj))];
        figtitle=['Difference between epochs ', chstr, ' Heatmap ', ];
        figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
        set(gca,'FontSize', 22)
        sgtitle(figtitle)
        
        subplot(5,2,1)
        imagesc(tpDiffforPlot, fDiff, HhMm(:, specPlotIdx)); axis xy;
        title('Hold - Move')
        colorbar
        
        subplot(5,2,2)
        imagesc(tpDiffforPlot, fDiff, HhTh(:, specPlotIdx)); axis xy;
        title('Hold - Transition to hold')
        colorbar
        
        subplot(5,2,3)
        imagesc(tpDiffforPlot, fDiff, HhTm(:, specPlotIdx)); axis xy;
        title('Hold - Transition to move')
        colorbar
        
        subplot(5,2,4)
        imagesc(tpDiffforPlot, fDiff, MmTh(:, specPlotIdx)); axis xy;
        title('Move - Transition to hold')
        colorbar
        
        subplot(5,2,5)
        imagesc(tpDiffforPlot, fDiff, MmTm(:, specPlotIdx)); axis xy;
        title('Move - Transition to move')
        colorbar
        
        subplot(5,2,6)
        imagesc(tpDiffforPlot, fDiff, ThTm(:, specPlotIdx)); axis xy;
        title('Transition to hold - transition to move')
        colorbar
        
        subplot(5,2,7)
        imagesc(tpHold, fDiff, HhI(:, specPlotIdx)); axis xy;
        title('Hold - iti')
        colorbar
        
        subplot(5,2,8)
        imagesc(tpMove, fDiff, MmI(:, specPlotIdx)); axis xy;
        title('Move - iti')
        colorbar
        
        subplot(5,2,9)
        imagesc(tpTransMove, fDiff, TmI(:, specPlotIdx)); axis xy;
        title('Transition to Move - iti')
        colorbar
        
        subplot(5,2,10)
        imagesc(tpTransHold, fDiff, ThI(:, specPlotIdx)); axis xy;
        title('Transition to Hold - iti')
        colorbar
        
        figtitle=['Epochs ', chstr, ' Heatmap ', ];
        figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
        set(gca,'FontSize', 22)
        sgtitle(figtitle)
        
        subplot(2, 2 ,1)
        imagesc(tpHold, fDiff, Hh(:, specPlotIdx)); axis xy;
        title('Hold')
        colorbar
        
        subplot(2,2,2)
        imagesc(tpMove, fDiff, Mm(:, specPlotIdx)); axis xy;
        title('Move')
        colorbar
        
        subplot(2,2,3)
        imagesc(tpTransMove, fDiff, Tm(:, specPlotIdx)); axis xy;
        title('Transition to move')
        colorbar
        
        subplot(2,2,4)
        imagesc(tpTransHold, fDiff, Th(:, specPlotIdx)); axis xy;
        title('Transition to hold')
        colorbar
        
    end
end

%%
=======


%% to obtain the cursor position and the spike rates


%go through each channel and pull the spike data
for jj=1:length(ChSpk) %run through relevant channels
    for ii=1:length(moveSpk) %run through trials
        chMoveSpk{jj}(ii,:)=moveSmooth{ii}(ChSpk(jj),:);
        dataChTemp=moveData{ii}(ChSpk(jj),:);
        
        specTemp=Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(dataChTemp, fs, downSample), 'Spectrogram', Spectrogram);
        chMoveData{jj}(:,:,ii)=specTemp; %load a 3d matrix for time x freq x trial
        
    

    end
end






%% grab and process the LFP data
%add a rampup
for ii=1:2:length(timeHold)    
    HoldWindow(ii,1)=timeHold(ii,1)-fs*bufferT(1,1); %add a buffer window of time bufferT
    HoldWindow(ii+1,1)=timeHold(ii+1,1)+fs*bufferT(1,2); %add a buffer window of .5s
end
for ii=1:2:length(timeMove)
    MoveWindow(ii,1)=timeMove(ii,1)-fs*bufferT(1,1); %add a buffer window of .5s
    MoveWindow(ii+1,1)=timeMove(ii+1,1)+fs*bufferT(1,2); %add a buffer window of .5s
end

tt=tic;


%% downsample and process the data with either a spectrogram or bandpass
%set up a dummy bandfilter if using spectrogram
if Spectrogram
    bandfilter=1;
else
    bandfilter=[];
end
    
idx2=1;
for kk=1:2:size(HoldWindow,1)
    holdData{idx2}=double(data(:,HoldWindow(kk,1):HoldWindow(kk+1,1)));
    if isempty(bandfilter)
        [holdDataP{idx2}, params, bandfilter]=Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(holdData{idx2}, fs, downSample), 'Spectrogram', Spectrogram);
    else
        [holdDataP{idx2}, params]=Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(holdData{idx2}, fs, downSample), 'Spectrogram', Spectrogram, 'bandfilter', bandfilter);
        
        idx2=idx2+1;
    end
end

idx3=1;
for kk=1:2:size(MoveWindow,1)
    moveData{idx3}=double(data(:, MoveWindow(kk,1):MoveWindow(kk+1,1)));
    moveDataP{idx3}=Analysis.NPTL.dataPrep(Analysis.NPTL.downSample(moveData{idx3}, fs, downSample), 'Spectrogram', Spectrogram, 'bandfilter', bandfilter);
    
    idx3=idx3+1;
end
toc(tt);

% get the stepsize and start times
%THE DATA OUTPUT IS TIME X F X CH
if Spectrogram
    stepsz=params.win(1,2);
    st=epoch(1,2)/stepsz+.5/stepsz; %the starting point to take the epoch from. the .5 is the 0 mark, based on a .5s ramp up
else %for bandpasseed
    stepsz=1/downSample;
    st=epoch(1,2)*downSample+.5*downSample;
end

%% compare data
%create 3d structures broken up by channel (so {channel}.(freq x time x trial) and cut into epochs that
for ii=1:size(holdDataP,2) %trials
    for jj=1:size(holdDataP{1}.data,3)   %channels     
        holdDataPCut{jj}(:,:,ii)=holdDataP{ii}.data(:, st:(st+epoch(1,1)/stepsz),jj);
    end
end
for ii=1:size(holdDataP,2)
    for jj=1:size(holdDataP{1}.data,3)        
        moveDataPCut{jj}(:,:,ii)=moveDataP{ii}.data(:, st:(st+epoch(1,1)/stepsz),jj);
    end
end

for ii=1:size(holdDataPCut,2)
    [meanHold{ii}, meanMove{ii}, stdHold{ii}, stdMove{ii}, sigclust{ii}, rlab{ii}]=stats.cluster_permutation_Ttest_gpu3d(holdDataPCut{ii}, moveDataPCut{ii}); 
end

%% set up plotting
tCut=holdDataP{1}.tplot(st:(st+epoch(1,1)/stepsz))-0.5; %creates the time for plotting
f=holdDataP{1}.f;

%set up colors
C=linspecer(36);

%create the numbers for the grid
for jj=1:10
    tmp=[];
    tmp=[1:10];
    tmp=tmp+((jj-1)*10);
    gridlayout(jj,1:10)=tmp;    
end
gridlayout=gridlayout'-1;
gridlayout(11:end)=gridlayout(11:end)-1;
gridlayout(91:end)=gridlayout(91:end)-1;
gridlayout([1 10 91 100])=NaN;
gridlayout=fliplr(gridlayout);

 
% figure



if plotMean
    
    for ii=1:size(moveDataPCut,2)
        meanData=meanHold{ii}-meanMove{ii};
        
        figtitle=['Hold minus Move Channel ', num2str(ii), ' Heatmap ', ];
            figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
            subplot(3,2, [1 2 3 4])
            
            im=imagesc(tCut, f, meanData); axis xy;
            ax=gca;
            title(['Normalized Power '])
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            colormap(inferno(100));
            ax.YTick=(0:20:round(f(end)));
            
            % plot where on the array the electrode is NOT DONE
%             subplot(3,2,5)
%             for ii=1:100
%                 
%                 for ii=1:gridlayout
%                     text(1,1, num2str(gridlayout(ii)));
%                 end
%             end
%             box on
%             axis off

            %for color schemes
            %temp_p=double(sigclustDB');
            %temp_p(temp_p==0)=0.6;
            %temp_p(temp_p==1)=0.18;
            %temp_p(1,1)=0; temp_p(1,2)=1;
%             im=imagesc(tplot, f, rlab); axis xy;
%             ax=gca;
%             xlim([plot_buff(1) plot_buff(2)]); %only show the plot buffer pre and buffer post
%             title(['Pvalues Bonferroni ', ecog.evtNames{ff},' channel ',blc.ChannelInfo(ch(kk)).Label])
%             xlabel('Time (s)','Fontsize',13);
%             ylabel('Frequency (Hz)','Fontsize',13);
%             ax.YTick=(0:20:round(f(end)));
            
            
            %plot the sig clust
            subplot(3,2,6)
            temp_p=double(sigclust{ii});
            %temp_p(temp_p==0)=0.6;
            %temp_p(temp_p==1)=0.18;
            %temp_p(1,1)=0; temp_p(1,2)=1;
            im=imagesc(tCut, f, temp_p); axis xy;
            ax=gca;
            title(['Pvalues Cluster Permutation '])
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            ax.YTick=(0:20:round(f(end)));
    end
end
    


dataHoldMove=struct;
dataHoldMove.holdRaw=holdData;
dataHoldMove.holdProc=holdDataP;
dataHoldMove.holdProcCut=holdDataPCut;
dataHoldMove.moveRaw=moveData;
dataHoldMove.moveProc=moveDataP;
dataHoldMove.moveProcCut=moveDataPCut;
dataHoldMove.holdTime=HoldWindow;
dataHoldMove.moveTime=MoveWindow;
dataHoldMove.params=params;
dataHoldMove.tCut=tCut;
dataHoldMove.f=f;

>>>>>>> master



    


end

