function blocks = getProcwinNEVBlocks(nv,procwin,varargin)
% GETPROCWINNEVBLOCKS Identify recording blocks associated with procwins
%
% SUMMARY:
% bad trials are those for which the start time matches multiple recording
% blocks due to a clock reset. here we make an assumption that bad trials
% will be clustered at the beginning and/or the end of the trials:
%
%   (*) if a clock reset occurs after the trials have finished but before
%       data stopped recording, then early trials' near-0 start times will
%       match multiple recording blocks
%
%   (*) if a clock reset occurs during the trial run, then early and late
%       trials will have conflicting start times and both will match
%       multiple recording blocks
%
% so long as there is a contiguous block of single-block start times in
% the middle of the trials, we can use that information to infer which
% block should be used for the early and late trials matching multiple
% blocks.

% interpret column 2 of procwin as either length or end time
idx = strcmpi(varargin,'col2mode');
col2mode = 'length';
if any(idx)
    col2mode = varargin{circshift(idx,1,2)};
    varargin(idx|circshift(idx,1,2)) = [];
end

% check for samples or seconds
idx = strcmpi(varargin,'units');
units = 'time';
if any(idx)
    units = varargin{circshift(idx,1,2)};
    varargin(idx|circshift(idx,1,2)) = [];
end
assert(isempty(varargin),'unexpected inputs');

% process procwin
numArrays = length(nv);
if iscell(procwin)
    assert(length(procwin)==length(nv),'Must provide same number of procwin cells as ns cells');
else
    procwin = arrayfun(@(x)procwin,1:numArrays,'UniformOutput',false);
end

% check whether procwin cells contain matrices or cell arrays
if all(cellfun(@(x)iscell(x),procwin))
    procwin = cellfun(@(x)cat(1,x{:}),procwin,'UniformOutput',false);
end

% choose block id fcn based on units
assert(ischar(units),'must provide units as char, not ''%s''',class(units));
if any(strcmpi(units,{'time','times','second','seconds','sec'}))
    fn = @getBlocksContainingTimeWindow;
elseif any(strcmpi(units,{'sample','samples'}))
    fn = @getBlocksContainingSampleWindow;
else
    error('unknown units ''%s''',units);
end

% check whether we can localize each trial to a single recording blocks
blocks = cell(1,numArrays);
for kk=1:numArrays
    numTrials = size(procwin{kk},1);

    st = procwin{kk}(:,1);
    if strcmpi(col2mode,'length')
        et = procwin{kk}(:,1)+procwin{kk}(:,2);
    elseif strcmpi(col2mode,'endtime')
        et = procwin{kk}(:,2);
    end
    [~,startBlocks,endBlocks] = arrayfun(@(x)fn(nv{kk},st(x),et(x)),1:numTrials,'UniformOutput',false);
    startNum = cellfun(@(y)length(y(~isnan(y))),startBlocks);
    
    % identify blocks of the good trials
    if all(startNum==0)
        endNum = cellfun(@(y)length(y(~isnan(y))),endBlocks);
        if any(endNum~=0)
            
            % in a last ditch effort, make an assumption that the end block
            % might have the data we need
            startBlocks = {nan}; %endBlocks;
        else
            
            % out of luck, set to nan and continue
            blocks{kk} = nan;
            continue;
        end
    end
    
    % process start blocks/nums
    startBlocks = procBlockNum(startBlocks,startNum);
    assert(all(cellfun(@length,startBlocks)==1),'start blocks still contain multiple entries');
    
    % if no end blocks, just use start blocks and return
    if isempty(endBlocks)
        blocks{kk} = startBlocks;
    else
        
        % process end blocks/nums
        endNum = cellfun(@(y)length(y(~isnan(y))),endBlocks);
        endBlocks = procBlockNum(endBlocks,endNum);
        assert(all(cellfun(@length,endBlocks)==1),'end blocks still contain multiple entries');
        
        % combine start/end blocks into single list of blocks per procwin
        blocks{kk} = cell(1,numTrials);
        for bb=1:numTrials
            if isnan(startBlocks{bb}) && isnan(endBlocks{bb})
                blocks{kk}{bb} = nan;
            elseif isnan(startBlocks{bb})
                blocks{kk}{bb} = [nan endBlocks{bb}];
            elseif isnan(endBlocks{bb})
                blocks{kk}{bb} = [startBlocks{bb} nan];
            else
                blocks{kk}{bb} = startBlocks{bb}:endBlocks{bb};
            end
        end
    end
