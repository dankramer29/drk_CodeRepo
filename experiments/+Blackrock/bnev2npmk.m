function npmk = bnev2npmk(bnev)
% NEV2NPMK Convert Blackrock.NEV object into NPMK struct
%
%   NPMK = BNEV2NPMK(BNEV)
%   Create NPMK struct from the Blackrock.NEV object BNEV.  Will read all
%   data from the NEV file using the READ method.

% default empty output
npmk = [];

% make sure the NEV file has been loaded
if ~bnev.SourceDataLoaded, return; end

% read data from the NEV file
[Spikes,Comments,Digital,Video,Tracking,Button,Config] = bnev.read(...
    'waveforms','spikes','comments','digital','video','tracking','buttons','config','quiet','allblocks');
if isempty(Spikes), Spikes=[]; else Spikes = util.ascell(Spikes); end
if isempty(Comments), Comments=[]; else Comments = util.ascell(Comments); end
if isempty(Digital), Digital=[]; else Digital = util.ascell(Digital); end
if isempty(Video), Video=[]; else Video = util.ascell(Video); end
if isempty(Tracking), Tracking=[]; else Tracking = util.ascell(Tracking); end
if isempty(Button), Button=[]; else Button = util.ascell(Button); end
if isempty(Config), Config=[]; else Config = util.ascell(Config); end

% MetaTags
npmk.MetaTags.Subject = [];
npmk.MetaTags.Experimenter = [];
npmk.MetaTags.DateTime = bnev.OriginTimeString;
npmk.MetaTags.SampleRes = bnev.ResolutionSamples;
npmk.MetaTags.Comment = bnev.Comment;
npmk.MetaTags.FileTypeID = bnev.FileTypeID;
npmk.MetaTags.Flags = dec2bin(bnev.AdditionalFlags);
npmk.MetaTags.openNEVver = NaN;
npmk.MetaTags.DateTimeRaw = bnev.OriginTimeDatenum;
npmk.MetaTags.FileSpec = sprintf('%d.%d',bnev.FileSpecMajor,bnev.FileSpecMinor);
npmk.MetaTags.PacketBytes = bnev.BytesPerDataPacket;
npmk.MetaTags.HeaderOffset = bnev.BytesInHeaders;
npmk.MetaTags.DataDuration = bnev.Timestamps{end}(end);
npmk.MetaTags.DataDurationSec = bnev.Timestamps{end}(end)/bnev.ResolutionSamples;
npmk.MetaTags.PacketCount = sum(bnev.RecordingBlockPacketCount);
npmk.MetaTags.TimeRes = bnev.ResolutionTimestamps;
npmk.MetaTags.Application = bnev.ApplicationName;
npmk.MetaTags.Filename = bnev.SourceBasename;
npmk.MetaTags.FilePath = bnev.SourceDirectory;
npmk.MetaTags.ChannelID = [bnev.ChannelInfo.ChannelID];

% ElectrodesInfo
for kk=1:length(bnev.ChannelInfo)
    npmk.ElectrodesInfo(kk).ElectrodeID = bnev.ChannelInfo(kk).ChannelID;
    npmk.ElectrodesInfo(kk).ConnectorBank = bnev.ChannelInfo(kk).PhysicalConnector;
    npmk.ElectrodesInfo(kk).ConnectorPin = bnev.ChannelInfo(kk).ConnectorPin;
    npmk.ElectrodesInfo(kk).DigitalFactor = bnev.ChannelInfo(kk).DigitizationFactor;
    npmk.ElectrodesInfo(kk).EnergyThreshold = bnev.ChannelInfo(kk).EnergyThreshold;
    npmk.ElectrodesInfo(kk).HighThreshold = bnev.ChannelInfo(kk).HighThreshold;
    npmk.ElectrodesInfo(kk).LowThreshold = bnev.ChannelInfo(kk).LowThreshold;
    npmk.ElectrodesInfo(kk).Units = bnev.ChannelInfo(kk).NumSortedUnits;
    npmk.ElectrodesInfo(kk).WaveformBytes = bnev.ChannelInfo(kk).BytesPerWaveformSample;
    npmk.ElectrodesInfo(kk).ElectrodeLabel = bnev.ChannelInfo(kk).Label;
    npmk.ElectrodesInfo(kk).HighFreqCorner = bnev.ChannelInfo(kk).HighFreqCorner;
    npmk.ElectrodesInfo(kk).HighFreqOrder = bnev.ChannelInfo(kk).HighFreqOrder;
    npmk.ElectrodesInfo(kk).HighFilterType = bnev.ChannelInfo(kk).HighFilterType;
    npmk.ElectrodesInfo(kk).LowFreqCorner = bnev.ChannelInfo(kk).LowFreqCorner;
    npmk.ElectrodesInfo(kk).LowFreqOrder = bnev.ChannelInfo(kk).LowFreqOrder;
    npmk.ElectrodesInfo(kk).LowFilterType = bnev.ChannelInfo(kk).LowFilterType;
