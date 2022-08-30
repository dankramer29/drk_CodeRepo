function varargout = read(this,varargin)
% READ read data from NEV file
%
%   DATA = READ(THIS)
%   Read all available spike data from the largest recording block and from
%   all available channels; return values in the output DATA, with fields
%   for each type of available data. In this default mode, DATA will be a
%   struct containing fields related to spike data including Timestamps,
%   Units, Channels, and others (by default, waveforms will not be read).
%   It will also have a field named PacketIdx which represents the index
%   into the original set of data packets.
%
%   DATA = READ(...,'TIMESTAMP[S]',[ST ET]);
%   DATA = READ(...,'TIME[S]',[ST ET]);
%   Read data from the range of times (in seconds) or samples (in timestamp
%   sampling frequency) specified in [ST ET], where ST is the start of the
%   range and ET is the end of the range. Since it is possible that the NSP
%   clock might reset during a recording, there is also the possibility
%   that a time range may match multiple instances within the same NEV
%   file. The requested range will be matched to the available data in one
%   one of the following ways:
%
%   * If one and only one run of contiguous timestamps wholly contains the
%     requested time range, that run of timestamps will be used.
%   * If no run of contiguous timestamps contains the entire requested
%     range, the run that provides the largest range of timestamps within
%     [ST ET] will be used.
%   * If more than one run matches, an error will be thrown as there is no
%     way to implicitly infer which should be used.
%
%   Note that a "run of contiguous non-decreasing timestamps" may span one
%   or more recording blocks, i.e., when there is no clock reset between
%   blocks.
%
%   DATA = READ(...,'BL[OCKS]',LIST)
%   Specify the recording block(s) to read as integer values in BLOCKS. If
%   multiple blocks are requested, the outputs will consist of cell arrays
%   of structs, with one cell per block.
%
%   DATA = READ(...,'ALLBL[OCKS]')
%   Shortcut to specify reading from all available recording blocks.
%
%   DATA = READ(...,'HOURS'|'MINUTES'|'SECONDS'|'MILLISECONDS')
%   Specify the units with which to interpret arguments provided via the
%   'TIME[S]' key-value pair. Default is 'SECONDS'.
%
%   DATA = READ(...,'CH[ANNELS]',LIST)
%   DATA = READ(...,'EL[ECTRODES]',LIST)
%   Read values from the list of channels or electrodes specified in LIST
%   and return in DATA. LIST may be numeric, in which case each number is
%   interpreted as a ChannelID, or a string or cell array of strings, in
%   which case each string is interpreted as the Label of a channel. If a
%   list of electrodes is provided, a BLACKROCK.ARRAYMAP object must also
%   have been associated with the BLACKROCK.NEV object THIS.
%
%   DATA = READ(...,CLASS)
%   If waveform values are set to be read, they will be returned cast to
%   the class specified in CLASS: 'DOUBLE', 'SINGLE', 'INT32', or 'INT16'.
%   Waveform samples are stored as INT16 in NEV files, and memory
%   requirements will be larger than the file size if a larger
%   representation is requested. The default class is 'DOUBLE'.
%
%   DATA = READ(...,TYPE1,TYPE2,...,TYPEn,...)
%   Read the data types specified by TYPE1, TYPE2, ..., TYPEn. These inputs
%   may take the following char values (case insensitive): SPIKES,
%   COMMENTS, DIGITAL, VIDEO, TRACKING, BUTTONS, CONFIG. Each of the data
%   types, if there is such data in the NEV file, will have a corresponding
%   struct array stored in a self-named field of the output struct DATA.
%   For example, SPIKES will appear in DATA.SPIKES. Each of these data
%   types have their own set of fields:
%
%     SPIKES - fields PacketIdx, Timestamps, Units (sorted unit assignment:
%              0/unsorted, 255/noise, 1-254 sorted), and Channels (the
%              channel NOT electrode associated with the event).  By
%              default, waveforms are not read or returned.
%
%   COMMENTS - fields PacketIdx, Timestamps, CharSet (0/ANSI, 1/UTF-16),
%              Color (uint32 RGBA color code), and Text (each row a 92-char
%              vector, one row per data packet).
%
%    DIGITAL - fields Timestamps, PacketIdx, Flags (bit 0 set if digital
%              channel changed; bits 0 and 7 set if serial channel
%              changed), and Data (uint16 data recorded from the digital
%              input for the event).
%
%  VIDEOSYNC - fields Timestamps, PacketIdx, FileNumber (video file split
%              number, zero-based), FrameNumber (vide frame number, zero-
%              based), and SourceIDs (video source ID, zero-based).
%
%   TRACKING - fields Timestamps, PacketIdx, ParentID, NodeID, NodeCount,
%              PointCount, and Points.  See file spec for details.
%
%    BUTTONS - fields Timestamps, PacketIdx, and TriggerType.  See file
%              spec for details.
%
%     CONFIG - fields Timestamps, PacketIdx, ChangeType, and Changed.  See
%              file spec for details.
%    
%   DATA = READ(...,'WAVEFORMS')
%   Load the waveforms associated with each spike event as a separate field
%   ('WAVEFORMS') of the struct output. Only applicable when SPIKE data is
%   being read.
%
%   [DATA1,DATA2,...,DATAn] = READ(...,TYPE1,TYPE2,...,TYPEn)
%   Return the different data types as separate outputs, each its own
%   struct with one cell per block, instead of as a struct of struct
%   arrays. Outputs are returned in the order in which they are requested.
%
%   READ(...,'UNIFORMOUTPUT',TRUE|FALSE)
%   Specify whether to enforce uniform outputs, i.e. matrix output, or
%   nonuniform outputs, i.e. cell arrays. If TRUE, and if multiple
%   recording blocks have been read, elements across recording blocks will
%   be concatenated into matrices with no indication of block boundaries.
%   If FALSE, fields of the output will be in cell arrays regardless of
%   whether one or multiple recording blocks were read. Default is TRUE
%   when a single recording block is read, and FALSE when multiple
%   recording blocks are read.
if isempty(this.Timestamps)
    varargout = arrayfun(@(x)[],1:nargout,'UniformOutput',false);
    return;
