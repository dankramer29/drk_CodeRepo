function updateChannelInfo(blc,channel_id,user_input,varargin)

% process inputs
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,nan);
if ~found_debug
    debug = Debug.Debugger('updateChannelInfo','screen');
end
if ischar(blc)
    assert(exist(blc,'file')==2,'Could not find BLc file "%s"',blc);
    blc = BLc.Reader(blc,debug);
end
assert(isa(blc,'BLc.Reader'),'Must provide valid BLc.Reader object, not "%s"',class(blc));
util.argempty(varargin);

% validate channel input
if isnumeric(channel_id)
    idx_channel_info = find([blc.ChannelInfo.ChannelNumber]==channel_id,1,'first');
    assert(~isempty(idx_channel_info),'Could not find channel %d',channel_id);
elseif ischar(channel_id)
    idx_channel_info = find(strcmpi(channel_id,{blc.ChannelInfo.Label}));
    assert(~isempty(idx_channel_info),'Could not find channel "%s"',channel_id);
else
    error('Unknown channel ID type "%s"',class(channel_id));
end
assert(~isempty(idx_channel_info) && idx_channel_info>0 && idx_channel_info<=blc.ChannelCount,'Could not find requested channel');

% process updated information
user_info = struct('ChannelNumber',blc.ChannelInfo(idx_channel_info).ChannelNumber);
if isstruct(user_input)
    if isfield(user_input,'Label')
        user_info.Label = user_input.Label;
    end
    if isfield(user_input,'MinDigitalValue')
        user_info.MinDigitalValue = user_input.MinDigitalValue;
    end
    if isfield(user_input,'MaxDigitalValue')
        user_info.MaxDigitalValue = user_input.MaxDigitalValue;
    end
    if isfield(user_input,'MinAnalogValue')
        user_info.MinAnalogValue = user_input.MinAnalogValue;
    end
    if isfield(user_input,'MaxAnalogValue')
        user_info.MaxAnalogValue = user_input.MaxAnalogValue;
    end
    if isfield(user_input,'AnalogUnits')
        user_info.AnalogUnits = user_input.AnalogUnits;
    end
elseif istable(user_input)
    if any(strcmpi('Label',user_input.Properties.VariableNames))
        user_info.Label = user_input.Label;
    end
    if any(strcmpi('MinDigitalValue',user_input.Properties.VariableNames))
        user_info.MinDigitalValue = user_input.MinDigitalValue;
    end
    if any(strcmpi('MaxDigitalValue',user_input.Properties.VariableNames))
        user_info.MaxDigitalValue = user_input.MaxDigitalValue;
    end
    if any(strcmpi('MinAnalogValue',user_input.Properties.VariableNames))
        user_info.MinAnalogValue = user_input.MinAnalogValue;
    end
    if any(strcmpi('MaxAnalogValue',user_input.Properties.VariableNames))
        user_info.MaxAnalogValue = user_input.MaxAnalogValue;
    end
    if any(strcmpi('AnalogUnits',user_input.Properties.VariableNames))
        user_info.AnalogUnits = user_input.AnalogUnits;
    end
elseif iscell(user_input)
    [user_input,lbl,~,found_lbl] = util.argkeyval('label',user_input,nan);
    if found_lbl
        user_info.Label = lbl;
    end
    [user_input,mindig,~,found_mindig] = util.argkeyval('MinDigitalValue',user_input,nan);
    if found_mindig
        user_info.MinDigitalValue = mindig;
    end
    [user_input,maxdig,~,found_maxdig] = util.argkeyval('MaxDigitalValue',user_input,nan);
    if found_maxdig
        user_info.MaxDigitalValue = maxdig;
    end
    [user_input,minan,~,found_minan] = util.argkeyval('MinAnalogValue',user_input,nan);
    if found_minan
        user_info.MinAnalogValue = minan;
    end
    [user_input,maxan,~,found_maxan] = util.argkeyval('MaxAnalogValue',user_input,nan);
    if found_maxan
        user_info.MaxAnalogValue = maxan;
    end
    [user_input,anun,~,found_anun] = util.argkeyval('AnalogUnits',user_input,nan);
    if found_anun
        user_info.AnalogUnits = anun;
    end
    util.argempty(user_input);
else
    error('Unknown input "%s"',class(user_input));
end

% validate updated information
if isfield(user_info,'Label')
    if iscell(user_info.Label)
        user_info.Label = user_info.Label{1};
    end
    assert(ischar(user_info.Label),'Must provide char Label, not "%s"',class(user_info.Label));
end
if isfield(user_info,'MinDigitalValue')
    if iscell(user_info.MinDigitalValue)
        user_info.MinDigitalValue = user_info.MinDigitalValue{1};
    end
    assert(isnumeric(user_info.MinDigitalValue),'Must provide numeric MinDigitalValue, not "%s"',class(user_info.MinDigitalValue));