end

% Data - SerialDigitalIO
try
    npmk.Data.SerialDigitalIO = struct(...
        'InputType',[],'TimeStamp',[],'TimeStampSec',[],'Type',[],...
        'Value',[],'InsertionReason',zeros(1,0,'uint8'),'UnparsedData',[]);
    for bb=1:length(Digital);
        npmk.Data.SerialDigitalIO.InputType = [];
        npmk.Data.SerialDigitalIO.TimeStamp = cat(2,npmk.Data.SerialDigitalIO.TimeStamp,Digital{bb}.Timestamps);
        npmk.Data.SerialDigitalIO.TimeStampSec = cat(2,npmk.Data.SerialDigitalIO.TimeStampSec,Digital{bb}.Timestamps/bnev.ResolutionTimestamps);
        npmk.Data.SerialDigitalIO.Type = [];
        npmk.Data.SerialDigitalIO.Value = [];
        npmk.Data.SerialDigitalIO.InsertionReason = [];
        npmk.Data.SerialDigitalIO.UnparsedData = cat(2,npmk.Data.SerialDigitalIO.UnparsedData,Digital{bb}.Data);
    end
catch ME
    util.errorMessage(ME);
    fprintf('Please be aware that this function has not been tested for Serial Digital IO data\n');
end

% Data - Spikes
npmk.Data.Spikes = struct('TimeStamp',zeros(1,0,'uint32'),...
    'Electrode',zeros(1,0,'uint16'),'Unit',zeros(1,0,'uint8'),...
    'Waveform',zeros(bnev.ChannelInfo(1).SpikeWidthSamples,0,'int16'),'WaveformUnit','');