end

% get packet information
[~,~,~,isPreResetBlock] = analyzeBlocks(this);

% force uniform (matrix, uniform length) or nonuniform (cell, different length) output
FlagUniformOutput = nan;
idx = strcmpi(varargin,'UniformOutput');
if any(idx)
    FlagUniformOutput = varargin{circshift(idx,1,2)};
    varargin(idx|circshift(idx,1,2)) = [];
end

% class of output data
OutputClass = 'double';
idx_char = find(cellfun(@ischar,varargin));
idx = ismember(cellfun(@lower,varargin(idx_char),'UniformOutput',false),{'double','single','int32','uint32','int16','uint16'});
if any(idx)
    OutputClass = varargin{idx_char(idx)};
    varargin(idx_char(idx)) = [];
end

% process user inputs
idx = strcmpi(varargin,'all');
if any(idx) % read everything
    
    % remove any conflicting inputs
    varargin(idx) = [];
    varargin(strcmpi(varargin,'waveforms')) = [];
    varargin(strcmpi(varargin,'allblocks')) = [];
    idx = strcmpi(varargin,'channels');
    if any(idx),varargin(idx|circshift(idx,1,2))=[];end
    varargin(strcmpi(varargin,'spikes')) = [];
    varargin(strcmpi(varargin,'comments')) = [];
    varargin(strcmpi(varargin,'digital')) = [];
    varargin(strcmpi(varargin,'videosync')) = [];
    varargin(strcmpi(varargin,'tracking')) = [];
    varargin(strcmpi(varargin,'buttons')) = [];
    varargin(strcmpi(varargin,'config')) = [];
    
    % configure inputs to read everything
    varargin = [varargin {'waveforms','allblocks','channels',[this.ChannelInfo.ChannelID],'spikes',...
        'comments','digital','videosync','tracking','buttons','config'}];
end

% flags for reading packet types
FlagPacketSpike = false;
FlagPacketComment = false;
FlagPacketDigital = false;
FlagPacketVideo = false;
FlagPacketTracking = false;
FlagPacketButton = false;
FlagPacketConfig = false;

% configure waveforms
FlagWaveform = false;
idx = strncmpi(varargin,'waveforms',3);
if any(idx)
    FlagWaveform = true;
    varargin(idx) = [];
    assert(~strcmpi(OutputClass(1:4),'uint'),'Cannot request unsigned integer type when waveforms are also requested');
end

% configure blocks
UserBlockInputs = [];
idx = strncmpi(varargin,'allblocks',5);
if any(idx)
    UserBlockInputs = arrayfun(@(x)x,1:this.NumRecordingBlocks,'UniformOutput',false);
    varargin(idx) = [];
else
    idx = strncmpi(varargin,'blocks',2);
    if any(idx)
        blk = varargin{circshift(idx,1,2)};
        varargin(idx|circshift(idx,1,2)) = [];
        if isnumeric(blk)
            UserBlockInputs = arrayfun(@(x)x,blk,'UniformOutput',false);
        elseif iscell(blk)
            UserBlockInputs = blk;
        else
            assert(ischar(blk)&&strcmpi(blk,'max'),'Non-numeric, non-cell input must be ''char'' value ''MAX''');
        end
    end
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
        assert(~isempty(this.hArrayMap),'Must have initialized ArrayMap object in order to convert channels into electrodes.');
        UserRequestedChannels = this.hArrayMap.el2ch(varargin{circshift(idx,1,2)});
        varargin(idx|circshift(idx,1,2)) = [];
    end
end
assert(~isempty(UserRequestedChannels),'No channels requested');
assert(all(ismember(UserRequestedChannels,[this.ChannelInfo.ChannelID])),'Invalid channel selection %s (available channels are %s)',util.vec2str(UserRequestedChannels),util.vec2str([this.ChannelInfo.ChannelID]));
log(this,sprintf('Channel selection %s',util.vec2str(UserRequestedChannels)),'info');

% identify data types to read from NEV file
UserRequestedPacketIDs = [];
idx = strncmpi(varargin,'spikes',2);
if any(idx)
    varargin(idx) = [];
    UserRequestedPacketIDs = [UserRequestedPacketIDs; UserRequestedChannels(:)];
    FlagPacketSpike = true;
end
idx = strncmpi(varargin,'comments',3);
if any(idx)
    varargin(idx) = [];
    UserRequestedPacketIDs = [UserRequestedPacketIDs; 65535];
    FlagPacketComment = true;
end
idx = strncmpi(varargin,'digital',3)|strncmpi(varargin,'serial',3);
if any(idx)
    varargin(idx) = [];
    UserRequestedPacketIDs = [UserRequestedPacketIDs; 0];
    FlagPacketDigital = true;
