%%%%%%%
%% BASIC PROCESSING OF NPIX FILES 11/20/2025
% NOTE: this is called in the msit processing so don't need to call it
% separately.
%%%%%%%

% Condition = a conflict trial, 1 = a non conflict trial (xx3 or 100)
% Conflict = ???
% Correct = what the correct answer is supposed to be
% ISI = fixation cross time of the preceding ITI 
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


addpath(genpath('Z:\KramerEmotionID_2023\Data\NPIX'));

%load the patient data
% subjectId = '004';
% dataName = 'NPIX_MSIT_004.nwb';



%create the folder
folderName=strcat('Z:\KramerEmotionID_2023\Data\NPIX\MSIT\', subjectId, '\', dataName);


nwbObj = nwbRead(folderName);

nwbUnitProperties = properties(nwbObj.units);
nwbtaskProperties = properties(nwbObj.intervals_epochs);
nwbtrialProperties = properties(nwbObj.intervals_trials);

%cols = nwbObj.units.colnames; %get all column names
cols = nwbObj.intervals_trials.vectordata.keys; %get all the properties in the vectordata map
for i = 1:length(cols)
    field = cols{i};
    taskData.(field) = nwbObj.intervals_trials.vectordata.get(field).data.load();
end

%for data that does not load from the vectordata.keys (which can be in the
%object but not listed as a key, do the following:
% taskData.start_time = nwbObj.intervals_trials.start_time.data.load;
% taskData.stop_time = nwbObj.intervals_trials.stop_time.data.load;
%however, these are the same times listed as fixation time and trial end


%cols = nwbObj.units.colnames; %get all column names
cols = nwbObj.units.vectordata.keys; %get all the properties in the vectordata map
for i = 1:length(cols)
    field = cols{i};
    unitData.(field) = nwbObj.units.vectordata.get(field).data.load();
end


%grab just the units (doubled up above in the fie
spikeTimes = nwbObj.units.spike_times.data.load();         % All spike times concatenated
spikeIndex = nwbObj.units.spike_times_index.data.load();   % End indices for each unit meaning the point in the concat list above where each unit ends and the next starts
%convert to cell by units
nUnits = length(spikeIndex);
unitSpikes = cell(nUnits,1);

startIdx = 1;
for i = 1:nUnits
    endIdx = spikeIndex(i);
    unitSpikes{i} = spikeTimes(startIdx:endIdx);
    startIdx = endIdx + 1;
end

goodUnitTotal = sum(strcmp('good', unitData.label)); %number of good units
muaUnitTotal = sum(strcmp('mua', unitData.label)); %number of mua
noiseUnitTotal = sum(strcmp('noise', unitData.label)); %number of noise


%remove noise (currently lumping mua and good together) OF NOTE, THIS IS AN
%AUTOMATED CLEANING PROCESS AND NOT PERFECT. NEED TO BUILD IN A VISUAL
%INSPECTION?
idx1 = 1;
for ii = 1:length(unitData.label)
    if strcmp('noise', unitData.label{ii}) == 0
        unitSpikesCl{idx1,1} = unitSpikes{ii};
        for i = 2:length(cols)
            field = cols{i};
            unitDataCl.(field)(idx1,1) = unitData.(field)(ii); %store only the information for the non noise
        end
        idx1 = idx1+1;
    end
end