for bb=1:length(Spikes)
    npmk.Data.Spikes.TimeStamp = cat(2,npmk.Data.Spikes.TimeStamp,Spikes{bb}.Timestamps');
    npmk.Data.Spikes.Electrode = cat(2,npmk.Data.Spikes.Electrode,Spikes{bb}.Channels');
    npmk.Data.Spikes.Unit = cat(2,npmk.Data.Spikes.Unit,Spikes{bb}.Units');
    npmk.Data.Spikes.Waveform = cat(2,npmk.Data.Spikes.Waveform,Spikes{bb}.Waveforms);
    npmk.Data.Spikes.WaveformUnit = 'raw';
end

% Data - Comments
npmk.Data.Comments = struct('TimeStamp',zeros(1,0,'uint32'),...
    'TimeStampSec',zeros(1,0,'double'),'CharSet',zeros(1,0,'uint8'),...
    'Color',zeros(1,0,'uint32'),'Text',{{}});
for bb=1:length(Comments)
    npmk.Data.Comments.TimeStamp = cat(2,npmk.Data.Comments.TimeStamp,Comments{bb}.Timestamps');
    npmk.Data.Comments.TimeStampSec = cat(2,npmk.Data.Comments.TimeStampSec,Comments{bb}.Timestamps'/bnev.ResolutionTimestamps);
    npmk.Data.Comments.CharSet = cat(2,npmk.Data.Comments.CharSet,Comments{bb}.CharSet');
    npmk.Data.Comments.Color = cat(2,npmk.Data.Comments.Color,Comments{bb}.Color');
    npmk.Data.Comments.Text = [npmk.Data.Comments.Text Comments{bb}.Text'];
end

% Data - VideoSync
try
    npmk.Data.VideoSync = struct('TimeStamp',[],'FileNumber',[],...
        'FrameNumber',[],'ElapsedTime',[],'SourceID',[]);
    for bb=1:length(Video)
        npmk.Data.VideoSync.TimeStamp = cat(2,npmk.Data.VideoSync.TimeStamp,Video{bb}.Timestamps);
        npmk.Data.VideoSync.FileNumber = cat(2,npmk.Data.VideoSync.FileNumber,Video{bb}.FileNumber);
        npmk.Data.VideoSync.FrameNumber = cat(2,npmk.Data.VideoSync.FrameNumber,Video{bb}.FrameNumber);
        npmk.Data.VideoSync.ElapsedTime = [];
        npmk.Data.VideoSync.SourceID = cat(2,npmk.Data.VideoSync.SourceID,Video{bb}.SourceIDs);
    end
catch ME
    util.errorMessage(ME);
    fprintf('Please be aware that this function has not been tested for Video Sync data\n');
end

% Data - Tracking
try
    npmk.Data.Tracking = struct('TimeStamp',[],'ParentID',[],'NodeID',[],...
        'NodeCount',[],'PointCount',[],'Points',[]);
    for bb=1:length(Tracking)
        npmk.Data.Tracking.TimeStamp = cat(2,npmk.Data.Tracking.TimeStamp,Tracking{bb}.Timestamps);
        npmk.Data.Tracking.ParentID = cat(2,npmk.Data.Tracking.ParentID,Tracking{bb}.ParentID);
        npmk.Data.Tracking.NodeID = cat(2,npmk.Data.Tracking.NodeID,Tracking{bb}.NodeID);
        npmk.Data.Tracking.NodeCount = cat(2,npmk.Data.Tracking.NodeCount,Tracking{bb}.NodeCount);
        npmk.Data.Tracking.PointCount = cat(2,npmk.Data.Tracking.PointCount,Tracking{bb}.PointCount);
        npmk.Data.Tracking.Points = cat(2,npmk.Data.Tracking.Points,Tracking{bb}.Points);
    end
catch ME
    util.errorMessage(ME);
    fprintf('Please be aware that this function has not been tested for Tracking data\n');
end

% Data - Tracking Events
npmk.Data.TrackingEvents = struct('TimeStamp',[],'TimeStampSec',[],'Text',[]);

% Data - PatientTrigger
try
    npmk.Data.PatientTrigger = struct('TimeStamp',[],'TriggerType',[]);
    for bb=1:length(Button)
        npmk.Data.PatientTrigger.TimeStamp = cat(2,npmk.Data.PatientTrigger.TimeStamp,Button{bb}.Timestamps);
        npmk.Data.PatientTrigger.TriggerType = cat(2,npmk.Data.PatientTrigger.TriggerType,Button{bb}.TriggerType);
    end
catch ME
    util.errorMessage(ME);
    fprintf('Please be aware that this function has not been tested for Patient Trigger data\n');
end

% Data - Config
try
    npmk.Data.Reconfig = struct('TimeStamp',[],'ChangeType',[],'CompName',[],'ConfigChanged',[]);
    for bb=1:length(Config)
        npmk.Data.Reconfig.TimeStamp = cat(2,npmk.Data.Reconfig.TimeStamp,Config{bb}.Timestamps);
        npmk.Data.Reconfig.ChangeType = cat(2,npmk.Data.Reconfig.ChangeType,Config{bb}.ChangeType);
        npmk.Data.Reconfig.CompName = [];
        npmk.Data.Reconfig.ConfigChanged = cat(2,npmk.Data.Reconfig.ConfigChanged,Config{bb}.Changed);
    end
catch ME
    util.errorMessage(ME);
    fprintf('Please be aware that this function has not been tested for Reconfig data\n');
end

% IOLabels
npmk.IOLabels = cell(1,length(bnev.DigitalInfo));
for kk=1:length(bnev.DigitalInfo)
    npmk.IOLabels{kk} = bnev.DigitalInfo(kk).Label;
end