end



function blocks = procBlockNum(blocks,num)
numTrials = length(blocks);

% use information about future or past trials to infer the correct block
% for the current trial, if multiple blocks match
for bb=1:numTrials
    
    % two cases we want to correct: (1) multiple matching blocks, and we
    % need to decide which of these multiples is correct; (2) a middle
    % trial gets assigned the incorrect block, and we want to replce it
    % with the block assigned to the previous/next trials
    if ~isscalar(blocks{bb}) || isnan(blocks{bb})
        
        % check whether there are valid (i.e., single) blocks before/after
        if any(num(bb+1:end)==1)
            blockNextValid = blocks{bb+find(num(bb+1:end)==1,1,'first')};
        else
            blockNextValid = nan;
        end
        if any(num(1:bb-1)==1)
            blockPrevValid = blocks{find(num(1:bb-1)==1,1,'last')};
        else
            blockPrevValid = nan;
        end
        
        % replace the multiple blocks with single blocks depending on
        % configuration of preceding/following blocks
        if isnan(blockPrevValid) && isnan(blockNextValid)
            
            % no prior or following single blocks, so nothing we can do!
            blocks{bb} = nan; % DONT KNOW
        elseif isnan(blockPrevValid)
            
            % there is no preceding, but there is a following; replace if it is
            % one of the already matching blocks, otherwise nothing we can do
            if ismember(blockNextValid,blocks{bb}) || isnan(blocks{bb})
                blocks{bb} = blockNextValid;
            else
                blocks{bb} = nan; % DONT KNOW
            end
        elseif isnan(blockNextValid)
            
            % there is no following, but there is a preceding; replace if it is
            % one of the already matching blocks, otherwise nothing we can do
            if ismember(blockPrevValid,blocks{bb}) || isnan(blocks{bb})
                blocks{bb} = blockPrevValid;
            else
                blocks{bb} = nan; % DONT KNOW
            end
        else
            
            % both preceding and following trials have single matching blocks
            if (ismember(blockPrevValid,blocks{bb}) && ismember(blockNextValid,blocks{bb})) || all(isnan(blocks{bb}))
                
                % if they are the same blocks, all good and replace; otherwise
                % don't know what to do
                if blockPrevValid==blockNextValid
                    blocks{bb} = blockPrevValid;
                else
                    blocks{bb} = nan; % DONT KNOW
                end
            elseif ismember(blockPrevValid,blocks{bb})
                
                % only the previous single blocks matches
                blocks{bb} = blockPrevValid;
            elseif ismember(blockNextValid,blocks{bb})
                
                % only the following single blocks matches
                blocks{bb} = blockNextValid;
            else
                
                % neither the previous nor the following single blocks matches
                blocks{bb} = nan; % DONT KNOW
            end
        end
    else
        
        % check whether there are valid (i.e., single) blocks before/after
        if any(num(bb+1:end)==1)
            blockNextValid = blocks{bb+find(num(bb+1:end)==1)};
        else
            blockNextValid = nan;
        end
        if any(num(1:bb-1)==1)
            blockPrevValid = blocks{num(1:bb-1)==1};
        else
            blockPrevValid = nan;
        end
        
        % check for incongruity (i.e., we make an assumption that
        % consecutive trials will occur later in time, and so should
        % correspond to nondecreasing block numbers)
        if ~all(isnan(blockPrevValid)) && blocks{bb} < nanmax(blockPrevValid)
            
            % since we're processing sequentially in order, we'll have
            % already fixed any previous anomalies and can safely use the
            % largest previous value
            blocks{bb} = nanmax(blockPrevValid);
        elseif ~all(isnan(blockNextValid)) && blocks{bb} > nanmin(blockNextValid)
            
            % we haven't processed future trials yet, so we need to
            % make sure not to use a future anomalous value.
            if ~all(isnan(blockPrevValid))
                
                % use the minimum future value that's greater than or equal
                % to the maximum previous value
                blocks{bb} = nanmin(blockNextValid(blockNextValid>=nanmax(blockPrevValid)));
            else
                
                % use the minimum future value (all previous values are nan
                % or nonexistent)
                blocks{bb} = nanmin(blockNextValid);
            end
        end
    end
end