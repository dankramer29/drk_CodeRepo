function [trialidx,ntrials,args] = trialIndices(args,task,params,debugger)

% default all trials
trialidx = true(1,task.numTrials);

% check for minimum time violations
len = task.trialTimes(:,2);
idx = find(len<params.tm.min);
if ~isempty(idx)
    if length(idx)>1
        tstr = sprintf('Trials %s violate',util.vec2str(idx));
    else
        tstr = sprintf('Trial %d violates',idx);
    end
    debugger.log(sprintf('%s the minimum time policy of %.2f sec',tstr,params.tm.min),'warn');
    trialidx(idx) = false;
end

% check for user input overrides
if ~isempty(args)
    
    % trialidx - indicating which trials to read and which to skip
    trialidx = args{1};
    
    % should be logical; attempt to infer logical values if not
    if any(~islogical(trialidx))
        if any(isnan(trialidx))
            
            % trialidx has NaNs to indicate bad trials
            trialidx = ~isnan(trialidx);
        elseif all(ismember(trialidx,1:task.numTrials))
            
            % trialidx is a list of indices, skipping some
            orig = trialidx;
            trialidx = false(1,task.numTrials);
            trialidx(orig) = true;
        else
            
            % no other matches, issue warning and assume all trials kept
            debugger.log('trialidx did not match any processing schemes, so keeping all trials','warn');
            trialidx = true(1,task.numTrials);
        end
    end
    
    % remove from varargin
    args(1) = [];
end

% convert to numerical indexing
trialidx = find(trialidx);
ntrials = length(trialidx);