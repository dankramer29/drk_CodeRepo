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

sigWindow = 30; %lenght of ms that the firing rate needs to be positive for to count it (probably 30-50ms)

interval.preStim = 750; %ms prior to stim on (includes a ramp to cut off for edge effects)
interval.postStim = 1750; %ms post to stim on (includes a ramp to cut off for edge effects)
interval.preITI = 250; %ms prior to iti on (includes a ramp to cut off for edge effects)
interval.postITI = 2500; %ms prior to iti on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti
interval.preResp = 250; %ms prior to iti on (includes a ramp to cut off for edge effects)
interval.postResp = 2500; %ms prior to iti on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti

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

%find the longest trial
trialLength = taskData.trial_end_time-taskData.fixaton_time;
longestTrial = max(trialLength);

%get the reaction time
reactionTime = taskData.response_time-taskData.stimulus_time;
maxReactionTime = max(reactionTime);
if maxReactionTime*1000 > interval.postStim
    warning('the window around stim does not include the longest reaction time')
end


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