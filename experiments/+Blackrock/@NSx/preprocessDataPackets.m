function preprocessDataPackets(this)

% check file size
nsxfile = fullfile(this.SourceDirectory,[this.SourceBasename this.SourceExtension]);
info = dir(nsxfile);
this.SourceFileSize = info.bytes;

% open the file for reading
fid = fopen(nsxfile,'r');

% seek to first data packet
try
    status = fseek(fid,this.BytesInHeaders,'bof');
    assert(status>=0,'Error reading file: %s',ferror(fid));
catch ME
    fclose(fid);
    rethrow(ME);
end

% loop over data packets
while ftell(fid)<this.SourceFileSize
    
    % grab current byte (start of this data packet)
    PacketByteIdx = ftell(fid);
    
    % read header information
    try
        HeaderByte = fread(fid,1,'uint8=>double');
        assert(HeaderByte==1,'Invalid data packet');
        Timestamp = fread(fid,1,'uint32=>double');
        NumDataPoints = fread(fid,1,'uint32=>double');
    catch ME
        fclose(fid);
        rethrow(ME);
    end
    
    % calculate number of bytes in this packet
    DataPacketBytes = NumDataPoints * this.ChannelCount * 2;
    if ftell(fid) + DataPacketBytes > this.SourceFileSize
        error('Blackrock:NSx:InvalidHeader','Invalid header at byte index %d (packet %d): too many data points',PacketByteIdx, this.NumDataPackets+1);
    end
    
    % update object properties
    this.NumDataPackets = this.NumDataPackets + 1;
    this.Timestamps(this.NumDataPackets) = Timestamp;
    this.PointsPerDataPacket(this.NumDataPackets) = NumDataPoints;
    this.DataPacketByteIdx(this.NumDataPackets,1:2) = [PacketByteIdx PacketByteIdx+DataPacketBytes+9-1];
    
    % seek to end of data packet
    try
        status = fseek(fid,DataPacketBytes,'cof');
        assert(status>=0,'Error reading file: %s',ferror(fid));
    catch ME
        fclose(fid);
        rethrow(ME);
    end
end

% close the file
fclose(fid);
