function report = validateOutput(taskFile,fwInfo)
report = {};

% make sure the output file(s) exists
assert(exist(taskFile,'file')==2,'Cannot find ''%s''',taskFile);
report{end+1} = sprintf('Found taskFile ''%s''',taskFile);

% load task data from the first task file
Block = load(taskFile);
report{end+1} = sprintf('Loaded taskFile ''%s''',taskFile);

% check presence of basic fields
assert(isfield(Block,'Data') && isstruct(Block.Data),'Missing Data struct from task file');
report{end+1} = sprintf('Found Data struct in task file');

assert(isfield(Block,'Options') && isstruct(Block.Options),'Missing Options struct from task file');
report{end+1} = sprintf('Found Options struct in task file');

assert(isfield(Block,'Predictor') && isstruct(Block.Predictor),'Missing Predictor struct from task file');
report{end+1} = sprintf('Found Predictor struct in task file');

assert(isfield(Block,'Task') && isstruct(Block.Task),'Missing Task struct from task file');
report{end+1} = sprintf('Found Task struct in task file');

assert(isfield(Block,'Runtime') && isstruct(Block.Runtime),'Missing Runtime struct from task file');
report{end+1} = sprintf('Found Runtime struct in task file');

assert(isfield(Block,'idString') && ischar(Block.idString),'Missing idString from task file');
report{end+1} = sprintf('Found idString in task file');

assert(isfield(Block.Runtime,'runString') && ischar(Block.Runtime.runString),'Missing runString from task file');
report{end+1} = sprintf('Found runString in task file');

% check that data buffers contain reasonable amounts of data
dataFields = {'frameId','neuralTime','computerTime','instantPeriod','prediction','state','target','features'};
for kk=1:length(dataFields)
    assert(any(size(Block.Data.(dataFields{kk}))==fwInfo.frameId),'Data field ''%s'' is the wrong size',dataFields{kk});
    report{end+1} = sprintf('Data field ''%s'' appears to be the right size',dataFields{kk});
end

% make sure timing wasn't too far off
assert(nnz(isnan(Block.Data.instantPeriod(2:end)))==0,'Framework instant period should not have NaNs after first index');
report{end+1} = sprintf('No unexpected NaNs in the Framework instantPeriod vector');

avgInstPd = mean(Block.Data.instantPeriod(2:end));
assert(avgInstPd <= 0.07,'Framework period is too long: mean value was %.2f',avgInstPd);
report{end+1} = sprintf('Average Framework period was %.2f',avgInstPd);
