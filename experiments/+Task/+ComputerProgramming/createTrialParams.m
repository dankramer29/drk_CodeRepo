function params = createTrialParams(user)

% get the var IDs
conditionsToDistribute = user.var_labels; % fields that contain values to be balanced
numValuesPerCondition = cellfun(@(x)length(user.(x)),conditionsToDistribute); % number of elements in each field that need to be balanced
conditionsToBalance = cellfun(@lower,user.balance,'UniformOutput',false); % fields that should have balanced distribution
assert(all(ismember(conditionsToBalance,cellfun(@lower,conditionsToDistribute,'UniformOutput',false))),'Balance conditions must be present in the set of conditions to distribute');
whetherToBalance = ismember(cellfun(@lower,conditionsToDistribute,'UniformOutput',false),conditionsToBalance);
balanceData = cell(1,length(conditionsToDistribute));
[balanceData{:}] = Task.Common.balanceTrials(whetherToBalance,numValuesPerCondition,user.numTrialsPerBalanceCondition);
numTrialsTotal = length(balanceData{1});

% identify correct response
idx_progidx = strcmpi(conditionsToDistribute,'program_idx');
idx_rspvar = strcmpi(conditionsToDistribute,'response_var');
answer = cell(numTrialsTotal,1);
for kk=1:numTrialsTotal
    taskdir = fileparts(mfilename('fullpath'));
    c = Task.ComputerProgramming.CodeRunner(fullfile(taskdir,user.programs{balanceData{idx_progidx}(kk)}));
    varlist = user.strrep_vars;
    varvals = cell(1,length(varlist));
    for nn=1:length(varlist)
        idx = strcmpi(conditionsToDistribute,varlist{nn});
        if ischar(user.(varlist{nn}){balanceData{idx}(kk)})
            varvals{nn} = user.(varlist{nn}){balanceData{idx}(kk)};
        else
            varvals{nn} = sprintf('%d',user.(varlist{nn}){balanceData{idx}(kk)});
        end
    end
    c.strrep(varlist,varvals);
    vr = c.run;
    assert(isfield(vr,user.response_var{balanceData{idx_rspvar}(kk)}),'Could not find requested response variable ''%s''',user.response_var{balanceData{idx_rspvar}(kk)});
    answer{kk} = vr.(user.response_var{balanceData{idx_rspvar}(kk)});
end

% create array of structs (cell arrays args dealt across array)
trialParams = cellfun(@(x,y)user.(x)(y),conditionsToDistribute(:)',balanceData(:)','UniformOutput',false);
trialParams = cellfun(@(x)x(:),trialParams,'UniformOutput',false);
conditionsToDistribute = [conditionsToDistribute {'answer'}];
trialParams = [trialParams {answer}];
structInputs = [conditionsToDistribute(:)'; trialParams(:)'];
params = struct(structInputs{:});