function params = createTrialParams(user)

% get the var indices
conditionsToDistribute = {'nummodality','cuemodality','operators','answers'}; % fields that contain values to be distributed
numValuesPerCondition = cellfun(@(x)length(user.(x)),conditionsToDistribute); % number of elements in each field that need to be distributed
conditionsToBalance = cellfun(@lower,user.balance,'UniformOutput',false); % fields that should have balanced distribution
assert(all(ismember(conditionsToBalance,conditionsToDistribute)),'Balance conditions must be present in the set of conditions to distribute');
whetherToBalance = ismember(conditionsToDistribute,conditionsToBalance);
[nummodID,cuemodID,opID,ansID] = Task.Common.balanceTrials(whetherToBalance,numValuesPerCondition,user.numTrialsPerBalanceCondition);
numTrialsTotal = length(cuemodID);
catchID = Task.Common.addCatchTrials(whetherToBalance,numTrialsTotal,user.numCatchTrials,user.catchTrialSelectMode,nummodID,cuemodID,opID,ansID);

% determine arithmetic equations
num1 = cell(1,numTrialsTotal);
num2 = cell(1,numTrialsTotal);
answer = cell(1,numTrialsTotal);
prm = primes(max(user.answers));
for kk=1:numTrialsTotal
    
    % construct pairs of numbers and results of applying the operation
    [range1,range2] = ndgrid(user.numbers,user.numbers);
    vals = feval(user.operators{opID(kk)},range1(:),range2(:));
    
    % discard invalid pairs based on their answers
    idx = vals~=user.answers(ansID(kk));
    
    % avoid very simple problems: *1, /1
    if isequal(user.operators{opID(kk)},@times) && ~ismember(user.answers(ansID(kk)),[0 1]) && ~ismember(user.answers(ansID(kk)),prm)
        idx = idx | range1(:)==user.answers(ansID(kk)) | range2(:)==user.answers(ansID(kk));
    elseif isequal(user.operators{opID(kk)},@rdivide) && user.answers(ansID(kk))~=0 && ~ismember(user.answers(ansID(kk)),prm)
        if nnz(~idx)>1
            idx = idx | range1(:)==user.answers(ansID(kk)) | range2(:)==user.answers(ansID(kk));
        end
    end
    range1(idx) = [];
    range2(idx) = [];
    vals(idx) = [];
    
    % make sure there's something left to use
    assert(~isempty(vals),'Uh-oh (1) [op %s, ans %d]...',func2str(user.operators{opID(kk)}),user.answers(ansID(kk)));
    randidx = randperm(length(vals));
    num1{kk} = range1(randidx(1));
    num2{kk} = range2(randidx(1));
    answer{kk} = user.answers(ansID(kk));
end

% create array of structs (cell arrays args dealt across array)
params = struct(...
    'operator',user.operators(opID(:)'),...
    'cuemodality',user.cuemodality(cuemodID(:)'),...
    'nummodality',user.nummodality(nummodID(:)'),...
    'number1',num1(:)',...
    'number2',num2(:)',...
    'answer',answer(:)',...
    'catch',user.catch(catchID(:)'));