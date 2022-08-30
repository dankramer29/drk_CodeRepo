function [blocks,tm,idx_ok] = processBlocksNV(nv,procwin,blocks,numArrays,numWins,logfcn)
FlagUpdateBlocks = false;
if iscell(blocks)
    
    % first, make sure one block per array
    if length(blocks)==1
        blocks = arrayfun(@(x)blocks{1}(:),1:numArrays,'UniformOutput',false);
    else
        assert(length(blocks)==numArrays,'If blocks is a cell with more than one cell, it must have %d cells',numArrays);
    end
    
    % next make sure correct dimensions
    for nn=1:numArrays
        if length(blocks{nn})==1
            blocks{nn} = arrayfun(@(x)blocks{nn},1:numWins,'UniformOutput',false);
        end
        assert(length(blocks{nn})==numWins,'Each cell of blocks must be length %d',numWins);
    end
elseif isnan(blocks)
    
    % identify recording blocks associated with trial timing
    blocks = proc.helper.getProcwinNEVBlocks(nv,procwin,'col2mode','length','units','seconds');
    FlagUpdateBlocks = true;
else
    if isnumeric(blocks)
        if isscalar(blocks)
            blocks = arrayfun(@(y)arrayfun(@(x)blocks,(1:numWins)','UniformOutput',false),1:numArrays,'UniformOutput',false);
        else
            if length(blocks)==numWins
                blocks = arrayfun(@(x)arrayfun(@(y)blocks(y),(1:numWins)','UniformOutput',false),1:numArrays,'UniformOutput',false);
            elseif length(blocks)==numArrays
                blocks = arrayfun(@(x)arrayfun(@(y)x,(1:numWins)','UniformOutput',false),blocks,'UniformOutput',false);
            elseif size(blocks,1)==numWins && size(blocks,2)==numArrays
                blocks = mat2cell(blocks,numWins,numArrays);
            else
                error('Unknown configuration for blocks input');
            end
        end
    end
end
assert(length(blocks)==numArrays && all(cellfun(@(x)length(x)==numWins,blocks)==1),'If blocks is a cell array, it must be length %d, each cell length %d',numArrays,numWins);

% identify file read timing and raw data sample placement
tm = arrayfun(@(x)cell(numWins,1),1:numArrays,'UniformOutput',false);
idx_ok = arrayfun(@(x)true(numWins,1),1:numArrays,'UniformOutput',false);
for kk=1:numWins
    for nn=1:numArrays
        idxBlock = blocks{nn}{kk};
        idxBlock = unique(idxBlock(~isnan(idxBlock)));
        assert(~isempty(idxBlock),'Could not identify recording block for procwin %d/%d, array %d/%d: requested [%.2f +%.2f] sec',kk,numWins,nn,numArrays,procwin{nn}(kk,1),procwin{nn}(kk,2));
        [~,idxWhich] = max(nv{nn}.RecordingBlockPacketCount(idxBlock));
        idxBlock = idxBlock(idxWhich);
        local_min_time = nv{nn}.Timestamps{idxBlock}(1)/nv{nn}.ResolutionTimestamps;
        local_max_time = nv{nn}.Timestamps{idxBlock}(end)/nv{nn}.ResolutionTimestamps;
        local_pw = procwin{nn}(kk,:);
        
        % determine requested time range (start,end)
        tm{nn}{kk}(1) = max(local_min_time,local_pw(1));
        if tm{nn}{kk}(1)>local_pw(1)
            proc.helper.log(logfcn,sprintf('Array %d/%d, procwin %d/%d start time clamped to %.3f',nn,numArrays,kk,numWins,tm{nn}{kk}(1)),'warn');
        end
        tm{nn}{kk}(2) = min(local_max_time,local_pw(1)+local_pw(2));
        if tm{nn}{kk}(2)<=tm{nn}{kk}(1)
            proc.helper.log(logfcn,sprintf('Insufficient data for array %d/%d, procwin %d/%d',nn,numArrays,kk,numWins),'warn');
            idx_ok{nn}(kk) = false;
            tm{nn}{kk} = [nan nan];
            continue;
        end
        if tm{nn}{kk}(2)<(local_pw(1)+local_pw(2))
            proc.helper.log(logfcn,sprintf('Array %d/%d, procwin %d/%d end time clamped to %.3f',nn,numArrays,kk,numWins,tm{nn}{kk}(2)),'warn');
        end
    end
end

% remove processing windows not supported by data
for nn=1:numArrays
    tm{nn}(~idx_ok{nn}) = [];
end
idx_ok = cellfun(@(x)find(x),idx_ok,'UniformOutput',false);

% identify recording packets associated with each file timing
if FlagUpdateBlocks
    blocks = proc.helper.getProcwinNEVBlocks(nv,tm,'col2mode','endtime','units','seconds');
end