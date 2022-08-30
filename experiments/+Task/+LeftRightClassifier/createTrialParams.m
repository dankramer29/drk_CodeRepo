function [params] = createTrialParams(user)

% get the var indices
assert(isfield(user,'conditionsToDistribute'),'Could not find field "conditionsToDistribute"');
assert(isfield(user,'conditionsToBalance'),'Could not find field "conditionsToBalance"');
assert(isfield(user,'allowedEqualIDs'),'Could not find field "allowedEqualIDs"');
assert(all(size(user.allowedEqualIDs)==length(user.conditionsToDistribute)),'Field "allowedEqualIDs" must be %dx%d matrix (pairwise entry per distribute condition)',length(user.conditionsToDistribute),length(user.conditionsToDistribute));
numValuesPerCondition = cellfun(@(x)length(user.(x)),user.conditionsToDistribute); % number of elements in each field that need to be distributed
assert(all(ismember(user.conditionsToBalance,user.conditionsToDistribute)),'Balance conditions must be present in the set of conditions to distribute');
whetherToBalance = ismember(user.conditionsToDistribute,user.conditionsToBalance);
[wrdID,clrID,cmodID,rmodID,cngID] = Task.Common.balanceTrials(whetherToBalance,numValuesPerCondition,user.numTrialsPerBalanceCondition,user.allowedEqualIDs);
numTrialsTotal = length(wrdID);
catchID = Task.Common.addCatchTrials(whetherToBalance,numTrialsTotal,user.numCatchTrials,user.catchTrialSelectMode,wrdID,clrID,cmodID,rmodID,cngID);

% determine response
answer = cell(1,numTrialsTotal);
rgb = cell(1,numTrialsTotal);
blockPosition = cell(1,numTrialsTotal);
ansID = nan(numTrialsTotal,1);
warning('below code assumes cue_words and cue_blocks are the same list!');
for kk=1:numTrialsTotal
    
    % identify the correct response
    % force congruent if necessary
    % (this means that it would be difficult to balance blocks and words
    % simultaneously if also balancing congruency)
    switch lower(user.response_modality{rmodID(kk)})
        case 'text'
            if strcmpi(user.cue_congruency{cngID(kk)},'congruent')
                clrID(kk) = wrdID(kk);
            end
            ansID(kk) = wrdID(kk);
            answer{kk} = user.cue_words{ansID(kk)};
        case 'block'
            if strcmpi(user.cue_congruency{cngID(kk)},'congruent')
                wrdID(kk) = clrID(kk);
            end
            ansID(kk) = clrID(kk);
            answer{kk} = user.cue_blocks{ansID(kk)};
        otherwise
            error('Unknown response modality "%s"',user.response_modality{rmodID(kk)});
    end
    
    % identify the rgb values to use for the block
    idx = strcmpi(user.block_names,user.cue_blocks{clrID(kk)});
    assert(nnz(idx)==1,'Could not identify single match for block "%s"',user.cue_blocks{clrID(kk)});
    rgb{kk} = user.block_rgb{idx};
    
    set(0,'Units','pixels');
    sz = get(0,'MonitorPositions');
    if strcmpi(user.cue_words{wrdID(kk)},'Left')
        blockPosition{kk} = [sz(6)-sz(6) sz(8)-(sz(8)/2)]; % Display block on left side
    else
        blockPosition{kk} = [sz(6) sz(8)-(sz(8)/2)]; % Display block on right side
    end
end

% create array of structs (cell arrays args dealt across array)
params = struct(...
    'cue_word',user.cue_words(wrdID(:)'),...
    'cue_block',user.cue_blocks(clrID(:)'),...
    'cue_rgb',rgb(:)',...
    'cue_modality',user.cue_modality(cmodID(:)'),...
    'response_modality',user.response_modality(rmodID(:)'),...
    'answer',answer(:)',...
    'catch',arrayfun(@(x)logical(x),catchID(:)','UniformOutput',false),...
    'blockPosition',blockPosition(:)');

%{
switch lower(this.cTrialParams.cue_words)
    case 'left'
        user.blockPosition = [sz(6)-sz(6) sz(8)-(sz(8)/2)]; % Display block on left side
    case 'right'
        user.blockPosition = [sz(6) sz(8)-(sz(8)/2)]; % Display block on right side
    otherwise
        error('Unknown block side "%s"',this.cTrialParams.response_modality);
end
%}