end
idx = strncmpi(varargin,'videosync',3);
if any(idx)
    varargin(idx) = [];
    UserRequestedPacketIDs = [UserRequestedPacketIDs; 65534];
    FlagPacketVideo = true;
end
idx = strncmpi(varargin,'tracking',2);
if any(idx)
    varargin(idx) = [];
    UserRequestedPacketIDs = [UserRequestedPacketIDs; 65533];
    FlagPacketTracking = true;
end
idx = strncmpi(varargin,'buttons',2);
if any(idx)
    varargin(idx) = [];
    UserRequestedPacketIDs = [UserRequestedPacketIDs; 65532];
    FlagPacketButton = true;
end
idx = strncmpi(varargin,'config',3);
if any(idx)
    varargin(idx) = [];
    UserRequestedPacketIDs = [UserRequestedPacketIDs; 65531];
    FlagPacketConfig = true;
end
if isempty(UserRequestedPacketIDs)
    UserRequestedPacketIDs = UserRequestedChannels;
    FlagPacketSpike = true;
    log(this,'Default packet selection (spikes only)','info');
end
if FlagPacketSpike && ~FlagWaveform
    log(this,'Reading spike data without waveforms','info');
end

% make sure correct number of outputs
NumFlaggedPackets = FlagPacketSpike + FlagPacketComment + ...
    FlagPacketDigital + FlagPacketVideo + FlagPacketTracking + ...
    FlagPacketButton + FlagPacketConfig;
assert(nargout==1|nargout==NumFlaggedPackets,'Requested %d outputs, but only %d will be generated',nargout,NumFlaggedPackets);

% identify requested packets
UserDataPointInputs = {};
idxTime = strncmpi(varargin,'time',4); % in seconds
idxTimestamps = strncmpi(varargin,'timestamps',9); % in timestamps
if any(idxTime) && ~any(idxTimestamps)
    
    % calculate the timing factor to convert from different time scales
    % (hours, minutes, etc.) to the timestamp sampling rate
    Time2Samples = this.ResolutionTimestamps; % default in seconds
    if any(strncmpi(varargin,'hours',4))
        Time2Samples = 60*60*this.ResolutionTimestamps;
    elseif any(strncmpi(varargin,'minutes',3))
        Time2Samples = 60*this.ResolutionTimestamps;
    elseif any(strncmpi(varargin,'seconds',3))
        Time2Samples = this.ResolutionTimestamps;
    elseif any(strncmpi(varargin,'milliseconds',5))
        Time2Samples = this.ResolutionTimestamps/1000;
    end
    
    % calculate data points based on timing input
    dpin = varargin{circshift(idxTime,1,2)};
    varargin(idxTime|circshift(idxTime,1,2)) = [];
    if ~iscell(dpin),dpin={dpin};end
    UserDataPointInputs = cell(1,length(dpin));
    for pp=1:length(dpin)
        assert(dpin{pp}(2)>dpin{pp}(1),'Time input must be in the form of [START END] (data point %d/%d has start time %.2f and end time %.2f)',pp,length(dpin),dpin{pp}(1),dpin{pp}(2));
        
        % convert time inputs to samples
        st = round(double(dpin{pp}(1))*Time2Samples);
        et = round(double(dpin{pp}(2))*Time2Samples)-1;
        
        % capture start/length
        UserDataPointInputs{pp} = [st et];
    end
elseif any(idxTimestamps)
    
    % calculate data points based on data point input
    dpin = varargin{circshift(idxTimestamps,1,2)};
    varargin(idxTimestamps|circshift(idxTimestamps,1,2)) = [];
    if ~iscell(dpin),dpin={dpin};end
    UserDataPointInputs = cell(1,length(dpin));
    for pp=1:length(dpin)
        assert(dpin{pp}(2)>dpin{pp}(1),'Data point input must be in the form of [START END]');
        
        % pull out start, length
        st = round(double(dpin{pp}(1)));
        et = round(double(dpin{pp}(2)));
        
        % interpret as samples (in this.Fs sampling rate)
        UserDataPointInputs{pp} = [st et];
    end
end
flagUserProvidedTimingInput = ~isempty(UserDataPointInputs);
flagUserProvidedBlockInput = ~isempty(UserBlockInputs);

% identify requested recording packets and their associated data points
% based on what values the user has provided
if ~flagUserProvidedTimingInput
    if ~flagUserProvidedBlockInput
        
        % neither provided - default to read all from largest block
        [~,RequestedBlocks{1}] = max(this.RecordingBlockPacketCount);
        RequestedDataPoints = {[1 this.RecordingBlockPacketCount(RequestedBlocks{1})]};
    else
        
        % user provided blocks but no data points
        assert(all(cellfun(@length,UserBlockInputs)==1),'UserBlockInputs must be cells with one block per cell');
        RequestedBlocks = UserBlockInputs;
        RequestedDataPoints = cellfun(@(x)[1 this.RecordingBlockPacketCount(x)],UserBlockInputs,'UniformOutput',false);
    end
