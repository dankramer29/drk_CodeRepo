function params = createTrialParams(user)

% values calculated to assist in balancing trials
assert(iscell(user.cue_types),'Cue types must be a cell array of strings');
assert(iscell(user.rsp_types),'Response types must be a cell array of strings');
numCueTypes = length(user.cue_types);
numRspTypes = length(user.rsp_types);
numTrials = user.numTrialsPerBalanceCondition;

% distribute cue types, response types, and numbers
% at the moment the only thing that causes any difference is the 'all',
% which will generate a lot of trials; number, cue and response all result
% in the same output.
if strcmpi(user.balance,'preface')
    
    % create a series of trials mainly geared to step through cue types
    % with random numbers - NOT randomized
    cueTypeID = 1:numCueTypes;
    rspTypeID = ones(1,numCueTypes);
    number = user.numbers( randperm(length(user.numbers),numCueTypes) );
    numTrialsTotal = numCueTypes;
else
    switch lower(user.balance)
        case 'all'
            cues = repmat(1:numCueTypes,numTrials,1);
            rsps = repmat(1:numRspTypes,numTrials,1);
            nums = repmat(user.numbers(:)',numTrials,1);
        case 'number'
            cues = 1:numCueTypes;
            rsps = 1:numRspTypes;
            nums = repmat(user.numbers(:)',numTrials,1);
        case 'cue'
            cues = repmat(1:numCueTypes,numTrials,1);
            rsps = 1:numRspTypes;
            nums = user.numbers;
        case 'response'
            cues = 1:numCueTypes;
            rsps = repmat(1:numRspTypes,numTrials,1);
            nums = user.numbers;
        otherwise
            error('Unknown balance option ''%s''',user.balance);
    end
    [cueTypeIDs,rspTypeIDs,numbers] = ndgrid(cues(:)',rsps(:)',nums(:)');
    number = numbers(:)';
    cueTypeID = cueTypeIDs(:)';
    rspTypeID = rspTypeIDs(:)';
    
    % randomize trials
    numTrialsTotal = length(number);
    randIdx = randperm(numTrialsTotal);
    number = number(randIdx);
    cueTypeID = cueTypeID(randIdx);
    rspTypeID = rspTypeID(randIdx);
end

% calculate correct response
responses = cell(1,numTrialsTotal);
for kk=1:numTrialsTotal
    num = number(kk);
    [~,~,fn] = Task.NumberLanguage.getResponseData(user.rsp_types{rspTypeID(kk)}{1},user.rsp_types{rspTypeID(kk)}{2});
    responses{kk} = feval(fn,user.numbers,num);
end

% add in position/size/color
position = cell(1,numTrialsTotal);
size = cell(1,numTrialsTotal);
color = cell(1,numTrialsTotal);
for kk=1:length(user.cue_types)
    [~,~,fn] = Task.NumberLanguage.getCueData(user.cue_types{kk}{1},user.cue_types{kk}{2});
    idx = ismember(cueTypeID,kk);
    [pos,sz,clr] = feval(fn,user,user.cue_types{kk},number(idx),user.cue_args{kk}{:});
    position(idx) = pos;
    size(idx) = sz;
    color(idx) = clr;
end

% add in type/subtype
cue_type = cellfun(@(x)x{1},user.cue_types(cueTypeID),'UniformOutput',false);
cue_subtype = cellfun(@(x)x{2},user.cue_types(cueTypeID),'UniformOutput',false);
rsp_type = cellfun(@(x)x{1},user.rsp_types(rspTypeID),'UniformOutput',false);
rsp_subtype = cellfun(@(x)x{2},user.rsp_types(rspTypeID),'UniformOutput',false);

% create array of structs (cell arrays args dealt across array)
params = struct(...
    'number',arrayfun(@(x)x,number,'UniformOutput',false),...
    'cue_type',cue_type,...
    'cue_subtype',cue_subtype,...
    'rsp_type',rsp_type,...
    'rsp_subtype',rsp_subtype,...
    'response',responses,...
    'position',position,...
    'size',size,...
    'color',color);