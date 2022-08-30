function params = createTrialParams(user)

% values calculated to assist in balancing trials
subLetters = fieldnames(user.subs); subLetters = subLetters(:)';
subNumbers = struct2array(user.subs);
numSubs = length(subNumbers);
numSubsPerWord = user.numSubsPerWord;
numResponseTypes = length(user.responseTypes);
numTrials = user.numTrials;

% read in words
srcdir = fileparts(mfilename('fullpath'));
srcfile = fullfile(srcdir,user.wordFile);
assert(exist(srcfile,'file')==2,'Cannot locate source file ''%s''',user.wordFile);
fid = fopen(srcfile);
assert(fid>=0);
try
    words = textscan(fid,'%s','Delimiter','\n');
    words = words{1}(:)';
catch ME
    util.errorMessage(ME);
    fclose(fid);
end
fclose(fid);

% repeat words if needed to cover trials, with extra in case
N = 2*max(length(words),numTrials);
if length(words)<N
    words = repmat(words,1,ceil(N/length(words)));
end

% random word ordering
idx = randperm(length(words));
words = words(idx);

% create parameters
currWordIdx = 1;
switch user.balance
    case 'response_type'
        assert(rem(numTrials/numResponseTypes,numSubs)==0,'Must set number of trials to an integer multiple of the number of substitution pairs x the number of response types (%dx%d = %d)',numSubs,numResponseTypes,numSubs*numResponseTypes);
        numTrialsPerResponseType = numTrials/numResponseTypes;
        assert(numTrialsPerResponseType>=user.minTrialsPerCondition,'Not enough trials');
        
        % initialize trial parameters
        responseTypes = cell(1,numResponseTypes);
        wordsUse = cell(1,numResponseTypes);
        letters = cell(1,numResponseTypes);
        numbers = cell(1,numResponseTypes);
        
        % loop over conditions (response types)
        for kk=1:numResponseTypes
            
            % this is the condition for this set of trials
            responseTypes{kk} = arrayfun(@(x)user.responseTypes{kk},1:numTrialsPerResponseType,'UniformOutput',false);
            
            % words for this condition
            wordsUse{kk} = words(currWordIdx + (0:numTrialsPerResponseType-1));
            currWordIdx = currWordIdx + numTrialsPerResponseType;
            
            % evenly distribute letters/numbers
            letters{kk} = repmat(cellfun(@(x){x},subLetters(:)','UniformOutput',false),1,numTrialsPerResponseType/numSubs);
            numbers{kk} = repmat(arrayfun(@(x)x,subNumbers(:)','UniformOutput',false),1,numTrialsPerResponseType/numSubs);
        end
        
    case 'subs'
        assert(rem(numTrials/numSubs,numResponseTypes)==0,'Must set number of trials to an integer multiple of the number of substitution pairs x the number of response types (%dx%d = %d)',numSubs,numResponseTypes,numSubs*numResponseTypes);
        numTrialsPerSub = numTrials/numSubs;
        assert(numTrialsPerSub>=user.minTrialsPerCondition,'Not enough trials');
        
        % initialize cell arrays - one cell per condition
        responseTypes = cell(1,numSubs);
        wordsUse = cell(1,numSubs);
        letters = cell(1,numSubs);
        numbers = cell(1,numSubs);
        
        % loop over conditions (subs)
        for kk=1:numSubs
            
            % evenly distribute response types
            responseTypes{kk} = repmat(user.responseTypes(:)',1,numTrialsPerSub/numResponseTypes);
            
            % same letter/number substitution pair for this set of trials
            letters{kk} = arrayfun(@(x)subLetters(kk),1:numTrialsPerSub,'UniformOutput',false);
            numbers{kk} = arrayfun(@(x)subNumbers(kk),1:numTrialsPerSub,'UniformOutput',false);
            
            % words for this condition
            wordsUse{kk} = words(currWordIdx + (0:numTrialsPerSub-1));
            currWordIdx = currWordIdx + numTrialsPerSub;
        end
        
    case 'words'
        numTrialsPerWord = user.minTrialsPerCondition;
        numWords = numTrials/numTrialsPerWord;
        assert(numTrialsPerWord>=user.minTrialsPerCondition,'Not enough trials');
        assert(rem(numTrials/numWords,numResponseTypes)==0,'Must set number of trials to an integer multiple of the number of words x the number of response types (%dx%d = %d)',numWords,numResponseTypes,numWords*numResponseTypes);
        
        % initialize cell arrays - one cell per condition
        responseTypes = cell(1,numWords);
        wordsUse = cell(1,numWords);
        letters = cell(1,numWords);
        numbers = cell(1,numWords);
        
        % loop over conditions (words)
        for kk=1:numWords
            
            % evenly distribution response types
            responseTypes{kk} = repmat(user.responseTypes(:)',1,numTrialsPerWord/numResponseTypes);
            
            % same word for this set of trials
            wordsUse{kk} = arrayfun(@(x)words{currWordIdx},1:numTrialsPerWord,'UniformOutput',false);
            currWordIdx = currWordIdx + 1;
            
            % identify substitution pairs that will work for this word
            idx = find(ismember(subLetters(:),wordsUse{kk}{1}(:)));
            idx = repmat(idx(:)',1,ceil(numTrialsPerWord/length(idx)));
            idx = idx(1:numTrialsPerWord);
            letters{kk} = cellfun(@(x){x},subLetters(idx),'UniformOutput',false);
            numbers{kk} = arrayfun(@(x)x,subNumbers(idx),'UniformOutput',false);
        end
        
    otherwise
        error('Unknown balance option ''%s''',user.balance);
end
wordsUse = cat(2,wordsUse{:});
responseTypes = cat(2,responseTypes{:});
letters = cat(2,letters{:});
numbers = cat(2,numbers{:});

% construct l33t versions of words
l33t = cell(1,numTrials);
for nn=1:numTrials
    
    % make sure the word has the requested letters
    idx = ismember(letters{nn}(:),wordsUse{nn}(:));
    while ~all(idx)
        wordsUse{nn} = words{currWordIdx};
        currWordIdx = currWordIdx + 1;
        if currWordIdx>length(words),currWordIdx=1;end
        idx = ismember(letters{nn}(:),wordsUse{nn}(:));
    end
    assert(all(idx),'Failed to find a word with the requested letters');
    
    % construct l33t version of word
    l33t{nn} = wordsUse{nn};
    for ll=1:numSubsPerWord
        idx = find(l33t{nn}==letters{nn}{ll},1,'first');
        l33t{nn}(idx) = num2str(numbers{nn}(ll));
    end
end

% randomize trials
randIdx = randperm(numTrials);
wordsUse = wordsUse(randIdx);
l33t = l33t(randIdx);
responseTypes = responseTypes(randIdx);
letters = letters(randIdx);
numbers = numbers(randIdx);

% calculate correct response
responses = cell(1,numTrials);
for nn=1:numTrials
    switch lower(responseTypes{nn})
        case 'word'
            rsp = feval(user.wordTrialSuccessFcn,wordsUse{nn},l33t{nn},letters{nn},numbers{nn});
        case 'number'
            rsp = feval(user.numberTrialSuccessFcn,wordsUse{nn},l33t{nn},letters{nn},numbers{nn});
        case 'numberword'
            rsp = feval(user.numberwordTrialSuccessFcn,wordsUse{nn},l33t{nn},letters{nn},numbers{nn});
        otherwise
            error('Unknown response type ''%s''',responseTypes{nn});
    end
    responses{nn} = rsp;
end

% create array of structs (cell arrays args dealt across array)
params = struct(...
    'word',wordsUse(:)',...
    'l33t',l33t(:)',...
    'response_type',responseTypes(:)',...
    'letters',letters(:)',...
    'numbers',numbers(:)',...
    'response',responses(:)');