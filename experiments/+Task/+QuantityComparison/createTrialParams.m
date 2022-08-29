function params = createTrialParams(user)

% values calculated to assist in balancing trials
numValuesPerSymbol = cellfun(@(x)length(x{3}),user.symbol);
numQuadrants = length(user.quadrant);
numJustify = length(user.justify);
numPrompts = length(user.prompt);
numTrials = user.numTrialsPerBalanceCondition;

% distribute parameters
if strcmpi(user.balance,'preface')
    
    % create a series of trials for preface (instructions)
    quadID = 1:numSymbols;
    justID = ones(1,numPositions);
    numTrialsTotal = numSymbols;
else
    vals = 1:sum(numValuesPerSymbol);
    quad = 1:numQuadrants;
    just = 1:sum(numJustify);
    prom = 1:numPrompts;
    [valID,quadID,justID,promID] = ndgrid(vals(:)',quad(:)',just(:)',prom(:)');
    valID = repmat(valID(:)',1,numTrials);
    quadID = repmat(quadID(:)',1,numTrials);
    justID = repmat(justID(:)',1,numTrials);
    promID = repmat(promID(:)',1:numTrials);
    
    % randomize trials
    numTrialsTotal = length(justID);
    randIdx = randperm(numTrialsTotal);
    valID = valID(randIdx);
    quadID = quadID(randIdx);
    justID = justID(randIdx);
    promID = promID(randIdx);
end

% determine the prompt
prompt = user.prompt(promID);

% determine symbol, quantity, and value for each trial
symbolMatrix = arrayfun(@(x)x<=cumsum(numValuesPerSymbol),valID,'UniformOutput',false);
symbolMatrix = cellfun(@(x)find(x,1,'first'),symbolMatrix);
symbol = arrayfun(@(x)user.symbol{x}{1},symbolMatrix,'UniformOutput',false);
quantity = cell(1,numTrialsTotal);
for kk=1:length(user.symbol)
    quantity(symbolMatrix==kk) = arrayfun(@(x)user.symbol{kk}{2},1:nnz(symbolMatrix==kk),'UniformOutput',false);
end
allValues = cellfun(@(x)x{3}(:)',user.symbol,'UniformOutput',false);
allValues = cat(2,allValues{:});
answerValue = arrayfun(@(x)allValues(x),valID,'UniformOutput',false);

% make sure the value1 and prompt don't conflict (for example, with range
% 0..9, cannot use value1==0 and prompt==@lt)
for kk=1:numTrialsTotal
    valsKK = user.symbol{symbolMatrix(kk)}{3};
    midptKK = mean([max(valsKK) min(valsKK)]);
    switch lower(func2str(prompt{kk}))
        case 'gt'
            
            % if greater than, make sure first val is not max
            if answerValue{kk}<midptKK
                
                % if it is max, swap this value with another value not
                % associated with greater than, but still the same symbol
                symbolIdx = find(symbolMatrix==symbolMatrix(kk));
                idx = symbolIdx(randperm(length(symbolIdx)));
                idx = setdiff(idx,kk);
                for nn=idx(:)'
                    valsNN = user.symbol{symbolMatrix(nn)}{3};
                    midptNN = mean([max(valsNN) min(valsNN)]);
                    
                    % evaluate whether it's okay to bring the NNth value to
                    % the KKth index
                    okayNN2KK = answerValue{nn}>midptKK && ismember(answerValue{nn},valsKK);
                    if ~okayNN2KK,continue;end
                    
                    % evaluate whether it's okay to send the KKth value to
                    % the NNth index
                    switch lower(func2str(prompt{nn}))
                        case 'gt'
                            okayKK2NN = answerValue{kk}>midptNN && ismember(answerValue{kk},valsNN);
                        case 'lt'
                            okayKK2NN = answerValue{kk}<midptNN && ismember(answerValue{kk},valsNN);
                        otherwise
                            error('Unknown prompt ''%s''',func2str(prompt{nn}));
                    end
                    if ~okayKK2NN,continue;end
                    
                    % swap the values
                    tmp = answerValue{kk};
                    answerValue{kk} = answerValue{nn};
                    answerValue{nn} = tmp;
                    break;
                end
                assert(answerValue{kk}>midptKK,'Uh-oh...');
                if answerValue{kk}<=midptKK
                    keyboard
                end
            end
        case 'lt'
            
            % if less than, make sure first val is not max
            if answerValue{kk}>midptKK
                
                % if it is max, swap this value with another value not
                % associated with greater than, but still the same symbol
                symbolIdx = find(symbolMatrix==symbolMatrix(kk));
                idx = symbolIdx(randperm(length(symbolIdx)));
                idx = setdiff(idx,kk);
                for nn=idx(:)'
                    valsNN = user.symbol{symbolMatrix(nn)}{3};
                    midptNN = mean([max(valsNN) min(valsNN)]);
                    
                    % evaluate whether it's okay to bring the NNth value to
                    % the KKth index
                    okayNN2KK = answerValue{nn}<midptKK && ismember(answerValue{nn},valsKK);
                    if ~okayNN2KK,continue;end
                    
                    % evaluate whether it's okay to send the KKth value to
                    % the NNth index
                    switch lower(func2str(prompt{nn}))
                        case 'gt'
                            okayKK2NN = answerValue{kk}>midptNN && ismember(answerValue{kk},valsNN);
                        case 'lt'
                            okayKK2NN = answerValue{kk}<midptNN && ismember(answerValue{kk},valsNN);
                        otherwise
                            error('Unknown prompt ''%s''',func2str(prompt{nn}));
                    end
                    if ~okayKK2NN,continue;end
                    
                    % swap the values
                    tmp = answerValue{kk};
                    answerValue{kk} = answerValue{nn};
                    answerValue{nn} = tmp;
                    break;
                end
                if answerValue{kk}>=midptKK
                    keyboard
                end
                assert(answerValue{kk}<midptKK,'Uh-oh...');
            end
        otherwise
            error('Unknown prompt ''%s''',func2str(prompt{kk}));
    end
end

% going to choose value2 so that it mirrors the distance from the other end
% of the range of possible values of value1 (so small/large quantities will
% always be matched with equally large/small quantities).  will never get
% very large/small with medium large/small, but that's a conscious decision
% for now.
distractorValue = cell(1,numTrialsTotal);
for kk=1:length(answerValue)
    switch lower(func2str(prompt{kk}))
        case 'gt'
            distractorValue{kk} = min(user.symbol{symbolMatrix(kk)}{3}) + ( max(user.symbol{symbolMatrix(kk)}{3}) - answerValue{kk} );
        case 'lt'
            distractorValue{kk} = max(user.symbol{symbolMatrix(kk)}{3}) - ( answerValue{kk} - min(user.symbol{symbolMatrix(kk)}{3}) );
        case 'eq'
            distractorValue{kk} = answerValue{kk};
    end
    assert(ismember(distractorValue{kk},user.symbol{symbolMatrix(kk)}{3}),'Uh-oh...');
end

% determine the quadrant (of the answer) and justification within the quadrant
answerQuadrant = user.quadrant(quadID);
distractorQuadrant = cell(1,numTrialsTotal);
for kk=1:length(user.quadrant)
    idx = cellfun(@(x)strcmpi(x,user.quadrant{kk}),answerQuadrant);
    otherIdx = kk+1;
    if otherIdx>length(user.quadrant)
        otherIdx=1;
    end
    distractorQuadrant(idx) = arrayfun(@(x)user.quadrant{otherIdx},1:nnz(idx),'UniformOutput',false);
end
justify = user.justify(justID);

% determine response
responses = cell(1,length(user.quadrant));
for kk=1:length(user.quadrant)
    switch lower(user.quadrant{kk})
        case 'left',responses{kk}='LeftArrow';
        case 'right',responses{kk}='RightArrow';
        case 'top',responses{kk}='UpArrow';
        case 'bottom',responses{kk}='DownArrow';
        otherwise
            error('Unknown quadrant ''%s''',user.quadrant{kk});
    end
end

% create array of structs (cell arrays args dealt across array)
params = struct(...
    'symbol',symbol,...
    'quantity',quantity,...
    'answerValue',answerValue,...
    'answerQuadrant',answerQuadrant,...
    'distractorValue',distractorValue,...
    'distractorQuadrant',distractorQuadrant,...
    'prompt',prompt,...
    'justify',justify,...
    'response',responses(quadID));