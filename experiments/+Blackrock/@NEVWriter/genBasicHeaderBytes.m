function [bytes,info] = genBasicHeaderBytes(info,numExtendedHeaders)
if nargin>=2&&~isempty(numExtendedHeaders)
    info.NumExtendedHeaders = numExtendedHeaders;
    info.BytesInHeaders = Blackrock.NEVWriter.BasicHeaderSize + 32*numExtendedHeaders;
end

% application name
ApplicationNameBytes = cast(info.ApplicationName(1:min(length(info.ApplicationName),31)),'uint8');
ApplicationNameBytes(end+1:32) = 0; % null-terminated, 32-byte

% comment field
commentString = '';
CommentBytes = cast(commentString(1:min(255,length(commentString))),'uint8');
CommentBytes(end+1:256) = 0; % null-terminated, 256-byte

% validate info
reqfields = {'FileTypeID','FileSpecMajor','FileSpecMinor','AdditionalFlags','BytesInHeaders',...
    'BytesPerDataPacket','ResolutionTimestamps','ResolutionSamples','TimeOrigin',...
    'NumExtendedHeaders'};
missing = ~ismember(reqfields,fieldnames(info));
assert(~any(missing),'Must provide all required fields including %s',strjoin(reqfields(missing),', '));
assert(ischar(info.FileTypeID),'FileTypeID must be char, not ''%s''',class(info.FileTypeID));
assert(length(info.FileTypeID)==8,'FileTypeID must be 8 characters long, not %d',length(info.FileTypeID));
assert(isnumeric(info.FileSpecMajor)&isnumeric(info.FileSpecMinor),'FileSpecMajor and FileSpecMinor must be numeric, not ''%s''',strjoin(unique({class(info.FileSpecMajor),class(info.FileSpecMinor)}),', '));
assert(isnumeric(info.AdditionalFlags),'AdditionalFlags must be numeric, not ''%s''',class(info.AdditionalFlags));
assert(isnumeric(info.BytesInHeaders),'BytesInHeaders must be numeric, not ''%s''',class(info.BytesInHeaders));
assert(isnumeric(info.BytesPerDataPacket),'BytesPerDataPacket must be numeric, not ''%s''',class(info.BytesPerDataPacket));
assert(isnumeric(info.ResolutionTimestamps),'ResolutionTimestamps must be numeric, not ''%s''',class(info.ResolutionTimestamps));
assert(isnumeric(info.ResolutionSamples),'ResolutionSamples must be numeric, not ''%s''',class(info.ResolutionSamples));
assert(isnumeric(info.TimeOrigin),'TimeOrigin must be numeric, not ''%s''',class(info.TimeOrigin));
assert(length(info.TimeOrigin)==8,'TimeOrigin must be a vector of length 8, not %d (one element for each of Year, Month, DayOfWeek, Day, Hour, Minute, Second, and Millisecond)',length(info.TimeOrigin));

% bytes
bytes = zeros(1,Blackrock.NEV.BasicHeaderSize,'uint8');
bytes(1:8)      = cast(info.FileTypeID,'uint8');
bytes(9:10)     = typecast(cast([info.FileSpecMajor info.FileSpecMinor],'uint8'),'uint8');
bytes(11:12)    = typecast(cast(info.AdditionalFlags,'uint16'),'uint8');
bytes(13:16)    = typecast(cast(info.BytesInHeaders,'uint32'),'uint8');
bytes(17:20)    = typecast(cast(info.BytesPerDataPacket,'uint32'),'uint8');
bytes(21:24)    = typecast(cast(info.ResolutionTimestamps,'uint32'),'uint8');
bytes(25:28)    = typecast(cast(info.ResolutionSamples,'uint32'),'uint8');
bytes(29:44)    = typecast(cast(info.TimeOrigin,'uint16'),'uint8');
bytes(45:76)    = ApplicationNameBytes;
bytes(77:332)   = CommentBytes;
bytes(333:336)  = typecast(cast(info.NumExtendedHeaders,'uint32'),'uint8');