function varargout = balanceTrials(balance,numvals,trpercomb,equalid)
% BALANCEDTRIALS balance a set of conditions across trials
%
%   [ID1,ID2,...] = BALANCETRIALS(BAL,NUM,TRPERCOMB)
%   Compute a set of 1xN indices ID1, ID2, ..., IDXM to balance M trial
%   conditions across N trials. The outputs IDx contain indices into trial
%   condition sets. For example, a trial condition "color" with values
%   {'red','blue','cyan'} might lead to an output ID1 = [1 3 2 2 1 2 3 3 1]
%   with three trials per condition value, pseudorandomly interleaved over
%   N=9 trials).
%
%   To set up the balancing problem, indicate logically whether the M trial
%   conditions should be balanced (a 1xM logical vector, TRUE for balance 
%   and FALSE otherwise); provide the number of possible values for each of
%   the M conditions in NUMVALS (a 1xM numerical vector); and specify the
%   number of replicate trials each unique combination of conditions should
%   have in TRPERCOMB (a scalar numerical value).
%
%   The result is a set of M outputs ID1, ID2, ..., IDM (one per trial
%   condition) containing 1xN numerical indices (one per trial) into the
%   set of possible values for the corresponding condition. The output
%   order is the same as the input order (BAL and NUMVALS).

% make sure there's something to balance
assert(~isempty(balance)&&any(balance),'Balance cannot be empty and must contain at least one nonzero value (len %d, nnz %d)',length(balance),nnz(balance));

% set default for allowing equal IDs between conditions
if nargin<4||isempty(equalid),equalid=nan(length(balance));end

% get the indices for vars to be balanced
[idx_balanced,numTrialsTotal] = getBalancedVars(numvals(balance),trpercomb);

% get indices for remaining (unbalanced) vars
idx_unbalanced = getUnbalancedVars(numvals(~balance),numTrialsTotal);

% combine the IDs
numvars = length(balance);
idx = cell(1,numvars);
idx(balance) = idx_balanced;
idx(~balance) = idx_unbalanced;

% remove any entries which are disallowed by equal ID
for kk=1:length(idx)
    idx_allowed = equalid(kk,:);
    
    % if all combinations allowed, move on
    % only looking at subsequent combinations, since we've already
    % addressed all prior and (ASSUMPTION) the input matrix should be
    % symmetric about the diagonal
    if all(isnan(idx_allowed(kk:end,:))),continue;end
    
    % we know some are forced same or different
    idx_verify = find(~isnan(idx_allowed));
    for nn=idx_verify(:)'
        if idx_allowed(nn)==0 % CANNOT BE THE SAME
            idx_update = find(idx{kk}==idx{nn});
        elseif idx_allowed(nn)==1 % MUST BE THE SAME
            idx_update = find(idx{kk}~=idx{nn});
        else
            error('unknown value for idx_allowed, index %d',nn);
        end
        
        % action depends on whether either/both conditions are balanced
        if balance(kk) && balance(nn)
            
            % both are balanced
            if idx_allowed(nn)==1
                
                % must be the same
                idx{nn}(idx_update) = idx{kk}(idx_update);
            else
                
                % cannot be the same
                % since both balanced, removing these does not affect
                % balance. however, need to remove from ALL conditions
                % (we're removing trials globally)
                idx = cellfun(@(x)x(setdiff(1:length(x),idx_update)),idx,'UniformOutput',false);
            end
        else
            
            if balance(kk) || balance(nn)
                
                % to avoid re-writing all this code just to swap indices, use
                % dummy variables
                if balance(kk)
                    aa = kk;
                    bb = nn;
                else
                    aa = nn;
                    bb = kk;
                end
                
            else
                
                % we'll keep constant the condition that has fewer missing
                % conditions
                n_kk = histcounts(idx{kk}(setdiff(1:length(idx{kk}),idx_update)));
                n_nn = histcounts(idx{nn}(setdiff(1:length(idx{nn}),idx_update)));
                if sum(n_kk) < sum(n_nn)
                    aa = kk;
                    bb = nn;
                else
                    aa = nn;
                    bb = kk;
                end
            end
            
            % only aa is balanced: need to select new bb to match
            % count how many per condition already, and we'll prioritize
            % the conditions that have fewer presentations so far
            n = histcounts(idx{aa}(setdiff(1:length(idx{aa}),idx_update)));
            num_left_per_condition = numvals(aa) - n;
            for mm=1:length(idx_update)
                
                % find the first one left that has fewer presentations and
                % isn't equal to kk
                if idx_allowed(nn)==1 % MUST BE THE SAME
                    potential_value = idx{aa}(idx_update(mm));
                elseif idx_allowed(nn)==0 % CANNOT BE THE SAME
                    potential_value = find(num_left_per_condition>0);
                    potential_value = potential_value(potential_value~=idx{aa}(idx_update(mm)));
                    
                    % if none of those available, select one at random that
                    % isn't aa
                    if isempty(potential_value)
                        potential_value = randi(length(n),1);
                        while potential_value==idx{aa}(idx_update(mm))
                            potential_value = randi(length(n),1);
                        end
                    else
                        potential_value = potential_value(1);
                    end
                end
                
                % update this entry
                idx{bb}(idx_update(mm)) = potential_value;
                
                % update number left
                n = histcounts(idx{aa}(setdiff(1:length(idx{aa}),idx_update((mm+1):end))));
                num_left_per_condition = numvals(aa) - n;
            end
        end
    end
end
numTrialsTotal = unique(cellfun(@length,idx));
assert(nnz(numTrialsTotal)==1,'All conditions must have same number of trials');

% randomize trials
randIdx = randperm(numTrialsTotal);
idx = cellfun(@(x)x(randIdx),idx,'UniformOutput',false);
idx = cellfun(@(x)x(:),idx,'UniformOutput',false);

% assign outputs
varargout = idx;

function [idx,numTrialsTotal] = getBalancedVars(varnum,percond)
numvars = length(varnum);
idx = {};
numTrialsTotal = 0;
if numvars==0,return;end

% construct {id1(:)',id2(:)',...}
idx = arrayfun(@(x)1:varnum(x),1:numvars,'UniformOutput',false);

% overwrite with output of ndgrid
[idx{:}] = ndgrid(idx{:});

% repmat each set of idxs for num trials per condition
idx = cellfun(@(x)repmat(x(:),percond,1),idx,'UniformOutput',false);

% count total number of trials
numTrialsTotal = length(idx{1});

function idx = getUnbalancedVars(varnum,total)
numvars = length(varnum);
idx = {};
if numvars==0,return;end

% construct {id1(:)',id2(:)',...}
% note getVarIdx used to determine list of idxs
idx = arrayfun(@(x)getVarIdx(varnum(x),total),1:numvars,'UniformOutput',false);

% overwrite with output of ndgrid
[idx{:}] = ndgrid(idx{:});
idx = cellfun(@(x)x(:),idx,'UniformOutput',false);
idx = cellfun(@(x)x(randi(length(x),[1 total])),idx,'UniformOutput',false);

% repmat each set of IDs for (at least) the number of total trials
%ids = cellfun(@(x)repmat(x(:)',1,ceil(total/length(x(:)))),ids,'UniformOutput',false);

function idx = getVarIdx(numVar,numTotal)
% for convenience: if there are more possible values than total number of
% trials, then choose a "random" selection of values rather than just
% picking the first N values.
if numVar>numTotal
    idx = randperm(numVar,numTotal);
else
    idx = 1:numVar;
end