function varargout = read(this,varargin)
% READ Read data from NSx file
%
%   DATA = READ(THIS)
%   Read all available channels of data from the largest data packet;
%   return values in DATA with output class 'double' and with normalized 
%   units (normalized to the digital min/max found in the channel info).
%
%   DATA = READ(...,'POINT[S]',[ST ET])
%   DATA = READ(...,'TIME[S]',[ST ET])
%   DATA = READ(...,'TIMESTAMP[S]',[ST ET])
%   Read values from the range of times (in seconds), points (in data
%   sampling frequency), or timestamps (in TimestampTimeResolution sampling
%   frequency) specified in [ST ET], where ST is the start of the range and
%   ET is the end of the range. Time and timestamps are both zero-indexed
%   (by Blackrock convention, i.e. 0 corresponds to the first sample)
%   whereas data points are 1-indexed (i.e. 1 corresponds to the first
%   sample). Requested data are returned in DATA.
%
%   DATA = READ(...,'REF[ERENCE]','PACKET'|'TIMESTAMP')
%   Select the timing reference point for interpreting the timing inputs.
%   Two options are available: packet or timestamp. In "packet" mode, the
%   first available time corresponds to the first available sample in a
%   packet. In "timestamp" mode, the first time corresponds to either:
%
%       (1) the 0 timestamp for any packet starting with a clock reset
%           (e.g. the first packet or the packet immediately after two NSPs
%           sync); note that the first sample may occur at some timestamp
%           larger than 0.
%       (2) the first sample in the packet for any other packet.
%
%   See "Timestamp" property of parent object. Default is "timestamp".
%
%   DATA = READ(...,TIMEUNITS)
%   Specify the units with which to interpret arguments provided via the
%   'TIME[S]' key-value pair. TIMEUNITS must be CHAR, and may take any of
%   the following values: 'HOURS', 'MINUTES', 'SECONDS', or 'MILLISECONDS'.
%
%   DATA = READ(...,'PACK[ETS]',PKT)
%   DATA = READ(...,'PACK[ETS]','MAX')
%   Read values from the data packet(s) specified in PKT. If multiple
%   packets are listed, any TIME or POINTS input must be a cell array with
%   one cell per packet, and DATA will be a cell array with one cell per
%   packet. If PKT is set to 'MAX', then the largest packet will be used.
%
%   DATA = READ(...,'CH[ANNELS]',LIST)
%   DATA = READ(...,'EL[ECTRODES]',LIST)
%   Read values from the list of channels or electrodes specified in LIST
%   and return in DATA. LIST may be numeric, in which case each number is
%   interpreted as a ChannelID, or a string or cell array of strings, in
%   which case each string is interpreted as the Label of a channel. If a
%   list of electrodes is provided, a BLACKROCK.ARRAYMAP object must also
%   have been associated with the BLACKROCK.NSX object THIS.
%
%   DATA = READ(...,CLASS)
%   Return values in DATA of class CLASS: 'DOUBLE', 'SINGLE', 'INT32', or
%   'INT16'. Data is stored as INT16 in NSx files, and memory requirements
%   will be larger than the file size if a larger representation is
%   requested. The default class is 'DOUBLE'.
%
%   DATA = READ(...,UNITS)
%   Return values in DATA with the units specified in UNITS: 'NORMALIZED',
%   'MICROVOLTS', 'MILLIVOLTS', or 'VOLTS'. The default is 'MICROVOLTS'.
%
%   DATA = READ(...,'Q[UIET]')
%   Do not print warnings or other information to the command window.
%
%   [TF,SZ,BYT] = READ(...,'MEMCHECK')
%   Determine the size of the requested data (SZ), whether it will fit in
%   memory (TF), and how many bytes per data element (BYT; i.e. 8 bytes for
%   double). Return without reading any actual data.

% get packet information
[packetStartTimestamp,packetEndTimestamp,~,isShortPacket,isPreResetPacket,~,~] = analyzePackets(this);

% identify reference point for timing inputs
idxReference = strncmpi(varargin,'reference',3);
UserRequestedTimeReference = 'timestamp'; % timestamp, packet
if any(idxReference)
    UserRequestedTimeReference = varargin{circshift(idxReference,1,2)};
    varargin(idxReference|circshift(idxReference,1,2)) = [];
end