else
    
    % The two remaining conditions:
    %  * user has provided timing information
    %  * user may or may not have specified blocks
    %
    % These conditions share overlapping code requirements:
    %  * if no block inputs, infer blocks based on time windows
    %  * if block provided, copy values over directly
    %  * in both cases, divvy up timing windows to set of requested blocks
    
    % Assign RequestedBlocks: infer from requested data points, or copy
    % from UserBlockInputs
    if ~flagUserProvidedBlockInput
        
        % user provided samples - try to infer which blocks
        RequestedBlocks = cell(1,length(UserDataPointInputs));
        for bb=1:length(UserDataPointInputs)
            
            % determine all blocks corresponding to requested time range
            [allBlocks,startBlock,endBlock] = getBlocksContainingTimestampWindow(this,UserDataPointInputs{bb}(1),UserDataPointInputs{bb}(2));
            
            % basic error checking
            assert( isscalar(startBlock), 'Multiple recording blocks match the requested start time');
            assert( isscalar(endBlock), 'Multiple recording blocks match the requested end time');
            assert( ~any(isPreResetBlock(allBlocks(1:end-1))), 'NSP clock reset occurs within the requested block range (unsupported due to timing ambiguity)');
            
            % assign the requested blocks
            RequestedBlocks{bb} = allBlocks;
        end
    else
        
        % validate user input
        assert(length(UserBlockInputs)==length(UserDataPointInputs),'Must provide same numbers of blocks and data points');
        
        % assign the requested blocks
        RequestedBlocks = UserBlockInputs;
    end
    
    % next assign RequestedDataPoints
    RequestedDataPoints = cell(1,length(UserDataPointInputs));
    for pp=1:length(UserDataPointInputs)
        
        % data points are in TimestampTimeResolution sampling rate
        st = UserDataPointInputs{pp}(1);
        et = UserDataPointInputs{pp}(2);
        
        % loop over the blocks and pull out matching time ranges
        numBlocks = length(RequestedBlocks{pp});
        RequestedDataPoints{pp} = nan(numBlocks,2);
        for bb=1:numBlocks
            currBlock = RequestedBlocks{pp}(bb);
            if bb==1
                
                % first block: mid-block starting point
                idx_st = find(this.Timestamps{currBlock}>=st,1,'first');
            else
                
                % otherwise, start from first timestamp
                idx_st = 1;
            end
            if bb==numBlocks
                
                % last block: mid-block ending point
                idx_et = find(this.Timestamps{currBlock}<=et,1,'last');
            else
                
                % otherwise, read until last timestamp
                idx_et = this.RecordingBlockPacketCount(currBlock);
            end
            RequestedDataPoints{pp}(bb,:) = [idx_st idx_et];
        end
    end
end
assert(isempty(varargin),'Unexpected inputs');

% validate block and data point values
assert(length(RequestedDataPoints)==length(RequestedBlocks),'Must provide a set of data points for each requested block');
selectedBlocks = unique(cat(2,RequestedBlocks{:}));
assert(all(isnan(selectedBlocks)|ismember(selectedBlocks,1:this.NumRecordingBlocks)),'Invalid packet selection %s (available blocks are %s)',util.vec2str(selectedBlocks),util.vec2str(1:this.NumRecordingBlocks));
for pp=1:length(RequestedDataPoints)
    assert(RequestedDataPoints{pp}(1)>=1&&RequestedDataPoints{pp}(2)<=this.RecordingBlockPacketCount(RequestedBlocks{pp}),'Data points for recording block %d are out of bounds',RequestedBlocks{pp});
end
log(this,sprintf('Block selection %s (available blocks %s)',util.vec2str(selectedBlocks(~isnan(selectedBlocks))),util.vec2str(1:this.NumRecordingBlocks)),'info');

% determine packets to be read
NumRequestedBlocks = length(RequestedBlocks);
UniqueRequestedPacketIDs = sort(unique(UserRequestedPacketIDs),'ascend');
MasterReqPacketIDs = cell(1,NumRequestedBlocks);
RequestedPacketIdx = cell(1,NumRequestedBlocks);
RequestedPacketIDs = cell(1,NumRequestedBlocks);
StartingByte = zeros(1,NumRequestedBlocks);
NumPackets = zeros(1,NumRequestedBlocks);
for bb = 1:NumRequestedBlocks
    
    % identify block
    BlockIdx = RequestedBlocks{bb};
    
    % identify user-requested start/end (from input 'time' or 'sample')
    UserStartIdx = RequestedDataPoints{bb}(1);
    UserEndIdx = RequestedDataPoints{bb}(2);
    
    % identify which packets to retain based on user-requested packet IDs
    % Master* is for identifying in the context of the whole file
    % Requested* is for keeping track of just the data packets read locally
    MasterReqPacketIdx = UserStartIdx:UserEndIdx;
    ReqPacketIDs = this.PacketIDs{BlockIdx}(MasterReqPacketIdx);
    MasterReqPacketIDs{bb} = nan(size(this.PacketIDs{BlockIdx}));
    MasterReqPacketIDs{bb}(MasterReqPacketIdx) = ReqPacketIDs;
    RequestedPacketIdx{bb} = ismember(ReqPacketIDs,UniqueRequestedPacketIDs);
    RequestedPacketIDs{bb} = ReqPacketIDs(RequestedPacketIdx{bb});
    
    % identify starting byte and number of packets to read for each block
    BlockStartingByte = this.BytesInHeaders + this.BytesPerDataPacket*(this.RecordingBlockPacketIdx(BlockIdx,1)-1); % zero-indexed
    UserStartOffset = this.BytesPerDataPacket*(UserStartIdx-1); % zero-indexed
    StartingByte(bb) = BlockStartingByte + UserStartOffset;
    NumPackets(bb) = UserEndIdx-UserStartIdx+1;
