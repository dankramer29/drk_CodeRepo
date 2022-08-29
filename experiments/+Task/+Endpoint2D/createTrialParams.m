function params = createTrialParams(user)

% get the var indices
conditionsToDistribute = {'target_locations','state_modes'}; % fields that contain values to be distributed
numValuesPerCondition = cellfun(@(x)length(user.(x)),conditionsToDistribute); % number of elements in each field that need to be distributed
conditionsToBalance = cellfun(@lower,user.balance,'UniformOutput',false); % fields that should have balanced distribution
assert(all(ismember(conditionsToBalance,conditionsToDistribute)),'Balance conditions must be present in the set of conditions to distribute');
whetherToBalance = ismember(conditionsToDistribute,conditionsToBalance);
[tgtID,smID] = Task.Common.balanceTrials(whetherToBalance,numValuesPerCondition,user.numTrialsPerBalanceCondition);

% add inbound targets if requested
tgtloc = user.target_locations(tgtID(:));
modes = user.state_modes(smID(:));

% create array of structs (cell arrays args dealt across array)
params = struct(...
    'targetID',arrayfun(@(x)x,tgtID(:),'UniformOutput',false),...
    'targetLocation',tgtloc(:),...
    'stateMode',modes(:));