function save(this)
% SAVE save data packets to a new NEV file
%
%   SAVE(THIS)
%   Create a NEV file at the path and file specified by TARGET, using data
%   read from the loaded NEV file represented by the Blackrock.NEV object
%   THIS.
%
%   See also BLACKROCK.NEVWRITER.

% data properties
dtprop.Spike = 'SpikeData';
dtprop.Comment = 'CommentData';
dtprop.Digital = 'DigitalData';
dtprop.Video = 'VideoData';
dtprop.Tracking = 'TrackingData';
dtprop.Button = 'ButtonData';
dtprop.Config = 'ConfigData';

% metadata fields
metafields = Blackrock.NEV.getMetadataFields;

% functions to translate packet data into bytes
pktbytefn.Spike = @packetBytesSpike;
pktbytefn.Comment = @packetBytesComment;
pktbytefn.Digital = @packetBytesDigital;
pktbytefn.Video = @packetBytesVideo;
pktbytefn.Tracking = @packetBytesTracking;
pktbytefn.Button = @packetBytesButton;
pktbytefn.Config = @packetBytesConfig;

% data types and IDs
dtype = {'Spike','Comment','Digital','Video','Tracking','Button','Config'};
present = false(1,length(dtype));
for tt=1:length(dtype)
    id.(dtype{tt}) = tt;
    present(tt) = ~isempty(this.(dtprop.(dtype{tt})));
end

% reduce to just the available data types
dtype(~present) = [];
assert(~isempty(dtype),'No data provided');

% number of recording blocks
NumBlocks = cellfun(@(x)length(this.(dtprop.(x))),dtype);
assert(numel(unique(NumBlocks))==1,'All available data must have the same number of recording blocks');
NumUserRecordingBlocks = NumBlocks(1);
assert(NumUserRecordingBlocks>0,'No data provided');

% preprocess the data to generate packet IDs and ordering information
fd.pkt = cell(1,NumUserRecordingBlocks); % packet ID
fd.upkt = cell(1,NumUserRecordingBlocks); % unique packet IDs
fd.tm = cell(1,NumUserRecordingBlocks); % timestamps
fd.id = cell(1,NumUserRecordingBlocks); % packet type IDs
fd.idx = cell(1,NumUserRecordingBlocks); % packet indices
fd.bytes = cell(1,NumUserRecordingBlocks); % packet bytes