end
if isfield(user_info,'MaxDigitalValue')
    if iscell(user_info.MaxDigitalValue)
        user_info.MaxDigitalValue = user_info.MaxDigitalValue{1};
    end
    assert(isnumeric(user_info.MaxDigitalValue),'Must provide numeric MaxDigitalValue, not "%s"',class(user_info.MaxDigitalValue));
end
if isfield(user_info,'MinAnalogValue')
    if iscell(user_info.MinAnalogValue)
        user_info.MinAnalogValue = user_info.MinAnalogValue{1};
    end
    assert(isnumeric(user_info.MinDigitalValue),'Must provide numeric MinAnalogValue, not "%s"',class(user_info.MinAnalogValue));
end
if isfield(user_info,'MaxAnalogValue')
    if iscell(user_info.MaxAnalogValue)
        user_info.MaxAnalogValue = user_info.MaxAnalogValue{1};
    end
    assert(isnumeric(user_info.MaxAnalogValue),'Must provide numeric MaxAnalogValue, not "%s"',class(user_info.MaxAnalogValue));
end
if isfield(user_info,'AnalogUnits')
    if iscell(user_info.AnalogUnits)
        user_info.AnalogUnits = user_info.AnalogUnits{1};
    end
    assert(ischar(user_info.AnalogUnits),'Must provide char AnalogUnits, not "%s"',class(user_info.AnalogUnits));
end

% open the file for reading
srcfile = fullfile(blc.SourceDirectory,sprintf('%s%s',blc.SourceBasename,blc.SourceExtension));
fid = util.openfile(srcfile,'r+');

% everything after here in try-catch statement to manage the file resource
try
    
    % compute byte position of desired channel
    start_byte = blc.BytesInHeader + BLc.Properties.ChannelInfoHeaderLength + (idx_channel_info-1)*BLc.Properties.ChannelInfoContentLength;
    fseek(fid,start_byte,'bof');
    
    % read the channel number and verify we're at the correct position
    bytes = fread(fid,BLc.Properties.ChannelInfoContentLength,'uint8');
    file_info.ChannelNumber = double(typecast(uint8(bytes(1:8)),'uint64'));
    file_info.Label = BLc.helper.stringFromBytes(bytes(9:24));
    file_info.MinDigitalValue = cast(typecast(bytes(25:28),'int32'),'double');
    file_info.MaxDigitalValue = cast(typecast(bytes(29:32),'int32'),'double');
    file_info.MinAnalogValue = cast(typecast(bytes(33:36),'int32'),'double');
    file_info.MaxAnalogValue = cast(typecast(bytes(37:40),'int32'),'double');
    file_info.AnalogUnits = BLc.helper.stringFromBytes(bytes(41:56));
    assert(file_info.ChannelNumber==user_info.ChannelNumber,'Could not find record for channel %d in the BLc file',blc.ChannelInfo(idx_channel_info).ChannelNumber);
    
    % update the Label property
    if isfield(user_info,'Label')
        LabelBytes = cast(user_info.Label(1:min(15,length(user_info.Label))),'uint8');
        LabelBytes(end+1:16) = 0; % null-terminated, 16-byte
        bytes(9:24) = LabelBytes;
    end
    
    % update the MinDigitalValue property
    if isfield(user_info,'MinDigitalValue')
        MinDigitalValueBytes = typecast(cast(user_info.MinDigitalValue,'int32'),'uint8');
        bytes(25:28) = MinDigitalValueBytes;
    end
    
    % update the MaxDigitalValue property
    if isfield(user_info,'MaxDigitalValue')
        MaxDigitalValueBytes = typecast(cast(user_info.MaxDigitalValue,'int32'),'uint8');
        bytes(29:32) = MaxDigitalValueBytes;
    end
    
    % update the MinAnalogValue property
    if isfield(user_info,'MinAnalogValue')
        MinAnalogValueBytes = typecast(cast(user_info.MinAnalogValue,'int32'),'uint8');
        bytes(33:36) = MinAnalogValueBytes;
    end
    
    % update the MaxDigitalValue property
    if isfield(user_info,'MaxAnalogValue')
        MaxAnalogValueBytes = typecast(cast(user_info.MaxAnalogValue,'int32'),'uint8');
        bytes(37:40) = MaxAnalogValueBytes;
    end
    
    % update the MaxDigitalValue property
    if isfield(user_info,'AnalogUnits')
        AnalogUnitsBytes = cast(user_info.AnalogUnits(1:min(15,length(user_info.AnalogUnits))),'uint8');
        AnalogUnitsBytes(end+1:16) = 0; % null-terminated, 16-byte
        bytes(41:56) = AnalogUnitsBytes;
    end
    
    % according to MATLAB documentation must call fseek or frewind between
    % fread/fwrite operations. set up the code to require a seek to start
    % of channel info content before writing the updated bytes
    fseek(fid,start_byte,'bof');
    fwrite(fid,bytes,'uint8');
catch ME
    util.closefile(fid);
    util.errorMessage(ME);
    return;
end

% close the file
util.closefile(fid);