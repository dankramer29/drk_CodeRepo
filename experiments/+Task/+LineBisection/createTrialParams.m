function params = createTrialParams(user)

% values calculated to assist in balancing trials
assert(iscell(user.symbolTypes)&&all(cellfun(@ischar,user.symbolTypes)),'Symbol types must be a cell array of strings');
assert(iscell(user.symbols)&&all(cellfun(@ischar,user.symbolTypes)),'Symbols must be a cell array of strings');
assert(length(user.symbols)==length(user.symbolTypes),'Must have one symbol type per symbol');
numLengths = length(user.lineLength);
numSymbols = length(user.symbols);
numPositions = length(user.bisectorPositions);
numTrials = user.numTrialsPerBalanceCondition;

% distribute parameters
if strcmpi(user.balance,'preface')
    
    % create a series of trials for preface (instructions)
    symID = 1:numSymbols;
    posID = ones(1,numPositions);
    numTrialsTotal = numSymbols;
else
    len = 1:numLengths;
    sym = 1:numSymbols;
    pos = 1:numPositions;
    [lenID,symID,posID] = ndgrid(len(:)',sym(:)',pos(:)');
    lenID = repmat(lenID(:)',1,numTrials);
    symID = repmat(symID(:)',1,numTrials);
    posID = repmat(posID(:)',1,numTrials);
    
    % randomize trials
    numTrialsTotal = length(lenID);
    randIdx = randperm(numTrialsTotal);
    lenID = lenID(randIdx);
    symID = symID(randIdx);
    posID = posID(randIdx);
end

% calculate correct response
responses = cell(1,numTrialsTotal);
for kk=1:numTrialsTotal
    if strcmpi(user.lineOrientation,'horizontal')
        
        % -1 -> left, +1 -> right
        if user.bisectorPositions(posID(kk))>0
            responses{kk} = 'RightArrow';
        elseif user.bisectorPositions(posID(kk))==0
            responses{kk} = 'UpArrow';
        elseif user.bisectorPositions(posID(kk))<0
            responses{kk} = 'LeftArrow';
        end
    elseif strcmpi(user.lineOrientation,'vertical')
        
        % -1 -> up, +1 -> down
        if user.bisectorPositions(posID(kk))>0
            responses{kk} = 'DownArrow';
        elseif user.bisectorPositions(posID(kk))==0
            responses{kk} = 'RightArrow';
        elseif user.bisectorPositions(posID(kk))<0
            responses{kk} = 'UpArrow';
        end
    else
        
        % -1 -> left, +1 -> right
        if user.bisectorPositions(posID(kk))>0
            responses{kk} = 'RightArrow';
        elseif user.bisectorPositions(posID(kk))==0
            responses{kk} = 'UpArrow';
        elseif user.bisectorPositions(posID(kk))<0
            responses{kk} = 'LeftArrow';
        end
    end
end

% calculate line positions, rotation, length
% position - a "normalized" value between -1 and 1 to indicate left/right
% or up/down shifts, with -1/1 being equivalent to the maximum possible
% shift (actual value to be calculated later)
linePosition = nan(2,numTrialsTotal);
switch user.linePosition{1}
    case 'fixed'
        linePosition(1,:) = zeros(1,numTrialsTotal);
    case 'random'
        linePosition(1,:) = 2*rand(1,numTrialsTotal)-1;
end
switch user.linePosition{2}
    case 'fixed'
        linePosition(2,:) = zeros(1,numTrialsTotal);
    case 'random'
        linePosition(2,:) = 2*rand(1,numTrialsTotal)-1;
end
linePosition = arrayfun(@(x)linePosition(:,x),1:numTrialsTotal,'UniformOutput',false);
lineOrientation = arrayfun(@(x)user.lineOrientation,1:numTrialsTotal,'UniformOutput',false);

% create array of structs (cell arrays args dealt across array)
params = struct(...
    'symbol',user.symbols(symID),...
    'symbolType',user.symbolTypes(symID),...
    'symbolSize',arrayfun(@(x)x,user.symbolSize(symID),'UniformOutput',false),...
    'bisectorPositionNorm',arrayfun(@(x)x,user.bisectorPositions(posID),'UniformOutput',false),...
    'linePositionNorm',linePosition,...
    'lineOrientation',lineOrientation,...
    'lineLength',arrayfun(@(x)x,user.lineLength(lenID),'UniformOutput',false),...
    'response',responses);