% loop over the recording blocks
for bb = 1:NumUserRecordingBlocks
    
    % loop over each data type
    for tt=1:length(dtype)
        
        % pull out timestamps, packet IDs for this block/type
        newtm = this.(dtprop.(dtype{tt})){bb}.Timestamps;
        newpkt = this.(dtprop.(dtype{tt})){bb}.PacketIDs;
        
        % pull together data from the different data types
        fd.pkt{bb} = [fd.pkt{bb}; newpkt(:)]; % packet IDs
        fd.tm{bb} = [fd.tm{bb}; newtm(:)]; % timestamps
        fd.id{bb} = [fd.id{bb}; id.(dtype{tt})*ones(length(newtm),1)]; % IDs
        fd.idx{bb} = [fd.idx{bb}; (1:length(newtm))']; % index
        
        % sort data for this data type (will sort packets globally below)
        % corner case: what happens if two events have the same timestamp?
        [this.(dtprop.(dtype{tt})){bb}.Timestamps,dtype_sort_idx] = sort(this.(dtprop.(dtype{tt})){bb}.Timestamps,'ascend');
        fields = fieldnames(this.(dtprop.(dtype{tt})){bb});
        fields(strcmpi(fields,'Timestamps')) = [];
        for ff=1:length(fields)
            
            % make sure this field has at least one dimension correct
            sz = size(this.(dtprop.(dtype{tt})){bb}.(fields{ff}));
            which = sz==length(dtype_sort_idx);
            if ~any(which)
                warning('Field "%s" for dtype "%s" in packet %d has an unexpected size: %s (expected at least one dimension to be %d)',...
                    fields{ff},dtype{tt},bb,Utilities.vec2str(size(this.(dtprop.(dtype{tt})){bb}.(fields{ff}))),length(dtype_sort_idx));
                continue;
            end
            
            % apply the sort
            if numel(sz)==2 
                if which(1) % matrix with correct number of rows
                    this.(dtprop.(dtype{tt})){bb}.(fields{ff}) = this.(dtprop.(dtype{tt})){bb}.(fields{ff})(dtype_sort_idx,:);
                elseif which(2) % matrix with correct number of columns
                    this.(dtprop.(dtype{tt})){bb}.(fields{ff}) = this.(dtprop.(dtype{tt})){bb}.(fields{ff})(:,dtype_sort_idx);
                end
            else
                warning('No support for more than two dimensions yet');
            end
        end
    end
    
    % re-arrange the packets in time-ascending order
    [fd.tm{bb},SortIdx] = sort(fd.tm{bb},'ascend');
    fd.pkt{bb} = fd.pkt{bb}(SortIdx);
    fd.upkt{bb} = unique(fd.pkt{bb});
    fd.id{bb} = fd.id{bb}(SortIdx);
    fd.idx{bb} = fd.idx{bb}(SortIdx);
end

% generate header byte strings
[ExtendedHeaderBytes,this.ExtendedHeaders] = Blackrock.NEVWriter.genExtendedHeaderBytes(this.ExtendedHeaders);
NumExtendedHeaders = length(ExtendedHeaderBytes)/32;
[BasicHeaderBytes,this.BasicHeader] = Blackrock.NEVWriter.genBasicHeaderBytes(this.BasicHeader,NumExtendedHeaders);

% generate data packets (in this function to avoid passing a bunch of data)
DataPacketBytes = cell(1,NumUserRecordingBlocks);
for bb = 1:NumUserRecordingBlocks
    
    % pre-allocate all bytes required for this recording block
    DataPacketBytes{bb} = zeros(this.BasicHeader.BytesPerDataPacket,length(fd.pkt{bb}),'uint8');
    
    % these packets common to all data types
    DataPacketBytes{bb}(1:4,:) = reshape(typecast(cast(fd.tm{bb},'uint32'),'uint8'),[4 length(fd.tm{bb})]);
    DataPacketBytes{bb}(5:6,:) = reshape(typecast(cast(fd.pkt{bb},'uint16'),'uint8'),[2 length(fd.pkt{bb})]);
    
    % loop over each data type to generate bytes from the relevant data
    for tt=1:length(dtype)
        idx = fd.id{bb}==id.(dtype{tt});
        DataPacketBytes{bb}(:,idx) = feval(pktbytefn.(dtype{tt}),...
            DataPacketBytes{bb}(:,idx),...
            this.(dtprop.(dtype{tt})){bb},...
            this.BasicHeader,this.ExtendedHeaders);
    end
    
    % put bytes into a single vector
    DataPacketBytes{bb} = DataPacketBytes{bb}(:);
end

% collapse reocrding blocks into single string of bytes
DataPacketBytes = cat(1,DataPacketBytes{:});

% open the file for writing
TargetFile = fullfile(this.TargetDirectory,sprintf('%s%s',this.TargetBasename,this.TargetExtension));
[fid,msg] = fopen(TargetFile,'w');
assert(fid>=0,'Could not open ''%s'': %s',TargetFile,msg);

% write basic headers, extended headers, and data packet bytes
try
    fwrite(fid,BasicHeaderBytes,'uint8');
    fwrite(fid,ExtendedHeaderBytes,'uint8');
    fwrite(fid,DataPacketBytes,'uint8');
    FileSize = ftell(fid);
catch ME
    util.errorMessage(ME);
    fclose(fid);
    return;
end

% close the file
fclose(fid);

% report back on number of bytes written and to which file
log(this,sprintf('Finished writing %d bytes to %s',FileSize,TargetFile),'info');

% check for metadata
mt = struct;
for dd=1:length(dtype)
    
    % skip if no data present
    if isempty(this.(dtprop.(dtype{dd}))),continue;end
    
    % skip if no metafields listed
    if isempty(metafields.(dtype{dd})),continue;end
    
    % loop over recording blocks
    for bb=1:NumUserRecordingBlocks
        
        % identify fields of the data structure and metadata
        dtfields = fieldnames(this.(dtprop.(dtype{dd})){bb});
        mtfields = metafields.(dtype{dd});
        
        % loop over the metadata fields
        for mm=1:length(mtfields)
            if ~ismember(mtfields{mm},dtfields),continue;end
            
            % copy over the metadata for each recording block
            mt.(dtype{dd}){bb}.(mtfields{mm}) = this.(dtprop.(dtype{dd})){bb}.(mtfields{mm});
        end
    end
end

% save the metadata if present
if ~isempty(mt) && isstruct(mt) && ~isempty(fieldnames(mt))
    MetadataFile = fullfile(this.MetaDirectoryFcn(this.TargetDirectory),this.MetaBasenameFcn(this.TargetBasename));
    save(MetadataFile,'-struct','mt');
end

end % END function save

function bytes = packetBytesSpike(bytes,dt,basic,ext)
% PACKETBYTESSPIKE Transform spike data into bytes

% get number of bytes per waveform
BytesPerWaveform = ext.ChannelInfo(1).SpikeWidthSamples*ext.ChannelInfo(1).BytesPerWaveformSample;

% pull out the unit assignment
bytes(7,:) = cast(dt.Units,'uint8');

% pull out waveform data
WaveformBytes = cast(dt.Waveforms,'int16');
bytes(9:9+BytesPerWaveform-1,:) = reshape(typecast(WaveformBytes(:),'uint8'),[BytesPerWaveform size(WaveformBytes,2)]);
end % END function packetBytesSpike

function bytes = packetBytesComment(bytes,dt,basic,ext)
% PACKETBYTESCOMMENT Transform comment data into bytes

% character set
bytes(7,:) = cast(dt.CharSet,'uint8');

% colors
ColorBytes = cast(dt.Color,'uint32');
bytes(9:12,:) = reshape(typecast(ColorBytes(:),'uint8'),[4 length(ColorBytes)]);

% loop over each comment
for tt = 1:length(dt.Text)
    
    % place text into the bytes
    lt = min(length(dt.Text{tt}),basic.BytesPerDataPacket-12);
    bytes(12 + (1:lt),tt) = dt.Text{tt}(1:lt);
end
end % END function packetBytesComment

function bytes = packetBytesDigital(bytes,dt,basic,ext)
% PACKETBYTESDIGITAL Transform digital data into bytes

% flag
bytes(7,:) = cast(dt.Flags,'uint8');

% digital data
bytes(9:10,:) = reshape(typecast(cast(dt.Data,'uint16'),'uint8'),[2 length(dt.Data)]);
end % END function packetBytesDigital

function bytes = packetBytesVideo(bytes,dt,basic,ext)
log(this,'Writing video packets not supported yet','warn');
end % END function packetBytesVideo

function bytes = packetBytesTracking(bytes,dt,basic,ext)
log(this,'Writing tracking packets not supported yet','warn');
end % END function packetBytesTracking

function bytes = packetBytesButton(bytes,dt,basic,ext)
log(this,'Writing button packets not supported yet','warn');
end % END function packetBytesButton

function bytes = packetBytesConfig(bytes,dt,basic,ext)
% PACKETBYTESCONFIG Transform config data into bytes

% change config type
bytes(7:8,:) = reshape(typecast(cast(dt.ChangeType,'uint16'),'uint8'),[2 length(dt.ChangeType)]);

% config changed text
for tt = 1:length(dt.Changed)
    
    % place text into the bytes
    lt = min(length(dt.Changed{tt}),basic.BytesPerDataPacket-8);
    bytes(9 + (1:lt),tt) = dt.Changed{tt}(1:lt);
end
end % END function packetBytesConfig