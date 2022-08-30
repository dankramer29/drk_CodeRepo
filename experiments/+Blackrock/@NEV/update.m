function update(this,Spike,varargin)
% UPDATE update spike assignments in NEV file
%
% The below examples assume 'nv' is an object of class Blackrock.NEV, and
% that the data structure Spike has been read out via nv.read and updated
% as needed.
%
% Examples:
%
% nv.update(Spike);
% This command will update the unit assignments (e.g., after sorting) in
% the NEV file used to create the object 'nv'.
%
% Spike data should be provided in the same format as is returned from
% the 'read' method of the Blackrock.NEV class.  If multiple recording 
% blocks are present, each data type should be provided as a cell array of 
% structs where each cell contains the data for that recording block. If a
% single recording block is provided, it may be either a single cell with a
% struct array, or a struct array. 
% 
% Recording blocks in the provided data must be matched up with recording 
% blocks in the existing file.  Two blocks are considered to be matching 
% if they have the same number of spike data packets.
% 
% See help for Blackrock.NEV.read for more information on recording blocks.
%
% Some inputs can be shortened:
% quiet         q[uiet]

% collect data to be written to the file
assert(~isempty(Spike),'Spike data is required');
Spike = util.ascell(Spike);
NumUserRecordingBlocks = length(Spike);
assert(NumUserRecordingBlocks>0,'No data provided');

% collect packet IDs and Timestamps
UniquePacketIDs = cell(1,NumUserRecordingBlocks);
WhichIdx = cell(1,NumUserRecordingBlocks);
for bb = 1:NumUserRecordingBlocks
    if isfield(Spike{bb},'Electrodes') && ~isfield(Spike{bb},'Channels')
        assert(~isempty(this.hArrayMap),'Cannot determine channels from electrodes without ArrayMap object');
        Spike{bb}.Channels = this.hArrayMap.el2ch(Spike{bb}.Electrodes);
    end
    assert(isfield(Spike{bb},'Units')&&isfield(Spike{bb},'Timestamps')&&isfield(Spike{bb},'Channels'),'Must provide Spike struct with at least Units, Timestamps, and Channels fields.');
    
    [Spike{bb}.Timestamps,WhichIdx{bb}] = sort(Spike{bb}.Timestamps,'ascend');
    UniquePacketIDs{bb} = unique(Spike{bb}.Channels);
end

% match up recording blocks
User2ExistingRecordingBlocks = nan(1,NumUserRecordingBlocks);
for ubb = 1:NumUserRecordingBlocks
    if isfield(Spike{ubb},'RecordingBlock') && Spike{ubb}.RecordingBlock<=this.NumRecordingBlocks
        User2ExistingRecordingBlocks(ubb) = Spike{ubb}.RecordingBlock;
    else
        for ebb = 1:this.NumRecordingBlocks
            if nnz( ismember(this.PacketIDs{ebb},UniquePacketIDs{ubb}) ) == length(Spike{ubb}.Units)
                User2ExistingRecordingBlocks(ubb) = ebb;
                break;
            end
        end
    end
end
assert(~any(isnan(User2ExistingRecordingBlocks)),'Unable to match provided recording blocks with existing recording blocks.');

% open the file for reading
try
    TargetFile = fullfile(this.SourceDirectory,[this.SourceBasename this.SourceExtension]);
    [fid,msg] = fopen(TargetFile,'r+');
    assert(fid>=0,'Could not open ''%s'' for writing: %s',TargetFile,msg);
catch ME
    util.errorMessage(ME);
    return;
end

% update spike unit assignments
try
    for bb = 1:NumUserRecordingBlocks
        BlockIdx = User2ExistingRecordingBlocks(bb);
        BlockStartByte = this.BytesInHeaders + this.BytesPerDataPacket*(this.RecordingBlockPacketIdx(BlockIdx,1)-1) + 6;
        fseek(fid,BlockStartByte,'bof');
        for pp = 1:length(Spike{bb}.Units)
            ThisPacketIdx = Spike{bb}.PacketIdx(WhichIdx{bb}(pp));
            BytesToSeek = (BlockStartByte + this.BytesPerDataPacket*(ThisPacketIdx-1)) - ftell(fid);
            fseek(fid,BytesToSeek,'cof');
            count = fwrite(fid,cast(Spike{bb}.Units(WhichIdx{bb}(pp)),'uint8'),'uint8');
            assert(count>=1,'Could not write to file ''%s''.',TargetFile);
        end
    end
catch ME
    util.errorMessage(ME);
    fclose(fid);
    return;
end

% close the file
fclose(fid);