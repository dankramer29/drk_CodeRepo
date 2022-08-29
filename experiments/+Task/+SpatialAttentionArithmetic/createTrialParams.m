function params = createTrialParams(user)

% values calculated to assist in balancing trials
numOperators = length(user.operators);
numQuadrants = length(user.quadrants);
numFontSizes = length(user.fontsizes)^length(user.quadrants); % binary encoding - one state to indicate each quadrant having a particular font size
numJustify = length(user.justify); % want to make the justifications mirrored between quadrants (left <-> right, middle <-> middle, etc.)
numTrials = user.numTrialsPerBalanceCondition;

% distribute parameters
if strcmpi(user.balance,'preface')
    
    % create a series of trials for preface (instructions)
    quadID = 1:numSymbols;
    fszID = ones(1,numPositions);
    numTrialsTotal = numSymbols;
else
    op = 1:numOperators;
    quad = 1:numQuadrants;
    fsz = 1:numFontSizes;
    just = 1:numJustify;
    [opID,quadID,fszID,justID] = ndgrid(op(:)',quad(:)',fsz(:)',just(:)');
    opID = repmat(opID(:)',1,numTrials);
    quadID = repmat(quadID(:)',1,numTrials);
    justID = repmat(justID(:)',1,numTrials);
    fszID = repmat(fszID(:)',1,numTrials);
    
    % randomize trials
    numTrialsTotal = length(justID);
    randIdx = randperm(numTrialsTotal);
    opID = opID(randIdx);
    quadID = quadID(randIdx);
    justID = justID(randIdx);
    fszID = fszID(randIdx);
end

% permutations to calculate the distractor from the same numbers
ops = user.operators;
signs = [1 -1];
[idxOp,idxS1,idxS2] = ndgrid(1:length(ops),1:length(signs),1:length(signs));
idxOp = idxOp(:)';
idxS1 = idxS1(:)';
idxS2 = idxS2(:)';
fn = cell(1,length(idxOp));
for kk=1:length(idxOp)
    o = user.operators{idxOp(kk)};
    s1 = signs(idxS1(kk));
    s2 = signs(idxS2(kk));
    fn{kk} = @(x,y)feval(o,s1*x,s2*y);
end
clear o s1 s2;

% determine arithmetic operations, answers, and distractors
num1 = cell(1,numTrialsTotal);
num2 = cell(1,numTrialsTotal);
answer = cell(1,numTrialsTotal);
distractor = cell(1,numTrialsTotal);
for kk=1:numTrialsTotal
    
    % select the first number
    range1 = user.numbers;
    num1{kk} = range1(randi(length(range1),1));
    
    % which potential second numbers would give acceptable answers
    outcomes = feval(user.operators{opID(kk)},num1{kk},user.numbers);
    range2 = user.numbers;
    answers = user.answers;
    if isequal(user.operators{opID(kk)},@times) || isequal(user.operators{opID(kk)},@rdivide)
        answers = setdiff(answers,num1{kk}); % disallow *1, /1 to get same number
    end
    range2(~ismember(outcomes,answers)) = [];
    assert(~isempty(range2),'Uh-oh (1) ...');
    
    % select the second number
    num2{kk} = range2(randi(length(range2),1));
    
    % compute the correct answer
    answer{kk} = feval(user.operators{opID(kk)},num1{kk},num2{kk});
    
    % compute a similar but incorrect answer
    potentialDistractors = cellfun(@(x)feval(x,num1{kk},num2{kk}),fn);
    potentialDistractors(~ismember(potentialDistractors,user.answers)) = [];
    potentialDistractors(potentialDistractors==answer{kk}) = [];
    if isempty(potentialDistractors)
        range = setdiff(user.answers,answer{kk});
        distractor{kk} = range(randi(length(range),1));
    else
        whichPotentialAnswer = randi(length(potentialDistractors),1);
        distractor{kk} = potentialDistractors(whichPotentialAnswer);
    end
    assert(ismember(distractor{kk},user.answers),'Uh-oh (2) ...');
end

% determine the font sizes of each quadrant
qs = cell(1,length(user.quadrants));
ss = arrayfun(@(x)1:length(user.fontsizes),1:length(user.quadrants),'UniformOutput',false);
[qs{:}] = ndgrid(ss{:});
qs = cellfun(@(x)x(:),qs,'UniformOutput',false);
qs = [qs{:}];
quadrantFontSize = arrayfun(@(x)user.fontsizes(qs(x,:)),fszID,'UniformOutput',false);

% determine justification of each quadrant
quadrantJustify = user.justify(justID);

% determine response
responses = cell(1,length(user.quadrants));
for kk=1:length(user.quadrants)
    switch lower(user.quadrants{kk})
        case 'left',responses{kk}='LeftArrow';
        case 'right',responses{kk}='RightArrow';
        case 'top',responses{kk}='UpArrow';
        case 'bottom',responses{kk}='DownArrow';
        otherwise
            error('Unknown quadrant ''%s''',user.quadrants{kk});
    end
end

% create array of structs (cell arrays args dealt across array)
params = struct(...
    'operator',user.operators(opID),...
    'number1',num1,...
    'number2',num2,...
    'answer',answer,...
    'distractor',distractor,...
    'quadrant',user.quadrants(quadID),...
    'fontsize',quadrantFontSize,...
    'justify',quadrantJustify,...
    'response',responses(quadID));