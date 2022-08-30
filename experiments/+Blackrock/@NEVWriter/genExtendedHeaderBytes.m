function [bytes,info] = genExtendedHeaderBytes(info)

% number of extended headers; note several are still unsupported
NumExtendedHeaders = 3*length(info.ChannelInfo) + length(info.DigitalInfo) + ~isempty(info.ArrayName) + ~isempty(info.ExtHeaderIndicatedMapFile);

% default null values
bytes = zeros(1,32*NumExtendedHeaders,'uint8');
idx = 0;
for cc = 1:length(info.ChannelInfo)
    lbl = info.ChannelInfo(cc).Label;
    lbl = lbl(1:min(length(lbl),15));
    lbl(end+1:16) = 0; % 16-byte, null-terminated
    switch lower(info.ChannelInfo(cc).HighFilterType)
        case 'butterworth', HighFilterType = 1;
        case 'none', HighFilterType = 0;
        otherwise, error('Unrecognized high filter type ''%s'' for electrode %d',info.ChannelInfo(cc).HighFilterType,cc);
    end
    switch lower(info.ChannelInfo(cc).LowFilterType)
        case 'butterworth', LowFilterType = 1;
        case 'none', LowFilterType = 0;
        otherwise, error('Unrecognized low filter type ''%s'' for electrode %d',info.ChannelInfo(cc).LowFilterType,cc);
    end
    
    % 1: NEUEVWAV
    bytes(idx + (1:8))      = cast('NEUEVWAV','uint8');
    bytes(idx + (9:10))     = typecast(cast(info.ChannelInfo(cc).ChannelID,'uint16'),'uint8');
    bytes(idx + (11))       = typecast(cast(info.ChannelInfo(cc).PhysicalConnector-64,'uint8'),'uint8');
    bytes(idx + (12))       = typecast(cast(info.ChannelInfo(cc).ConnectorPin,'uint8'),'uint8');
    bytes(idx + (13:14))    = typecast(cast(info.ChannelInfo(cc).DigitizationFactor,'uint16'),'uint8');
    bytes(idx + (15:16))    = typecast(cast(info.ChannelInfo(cc).EnergyThreshold,'uint16'),'uint8');
    bytes(idx + (17:18))    = typecast(cast(info.ChannelInfo(cc).HighThreshold,'int16'),'uint8');
    bytes(idx + (19:20))    = typecast(cast(info.ChannelInfo(cc).LowThreshold,'int16'),'uint8');
    bytes(idx + (21))       = typecast(cast(info.ChannelInfo(cc).NumSortedUnits,'uint8'),'uint8');
    bytes(idx + (22))       = typecast(cast(info.ChannelInfo(cc).BytesPerWaveformSample,'uint8'),'uint8');
    bytes(idx + (23:24))    = typecast(cast(info.ChannelInfo(cc).SpikeWidthSamples,'uint16'),'uint8');
    bytes(idx + (25:32))    = zeros(1,8,'uint8');
    idx = idx + 32;
    
    % 2: NEUEVLBL
    bytes(idx + (1:8))      = cast('NEUEVLBL','uint8');
    bytes(idx + (9:10))     = typecast(cast(info.ChannelInfo(cc).ChannelID,'uint16'),'uint8');
    bytes(idx + (11:26))    = cast(lbl,'uint8');
    bytes(idx + (27:32))    = zeros(1,6,'uint8');
    idx = idx + 32;
    
    % 3: NEUEVFLT
    bytes(idx + (1:8))      = cast('NEUEVFLT','uint8');
    bytes(idx + (9:10))     = typecast(cast(info.ChannelInfo(cc).ChannelID,'uint16'),'uint8');
    bytes(idx + (11:14))    = typecast(cast(info.ChannelInfo(cc).HighFreqCorner,'uint32'),'uint8');
    bytes(idx + (15:18))    = typecast(cast(info.ChannelInfo(cc).HighFreqOrder,'uint32'),'uint8');
    bytes(idx + (19:20))    = typecast(cast(HighFilterType,'uint16'),'uint8');
    bytes(idx + (21:24))    = typecast(cast(info.ChannelInfo(cc).LowFreqCorner,'uint32'),'uint8');
    bytes(idx + (25:28))    = typecast(cast(info.ChannelInfo(cc).LowFreqOrder,'uint32'),'uint8');
    bytes(idx + (29:30))    = typecast(cast(LowFilterType,'uint16'),'uint8');
    bytes(idx + (31:32))    = zeros(1,2,'uint8');
    idx = idx + 32;
end

for dd = 1:length(info.DigitalInfo)
    lbl = info.DigitalInfo(dd).Label;
    lbl = lbl(1:min(length(lbl),15));
    lbl(end+1:16) = 0; % 16-byte, null-terminated
    if lbl(end)~=char(0), lbl(end)=uint8(0); end
    switch lower(info.DigitalInfo(dd).Mode)
        case 'serial', DigMode = 0;
        case 'parallel', DigMode = 1;
        otherwise, error('Unrecognized digital channel mode ''%s''',info.DigitalInfo(dd).Mode);
    end
    
    % 1: DIGLABEL
    bytes(idx + (1:8))      = cast('DIGLABEL','uint8');
    bytes(idx + (9:24))     = cast(lbl,'uint8');
    bytes(idx + (25))       = cast(DigMode,'uint8');
    bytes(idx + (26:32))    = zeros(1,7,'uint8');
    idx = idx + 32;
end

if ~isempty(info.ArrayName)
    nm = info.ArrayName;
    nm = nm(1:min(length(nm),23));
    nm(end+1:24) = 0; % 16-byte, null-terminated
    if nm(end)~=char(0), nm(end)=uint8(0); end
    
    % 1: ARRAYNME
    bytes(idx + (1:8))      = cast('ARRAYNME','uint8');
    bytes(idx + (9:32))     = cast(nm,'uint8');
    idx = idx + 32;
end

if ~isempty(info.ExtraComment)
    warning('ExtraComment field is not supported');
end

if ~isempty(info.ExtHeaderIndicatedMapFile)
    mp = info.ExtHeaderIndicatedMapFile;
    mp = mp(1:min(length(mp),23));
    mp(end+1:24) = 0; % 16-byte, null-terminated
    if mp(end)~=char(0), mp(end)=uint8(0); end
    
    % 1: MAPFILE
    bytes(idx + (1:7))      = cast('MAPFILE','uint8');
    bytes(idx + (9:32))     = cast(mp,'uint8');
    idx = idx + 32;
end

if ~isempty(info.VideoInfo)
    warning('VideoInfo is not supported');
end

if ~isempty(info.TrackingInfo)
    warning('TrackingInfo is not supported');
end