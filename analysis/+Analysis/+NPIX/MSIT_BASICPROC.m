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
if maxReactionTime*1000 > postStim
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

%find the latest recroded unit
for ii = 1:length(unitSpikesCl)
    lastUnit(ii,1) = unitSpikesCl{ii}(end);   
end
lastRecording = max(lastUnit);

idx=1;
for ii = 1:length(unitSpikesCl)
    spikeRate(ii,1) = length(unitSpikesCl{ii})/lastRecording;  %units/second    
    if spikeRate(ii) > 0.5
        unitSpikesF{idx,1} = unitSpikesCl{ii};
        idx = idx+1;
    end
end

%% check if there is a last trial that doesn't have any spikes associated with it (or trials)
trialEndTime = taskData.trial_end_time(end);
for ii = 1:length(unitSpikesCl)
    lastSpikeTime(ii,1) = unitSpikesCl{ii,1}(end); 
end
lastlastSpikeTime = max(lastSpikeTime);
noSpikeTrial = find(taskData.trial_end_time>lastlastSpikeTime);
endTrials = noSpikeTrial(1)-1;
%% BREAK UP INTO TRIALS
% pull the spikes for each trial out with smoothed 
[spkITI,spkStimOn,spkResp] = Analysis.NPIX.parseTrials(unitSpikesF, taskData, 'shuffleFR', true, 'xshuffle', 100,...
    'endTrials', endTrials, 'interval', interval);



spkStimOn.spkTime(end+1) = 1750;

tt = spkStimOn.spkTime;

%this one just plots a single trial and a single raster to make sure they
%line up(they do as far as I can tell)
spikeId = 5;
for ii = 1:10
    figure
    subplot(2,1,1)
    plot(tt, spkStimOn.spkRateSm{spikeId}(ii,:))
    axis tight
    subplot(2,1,2)
    plt.raster_plot(spkStimOn.spk{spikeId}(ii,:), 'tm', tt, 'halfWidth', 0.4 )
end

%for plotting multiple units BUT NEEDS WORK
pltXxX = 3; 
idx1 = [1,2,3,7,8,9,13,14,15]; %top rows programmatically is 1:pltXxX, then that + pltXxX*2, then +pltXxX*4 until the end but i don't have time to codeit
idx2 = idx1+pltXxX;
for ii = 1:length(idx1)
    subplot(pltXxX*2,pltXxX,idx1(ii))
    spkMean = mean(spkStimOn.spkRateSm{ii}); 
    spkSD = std(spkStimOn.spkRateSm{ii});
    shadedErrorBar(tt, spkMean, spkSD);
    mygca(idx1(ii)) = gca;
    subplot(8,4,idx2(ii))
    plt.raster_plot(spkStimOn.spk{ii}, 'tm', spkStimOn.spkTime, 'halfWidth', 0.4 )
end

%for plotting any individual unit
ii = 108;
subplot(2,1,1)
spkMean = mean(spkStimOn.spkRateSm{ii});
spkSD = std(spkStimOn.spkRateSm{ii});
shadedErrorBar(tt(250:end-250), spkMean(250:end-250), spkSD(250:end-250));
subplot(2,1,2)
plt.raster_plot(spkStimOn.spk{ii}(:,(250:end-250)), 'tm', spkStimOn.spkTime(250:end-250), 'halfWidth', 0.4 )


if shuffleBaseline
    %need to make a shuffle baseline
end