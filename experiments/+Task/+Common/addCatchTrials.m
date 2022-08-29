function catchID = addCatchTrials(balance,numTrials,numCatch,selectMode,varargin)
% ADDCATCHTRIALS Distribute catch trials globally or within conditions
%
%   CATCHID = ADDCATCHTRIALS(BAL,NUMTRIALS,NUMCATCH);
%   Pseudorandomly distribute NUMCATCH catch trials across a set of
%   NUMTRIALS trials. NUMCATCH may be a floating point value in the range
%   (0.0,1.0) (i.e., between but excluding 0 and 1) in which case it will
%   be interpreted as a perentage of the total number of trials. Otherwise,
%   it will be interpreted as an absolute number of trials to distribute.
%
%   If NUMCATCH is scalar, CATCHID will comprise values 0 (not a catch
%   trial) and 1 (catch trial). If NUMCATCH is a 1xK vector, it will be
%   interpreted as meaning there are multiple catch conditions, inclusive
%   of the null condition, and each should be distributed. In this case,
%   CATCHID will comprise values 1-K (catch trial of the indicated
%   condition), and the sum of catch trials must equal the number of
%   trials (i.e., one catch assignment per trial).
%
%   CATCHID = ADDCATCHTRIALS(BAL,NUMTRIALS,NUMCATCH,SELECTMODE)
%   Optionally specify the mode to use when adding catch trials. The
%   default, 'global', pseudorandomly selects trials without knowledge of
%   the trial conditions' distribution over those trials. Specify
%   SELECTMODE of 'percomb' to indicate that a certain number of trials per
%   unique combination of balanced trial conditions should be assigned as
%   catch trials. If SELECTMODE is 'percomb', the set of trial conditions
%   must also be provided (i.e., the output from BALANCETRIALS; see below).
%
%   For 'percomb' selection, the same comments apply to NUMCATCH as stated
%   for selection mode of 'global', except that all calculations and
%   validations are performed for each set of trials per unique combination
%   instead of for the set of trials as a whole.
%
%   CATCHID = ADDCATCHTRIALS(BAL,NUMTRIALS,NUMCATCH,SELECTMODE,ID1,ID2,...)
%   Provide the set of conditions output by BALANCETRIALS. Only required
%   when SELECTMODE is 'percomb'; otherwise ignored.

% defaults
if nargin<3||isempty(selectMode),selectMode='global';end % default distribute catch trials without knowledge of balanced trial conditions

if strcmpi(selectMode,'global')
    
    % calculate how many total catch trials there should be
    % note that numCatch could be a vector, i.e., multiple catch conditions
    if all(numCatch>0) && all(numCatch<1)
        numCatch = round(numTrials*numCatch);
    end
    
    % validate number of catch trials
    if isscalar(numCatch)
        assert(sum(numCatch)<=numTrials,'Requested %d catch trials, but only %d total trials available',sum(numCatch),numTrials);
    else
        assert(sum(numCatch)==numTrials,'When numCatch is a vector, the sum of catch trials %d must equal the sum of trials %d',sum(numCatch),numTrials);
    end
    
    % pseudorandomly assign catch trials
    catchID = zeros(1,numTrials);
    idxCatch = randperm(numTrials);
    for kk=1:length(numCatch)
        catchID(idxCatch(1:numCatch(kk))) = kk;
        idxCatch(1:numCatch(kk)) = [];
    end
elseif strncmpi(selectMode,'percombination',7)
    
    % make sure the trial conditions have been provided
    assert(~isempty(varargin),'Must provide condition values in order to assign catch trials per unique combination of catch trials');
    
    % find the unique set of balanced trial conditions
    balancedConditions = varargin(balance);
    balancedConditions = cat(2,balancedConditions{:});
    uniqueCombinations = unique(balancedConditions,'rows');
    
    % loop over each condition, find the corresponding indices, and assign some
    % to catch trials
    catchID = zeros(1,numTrials);
    for nn=1:size(uniqueCombinations,1)
        
        % find the trials for this combination of balanced conditions
        idxCombination = find(ismember(balancedConditions,uniqueCombinations(nn,:),'rows'));
        numCombinationTrials = length(idxCombination);
        
        % calculate how many catch trials there should be for this
        % combination; note that numCatch could be a vector, i.e., multiple
        % catch conditions
        if all(numCatch>0) && all(numCatch<1)
            numCombinationCatch = round(numCombinationTrials*numCatch);
        else
            numCombinationCatch = numCatch;
        end
        
        % validate number of catch trials
        if isscalar(numCombinationCatch)
            assert(sum(numCombinationCatch)<=numCombinationTrials,'Requested %d catch trials, but only %d total trials available',sum(numCombinationCatch),numCombinationTrials);
        else
            assert(sum(numCombinationCatch)==numCombinationTrials,'When numCatch is a vector, the sum of catch trials %d must equal the sum of trials %d',sum(numCombinationCatch),numCombinationTrials);
        end
        
        % pseudorandomly select a subset of these to assign as catch trials
        idxCatch = randperm(numCombinationTrials);
        for kk=1:length(numCombinationCatch)
            catchID(idxCombination(idxCatch(1:numCombinationCatch(kk)))) = kk;
            idxCatch(1:numCombinationCatch(kk)) = [];
        end
    end
else
    error('Unknown value of selectMode, ''%s''',selectMode);
end