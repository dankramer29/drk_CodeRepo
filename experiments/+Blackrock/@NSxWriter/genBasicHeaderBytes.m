function [bytes,info] = genBasicHeaderBytes(info,commentString)

% label
LabelBytes = cast(info.Label(1:min(length(info.Label),15)),'uint8');
LabelBytes(end+1:16) = 0; % null-terminated, 16-byte

% comment field
if nargin<2||isempty(commentString),commentString = '';end
CommentBytes = cast(commentString(1:min(255,length(commentString))),'uint8');
CommentBytes(end+1:256) = 0; % null-terminated, 256-byte

% validate info
reqfields = {'FileTypeID','FileSpecMajor','FileSpecMinor','BytesInHeaders',...
    'Label','Comment','TimestampsPerSample','TimestampTimeResolution',...
    'TimeOrigin','ChannelCount'};
missing = ~ismember(reqfields,fieldnames(info));
assert(~any(missing),'Must provide all required fields including %s',strjoin(reqfields(missing),', '));
assert(ischar(info.FileTypeID),'FileTypeID must be char, not ''%s''',class(info.FileTypeID));
assert(length(info.FileTypeID)==8,'FileTypeID must be 8 characters long, not %d',length(info.FileTypeID));
assert(isnumeric(info.FileSpecMajor)&isnumeric(info.FileSpecMinor),'FileSpecMajor and FileSpecMinor must be numeric, not ''%s''',strjoin(unique({class(info.FileSpecMajor),class(info.FileSpecMinor)}),', '));
assert(isnumeric(info.BytesInHeaders),'BytesInHeaders must be numeric, not ''%s''',class(info.BytesInHeaders));
assert(isnumeric(info.TimestampTimeResolution),'TimestampTimeResolution must be numeric, not ''%s''',class(info.TimestampTimeResolution));
assert(isnumeric(info.TimestampsPerSample),'TimestampsPerSample must be numeric, not ''%s''',class(info.TimestampsPerSample));
assert(isnumeric(info.TimeOrigin),'TimeOrigin must be numeric, not ''%s''',class(info.TimeOrigin));
assert(length(info.TimeOrigin)==8,'TimeOrigin must be a vector of length 8, not %d (one element for each of Year, Month, DayOfWeek, Day, Hour, Minute, Second, and Millisecond)',length(info.TimeOrigin));

% bytes
bytes = zeros(Blackrock.NSx.BasicHeaderSize,1,'uint8');
bytes(1:8)      = cast(info.FileTypeID,'uint8');
bytes(9:10)     = typecast(cast([info.FileSpecMajor info.FileSpecMinor],'uint8'),'uint8');
bytes(11:14)    = typecast(cast(info.BytesInHeaders,'uint32'),'uint8');
bytes(15:30)    = LabelBytes;
bytes(31:286)   = CommentBytes;
bytes(287:290)  = typecast(cast(info.TimestampsPerSample,'uint32'),'uint8');
bytes(291:294)  = typecast(cast(info.TimestampTimeResolution,'uint32'),'uint8');
bytes(295:310)  = typecast(cast(info.TimeOrigin,'uint16'),'uint8');
bytes(311:314)  = typecast(cast(info.ChannelCount,'uint32'),'uint8');