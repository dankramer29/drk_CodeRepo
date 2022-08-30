function preprocessDataPackets(this)

% check file size
nevfile = fullfile(this.SourceDirectory,[this.SourceBasename this.SourceExtension]);
info = dir(nevfile);
this.SourceFileSize = info.bytes;
this.NumDataPackets = (this.SourceFileSize - this.BytesInHeaders)/this.BytesPerDataPacket;

% open the file for reading
fid = fopen(nevfile,'r');
assert(fid>=0,'Could not open the file');

% read Timestamps and Packet IDs for all data packets
try
    status = fseek(fid,this.BytesInHeaders,'bof');
    assert(status==0,'Error reading file: %s',ferror(fid));
    DataPackets = fread(fid,[6 this.NumDataPackets],'6*uint8=>uint8',this.BytesPerDataPacket - 6);
    fclose(fid);
catch ME
    util.errorMessage(ME);
    fclose(fid);
    return;
end

% process Timestamps and Packet IDs
if isempty(DataPackets)
    this.Timestamps = [];
    this.PacketIDs = [];
    this.UniquePacketIDs = [];
else
    tmpTimestamps = DataPackets(1:4,:);
    tmpTimestamps = double(typecast(tmpTimestamps(:),'uint32'));
    tmpPacketIDs = DataPackets(5:6,:);
    tmpPacketIDs = double(typecast(tmpPacketIDs(:),'uint16'));
    
    % find recording block boundaries, i.e., when the global timestamp
    % counter has reset (as happens when NSPs sync)
    dTimestamps = diff(tmpTimestamps);
    BlockBoundaries = find(dTimestamps<0)+1;
    bb = 1;
    while bb<=length(BlockBoundaries)
        if BlockBoundaries(bb)==1
            bb = bb+1;
        elseif BlockBoundaries(bb)==length(dTimestamps)
            bb = bb+1;
        elseif tmpPacketIDs(BlockBoundaries(bb))==65535 && dTimestamps(BlockBoundaries(bb)) > -dTimestamps(BlockBoundaries(bb)-1)
            
            % on record restart, there is a comment packet with
            % timestamp 0, but the clock has not reset and timestamps
            % continue on normally afterward. thus, the diff'd
            % timestamps will show a negative value before the zero,
            % and a larger positive value after the zero.
            BlockBoundaries(bb) = [];
        else
            bb = bb+1;
        end
    end
    
    % set up the recording blocks
    this.NumRecordingBlocks = length(BlockBoundaries)+1;
    if isempty(BlockBoundaries)
        this.RecordingBlockPacketIdx(1,:) = [1 length(tmpTimestamps)];
    else
        for bb = 1:length(BlockBoundaries)
            if bb==1
                this.RecordingBlockPacketIdx(bb,:) = [1 BlockBoundaries(1)-1];
            else
                this.RecordingBlockPacketIdx(bb,:) = [BlockBoundaries(bb-1) BlockBoundaries(bb)-1];
            end
        end
        this.RecordingBlockPacketIdx(end+1,:) = [BlockBoundaries(end) length(tmpTimestamps)];
    end
    this.RecordingBlockPacketCount = diff(this.RecordingBlockPacketIdx,1,2)+1;
    
    % get timestamps and packet IDs for each recording block
    for rr = 1:this.NumRecordingBlocks
        st = this.RecordingBlockPacketIdx(rr,1);
        lt = this.RecordingBlockPacketIdx(rr,2);
        
        this.Timestamps{rr} = tmpTimestamps(st:lt);
        this.PacketIDs{rr} = tmpPacketIDs(st:lt);
        this.UniquePacketIDs{rr} = unique(this.PacketIDs{rr});
    end
end
