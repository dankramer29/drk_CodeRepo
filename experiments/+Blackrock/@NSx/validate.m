function validate(this,which)
% VALIDATE Compare Blackrock.NSx and NPMK outputs
if nargin<2||isempty(which),which='npmk';end

% run requested validation routine
switch lower(which)
    case 'npmk',validate_npmk(this);
    case 'timing',validate_timing(this);
    otherwise
        error('Unknown validation type "%s"',which);
end
end % END function validate

function validate_npmk(this)
% look for NPMK
if exist('openNSx','file')~=2
    extdir = env.get('external');
    npmkdir = fullfile(extdir,'NPMK');
    if exist(npmkdir,'dir')==7
        addpath(genpath(npmkdir));
    end
end
assert(exist('openNSx','file')==2,'Could not locate NPMK package');

% read data from NPMK
ns2 = openNSx(fullfile(this.SourceDirectory,sprintf('%s%s',this.SourceBasename,this.SourceExtension)),'read');

% same number of packets and same packet lengths
assert(this.NumDataPackets==length(ns2.Data),'Mismatched number of packets (Blackrock.NSx %d, NPMK %d)',this.NumDataPackets,length(ns2.Data));
for kk=1:this.NumDataPackets
    assert(this.PointsPerDataPacket(kk)==size(ns2.Data{kk},2),'Mismatched number of data points in packet %d (Blackrock.NSx %d, NPMK %d)',kk,this.PointsPerDataPacket(kk),size(ns2.Data{kk},2));
end

% same channel count
assert(this.ChannelCount==size(ns2.Data{1},1),'Mismatched channel counts (Blackrock.NSx %d, NPMK %d)',this.ChannelCount,size(ns2.Data{1},1));

% select a random set of indices to compare
for kk=1:this.NumDataPackets
    ns1 = read(this,'packet',kk);
    idx_chan = randperm(this.ChannelCount,max(10,this.ChannelCount));
    for nn=1:length(idx_chan)
        idx_time = randperm(this.PointsPerDataPacket(kk),min(max(round(0.1*this.PointsPerDataPacket(kk)),1e4),this.PointsPerDataPacket(kk)));
        assert(all(ns1(idx_chan(nn),idx_time)==ns2.Data{kk}(idx_chan(nn),idx_time)),'Data values do not match');
    end
end
end % END function validate_npmk

function validate_timing(this)

% read same data using all timing input and referencing mechanisms

% first, read entire packet
[~,which] = max(this.PointsPerDataPacket);
nPoints = this.PointsPerDataPacket(which);
startTimestamp = this.Timestamps(which);
data_rpacket_ttime = this.read('ref','packet','time',[0 nPoints/this.Fs]);
data_rpacket_tpoints = this.read('ref','packet','points',[1 nPoints]);
data_rpacket_ttimestamps = this.read('ref','packet','timestamps',[0 nPoints*this.fs2ttr-1]);

data_rtimestamp_ttime = this.read('ref','timestamp','time',[startTimestamp (startTimestamp+nPoints*this.fs2ttr)]/this.TimestampTimeResolution);
data_rtimestamp_tpoints = this.read('ref','timestamp','points',[startTimestamp/this.fs2ttr+1 startTimestamp/this.fs2ttr+nPoints]);
data_rtimestamp_ttimestamps = this.read('ref','timestamp','timestamps',[startTimestamp startTimestamp+nPoints*this.fs2ttr-1]);

% next, read portion of a packet: samples 10 through 100
data_rpacket_ttime = this.read('ref','packet','time',[9/this.Fs 100/this.Fs]);
data_rpacket_tpoints = this.read('ref','packet','points',[10 100]);
data_rpacket_ttimestamps = this.read('ref','packet','timestamps',[9*this.fs2ttr 100*this.fs2ttr]);

data_rtimestamp_ttime = this.read('ref','timestamp','time',[startTimestamp+9*this.fs2ttr (startTimestamp+100*this.fs2ttr)]/this.TimestampTimeResolution);
data_rtimestamp_tpoints = this.read('ref','timestamp','points',[startTimestamp/this.fs2ttr+10 startTimestamp/this.fs2ttr+100]);
data_rtimestamp_ttimestamps = this.read('ref','timestamp','timestamps',[startTimestamp+9*this.fs2ttr startTimestamp+100*this.fs2ttr-1]);

% next, read portion of a packet: seconds 2-5
data_rpacket_ttime = this.read('ref','packet','time',[2 5]);
data_rpacket_tpoints = this.read('ref','packet','points',[2*this.Fs+1 5*this.Fs]);
data_rpacket_ttimestamps = this.read('ref','packet','timestamps',[2*this.Fs*this.fs2ttr 5*this.Fs*this.fs2ttr]);

data_rtimestamp_ttime = this.read('ref','timestamp','time',[startTimestamp/this.TimestampTimeResolution+2 startTimestamp/this.TimestampTimeResolution+5]);
data_rtimestamp_tpoints = this.read('ref','timestamp','points',[startTimestamp/this.fs2ttr+2*this.Fs+1 startTimestamp/this.fs2ttr+5*this.Fs]);
data_rtimestamp_ttimestamps = this.read('ref','timestamp','timestamps',[startTimestamp+2*this.TimestampTimeResolution startTimestamp+5*this.TimestampTimeResolution]);

% next, read across two packets

% next read ...?
end % END function validate_timing