end

% update uniform output
if isnan(FlagUniformOutput)
    FlagUniformOutput = NumRequestedBlocks==1;
end

% open file for reading
DataPackets = cell(1,NumRequestedBlocks);
nevfile = fullfile(this.SourceDirectory,[this.SourceBasename this.SourceExtension]);
[fid,errmsg] = fopen(nevfile,'r');
assert(fid>0,'Could not open NEV file ''%s'' for reading: %s',nevfile,errmsg);

% read data from file
try
    for bb = 1:NumRequestedBlocks
        status = fseek(fid,StartingByte(bb)+6,'bof'); % first 6 bytes of the first packet (packet ID and timestamp already read)
        assert(status>=0,'Error reading file: %s',ferror(fid));
        DataPackets{bb} = fread(fid,...
            [this.BytesPerDataPacket-6 NumPackets(bb)],...
            [num2str(this.BytesPerDataPacket-6) '*uint8=>uint8'],6);
        
        % retain only requested packets
        DataPackets{bb} = DataPackets{bb}(:,RequestedPacketIdx{bb});
    end
catch ME
    fclose(fid);
    util.errorMessage(ME);
    return;
end
fclose(fid);

% process data packets
PacketTypeList = cell(1,NumFlaggedPackets);
PacketDataIdx = 1;

