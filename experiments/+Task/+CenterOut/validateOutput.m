function report = validateOutput(taskFile,fwInfo)
report = {};

assert(exist(taskFile,'file')==2,'Task file ''%s'' does not exist',taskFile);
report{end+1} = sprintf('Task file ''%s'' exists',taskFile);

% load the task data
Block = load(taskFile);
report{end+1} = sprintf('Loaded taskFile ''%s''',taskFile);

% check presence of basic fields
assert(isfield(Block,'Task'),'Missing Task field from task file');
report{end+1} = sprintf('Task struct exists in task file');

assert(isfield(Block.Task,'TrialData')&&isstruct(Block.Task.TrialData),'Missing TrialData field from Task struct');
report{end+1} = sprintf('TrialData struct exists in Task struct');

assert(length(Block.Task.TrialData)==(fwInfo.nTrials),'TrialData has %d elements but expected %d',length(Block.Task.TrialData),fwInfo.nTrials);
report{end+1} = sprintf('TrialData contains the correct number of trials (%d)',fwInfo.nTrials);