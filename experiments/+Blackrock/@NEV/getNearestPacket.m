function [packet,bytes] = getNearestPacket(this,marker,varargin)
% GETNEARESTPACKET Get the index of the packet closest to a timestamp
%
%   [PACKET,BYTES] = GETNEARESTPACKET(THIS,MARKER)
%   Get the packet info (PACKET) and raw data (BYTES) of the packet in the
%   largest recording block whose timestamp is equal to or smaller than the
%   value in MARKER.
%
%   [PACKET,BYTES] = GETNEARESTPACKET(THIS,MARKER,'BYTE')
%   Interpret MARKER as a byte number instead of a timestamp.
%
%   GETNEARESTPACKET(...,'FORWARD')
%   Look after the provided marker (instead of default behavior to look
%   before the provided marker).
%
%   GETNEARESTPACKET(...,'BLOCK',BLOCKIDX)
%   Specify the recording block in which to search for a packet.

% process user inputs
[varargin,markerStyle] = util.ProcVarargin(varargin,{'timestamp','byte'},'timestamp');
[varargin,direction] = util.ProcVarargin(varargin,{'forward','backward'},'backward');
[~,defaultBlock] = max(cellfun(@length,this.PacketIDs));
[varargin,blockIdx] = util.ProcVarargin(varargin,'block',defaultBlock);
util.ProcVarargin(varargin);

% get the index of the packet
switch lower(markerStyle)
    case 'timestamp'
        
        % get the index of the packet with the next timestamp
        PacketIdxInBlock = find(this.Timestamps{blockIdx}>=marker,1,'first');
        assert(~isempty(PacketIdxInBlock),'TimeStamp %d out of bounds or missing from NEV range [%d %d]',marker,this.Timestamps{blockIdx}(1),this.Timestamps{blockIdx}(end));
        
        % account for looking backward instead of forward
        if strcmpi(direction,'backward')
            PacketIdxInBlock = PacketIdxInBlock - 1;
        end
        
        % convert from block to global index
        PacketIdxGlobal = PacketIdxInBlock + sum(cellfun(@length,this.PacketIDs(1:blockIdx-1)));
    case 'byte'
        
        % get the index of the packet with the next first byte
        PacketIdxGlobal = ((marker-this.BytesInHeaders)/this.BytesPerDataPacket)+1;
        
        % account for looking forward or backward
        if strcmpi(direction,'forward')
            PacketIdxGlobal = ceil(PacketIdxGlobal);
        elseif strcmpi(direction,'backward')
            PacketIdxGlobal = floor(PacketIdxGlobal);
        end
        
        % convert from global to block index
        PacketIdxInBlock = PacketIdxGlobal - sum(cellfun(@length,this.PacketIDs(1:blockIdx-1)));
    otherwise
        error('Unknown marker style ''%s''',markerStyle);
end

% validate the packet index
assert(PacketIdxInBlock>0&&PacketIdxInBlock<length(this.PacketIDs{blockIdx}),'Invalid packet ID');
assert(PacketIdxGlobal>0&&PacketIdxGlobal<this.NumDataPackets,'Invalid packet ID');

% find the closest byte
byte = this.BytesInHeaders + (PacketIdxGlobal-1)*this.BytesPerDataPacket;
assert(byte<=this.SourceFileSize,'Byte %d larger than NEV file size %d.',byte,this.SourceFileSize);

% read the packet
fid = fopen(fullfile(this.SourceDirectory,[this.SourceBasename this.SourceExtension]),'r');
try
    fseek(fid,byte,0);
    bytes = fread(fid,this.BytesPerDataPacket,'uint8=>uint8');
catch ME
    util.errorMessage(ME);
end
fclose(fid);

% identify the packet from the preprocessing data
timestamp = this.Timestamps{blockIdx}(PacketIdxInBlock);
packetID = this.PacketIDs{blockIdx}(PacketIdxInBlock);

% get packet ID and timestamp from file data and validate
bytes_timestamps = bytes(1:4);
bytes_timestamps = double(typecast(bytes_timestamps(:),'uint32'));
bytes_packetID = bytes(5:6);
bytes_packetID = double(typecast(bytes_packetID(:),'uint16'));
assert(bytes_packetID == packetID,'Mismatched data packet!');
assert(bytes_timestamps == timestamp,'Mismatched data packet!');

% interpret the packet data
packet.StartByte = byte;
packet.RecordingBlock = blockIdx;
packet.PacketIdx = PacketIdxGlobal;
packet.Timestamp = timestamp;
if ismember(packetID,[this.ChannelInfo.ChannelID])
    
    % spike packet
    packet.Unit = double(bytes(7));
    packet.Channel = packetID;
    if ~isempty(this.hArrayMap)
        packet.Electrode = this.hArrayMap.ch2el(packet.Channel);
    end
    WaveformBytes = bytes(9:end);
    packet.Waveform = double(typecast(WaveformBytes(:),'int16'));
elseif packetID==65535
    
    % comment packet
    packet.CharSet = bytes(7);
    ColorBytes = bytes(9:12);
    packet.Color = typecast(ColorBytes(:),'uint32');
    CommentsBytes = bytes(13:end);
    lt = find(CommentsBytes==0,1,'first');
    if isempty(lt),lt=length(CommentsBytes);end
    packet.Text = {char(CommentsBytes(1:lt-1)')};
else
    
    % nothing else implemented yet
    log(this,sprintf('getNearestPacket not configured to support packetID %d',packetID),'warn');
end