% process Spike Event packets (PacketID>=1 && PacketID<=2048)
if FlagPacketSpike
    Spike = cell(1,NumRequestedBlocks);
    for bb = 1:NumRequestedBlocks
        BlockIdx = RequestedBlocks{bb};
        RequestedReq = ismember(RequestedPacketIDs{bb},UserRequestedChannels);
        MasterReqSpikeIdx = ismember(MasterReqPacketIDs{bb},UserRequestedChannels);
        if ~any(MasterReqSpikeIdx)
            Spike{bb} = [];
        else
            Spike{bb}.RecordingBlock = cast(BlockIdx,OutputClass);
            Spike{bb}.PacketIdx = cast(find(MasterReqSpikeIdx),OutputClass);
            Spike{bb}.Timestamps = cast(this.Timestamps{BlockIdx}(MasterReqSpikeIdx),OutputClass);
            Spike{bb}.Units = cast(double(DataPackets{bb}(1,RequestedReq))',OutputClass);
            Spike{bb}.Channels = cast(MasterReqPacketIDs{bb}(MasterReqSpikeIdx),OutputClass);
            if ~isempty(this.hArrayMap)
                Spike{bb}.Electrodes = cast(this.hArrayMap.ch2el(Spike{bb}.Channels),OutputClass);
                Spike{bb}.Electrodes = Spike{bb}.Electrodes(:);
            end
            if FlagWaveform
                assert(this.AllSpikeWaveform16Bit,'Cannot handle the case where not all waveforms are 16-bit (code is close if you want to finish it yourself)');
                WaveformBytes = DataPackets{bb}(3:end,RequestedReq);
                Spike{bb}.Waveforms = cast(reshape(typecast(WaveformBytes(:),'int16'),[this.ChannelInfo(1).SpikeWidthSamples,length(Spike{bb}.PacketIdx)]),OutputClass);
                % Spike{bb}.Waveforms = zeros(this.ChannelInfo(1).SpikeWidthSamples,length(Spike{bb}.PacketIdx));
                % for pp = Spike{bb}.PacketIdx(:)'
                %     RequestedPacketIdx = RequestedReq(pp);
                %     MasterPacketIdx = MasterReqSpikeIdx(pp);
                %     SamplesPerWaveform = this.ChannelInfo(Spike{bb}.Channels(MasterPacketIdx)).SpikeWidthSamples;
                %     BytesPerSample = this.ChannelInfo(Spike{bb}.Channels(MasterPacketIdx)).BytesPerWaveformSample;
                %     BytesPerWaveform = BytesPerSample * SamplesPerWaveform;
                %     WaveformSampleIdx = 3:(3+BytesPerWaveform-1);
                %     switch BytesPerSample
                %         case 1, type = 'int8';
                %         case 2, type = 'int16';
                %         case 4, type = 'int32';
                %         case 8, type = 'int64';
                %         otherwise, error('Cannot process channel %d waveforms with %d bytes per sample.',Spike{bb}.Channels(MasterPacketIdx),BytesPerSample);
                %     end
                %     Spike{bb}.Waveforms(:,RequestedPacketIdx) = typecast(DataPackets{bb}(WaveformSampleIdx,RequestedPacketIdx),type);
                % end
            end % FlagWaveform
        end % MasterReq
    end % UserRequestedBlocks
    
    % load metadata
    if this.MetadataRead
        Spike = loadMetadata(this,Spike,'Spike',RequestedBlocks);
    end
    
    % finishing touches
    if all(cellfun(@isempty,Spike))
        FlagPacketSpike = false;
    else
        Spike = processUniformity(Spike,FlagUniformOutput);
        PacketData.Spike = Spike;
        PacketTypeList{PacketDataIdx} = 'Spike';
        PacketDataIdx = PacketDataIdx + 1;
    end
end

% process Comment Event packets (PacketID==65535)
if FlagPacketComment
    Comment = cell(1,NumRequestedBlocks);
    for bb = 1:NumRequestedBlocks
        BlockIdx = RequestedBlocks{bb};
        RequestedReq = ismember(RequestedPacketIDs{bb},65535);
        MasterReqCommentIdx = ismember(MasterReqPacketIDs{bb},65535);
        if ~any(MasterReqCommentIdx)
            Comment{bb} = [];
        else
            Comment{bb}.RecordingBlock = cast(BlockIdx,OutputClass);
            Comment{bb}.PacketIdx = cast(find(MasterReqCommentIdx),OutputClass);
            Comment{bb}.Timestamps = cast(this.Timestamps{BlockIdx}(MasterReqCommentIdx),OutputClass);
            
            Comment{bb}.CharSet = DataPackets{bb}(1,RequestedReq)';
            ColorBytes = DataPackets{bb}(3:6,RequestedReq);
            Comment{bb}.Color = typecast(ColorBytes(:),'uint32');
            CommentsBytes = DataPackets{bb}(7:end,RequestedReq);
            Comment{bb}.Text = cell(size(CommentsBytes,2),1);
            for cc = 1:length(Comment{bb}.Text)
                st = 1;
                lt = find(CommentsBytes(:,cc)==0,1,'first');
                if isempty(lt)
                    log(this,'Comments must be NULL terminated','debug');
                    lt = size(CommentsBytes,1);
                end
                Comment{bb}.Text{cc} = char(CommentsBytes(st:lt-1,cc)');
            end
        end % MasterReq
    end % UserRequestedBlocks
    
    % load metadata
    if this.MetadataRead
        Comment = loadMetadata(this,Comment,'Comment',RequestedBlocks);
    end
    
    % finishing touches
    if all(cellfun(@isempty,Comment))
        FlagPacketComment = false;
    else
        Comment = processUniformity(Comment,FlagUniformOutput);
        PacketData.Comment = Comment;
        PacketTypeList{PacketDataIdx} = 'Comment';
        PacketDataIdx = PacketDataIdx + 1;
    end
end

% process Digital Event packets (PacketID == 0)
if FlagPacketDigital
    Digital = cell(1,NumRequestedBlocks);
    for bb = 1:NumRequestedBlocks
        BlockIdx = RequestedBlocks{bb};
        RequestedReq = ismember(RequestedPacketIDs{bb},0);
        MasterReqDigitalIdx = ismember(MasterReqPacketIDs{bb},0);
        if ~any(MasterReqDigitalIdx)
            Digital{bb} = [];
        else
            Digital{bb}.RecordingBlock = cast(BlockIdx,OutputClass);
            Digital{bb}.PacketIdx = cast(find(MasterReqDigitalIdx),OutputClass);
            Digital{bb}.Timestamps = cast(this.Timestamps{BlockIdx}(MasterReqDigitalIdx),OutputClass);
            
            Digital{bb}.Flags = DataPackets{bb}(1,RequestedReq);
            DataBytes = DataPackets{bb}(3:4,RequestedReq);
            Digital{bb}.Data = typecast(DataBytes(:),'uint16');
        end
    end
    
    % load metadata
    if this.MetadataRead
        Digital = loadMetadata(this,Digital,'Digital',RequestedBlocks);
    end
    
    % finishing touches
    if all(cellfun(@isempty,Digital))
        FlagPacketDigital = false;
    else
        Digital = processUniformity(Digital,FlagUniformOutput);
        PacketData.Digital = Digital;
        PacketTypeList{PacketDataIdx} = 'Digital';
        PacketDataIdx = PacketDataIdx + 1;
    end
end

% process Video Sync Event packets (PacketID==65534)
if FlagPacketVideo
    Video = cell(1,NumRequestedBlocks);
    for bb = 1:NumRequestedBlocks
        BlockIdx = RequestedBlocks{bb};
        RequestedReq = ismember(RequestedPacketIDs{bb},65534);
        MasterReqVideoIdx = ismember(MasterReqPacketIDs{bb},65534);
        if ~any(MasterReqVideoIdx)
            Video{bb} = [];
        else
            Video{bb}.RecordingBlock = cast(BlockIdx,OutputClass);
            Video{bb}.PacketIdx = cast(find(MasterReqVideoIdx),OutputClass);
            Video{bb}.Timestamps = cast(this.Timestamps{BlockIdx}(MasterReqVideoIdx),OutputClass);
            
            FileNumberBytes = DataPackets{bb}(1:2,RequestedReq);
            Video{bb}.FileNumber = typecast(FileNumberBytes(:),'uint16');
            FrameNumberBytes = DataPackets{bb}(3:6,RequestedReq);
            Video{bb}.FrameNumber = typecast(FrameNumberBytes(:),'uint32');
            SourceIDBytes = DataPackets{bb}(7:10,RequestedReq);
            Video{bb}.SourceIDs = typecast(SourceIDBytes(:),'uint32');
        end
    end
    
    % load metadata
    if this.MetadataRead
        Video = loadMetadata(this,Video,'Video',RequestedBlocks);
    end
    
    % finishing touches
    if all(cellfun(@isempty,Video))
        FlagPacketVideo = false;
    else
        Video = processUniformity(Video,FlagUniformOutput);
        PacketData.Video = Video;
        PacketTypeList{PacketDataIdx} = 'Video';
        PacketDataIdx = PacketDataIdx + 1;
    end
end

% process Tracking Event packets (PacketID==65533)
if FlagPacketTracking
    Tracking = cell(1,NumRequestedBlocks);
    for bb = 1:NumRequestedBlocks
        BlockIdx = RequestedBlocks{bb};
        RequestedReq = ismember(RequestedPacketIDs{bb},65533);
        MasterReqTrackingIdx = ismember(MasterReqPacketIDs{bb},65533);
        if ~any(MasterReqTrackingIdx)
            Tracking{bb} = [];
        else
            Tracking{bb}.RecordingBlock = cast(BlockIdx,OutputClass);
            Tracking{bb}.PacketIdx = cast(find(MasterReqTrackingIdx),OutputClass);
            Tracking{bb}.Timestamps = cast(this.Timestamps{BlockIdx}(MasterReqTrackingIdx),OutputClass);
            
            ParentIDBytes = DataPackets{bb}(1:2,RequestedReq);
            Tracking{bb}.ParentID = typecast(ParentIDBytes(:),'uint16');
            NodeIDBytes = DataPackets{bb}(3:4,RequestedReq);
            Tracking{bb}.NodeID = typecast(NodeIDBytes(:),'uint16');
            NodeCountBytes = DataPackets{bb}(5:6,RequestedReq);
            Tracking{bb}.NodeCount = typecast(NodeCountBytes(:),'uint16');
            PointCountBytes = DataPackets{bb}(7:8,RequestedReq);
            Tracking{bb}.PointCount = typecast(PointCountBytes(:),'uint16');
            PointsBytes = DataPackets{bb}(9:end,RequestedReq);
            Tracking{bb}.Points = reshape(typecast(PointsBytes(:),'uint16'),[size(PointsBytes,1) length(Tracking{bb}.PacketIdx)]);
        end
    end
    
    % load metadata
    if this.MetadataRead
        Tracking = loadMetadata(this,Tracking,'Tracking',RequestedBlocks);
    end
    
    % finishing touches
    if all(cellfun(@isempty,Tracking))
        FlagPacketTracking = false;
    else
        Tracking = processUniformity(Tracking,FlagUniformOutput);
        PacketData.Tracking = Tracking;
        PacketTypeList{PacketDataIdx} = 'Tracking';
        PacketDataIdx = PacketDataIdx + 1;
    end
end

% process Button Event packets (PacketID==65532)
if FlagPacketButton
    Button = cell(1,NumRequestedBlocks);
    for bb = 1:NumRequestedBlocks
        BlockIdx = RequestedBlocks{bb};
        RequestedReq = ismember(RequestedPacketIDs{bb},65532);
        MasterReqButtonIdx = ismember(MasterReqPacketIDs{bb},65532);
        if ~any(MasterReqButtonIdx)
            Button{bb} = [];
        else
            Button{bb}.RecordingBlock = cast(BlockIdx,OutputClass);
            Button{bb}.PacketIdx = cast(find(MasterReqButtonIdx),OutputClass);
            Button{bb}.Timestamps = cast(this.Timestamps{BlockIdx}(MasterReqButtonIdx),OutputClass);
            
            TriggerTypeBytes = DataPackets{bb}(1:2,RequestedReq);
            Button{bb}.TriggerType = typecast(TriggerTypeBytes(:),'uint16');
        end
    end
    
    % load metadata
    if this.MetadataRead
        Button = loadMetadata(this,Button,'Button',RequestedBlocks);
    end
    
    % finishing touches
    if all(cellfun(@isempty,Button))
        FlagPacketButton = false;
    else
        Button = processUniformity(Button,FlagUniformOutput);
        PacketData.Button = Button;
        PacketTypeList{PacketDataIdx} = 'Button';
        PacketDataIdx = PacketDataIdx + 1;
    end
end

% process Config Event packets (PacketID==65531)
if FlagPacketConfig
    Config = cell(1,NumRequestedBlocks);
    for bb = 1:NumRequestedBlocks
        BlockIdx = RequestedBlocks{bb};
        RequestedReq = ismember(RequestedPacketIDs{bb},65531);
        MasterReqConfigIdx = ismember(MasterReqPacketIDs{bb},65531);
        if ~any(MasterReqConfigIdx)
            Config{bb} = [];
        else
            Config{bb}.RecordingBlock = cast(BlockIdx,OutputClass);
            Config{bb}.PacketIdx = cast(find(MasterReqConfigIdx),OutputClass);
            Config{bb}.Timestamps = cast(this.Timestamps{BlockIdx}(MasterReqConfigIdx),OutputClass);
            
            ChangeTypeBytes = DataPackets{bb}(1:2,RequestedReq);
            type = typecast(ChangeTypeBytes(:),'uint16');
            Config{bb}.ChangeType = type;
            Config{bb}.ChangeTypeString = cell(size(ChangeTypeBytes,2),1);
            for cc = 1:length(Config{bb}.ChangeTypeString)
                if type(cc)==0
                    Config{bb}.ChangeTypeString{cc} = 'normal';
                elseif type(cc)==1
                    Config{bb}.ChangeTypeString{cc} = 'critical';
                else
                    Config{bb}.ChangeTypeString{cc} = sprintf('unknown (%d)',type(cc));
                end
            end
            
            ChangedBytes = DataPackets{bb}(3:end,RequestedReq);
            Config{bb}.Changed = cell(size(ChangedBytes,2),1);
            for cc = 1:length(Config{bb}.Changed)
                st = 1;
                lt = find(ChangedBytes(:,cc)==0,1,'first');
                if isempty(lt)
                    log(this,'Comments must be NULL terminated','warn');
                    lt = size(ChangedBytes,1);
                end
                Config{bb}.Changed{cc} = char(ChangedBytes(st:lt-1,cc)');
            end
        end
    end
    
    % load metadata
    if this.MetadataRead
        Config = loadMetadata(this,Config,'Config',RequestedBlocks);
    end
    
    % finishing touches
    if all(cellfun(@isempty,Config))
        FlagPacketConfig = false;
    else
        Config = processUniformity(Config,FlagUniformOutput);
        PacketData.Config = Config;
        PacketTypeList{PacketDataIdx} = 'Config';
    end
end

% assign outputs
if nargout==1 && NumFlaggedPackets==1
    
    % single output: no structs or cells
    varargout{1} = PacketData.(PacketTypeList{1});
    if FlagUniformOutput && iscell(varargout{1}) && length(varargout{1})==1
        varargout{1} = varargout{1}{1};
    end
elseif nargout==1 && NumFlaggedPackets>1
    
    % multiple data times requested but single output: struct
    varargout{1} = PacketData;
else
    
    % multiple outputs, multiple data types: cell
    varargout = cell(1,NumFlaggedPackets);
    idx = 1;
    if FlagPacketSpike
        varargout{idx} = PacketData.Spike;
        idx = idx + 1;
    end
    if FlagPacketComment
        varargout{idx} = PacketData.Comment;
        idx = idx + 1;
    end
    if FlagPacketDigital
        varargout{idx} = PacketData.Digital;
        idx = idx + 1;
    end
    if FlagPacketVideo
        varargout{idx} = PacketData.Video;
        idx = idx + 1;
    end
    if FlagPacketTracking
        varargout{idx} = PacketData.Tracking;
        idx = idx + 1;
    end
    if FlagPacketButton
        varargout{idx} = PacketData.Buttons;
        idx = idx + 1;
    end
    if FlagPacketConfig
        varargout{idx} = PacketData.Config;
    end
end

function dataStruct = loadMetadata(this,dataStruct,dataType,RequestedBlocks)
% LOADMETADATA Load metadata into the data structure
%
%   DATASTRUCT = LOADMETADATA(THIS,DATASTRUCT,DATATYPE)
%   For the data type identified by string DATATYPE, and its associated
%   data in the struct DATASTRUCT, load any available metadata and
%   integrate the metadata into DATASTRUCT.
NumUserRequestedBlocks = length(RequestedBlocks);

% check whether metadata is potentially available
mtfile = fullfile(this.MetaDirectory,sprintf('%s%s',this.MetaBasename,this.MetaExtension));
mtfields = Blackrock.NEV.getMetadataFields(dataType);
flagOk = ~isempty(mtfields);

% check the file size (<=128 bytes indicates empty mat file
if flagOk
    info = dir(mtfile);
    flagOk = info.bytes>128;
end

% attempt to read list of variable names
if flagOk
    try
        vars = util.matwho(mtfile);
    catch ME
        util.errorMessage(ME);
        flagOk = false;
    end
end

% read data from MAT file
if flagOk && any(strcmpi(vars,dataType))
    mt = load(mtfile,dataType);
    assert(iscell(mt.(dataType))&&length(mt.(dataType))==this.NumRecordingBlocks,'Invalid %s metadata - must be cell array with %d cells (one per recording block',dataType,this.NumRecordingBlocks);
    for bb=1:NumUserRequestedBlocks
        BlockIdx = RequestedBlocks{bb};
        for mm=1:length(mtfields)
            if isfield(mt.(dataType){BlockIdx},mtfields{mm})
                dataStruct{bb}.(mtfields{mm}) = mt.(dataType){BlockIdx}.(mtfields{mm});
            end
        end
    end
end

function dataStruct = processUniformity(dataStruct,FlagUniformOutput)
% PROCESSUNIFORMITY Enforce either uniform or nonuniform output

% validate input
assert(iscell(dataStruct),'Input data must be cell array');

% process
if FlagUniformOutput
    if length(dataStruct)==1
        
        % simple case of single requested recording block
        dataStruct = dataStruct{1};
    else
        
        % user requested uniform output
        oldData = dataStruct;
        dataStruct = struct;
        fields = fieldnames(oldData{1});
        for ff=1:length(fields)
            
            % collect this field's data across all recording blocks
            dt = cellfun(@(x)x.(fields{ff}),oldData,'UniformOutput',false);
            
            % handle empty cells
            idx_empty = cellfun(@isempty,dt);
            dt(idx_empty) = [];
            if isempty(dt)
                dataStruct.(fields{ff}) = [];
                continue;
            end
            
            % concatenate the data along the one unequal dimension
            % (only one dimension can be unequal across blocks)
            sz = cellfun(@size,dt,'UniformOutput',false);
            sz = cat(1,sz{:});
            num_unique = arrayfun(@(x)numel(unique(sz(:,x))),1:size(sz,2));
            try
            assert(nnz(num_unique==1)>=(length(num_unique)-1),'There cannot be more than one dimension which is not the same across all recording blocks');
            catch me
                util.errorMessage(me)
                keyboard
            end
            dim = find(num_unique~=1,1,'first');
            if isempty(dim),dim=1;end
            dataStruct.(fields{ff}) = cat(dim,dt{:});
        end
    end
end