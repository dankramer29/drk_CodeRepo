function Parameters_StimParamSweep_Frequency(obj)
% This parameter set sweeps across all frequencies

% define which electrodes
taskdir = fileparts(mfilename('fullpath'));
csv_file = fullfile(taskdir,'activeSites.csv');
[~,~,obj.user.electrodeLabels] = xlsread(csv_file);
obj.user.electrodeNumbers = 1:numel(obj.user.electrodeLabels);
if strcmpi(env.get('type'),'PRODUCTION')
    gridMap = obj.hTask.hFramework.hNeuralSource.hGridMap{1,1};
    obj.user.electrodeID = cellfun(@(x)gridMap.ChannelInfo.RecordingChannel(strcmpi(x,gridMap.ChannelInfo.Label)),obj.user.electrodeLabels,'un',0);
else
    obj.user.electrodeID = arrayfun(@(x)x,obj.user.electrodeNumbers,'un',0);
end
% define stimulation parameters
obj.user.stimFrequencies = [50 100 150 200 250 300]; % possible frequencies in Hz
obj.user.stimAmplitudes = 1000; % possible amplitudes in uA
obj.user.stimPolarities = 1; % possible polarities (1 - cathodic, 0 = anodic first)
obj.user.stimPulses = 1; % number of stim pulses in waveform (1-255)
obj.user.stimPulseWidths = 160; % width of the first and second phase of stimulation in usec
obj.user.stimInterphases = 53; % inter-phase time in usec
obj.user.stimDurations = 100/1000; % duration of pulse train in sec
obj.user.numCatchTrials = 0; % 10% of trials should be catch trials => obj.user.numCatchTrials = 0.1;
obj.user.catchTrialSelectMode = 'global';
obj.user.balance = 'all';
obj.user.numBlockRep = 10;
obj.user.numTrialsPerBalanceCondition = obj.user.numBlockRep*numel(obj.user.electrodeLabels)*numel(obj.user.stimFrequencies); % number of trials for each balance condition
obj.user.conditionsToBalance = {'stimAmplitudes','stimPolarities','stimPulses','stimPulseWidths',...
    'stimInterphases','stimDurations'}; % fields that contain values to be balanced across trials
obj.user.conditionsToDistribute = {'stimAmplitudes','stimPolarities','stimPulses','stimPulseWidths',...
    'stimInterphases','stimDurations'}; % fields that contain values to be distributed
obj.user.allowedEqualIDs = nan(length(obj.user.conditionsToDistribute));

assert(isfield(obj.user,'conditionsToDistribute'),'Could not find field "conditionsToDistribute"');
assert(isfield(obj.user,'conditionsToBalance'),'Could not find field "conditionsToBalance"');
assert(isfield(obj.user,'allowedEqualIDs'),'Could not find field "allowedEqualIDs"');
assert(all(size(obj.user.allowedEqualIDs)==length(obj.user.conditionsToDistribute)),'Field "allowedEqualIDs" must be %dx%d matrix (pairwise entry per distribute condition)',length(obj.user.conditionsToDistribute),length(obj.user.conditionsToDistribute));
numValuesPerCondition = cellfun(@(x)length(obj.user.(x)),obj.user.conditionsToDistribute); % number of elements in each field that need to be distributed
assert(all(ismember(obj.user.conditionsToBalance,obj.user.conditionsToDistribute)),'Balance conditions must be present in the set of conditions to distribute');
obj.user.whetherToBalance = ismember(obj.user.conditionsToDistribute,obj.user.conditionsToBalance);
[obj.user.amplID,obj.user.polID,obj.user.pwID,obj.user.iphID,obj.user.durID] = Task.Common.balanceTrials(obj.user.whetherToBalance,numValuesPerCondition,obj.user.numTrialsPerBalanceCondition,obj.user.allowedEqualIDs);
obj.user.numParam = numel(obj.user.stimFrequencies);
freqInd = 1:obj.user.numParam;
obj.user.freqID = repmat(reshape(repmat(freqInd, numel(obj.user.electrodeLabels),1),[],1),obj.user.numBlockRep,1);

% load default settings
Task.StimParameterSweep.DefaultSettings(obj);

end