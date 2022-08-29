function bnev = mat2bnev(matfile)
% FROMBNEV Load from a Blackrock.NEV object saved to a MAT file
error('This function is not functioning yet! (hehe)');

% validate inputs
assert(ischar(matfile)&&exist(matfile,'file')==2,'Must provide a valid path to a MAT file');

% load the MAT file
tmp = load(matfile);

% re-set source dir/basename/ext/size to reflect the NEV file
this.SourceDirectory = tmp.SourceDirectory;
this.SourceBasename = tmp.SourceBasename;
this.SourceExtension = tmp.SourceExtension;
this.SourceFileSize = tmp.SourceFileSize;

% miscellaneous
if ~isempty(tmp.hArrayMap) && ~isnan(tmp.hArrayMap.MapFile)
    this.hArrayMap = Blackrock.ArrayMap(tmp.hArrayMap.MapFile,'quiet');
end
this.AllSpikeWaveform16Bit = logical(tmp.AllSpikeWaveform16Bit);

% basic header info
this.FileTypeID = tmp.FileTypeID;
this.FileSpecMajor = tmp.FileSpecMajor;
this.FileSpecMinor = tmp.FileSpecMinor;
this.AdditionalFlags = tmp.AdditionalFlags;
this.BytesInHeaders = tmp.BytesInHeaders;
this.BytesPerDataPacket = tmp.BytesPerDataPacket;
this.ResolutionTimestamps = tmp.ResolutionTimestamps;
this.ResolutionSamples = tmp.ResolutionSamples;
this.OriginTimeString = tmp.OriginTimeString;
this.OriginTimeDatenum = tmp.OriginTimeDatenum;
this.ApplicationName = tmp.ApplicationName;
this.Comment = tmp.Comment;
this.NumExtendedHeaders = tmp.NumExtendedHeaders;

% extended header
this.ArrayName = tmp.ArrayName;
this.ExtraComment = tmp.ExtraComment;
this.ExtHeaderIndicatedMapFile = tmp.ExtHeaderIndicatedMapFile;
this.ChannelInfo = tmp.ChannelInfo;
this.DigitalInfo = tmp.DigitalInfo;
this.VideoInfo = tmp.VideoInfo;
this.TrackingInfo = tmp.TrackingInfo;

% recording Blocks
this.NumRecordingBlocks = tmp.NumRecordingBlocks;
this.RecordingBlockPacketCount = tmp.RecordingBlockPacketCount;
this.RecordingBlockPacketIdx = tmp.RecordingBlockPacketIdx;

% data Packets
this.NumDataPackets = tmp.NumDataPackets;
this.Timestamps = tmp.Timestamps;
this.PacketIDs = tmp.PacketIDs;
this.UniquePacketIDs = tmp.UniquePacketIDs;
end % END function fromBNEV