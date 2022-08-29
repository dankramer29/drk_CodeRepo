function [bytes,info] = genExtendedHeaderBytes(info)

% number of extended headers
NumChannels = length(info.ChannelInfo);

% default null values
bytes = cell(1,NumChannels);
idx_keep = true(NumChannels,1);
for cc=1:NumChannels
    if isempty(info.ChannelInfo(cc).ChannelID)
        idx_keep(cc) = false;
        continue;
    end
    
    % prior computation
    LabelBytes = cast(info.ChannelInfo(cc).Label,'uint8');
    LabelBytes = LabelBytes(1:min(length(LabelBytes),15));
    LabelBytes(end+1:16) = 0; % 16-byte, null-terminated
    UnitsBytes = cast(info.ChannelInfo(cc).Units,'uint8');
    UnitsBytes = UnitsBytes(1:min(length(UnitsBytes),15));
    UnitsBytes(end+1:16) = 0; % 16-byte, null-terminated
    switch lower(info.ChannelInfo(cc).HighFilterType)
        case 'butterworth', HighFilterType = typecast(cast(1,'uint16'),'uint8');
        case 'none', HighFilterType = typecast(cast(0,'uint16'),'uint8');
        otherwise, error('Unrecognized high filter type ''%s'' for electrode %d',info.ChannelInfo(cc).HighFilterType,cc);
    end
    switch lower(info.ChannelInfo(cc).LowFilterType)
        case 'butterworth', LowFilterType = typecast(cast(1,'uint16'),'uint8');
        case 'none', LowFilterType = typecast(cast(0,'uint16'),'uint8');
        otherwise, error('Unrecognized low filter type ''%s'' for electrode %d',info.ChannelInfo(cc).LowFilterType,cc);
    end
    
    % create byte vector
    bytes{cc} = zeros(66,1,'uint8');
    bytes{cc}(1:2) = cast('CC','uint8');
    bytes{cc}(3:4) = typecast(cast(info.ChannelInfo(cc).ChannelID,'uint16'),'uint8');
    bytes{cc}(5:20) = LabelBytes;
    bytes{cc}(21) = typecast(cast(info.ChannelInfo(cc).PhysicalConnector-64,'uint8'),'uint8');
    bytes{cc}(22) = typecast(cast(info.ChannelInfo(cc).ConnectorPin,'uint8'),'uint8');
    bytes{cc}(23:24) = typecast(cast(info.ChannelInfo(cc).MinDigitalValue,'int16'),'uint8');
    bytes{cc}(25:26) = typecast(cast(info.ChannelInfo(cc).MaxDigitalValue,'int16'),'uint8');
    bytes{cc}(27:28) = typecast(cast(info.ChannelInfo(cc).MinAnalogValue,'int16'),'uint8');
    bytes{cc}(29:30) = typecast(cast(info.ChannelInfo(cc).MaxAnalogValue,'int16'),'uint8');
    bytes{cc}(31:46) = UnitsBytes;
    bytes{cc}(47:50) = typecast(cast(info.ChannelInfo(cc).HighFreqCorner,'uint32'),'uint8');
    bytes{cc}(51:54) = typecast(cast(info.ChannelInfo(cc).HighFreqOrder,'uint32'),'uint8');
    bytes{cc}(55:56) = HighFilterType;
    bytes{cc}(57:60) = typecast(cast(info.ChannelInfo(cc).LowFreqCorner,'uint32'),'uint8');
    bytes{cc}(61:64) = typecast(cast(info.ChannelInfo(cc).LowFreqOrder,'uint32'),'uint8');
    bytes{cc}(65:66) = LowFilterType;
end
bytes(~idx_keep) = [];
bytes = cat(1,bytes{:});