% identify requested data packet
UserPacketInputs = {};
idx = strncmpi(varargin,'allpackets',4);
if any(idx)
    UserPacketInputs = arrayfun(@(x)x,1:this.NumDataPackets,'UniformOutput',false);
    varargin(idx|circshift(idx,1,2)) = [];
else
    idx = strncmpi(varargin,'packets',4);
    if any(idx)
        pkt = varargin{circshift(idx,1,2)};
        varargin(idx|circshift(idx,1,2)) = [];
        if isnumeric(pkt)
            UserPacketInputs = arrayfun(@(x)x,pkt,'UniformOutput',false);
        elseif iscell(pkt)
            UserPacketInputs = pkt;
        else
            assert(ischar(pkt)&&strcmpi(pkt,'max'),'Non-numeric, non-cell input must be ''char'' value ''MAX''');
        end
    end
end

% calculate the multiplicative factor between the TimestampTimeResolution
% and the data sampling frequency Fs
if rem(this.TimestampTimeResolution/this.Fs,1)~=0
    log(this,'Non-integer relationship between TimestampTimerResolution and the data sampling frequency! Manually verify all results, particularly checking for rounding errors','warn');
end

% class of output data
OutputClass = 'double';
idx_char = find(cellfun(@ischar,varargin));
idx = ismember(cellfun(@lower,varargin(idx_char),'UniformOutput',false),{'double','single','int32','uint32','int16','uint16'});
if any(idx)
    OutputClass = varargin{idx_char(idx)};
    varargin(idx_char(idx)) = [];
end
switch lower(OutputClass)
    case 'double',OutputClassBytes=8;
    case {'single','int32','uint32'},OutputClassBytes=4;
    case {'int16','uint16'},OutputClassBytes=2;
    otherwise,error('Unknown data class');
end

% units of output data
OutputUnits = 'microvolts';
idx_char = find(cellfun(@ischar,varargin));
idx = ismember(cellfun(@lower,varargin(idx_char),'UniformOutput',false),{'microvolts','millivolts','volts','normalized'});
if any(idx)
    OutputUnits = varargin{idx_char(idx)};
    varargin(idx_char(idx)) = [];
end
switch lower(OutputUnits)
    case {'microvolts','millivolts','volts'},ProcessingBytes=8;
    case 'normalized',ProcessingBytes=OutputClassBytes;
    otherwise,error('Unknown output units');
end

% select channels
UserRequestedChannels = sort([this.ChannelInfo.ChannelID],'ascend');
idx = strncmpi(varargin,'channels',2);
if any(idx)
    UserRequestedChannels = varargin{circshift(idx,1,2)};
    varargin(idx|circshift(idx,1,2)) = [];
    if ischar(UserRequestedChannels) || (iscell(UserRequestedChannels) && ~isempty(UserRequestedChannels) && all(cellfun(@ischar,UserRequestedChannels)))
        UserRequestedChannelStrings = util.ascell(UserRequestedChannels);
        UserRequestedChannels = nan(1,length(UserRequestedChannelStrings));
        for nn=1:length(UserRequestedChannelStrings)
            labelIdx = arrayfun(@(x)strcmpi(x.Label,UserRequestedChannelStrings{nn}),this.ChannelInfo);
            assert(any(labelIdx),'Could not find a matching channel with label ''%s''',UserRequestedChannelStrings{nn});
            UserRequestedChannels(nn) = find(labelIdx);
        end
    end
else
    idx = strncmpi(varargin,'electrodes',2);
    if any(idx)
        assert(~isempty(this.hArrayMap),'Must having initialized ArrayMap object in order to convert electrodes into channels.');
        UserRequestedChannels = this.hArrayMap.el2ch(varargin{circshift(idx,1,2)});
        varargin(idx|circshift(idx,1,2)) = [];
    end
end
assert(~isempty(UserRequestedChannels),'No channels requested');
assert(all(ismember(UserRequestedChannels,[this.ChannelInfo.ChannelID])),'Invalid channel selection %s (available channels are %s)',util.vec2str(UserRequestedChannels),util.vec2str([this.ChannelInfo.ChannelID]));
log(this,sprintf('Channel selection %s',util.vec2str(UserRequestedChannels)),'info');

