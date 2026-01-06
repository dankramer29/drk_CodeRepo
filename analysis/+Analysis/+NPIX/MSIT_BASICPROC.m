%MSIT processing script


% Condition = a conflict trial, 1 = a non conflict trial (xx3 or 100)
% Conflict = ???
% Correct = what the correct answer is supposed to be
% ISI = fixation cross time of the preceding ITI (the clock is the same for spikes and task times and is in SECONDS not ms 
% ResponseAccuracy = if the correct answer is the same as what they pressed (so correct or not)
% ResponseKey = what they actually pressed
% ResponseUncertainty = ???
% Stimulation = ???
% Stimuli = the stimuli the patient saw
% Trial = trial number, 64 trial blocks
% fixation_time = start of the iti in ms
% responsetime = when they responded
% stimulus_time = when the stimulus appeared
% trial_end_time = when the trial ends and is fractions of a ms from when the next fixation time comes on.

%unitDataCl = spike metadata
%unitSpikesCl = spike times
%taskData = task data

% TO DO: LABEL THE LOCATIONS OF EACH UNIT

subjName = 'NPIX_MSIT_004'; %subject name

sigWindow = 30; %lenght of ms that the firing rate needs to be positive for to count it (probably 30-50ms)
qshuffles = 100; %number of shuffles to do for the tangling (100 is for speed, but can do 1000 or more and then save it once). Currently does not do a separate firing rate mean for congruent and incongruent, but shouldn't matter)


interval.preStim = 750; %ms prior to stim on (includes a ramp to cut off for edge effects)
interval.postStim = 1750; %ms post to stim on (includes a ramp to cut off for edge effects)
interval.preITI = 250; %ms prior to iti on (includes a ramp to cut off for edge effects)
interval.postITI = 2500; %ms post to iti on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti
interval.preResp = 1250; %ms prior to Response on (includes a ramp to cut off for edge effects)
interval.postResp = 750; %ms after Resonse on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti

%load the patient data
subjectId = '004';
dataName = 'NPIX_MSIT_004.nwb';

%will load all of the data into unitDataCl and unitSpikesCl (meaning it
%removes the noise spikes) and task data in taskData
run Analysis.NPIX.NWB_NPIX_BASICPROC.m

%choosing to do smoothing per trial with tails to cut off rather than
%smooth the whole thing and handle the time differences
%%
%trial parsing

%% behavioral information
%find the longest trial
trialLength = taskData.trial_end_time-taskData.fixaton_time;
longestTrial = max(trialLength);

%get the reaction time broken up by all, congruent and incongruent.
behavioral.reactionTime = taskData.response_time-taskData.stimulus_time;
behavioral.mnRT = mean(behavioral.reactionTime); %mean rt
behavioral.mnRT(:,2) = min(behavioral.reactionTime); %range
behavioral.mnRT(:,3) = max(behavioral.reactionTime);
behavioral.mnRT(:,4) = mean(behavioral.reactionTime(taskData.Condition == 1)); %congruent
behavioral.mnRT(:,5) = min(behavioral.reactionTime(taskData.Condition == 1));
behavioral.mnRT(:,6) = max(behavioral.reactionTime(taskData.Condition == 1));
behavioral.mnRT(:,7) = mean(behavioral.reactionTime(taskData.Condition == 2));%incongruent
behavioral.mnRT(:,8) = min(behavioral.reactionTime(taskData.Condition == 2));
behavioral.mnRT(:,9) = max(behavioral.reactionTime(taskData.Condition == 2));
if behavioral.mnRT(:,3)*1000 > interval.postStim
    warning('the window around stim does not include the longest reaction time')
end

%correct trials
behavioral.accuracy = sum(taskData.ResponseAccuracy)/length(taskData.ResponseAccuracy);
behavioral.accuracy(1,2) = sum(taskData.ResponseAccuracy(taskData.Condition == 1))/length(taskData.ResponseAccuracy);
%% GET BASIC SPIKE RATE DATA AND REMOVE LOW SPIKE RATE NEURONS
%evaluate the spike rate of each neuron and the mean spiking rate with SD
%to evaluate easiest rise above or below baseline. NOTE THIS ISN'T PERFECT,
%THE TRIAL STARTS AT 1 BUT I CAN'T TELL WHEN THE RECORDING ENDS, BUT STILL
%SHOULD BE FINE.
%TO DO: CALCULATE THE BASELINE, WILL REQUIRE TAKING THE MEAN ACROSS THE
%WHOLE RECORDING WHICH WILL REQUIRE GETTING ALL OF THE DATA INTO A MATRIX
%AND RUNNING THE SPIKE RATE SMOOTHING ON IT.


%% find the times that the recording starts.
% %if there is a period with no spikes for any unit and also a last trial that doesn't have any spikes associated with it (or trials)
trialEndTime = taskData.trial_end_time(end);
for ii = 1:length(unitSpikesCl)
    firstSpikeTime(ii,1) = unitSpikesCl{ii,1}(1); 
    lastSpikeTime(ii,1) = unitSpikesCl{ii,1}(end); 
end
startSpikeTime = min(firstSpikeTime);
finalSpikeTime = max(lastSpikeTime);
noSpikeTrial = find(taskData.trial_end_time>finalSpikeTime);
%find the trials that have no spikes:
endTrials = noSpikeTrial(1)-1;

idx=1; 
for ii = 1:length(unitSpikesCl)
    spikeRate(ii,1) = length(unitSpikesCl{ii})/(finalSpikeTime-startSpikeTime);  %units/second
    idx2 = 1;
    for jj = 1:round(finalSpikeTime-startSpikeTime)-1
        temp =find(unitSpikesCl{ii}>(startSpikeTime + jj) & unitSpikesCl{ii}<(startSpikeTime+jj+1));
        spikeRateMoving(ii,idx2) = length(temp); %records the spikes per second (so just spikes each second) to look for major spike drift
        idx2 = idx2+1;
        clear temp
    end
   
    if spikeRate(ii) > 0.5
        unitSpikesF{idx,1} = unitSpikesCl{ii};
        idx = idx+1;
    end
end
spikeRate(:,2) = mean(spikeRateMoving(:, 1:round(length(spikeRateMoving)/2)),2); %find the spike rate of 1st half to compare to second half
spikeRate(:,3) = mean(spikeRateMoving(:, round(length(spikeRateMoving)/2):end),2);




%% BREAK UP INTO TRIALS
% pull the spikes for each trial out with smoothed spike rates and it is
% {units}(trials x ms). The shuffled output is a series of shuffled means
% (currently set by xshuffle, that is just
% randomly chosen time points and then the mean across all "trials" and
% timepoints. if the actual mean crosses this threshold (97.5 or 2.5
% percentile) it would be considered positive. 
%THINGS TO DO, MAKE THIS FASTER. ALSO NEEDS TO BE RUN ONCE ONLY

%inputs:
%unitSpikesF = good units that pass the minimum threshold of firing rate
%(0.5Hz)
%taskData = output of the nwb above with taskData (Rex made this)
%shuffleFR = toggle on if you need to do a shuffle. you can do it 1000 or
%5000 times once and then keep that shuffle for this patient forever.
%Currently set at 100 for speed.
%xshuffle = number of shuffles
%endTrials = sometimes the recording stops before the trials end, so it
%just tells you which trial to stop evaluating on. this is probably only
%relevant for subject 004
%interval = the time you want to take on either side of the event
%startSpikeTime = the recording starts but the spikes don't always appear
%right away, this is so you don't try to take shuffles from before spikes
%appea, it is the first spike that shows up for any of the units.
%finalSpikeTime = same, but for the last spike.

%outputs:
%spkTime = the time window 
%spk = raster (done with nans), can convert back to 0s/1s if you want, just
%for easier plotting
%spkRateSm = smoothed with a gaussian kernel
%smMean = average of the smoothed data
%smSTD = standard deviation of the smoothed data
%posSection = logicals of when it crosses the shuffled boundary (mean)
%negSection = same but for when it crosses the lower shuffled boundary
%(mean)
%sigUnits = any units that cross the threshold for greater than 30 ms (can
%change within). column1 is positive, column2 is negative (most of them
%cross so it's kind of useless).
%shuffleHist = the histogram of the shuffled means for each unit

[spkITI, spkStimOn, spkResp,...
    sigUnits, shuffleHist, itiEnd,...
    responseTime] = Analysis.NPIX.parseTrials(unitSpikesF,...
                    taskData, 'shuffleFR', false, 'xshuffle', 100,...
                    'endTrials', endTrials, 'interval', interval, 'firstSpikeTime',...
                    startSpikeTime, 'lastSpikeTime', finalSpikeTime);


%% break up into conditions
%for cong/incong, cell 1 is all, 2-4 are the different button presses (1,
%2, 3). mean and SE (standard error) are self explanatory. The congSpk is
%just raster versions so you can plot and look at the rasters. 
[spkITI.cong, spkITI.incong, spkITI.congMean,...
    spkITI.incongMean, spkITI.congSE, spkITI.incongSE,...
    spkITI.congSpk, spkITI.incongSpk]...
    = Analysis.NPIX.conditionParsing(spkITI, taskData, endTrials);

[spkStimOn.cong, spkStimOn.incong, spkStimOn.congMean,...
    spkStimOn.incongMean, spkStimOn.congSE, spkStimOn.incongSE,...
    spkStimOn.congSpk, spkStimOn.incongSpk]...
    = Analysis.NPIX.conditionParsing(spkStimOn, taskData, endTrials);

[spkResp.cong, spkResp.incong, spkResp.congMean,...
    spkResp.incongMean, spkResp.congSE, spkResp.incongSE,...
    spkResp.congSpk, spkResp.incongSpk]...
    = Analysis.NPIX.conditionParsing(spkResp, taskData, endTrials);
%% PLOT
%FOR PLOTTING, OPEN UP PLOT_MSIT, WHICH IS A SCRIPT FOR PLOTTING LOTS OF
%UNITS AS WELL AS INDIVIDUAL UNITS.
edit Analysis.NPIX.PLOT_MSIT
%% set up data for pca/tangling
tt = -interval.preStim:interval.postStim-1;


%run PCA separately because tangling will end up being the data
%
centerDataOn{1} = 1; %toggle on for stimOn
centerDataOn{2} = {'Image On'};
timeEval = [-250 1000]; %pick what time to actually plot, since the trials are pretty long
[PCAdataStimOn] = Analysis.BasicDataProc.suaPCA(spkStimOn, 'interval',...
    interval, 'centerDataOn', centerDataOn, 'tt', timeEval);
[PCAdata123StimOn, dataCond123StimOn] = Analysis.BasicDataProc.suaPCA(spkStimOn,...
    'interval', interval, 'centerDataOn', centerDataOn,'tt', timeEval, 'pcaRun', 2);

centerDataOn{1} = 2; %toggle 2 for response
centerDataOn{2} = {'Response'};
timeEval = [-750 250]; %pick what time to actually plot, since the trials are pretty long
[PCAdataResp] = Analysis.BasicDataProc.suaPCA(spkResp, 'interval',...
    interval, 'centerDataOn', centerDataOn, 'tt', timeEval);
[PCAdata123Resp, dataCond123Resp] = Analysis.BasicDataProc.suaPCA(spkResp,...
    'interval', interval, 'centerDataOn', centerDataOn,'tt', timeEval, 'pcaRun', 2);

centerDataOn{1} = 3; %toggle 3 for iti
centerDataOn{2} = {'ITI'};
timeEval = [500 1500]; %pick what time to actually plot, since the pre/post stim are made long to include a lot
[PCAdataITI] = Analysis.BasicDataProc.suaPCA(spkITI, 'interval', interval,...
    'centerDataOn', centerDataOn, 'tt', timeEval);
[PCAdata123ITI, dataCond123ITI] = Analysis.BasicDataProc.suaPCA(spkITI,...
    'interval', interval, 'centerDataOn', centerDataOn, 'tt', timeEval, 'pcaRun', 2);


%tangling. the pca doubles up here, (done in tangling and in pca above) but
%it's fast
[tangling.qCStimOn, outCStimOn] = tangleAnalysis(dataCond123StimOn(1:3), .001, 'softenNorm', 1 ); % for data collected at 1kHz
[tangling.qIStimOn, outIStimOn] = tangleAnalysis(dataCond123StimOn(4:6), .001, 'softenNorm', 1); % for data collected at 1kHz

[tangling.pctOverUnityStimOn, tangling.pStimOn] = formattedScatter(tangling.qCStimOn, tangling.qIStimOn, {'Q Congruent','Q Incongruent'}, 'myTitle', 'Image On');

[tangling.qCResp, outCResp] = tangleAnalysis(dataCond123Resp(1:3), .001, 'softenNorm', 1 ); % for data collected at 1kHz
[tangling.qIResp, outIResp] = tangleAnalysis(dataCond123Resp(4:6), .001, 'softenNorm', 1); % for data collected at 1kHz

[tangling.pctOverUnityResp, tangling.pResp] = formattedScatter(tangling.qCResp, tangling.qIResp, {'Q Congruent','Q Incongruent'}, 'myTitle', 'Response');

[tangling.qCITI, outCITI] = tangleAnalysis(dataCond123ITI(1:3), .001, 'softenNorm', 1 ); % for data collected at 1kHz
[tangling.qIITI, outIITI] = tangleAnalysis(dataCond123ITI(4:6), .001, 'softenNorm', 1); % for data collected at 1kHz

[tangling.pctOverUnityITI, tangling.pITI] = formattedScatter(tangling.qCITI, tangling.qIITI, {'Q Congruent','Q Incongruent'},'myTitle', 'ITI');


%% run an LDA on congruent vs incongruent, and on each response (so answer is 1 vs 2 vs 3) for congruent vs incongruent.
pltLDA = true; %toggle on if you want to plot the LDAs.

colorTempTest = {'#2A2E74', '#C13979'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C1(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTempTest = {'#81CAD6', '#EDCD44', '#DC3E26'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C2(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
%% Stim centered
timeEval = [-250 1000]; %pick what time to actually plot, since the trials are pretty long
myTitle = 'Image On Congruent v Incongruent';
for jj = 1:length(spkStimOn.cong)
    spk1{jj,1} = spkStimOn.cong{jj,1};
    spk2{jj,1} = spkStimOn.incong{jj,1};
end
[acc.StimOnCongIncong] = Analysis.BasicDataProc.suaLDA(spk1, spk2, ...
    'plt', pltLDA, 'tt', timeEval, 'st', interval.preStim, 'myTitle', myTitle);

clear spk1 spk2

%--------------------------
myTitle = ['Image On', newline, 'Decoding Each Response during Congruent Condition v Incongruent Condition'];

for jj = 1:length(spkStimOn.cong) %congruent different responses
    spk1{jj,1} = spkStimOn.cong{jj,2};
    spk2{jj,1} = spkStimOn.cong{jj,3};
    spk3{jj,1} = spkStimOn.cong{jj,4};
end
[acc.StimOnCongXResp, ~, H1] = Analysis.BasicDataProc.suaLDA(spk1, spk2, 'spk3', spk3,...
    'plt', pltLDA, 'lineColor', C1(1,:), 'tt', timeEval, 'st', interval.preStim, 'myTitle', myTitle);

clear spk1 spk2 spk3

for jj = 1:length(spkStimOn.incong) %incongruent different responses
    spk1{jj,1} = spkStimOn.incong{jj,2};
    spk2{jj,1} = spkStimOn.incong{jj,3};
    spk3{jj,1} = spkStimOn.incong{jj,4};
end
[acc.StimOnIncongXResp, ~, H2] = Analysis.BasicDataProc.suaLDA(spk1, spk2, 'spk3', spk3,...
    'plt', pltLDA, 'multPlt', 1, 'lineColor', C1(2,:), 'tt', timeEval, 'st', interval.preStim, 'myTitle', myTitle);
legend([H1, H2], {'Congruent', 'Incongruent'})

clear spk1 spk2 spk3
%--------------------------------
%run it as each response compared cong vs incong (e.g Response 1 cong vs
%Response 1 incong)
myTitle = ['Image On', newline, 'Decoding Same Response Congruent v Incongruent'];
multPlt = 0;

for rr = 2:4
    for jj = 1:length(spkStimOn.incong) %CONG VS INCONG FOR A SINGLE RESPONSE.
        spk1{jj,1} = spkStimOn.cong{jj,rr};
        spk2{jj,1} = spkStimOn.incong{jj,rr};
    end
    if rr ~= 2
        multPlt = 1; %there is a weird double negative here, toggle off if the first plot and on if the subsequent plots
    end
    [acc.StimOnIncongXResp, ~, H{rr-1}] = Analysis.BasicDataProc.suaLDA(spk1, spk2,...
        'plt', pltLDA, 'multPlt', multPlt, 'tt', timeEval, 'st', interval.preStim,...
        'myTitle', myTitle, 'lineColor', C2(rr-1,:));

    clear spk1 spk2
end

legend([H{1}, H{2}, H{3}], {'Response 1'; 'Response 2'; 'Response 3'})


%% Response centered. 
ticT = tic;
timeEval = [-750 250]; %pick what time to actually plot, since the trials are pretty long
myTitle = 'Keypress Aligned Congruent v Incongruent';
for jj = 1:length(spkResp.cong)
    spk1{jj,1} = spkResp.cong{jj,1};
    spk2{jj,1} = spkResp.incong{jj,1};
end
[acc.Resp] = Analysis.BasicDataProc.suaLDA(spk1, spk2, 'tt', timeEval, 'st', interval.preResp, 'myTitle', myTitle);

clear spk1 spk2
%--------------------------------

%run the responses against each other with one line as congruent and one as
%incongruent
myTitle = ['Keypress Aligned', newline, 'Decoding Each Response during Congruent Condition v Incongruent Condition'];
for jj = 1:length(spkResp.cong) %congruent different responses
    spk1{jj,1} = spkResp.cong{jj,2};
    spk2{jj,1} = spkResp.cong{jj,3};
    spk3{jj,1} = spkResp.cong{jj,4};
end
[acc.RespCongXResp, ~, H1] = Analysis.BasicDataProc.suaLDA(spk1, spk2, 'spk3', spk3,...
    'plt', pltLDA, 'lineColor', C1(1,:), 'tt', timeEval, 'st', interval.preResp, 'myTitle', myTitle);

clear spk1 spk2 spk3

for jj = 1:length(spkResp.incong) %incongruent different responses
    spk1{jj,1} = spkResp.incong{jj,2};
    spk2{jj,1} = spkResp.incong{jj,3};
    spk3{jj,1} = spkResp.incong{jj,4};
end
[acc.RespIncongXResp, ~, H2] = Analysis.BasicDataProc.suaLDA(spk1, spk2, 'spk3', spk3,...
    'plt', pltLDA, 'multPlt', multPlt, 'lineColor', C1(2,:), 'tt', timeEval, 'st', interval.preResp, 'myTitle', myTitle);
legend([H1, H2], {'Congruent', 'Incongruent'})

%--------------------------------

%run it as each response compared cong vs incong (e.g Response 1 cong vs
%Response 1 incong)
myTitle = ['Keypress Aligned', newline, 'Decoding Same Response Congruent v Incongruent'];
multPlt = 0;

for rr = 2:4
    for jj = 1:length(spkResp.incong) %CONG VS INCONG FOR A SINGLE RESPONSE.
        spk1{jj,1} = spkResp.cong{jj,rr};
        spk2{jj,1} = spkResp.incong{jj,rr};
    end
    if rr ~= 2
        multPlt = 1; %there is a weird double negative here, toggle off if the first plot and on if the subsequent plots
    end
    [acc.RespIncongXResp, ~, H{rr-1}] = Analysis.BasicDataProc.suaLDA(spk1, spk2,...
        'plt', pltLDA, 'multPlt', multPlt, 'tt', timeEval, 'st', interval.preResp,...
        'myTitle', myTitle, 'lineColor', C2(rr-1,:));

    clear spk1 spk2
end

legend([H{1}, H{2}, H{3}], {'Response 1'; 'Response 2'; 'Response 3'})
toc(ticT)
%% ITI cntered
timeEval = [500 1500]; %pick what time to actually plot, since the trials are pretty long
myTitle = 'ITI Congruent v Incongruent';
for jj = 1:length(spkResp.cong)
    spk1{jj,1} = spkResp.cong{jj,1};
    spk2{jj,1} = spkResp.incong{jj,1};
end
[acc.ITI] = Analysis.BasicDataProc.suaLDA(spk1, spk2,...
    'plt', pltLDA, 'tt', timeEval, 'st', interval.preITI, 'myTitle', myTitle);

clear spk1 spk2

%----------------------------------
myTitle = ['ITI', newline, 'Decoding Each Response during Congruent Condition v Incongruent Condition'];
for jj = 1:length(spkResp.cong) %congruent different responses
    spk1{jj,1} = spkResp.cong{jj,2};
    spk2{jj,1} = spkResp.cong{jj,3};
    spk3{jj,1} = spkResp.cong{jj,4};
end
[acc.ITICongXResp, ~, H1] = Analysis.BasicDataProc.suaLDA(spk1, spk2, 'spk3', spk3,...
    'plt', pltLDA, 'lineColor', C1(1,:), 'tt', timeEval, 'st', interval.preITI, 'myTitle', myTitle);

clear spk1 spk2 spk3

for jj = 1:length(spkResp.incong) %congruent different responses
    spk1{jj,1} = spkResp.incong{jj,2};
    spk2{jj,1} = spkResp.incong{jj,3};
    spk3{jj,1} = spkResp.incong{jj,4};
end
[acc.ITIIncongXResp, ~, H2] = Analysis.BasicDataProc.suaLDA(spk1, spk2, 'spk3', spk3,...
    'plt', pltLDA, 'multPlt', true, 'lineColor', C1(2,:), 'tt', timeEval, 'st', interval.preITI, 'myTitle', myTitle);


legend([H1, H2], {'Congruent', 'Incongruent'})

clear spk1 spk2 spk3

%%
% % tangling with shuffled tangles THIS WORKS, BUT WAS ABANDONED FOR A
% DIFFERENT WAY TO RUN TANGLING.
% %congruent
% analyzett = 0:1499; %times to analyze the tangling between 
% 
% [Qsh] = Analysis.NPIX.shuffleTangling(spkStimOn, taskData, endTrials, 'tt', tt, 'analyzett', analyzett);

%% save the figures
savePlot = true;
if savePlot
    hh =  findobj('type','figure');
    nh = length(hh);
    plt.save_plots([13:nh], 'folderName', '\\SOM-NSG-R-AO1\DataMeta\KramerEmotionID_2023\Data\NPIX\MSIT\004', 'subjName', subjName, 'versionNum', '1');
end
% savePlot = true;
% if savePlot
%     hh =  findobj('type','figure'); 
%     nh = length(hh);
%     plt.save_plots([1:nh], 'folderName', '\\SOM-NSG-R-AO1\DataMeta\KramerEmotionID_2023\Data\NPIX\MSIT', 'subjName', subjName);
% end
% 


