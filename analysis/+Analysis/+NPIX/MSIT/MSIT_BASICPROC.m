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

preStim = 750; %ms prior to stim on (includes a ramp to cut off for edge effects)
postStim = 1750; %ms post to stim on (includes a ramp to cut off for edge effects)
preITI = 250; %ms prior to iti on (includes a ramp to cut off for edge effects)
postITI = 2500; %ms prior to iti on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti
preResp = 250; %ms prior to iti on (includes a ramp to cut off for edge effects)
postResp = 2500; %ms prior to iti on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti


%load the patient data
subjectId = '004';
dataName = 'NPIX_MSIT_004.nwb';

%will load all of the data into unitDataCl and unitSpikesCl (meaning it
%removes the noise spikes) and task data in taskData
run Analysis.NPIX.NWB_NPIX_BASICPROC 

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

%create template rasters the size specified above
tempStimSize = zeros(length(taskData.Trial), preStim+postStim);
tempITISize = zeros(length(taskData.Trial), preITI+postITI);
tempRespSize = zeros(length(taskData.Trial), preResp+postResp);
%create cell array for each unit
spkStimOn{jj} = cell(length(unitSpikesCl),1);
spkITI{jj} = cell(length(unitSpikesCl),1);
spkResp{jj} = cell(length(unitSpikesCl),1);

for jj = 1:length(unitSpikesCl) 
    spkStimOn{jj} = tempStimSize;
    spkITI{jj} = tempITISize;
    spkResp{jj} = tempRespSize;
    for ii = 1:length(taskData.Trial)-1
        itiSt = taskData.fixaton_time(ii);
        itiEnd = taskData.fixaton_time(ii+1);
        stimSt = taskData.stimulus_time(ii);
        stimEnd = taskData.trial_end_time(ii);
        respSt = taskData.response_time(ii);
        %round is putting it into the closest ms (can have more fine
        %grained spike bins if necessary)
        epochSt = itiSt-(preITI/1000); epochEnd = itiSt + (postITI/1000);
        tempSpikeTimes = unitSpikesCl{jj}(unitSpikesCl{jj} >= epochSt & unitSpikesCl{jj} <= epochEnd); %find spikes in this window
        tempSpikeTimesConverted = round((tempSpikeTimes - epochSt)*1000); %convert to per trial time and ms to put a spike in the cell
        if ~isempty(tempSpikeTimesConverted)
            if tempSpikeTimesConverted(1) == 0; tempSpikeTimesConverted(1) = 1; end %if round puts a spike at 0 or after the trial, move it to 1 or end
            if tempSpikeTimesConverted(end) > preITI+postITI; tempSpikeTimesConverted(1) = preITI+postITI; end %if round puts a spike at 0 or after the trial, move it to 1 or end
            spkITI{jj}(ii, tempSpikeTimesConverted) = 1;
        end
        clear tempSpikeTimes; clear tempSpikeTimesConverted
        epochSt = stimSt-(preStim/1000); epochEnd = stimSt + (postStim/1000);
        tempSpikeTimes = unitSpikesCl{jj}(unitSpikesCl{jj} >= epochSt & unitSpikesCl{jj} <= epochEnd); %find spikes in this window
        tempSpikeTimesConverted = round((tempSpikeTimes - epochSt)*1000); %convert to per trial time and ms to put a spike in the cell
        if ~isempty(tempSpikeTimesConverted)
            if tempSpikeTimesConverted(1) == 0; tempSpikeTimesConverted(1) = 1; end %if round puts a spike at 0 or after the trial, move it to 1 or end
            if tempSpikeTimesConverted(end) > preStim+postStim; tempSpikeTimesConverted(1) = preStim+postStim; end %if round puts a spike at 0 or after the trial, move it to 1 or end
            spkStimOn{jj}(ii, tempSpikeTimesConverted) = 1;
        end
        clear tempSpikeTimes; clear tempSpikeTimesConverted
        epochSt = respSt-(preResp/1000); epochEnd = respSt + (postResp/1000);
        tempSpikeTimes = unitSpikesCl{jj}(unitSpikesCl{jj} >= epochSt & unitSpikesCl{jj} <= epochEnd); %find spikes in this window
        tempSpikeTimesConverted = round((tempSpikeTimes - epochSt)*1000); %convert to per trial time and ms to put a spike in the cel
        if ~isempty(tempSpikeTimesConverted)
            if tempSpikeTimesConverted(1) == 0; tempSpikeTimesConverted(1) = 1; end %if round puts a spike at 0 or after the trial, move it to 1 or end
            if tempSpikeTimesConverted(end) > preResp+postResp; tempSpikeTimesConverted(1) = preResp+postResp; end %if round puts a spike at 0 or after the trial, move it to 1 or end
            spkResp{jj}(ii, tempSpikeTimesConverted) = 1;
        end
      
    end
end
Analysis.NPIX.

Analysis.NPIX.npixMSIT_test(unitSpikesCl, taskData);

if shuffleBaseline
    %need to make a shuffle baseline
end