% identify requested timestamps
% since Timestamps are the highest-resolution marker used for any indexing
% in NSx files, and since the Timestamps header field is always in
% TimestampTimerResolution even if the sampling rate Fs is lower, we
% convert everything to Timestamps here (convert to packet index later).
% Also note that here, timing inputs are interpreted as being in the
% "timestamp" reference frame, i.e., 0-indexed and packets may start at a
% timestamp greater than 0.
UserTimestampInputs = {};
idxTime = strncmpi(varargin,'time',4); % in seconds
idxTimestamps = strncmpi(varargin,'timestamps',9); % in timestamps
idxPoints = strncmpi(varargin,'points',5); % in samples
if any(idxTime) && ~any(idxTimestamps)
    
    % calculate the timing factor to convert from different time scales
    % (hours, minutes, etc.) to the data sampling rate
    Time2Samples = this.Fs; % default convert seconds to ttr (timestamp timer resolution)
    if any(strcmpi(varargin,'hours'))
        Time2Samples = 60*60*this.Fs;
    elseif any(strcmpi(varargin,'minutes'))
        Time2Samples = 60*this.Fs;
    elseif any(strcmpi(varargin,'seconds'))
        Time2Samples = this.Fs;
    elseif any(strcmpi(varargin,'milliseconds'))
        Time2Samples = this.Fs/1000;
    end
    
    % calculate data points based on timing input
    dpin = varargin{circshift(idxTime,1,2)};
    varargin(idxTime|circshift(idxTime,1,2)) = [];
    if ~iscell(dpin),dpin=arrayfun(@(x)dpin(x,:),1:size(dpin,1),'UniformOutput',false);end
    UserTimestampInputs = cell(1,length(dpin));
    for pp=1:length(dpin)
        assert(dpin{pp}(2)>dpin{pp}(1),'Time input must be in the form of [START END]');
        
        % convert time inputs to a timestamp, referencing the
        % times (0-indexed) to the timestamp of the packet (i.e.
        % the one specified in the Timestamp header field).
        st = round(double(dpin{pp}(1))*Time2Samples*this.fs2ttr); % at this point, time "0 sec" is timestamp "0"
        
        % convert length to number of timestamps
        len = round(double(diff(dpin{pp}))*Time2Samples*this.fs2ttr); % at this point, length "1" is 1 timestamp
        
        % capture start/length
        UserTimestampInputs{pp} = [st len];
    end
elseif any(idxTimestamps)
    
    % pull out timestamp input
    dpin = varargin{circshift(idxTimestamps,1,2)};
    varargin(idxTimestamps|circshift(idxTimestamps,1,2)) = [];
    if ~iscell(dpin),dpin=arrayfun(@(x)dpin(x,:),1:size(dpin,1),'UniformOutput',false);end
    UserTimestampInputs = cell(1,length(dpin));
    for pp=1:length(dpin)
        assert(dpin{pp}(2)>=dpin{pp}(1),'Timestamp input must be in the form of [START END]');
        
        % user provided timestamp inputs
        st = round(double(dpin{pp}(1)));
        len = round(double(diff(dpin{pp})+1));
        UserTimestampInputs{pp} = [st len];
    end
elseif any(idxPoints)
    
    % calculate timestamps based on data point input
    dpin = varargin{circshift(idxPoints,1,2)};
    varargin(idxPoints|circshift(idxPoints,1,2)) = [];
    if ~iscell(dpin),dpin=arrayfun(@(x)dpin(x,:),1:size(dpin,1),'UniformOutput',false);end
    UserTimestampInputs = cell(1,length(dpin));
    for pp=1:length(dpin)
        assert(dpin{pp}(2)>=dpin{pp}(1),'Data point input must be in the form of [START END]');
        
        % user provided data point inputs (1-indexed) so convert to
        % timestamps (0-indexed)
        st = round((double(dpin{pp}(1)-1)*this.fs2ttr)); % here point "1" is timestamp "0"
        len = round(double(diff(dpin{pp})+1)*this.fs2ttr); % here length "1" is 1*fs2ttr timestamps
        UserTimestampInputs{pp} = [st len];
    end
end
flagUserProvidedTimingInput = ~isempty(UserTimestampInputs);
flagUserProvidedPacketInput = ~isempty(UserPacketInputs);

% identify requested recording packets and their associated data points
% based on what values the user has provided
if ~flagUserProvidedTimingInput
    if ~flagUserProvidedPacketInput
        
        % nothing provided - default to read all from largest packet
        [~,RequestedPackets{1}] = max(this.PointsPerDataPacket);
        RequestedDataPointIdx = {[1 this.PointsPerDataPacket(RequestedPackets{1})]};
    else
        
        % user provided packets but no data points or times
        assert(all(cellfun(@length,UserPacketInputs)==1),'UserPacketInputs must be cells with one packet per cell');
        RequestedPackets = UserPacketInputs;
        RequestedDataPointIdx = cellfun(@(x)[1 this.PointsPerDataPacket(x)],RequestedPackets,'UniformOutput',false);
    end
