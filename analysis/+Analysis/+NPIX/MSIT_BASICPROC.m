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

% TO DO: LABEL THE LOCATIONS OF EACH 
% PARSE BASED ON TRIAL TYPE

sigWindow = 30; %lenght of ms that the firing rate needs to be positive for to count it (probably 30-50ms)
qshuffles = 100; %number of shuffles to do for the tangling


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

%get the reaction time
behavioral.reactionTime = taskData.response_time-taskData.stimulus_time;
behavioral.mnRT = mean(reactionTime); %mean rt
behavioral.mnRT(:,2) = min(reactionTime); %range
behavioral.mnRT(:,3) = max(reactionTime);
if behavioral.mnRT(:,3)*1000 > interval.postStim
    warning('the window around stim does not include the longest reaction time')
end

%correct trials
behavioral.accuracy = sum(taskData.ResponseAccuracy)/length(taskData.ResponseAccuracy);

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
% {units}(trials x ms)
%THINGS TO DO, MAKE THIS FASTER. ALSO NEEDS TO BE RUN ONCE ONLY
[spkITI, spkStimOn, spkResp,...
    sigUnits, shuffleHist, itiEnd,...
    responseTime] = Analysis.NPIX.parseTrials(unitSpikesF,...
                    taskData, 'shuffleFR', false, 'xshuffle', 100,...
                    'endTrials', endTrials, 'interval', interval, 'firstSpikeTime',...
                    startSpikeTime, 'lastSpikeTime', finalSpikeTime);


%% break up into conditions
%for cong/incong, cell 1 is all, 2-4 are the different button presses (1,
%2, 3)
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

%% set up data for pca/tangling
tt = -interval.preStim:interval.postStim-1;

centerDataOn{1} = 1; %toggle on for stimOn
centerDataOn{2} = {'Image On'};

%run PCA separately because tangling will end up being the data
%
centerDataOn{1} = 1; %toggle on for stimOn
centerDataOn{2} = {'Image On'};
timeEval = [-250 1000]; %pick what time to actually plot, since the trials are pretty long
[PCAdataStimOn] = Analysis.BasicDataProc.suaPCA(spkStimOn, 'interval',  interval, 'centerDataOn', centerDataOn, 'tt', timeEval);
[PCAdata123StimOn, dataCond123StimOn] = Analysis.BasicDataProc.suaPCA(spkStimOn, 'interval', interval, 'centerDataOn', centerDataOn,'tt', timeEval, 'pcaRun', 2);

centerDataOn{1} = 2; %toggle on for stimOn
centerDataOn{2} = {'Response'};
timeEval = [-750 250]; %pick what time to actually plot, since the trials are pretty long
[PCAdataResp] = Analysis.BasicDataProc.suaPCA(spkResp, 'interval', interval, 'centerDataOn', centerDataOn);
[PCAdata123Resp, dataCond123Resp] = Analysis.BasicDataProc.suaPCA(spkResp, 'interval', interval, 'centerDataOn', centerDataOn, 'pcaRun', 2);

centerDataOn{1} = 3; %toggle on for stimOn
centerDataOn{2} = {'ITI'};
timeEval = [500 1500]; %pick what time to actually plot, since the trials are pretty long
[PCAdataITI] = Analysis.BasicDataProc.suaPCA(spkITI, 'interval', interval, 'centerDataOn', centerDataOn);
[PCAdata123ITI, dataCond123ITI] = Analysis.BasicDataProc.suaPCA(spkITI, 'interval', interval, 'centerDataOn', centerDataOn, 'pcaRun', 2);


%tangling. the pca doubles up here, (done in tangling and in pca above) but
%it's fast
[tangling.qCStimOn, outCStimOn] = tangleAnalysis(dataCond123StimOn(1:3), .001, 'softenNorm', 5 ); % for data collected at 1kHz
[tangling.qIStimOn, outIStimOn] = tangleAnalysis(dataCond123StimOn(4:6), .001, 'softenNorm', 5); % for data collected at 1kHz

[tangling.pctOverUnityStimOn, tangling.pStimOn] = formattedScatter(qC, qI, {'Q_Congruent','Q_Incongruent'});

[tangling.qCResp, outCResp] = tangleAnalysis(dataCond123SResp(1:3), .001, 'softenNorm', 5 ); % for data collected at 1kHz
[tangling.qIResp, outIResp] = tangleAnalysis(dataCond123Resp(4:6), .001, 'softenNorm', 5); % for data collected at 1kHz

[tangling.pctOverUnityResp, tangling.pResp] = formattedScatter(qC, qI, {'Q_Congruent','Q_Incongruent'});

[tangling.qCITI, outCITI] = tangleAnalysis(dataCond123ITI(1:3), .001, 'softenNorm', 5 ); % for data collected at 1kHz
[tangling.qIITI, outIITI] = tangleAnalysis(dataCond123ITI(4:6), .001, 'softenNorm', 5); % for data collected at 1kHz

[tangling.pctOverUnityITI, tangling.pITI] = formattedScatter(qC, qI, {'Q_Congruent','Q_Incongruent'});


%run an LDA on congruent vs incongruent

[acc.StimOn] = Analysis.BasicDataProc.suaLDA(spkStimOn);
[acc.Resp] = Analysis.BasicDataProc.suaLDA(spkResp);
[acc.ITI] = Analysis.BasicDataProc.suaLDA(spkITI);



% % tangling with shuffled tangles
% %congruent
% analyzett = 0:1499; %times to analyze the tangling between 
% 
% [Qsh] = Analysis.NPIX.shuffleTangling(spkStimOn, taskData, endTrials, 'tt', tt, 'analyzett', analyzett);