else
    
    % The two remaining conditions:
    %  * user has provided timing information
    %  * user may or may not have specified packets
    %
    % These conditions share overlapping code requirements:
    %  * if no packet inputs, infer packets based on time windows
    %  * if packet provided, copy values over directly
    %  * in both cases, divvy up timing windows to set of requested packets
    
    % Assign RequestedPackets: infer from requested data points, or copy
    % from UserPacketInputs
    if ~flagUserProvidedPacketInput
        
        % user provided timing information but no packets; try to infer
        % which packets based on the requested timing
        RequestedPackets = cell(1,length(UserTimestampInputs));
        for pp = 1:length(UserTimestampInputs)
            
            % determine all packets corresponding to requested time range
            st = UserTimestampInputs{pp}(1);
            et = UserTimestampInputs{pp}(2);
            [allPackets,startDataPacket,~,endDataPacket] = getPacketsContainingTimestampWindow(this,st,et,UserRequestedTimeReference);
            nonanPackets = allPackets;
            nonanPackets(isnan(nonanPackets)) = [];
            
            % basic error checking
            assert( isempty(startDataPacket)||isscalar(startDataPacket), 'Multiple recording packets match the requested start time');
            assert( isscalar(endDataPacket), 'Multiple recording packets match the requested end time');
            assert( ~any(isPreResetPacket(nonanPackets(1:end-1))), 'NSP clock reset occurs within the requested packet range (unsupported due to timing ambiguity)');
            
            % assign the requested packets
            RequestedPackets{pp} = allPackets;
        end
    else
        
        % validate user input
        assert(length(UserPacketInputs)==length(UserTimestampInputs),'Must provide same numbers of packets and data points');
        
        % assign the requested packets
        RequestedPackets = UserPacketInputs;
    end
    
    % next assign RequestedDataPointIdx
    RequestedDataPointIdx = cell(1,length(UserTimestampInputs));
    for pp=1:length(UserTimestampInputs)
        
        % already in TimestampTimeResolution
        st = UserTimestampInputs{pp}(1);
        len = UserTimestampInputs{pp}(2);
        
        % check if we need to add NaNs when requesting timestamps outside
        % the packet boundaries
        numPackets = length(RequestedPackets{pp});
        flagAddBefore = false;
        flagAddAfter = false;
        flagReplace = false;
        for nn=1:numPackets
            currPacket = RequestedPackets{pp}(nn);
            if isnan(currPacket),continue;end
            if packetEndTimestamp(currPacket)-packetStartTimestamp(currPacket)<0
                flagReplace = true;
            else
                switch UserRequestedTimeReference
                    case 'packet'
                        if st<0 && (nn==1||(nn>1&&~isnan(RequestedPackets{pp}(nn-1))))
                            flagAddBefore = true;
                        end
                        if (st+len-1)>(packetEndTimestamp(currPacket)-packetStartTimestamp(currPacket)+1) && (nn==numPackets||(nn<numPackets&&~isnan(RequestedPackets{pp}(nn+1))))
                            flagAddAfter = true;
                        end
                    case 'timestamp'
                        if st<packetStartTimestamp(currPacket) && (nn==1||(nn>1&&~isnan(RequestedPackets{pp}(nn-1))))
                            flagAddBefore = true;
                        end
                        if (st+len-1)>packetEndTimestamp(currPacket) && (nn==numPackets||(nn<numPackets&&~isnan(RequestedPackets{pp}(nn+1))))
                            flagAddAfter = true;
                        end
                end
            end
        end
        if flagReplace && (isempty(RequestedPackets{pp}) || (length(RequestedPackets{pp})>=1 && ~isnan(RequestedPackets{pp}(1))))
            RequestedPackets{pp} = nan;
        end
        if flagAddBefore && (isempty(RequestedPackets{pp}) || (length(RequestedPackets{pp})>=1 && ~isnan(RequestedPackets{pp}(1))))
            RequestedPackets{pp} = [nan RequestedPackets{pp}];
        end
        if flagAddAfter && (isempty(RequestedPackets{pp}) || (length(RequestedPackets{pp})>=1 && ~isnan(RequestedPackets{pp}(end))))
            RequestedPackets{pp} = [RequestedPackets{pp} nan];
        end
        
        % determine data points needed from each packet
        allPackets = RequestedPackets{pp};
        numPackets = length(allPackets);
        RequestedDataPointIdx{pp} = nan(numPackets,2);
        for nn=1:numPackets
            
            % identify current data packet
            currPacket = allPackets(nn);
            
            % fill in NaNs, or specify data to read
            if isnan(currPacket)
                
                % fill with NaNs; figure out how many samples of NaNs we
                % need to generate. first look for previous/next valid
                % packet (this one is a NaN).
                nextValidPacket = allPackets(nn + find(~isnan(allPackets(nn+1:end)),1,'first'));
                lastValidPacket = allPackets(find(~isnan(allPackets(1:nn-1)),1,'last'));
                
                % start at 1
                local_st = 1;
                
                % if first/last packet, or if no more valid packets, fill
                % to end of requested data range; otherwise fill the gap
                if ~isempty(nextValidPacket) && ~isempty(lastValidPacket)
                    
                    % number of NaNs is equal to number of samples between
                    % last packet's end and next packet's beginning
                    nextPacketStart = packetStartTimestamp(nextValidPacket);
                    prevPacketEnd = packetEndTimestamp(lastValidPacket);
                    local_len = (nextPacketStart-1)-(prevPacketEnd+1) + 1;
                elseif ~isempty(nextValidPacket) && isempty(lastValidPacket)
                    
                    % at least one more valid packet, and none valid
                    % previous to this packet
                    local_len = packetStartTimestamp(nextValidPacket) - st;
                elseif isempty(nextValidPacket) && ~isempty(lastValidPacket)
                    
                    % no more valid packets, but at least one before this
                    local_len = len - nansum(RequestedDataPointIdx{pp}(:,2))*this.fs2ttr;
                else
                    
                    % no valid packets anywhere
                    local_len = len;
                end
            else
                
                % fill with actual data
                % calculate where to start reading in the packet
                switch UserRequestedTimeReference
                    case 'packet'
                        local_st = st + 1;
                        lenPacket = (packetEndTimestamp(currPacket)-packetStartTimestamp(currPacket)+1) - st;
                    case 'timestamp'
                        local_st = st - packetStartTimestamp(currPacket) + 1;
                        lenPacket = packetEndTimestamp(currPacket) - st + 1;
                end
                assert(local_st>=1,'Bad logic: starting value %d is invalid (<1)',local_st);
                
                % end of requested time could fall within the current data
                % packet or in a subsequent packet
                lenRequest = len;
                local_len = min(lenPacket,lenRequest);
            end
            
            % update the start timestamp
            st = st + local_len; % next sample after this segment
            
            % detect short packets (see note for idxShortPacket)
            if ~isnan(currPacket) && isShortPacket(currPacket)
                
                % update the length to reflect a full data point
                assert(local_len <= this.fs2ttr,'Bad logic: short packet length %d is larger than TimestampTimerResolution/Fs %d',local_len,this.fs2ttr);
                local_len = this.fs2ttr;
            end
            
            % update the length
            len = len - local_len;
            
            % resample the start/length into the data sampling
            % frequency (note the subtract one prior to resampling,
            % and the add one after resampling - to keep indexing
            % straight.
            resamp_st = round(max(0,local_st-1)/this.fs2ttr)+1;
            resamp_len = round(local_len/this.fs2ttr);
            RequestedDataPointIdx{pp}(nn,:) = [resamp_st resamp_len];
            
            % break early if no more length requested
            if len==0
                if nn<numPackets
                    RequestedPackets{pp}(nn+1:end) = [];
                    RequestedDataPointIdx{pp}(nn+1:end,:) = [];
                end
                break;
            end
        end
        assert(round(len)==0,'Bad logic: leftover data (%d samples)',len);
    end
end
assert(length(RequestedDataPointIdx)==length(RequestedPackets),'Must provide a set of data points for each requested packet');
selectedPackets = unique(cat(2,RequestedPackets{:}));
assert(all(isnan(selectedPackets)|ismember(selectedPackets,1:this.NumDataPackets)),'Invalid packet selection %s (available packets are %s)',util.vec2str(selectedPackets),util.vec2str(1:this.NumDataPackets));
log(this,sprintf('Packet selection %s (available packets %s)',util.vec2str(selectedPackets(~isnan(selectedPackets))),util.vec2str(1:this.NumDataPackets)),'info');

% remove any packets with zero requested samples
for pp = 1:length(RequestedPackets)
    toRemove = false(1,length(RequestedPackets{pp}));
    for nn=1:length(RequestedPackets{pp})
        if RequestedDataPointIdx{pp}(nn,2)==0
            toRemove(nn) = true;
        end
    end
    RequestedPackets{pp}(toRemove) = [];
    RequestedDataPointIdx{pp}(toRemove,:) = [];
end

% check boundaries
for pp = 1:length(RequestedPackets)
    for nn=1:length(RequestedPackets{pp})
        assert(~any(isnan(RequestedDataPointIdx{pp}(nn,:)))&&RequestedDataPointIdx{pp}(nn,2)>0,'Must request 1 or more data points (provide time ranges in the form of [start last])');
        if isnan(RequestedPackets{pp}(nn))
            continue;
        elseif RequestedDataPointIdx{pp}(nn,1) < 1 || ...
                (RequestedDataPointIdx{pp}(nn,1)+RequestedDataPointIdx{pp}(nn,2)-1) > this.PointsPerDataPacket(RequestedPackets{pp}(nn))
            error('Invalid range for packet %d: requested [%d %d], available [1 %d]',RequestedPackets{pp}(nn),RequestedDataPointIdx{pp}(nn,:),this.PointsPerDataPacket(RequestedPackets{pp}(nn)));
        end
    end
end

% create index into packets to pull out just the requested electrodes
AvailableChannels = [this.ChannelInfo.ChannelID];
UserRequestedChannelIdx = nan(size(UserRequestedChannels));
for cc = 1:length(UserRequestedChannels)
    idx = find(AvailableChannels==UserRequestedChannels(cc));
    assert(~isempty(idx),'Channel %d is not present in list of available channels.',UserRequestedChannels(cc));
    assert(nnz(idx)==1,'Channel %d corresponds to multiple entries in the list of available channels.',UserRequestedChannels(cc));
    UserRequestedChannelIdx(cc) = idx;
end

% check system resources
NumPoints = 0;
for pp = 1:length(RequestedPackets)
    NumPoints = NumPoints + sum(RequestedDataPointIdx{pp}(:,2));
end
sz = [length(UserRequestedChannelIdx) NumPoints];

% check the check flag
if any(strcmpi(varargin,'memcheck'))
    tf = util.memcheck(sz,ProcessingBytes,...
        'TotalUtilization',0.975,...
        'AvailableUtilization',1,...
        'quiet');
    varargout = {tf,sz,ProcessingBytes};
    return;
end
util.argempty(varargin);

% (finally) read data from file
DataPackets = cell(1,length(RequestedPackets));
nsxfile = fullfile(this.SourceDirectory,[this.SourceBasename this.SourceExtension]);
[fid,errmsg] = fopen(nsxfile,'r');
assert(fid>0,'Could not open NSx file ''%s'' for writing: %s',nsxfile,errmsg);
try
    for pp = 1:length(RequestedPackets)
        DataPackets{pp} = cell(1,length(RequestedPackets{pp}));
        for nn=1:length(RequestedPackets{pp})
            
            if isnan(RequestedPackets{pp}(nn))
                
                % determine the number of NaNs needed
                NumPoints = RequestedDataPointIdx{pp}(nn,2);
                
                % create NaNs
                DataPackets{pp}{nn} = nan(length(UserRequestedChannelIdx),NumPoints);
                
                % cast to target class
                if ~strcmpi(class(DataPackets{pp}{nn}),OutputClass)
                    DataPackets{pp}{nn} = cast(DataPackets{pp}{nn},OutputClass);
                end
            else
                
                % pre-calculate the number of data points to be read
                PacketIdx = RequestedPackets{pp}(nn);
                PacketDataStartByte = this.DataPacketByteIdx(PacketIdx,1)+9; % 9 bytes of header data
                PacketDataOffset = (RequestedDataPointIdx{pp}(nn,1)-1)*2*this.ChannelCount;
                log(this,sprintf('Packet %d/%d, Segment %d/%d: Packet %d, Offset %d, DataPoints %s',...
                    pp,length(RequestedPackets),nn,length(RequestedPackets{pp}),...
                    PacketIdx,PacketDataOffset,util.vec2str(RequestedDataPointIdx{pp}(nn,:),'[%d]')),'info');
                StartByte = PacketDataStartByte + PacketDataOffset;
                NumPoints = RequestedDataPointIdx{pp}(nn,2);
                
                % read the appropriate number of bytes from the file
                status = fseek(fid,StartByte,'bof'); % first 9 bytes are header with ID,Timestamp,NumDataPoints
                assert(status>=0,'Error reading file: %s',ferror(fid));
                DataPackets{pp}{nn} = fread(fid,[this.ChannelCount NumPoints],'*int16');
                assert(size(DataPackets{pp}{nn},2)==NumPoints,'Requested %d bytes, but fread returned %d bytes (file size %d bytes)',...
                    NumPoints,size(DataPackets{pp}{nn},2),this.SourceFileSize);
                
                % retain only requested channels
                DataPackets{pp}{nn} = DataPackets{pp}{nn}(UserRequestedChannelIdx,:);
                
                % convert units and data type
                if strcmpi(OutputUnits,'normalized')
                    
                    % for normalized output units, convert to output class directly
                    if ~strcmpi(class(DataPackets{pp}{nn}),OutputClass)
                        DataPackets{pp}{nn} = cast(DataPackets{pp}{nn},OutputClass);
                    end
                else
                    
                    % check if all requested source/dest ranges are same
                    dh = zeros(1,length(UserRequestedChannelIdx)); % data high (source range)
                    dl = zeros(1,length(UserRequestedChannelIdx)); % data low (source range)
                    nh = zeros(1,length(UserRequestedChannelIdx)); % normalized high (dest range)
                    nl = zeros(1,length(UserRequestedChannelIdx)); % normalized low (dest range)
                    for kk=1:length(UserRequestedChannelIdx)
                        
                        % get the channel and its settings
                        chidx = UserRequestedChannelIdx(kk);
                        chinfo = this.ChannelInfo(AvailableChannels(chidx));
                        dh(kk) = chinfo.MaxDigitalValue; % data high value
                        dl(kk) = chinfo.MinDigitalValue; % data low value
                        nh(kk) = chinfo.MaxAnalogValue; % normalized high value
                        nl(kk) = chinfo.MinAnalogValue; % normalized low value
                    end
                    
                    % unlikely to find channels with different digital or analog
                    % min/max so punting on this issue for now
                    assert(...
                        numel(unique(dh))==1 && numel(unique(dl))==1 && numel(unique(nh))==1 && numel(unique(nl))==1,...
                        'Conversion to *volts is not yet supported when channels have different Digital/Analog ranges! Use default ''normalized'' output units');
                    
                    % reduce to single unique value
                    unique_dh = unique(dh);
                    unique_dl = unique(dl);
                    unique_nh = unique(nh);
                    unique_nl = unique(nl);
                    
                    % determine multiplicative factor for volt/milli/micro
                    switch lower(OutputUnits)
                        case 'microvolts', multfactor=1;
                        case 'millivolts', multfactor=1e-3;
                        case 'volts', multfactor=1e-6;
                        otherwise, error('Unknown output units "%s"',OutputUnits);
                    end
                    
                    % will be performing division/multiplication, need double
                    if ~strcmpi(class(DataPackets{pp}{nn}),OutputClass)
                        DataPackets{pp}{nn} = cast(DataPackets{pp}{nn},OutputClass);
                        if multfactor<1 && (strncmpi(OutputClass,'int',3)||strncmpi(OutputClass,'uint',4))
                            warning('Requested output units of %s but data class is %s (likely to encounter significant numerical problems)');
                        end
                    end
                    
                    % loop over unique values
                    for dd=1:length(unique_dh)
                        idx = dh==unique_dh(dd);
                        
                        % convert to voltage, scale to requested unit
                        DataPackets{pp}{nn}(idx,:) = multfactor*((DataPackets{pp}{nn}(idx,:)-unique_dl(dd))*(unique_nh(dd)-unique_nl(dd))/(unique_dh(dd)-unique_dl(dd)) + unique_nl(dd));
                    end
                end
            end
        end
        
        % combine the packets into single cell
        DataPackets{pp} = cat(2,DataPackets{pp}{:});
    end
catch ME
    fclose(fid);
    rethrow(ME);
end

% close the file
fclose(fid);

% assign outputs
varargout = DataPackets;