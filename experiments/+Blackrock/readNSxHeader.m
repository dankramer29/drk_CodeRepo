function varargout = readNSxHeader(nfile,varargin)

% validate input
assert(ischar(nfile)&&exist(nfile,'file'),'Must provide the full path to an existing neural data file with extension ns*');

% open the file for reading
nsxfile = fullfile(nfile);
[fid,errmsg] = fopen(nsxfile,'r');
assert(fid>0,'Could not open NSx file ''%s'' for writing: %s',errmsg);

% read the basic header data
try
    headers.FileTypeID              = fread(fid,8,'*char')';
    headers.FileSpecMajor           = fread(fid,1,'uint8=>double');
    headers.FileSpecMinor           = fread(fid,1,'uint8=>double');
    headers.BytesInHeaders          = fread(fid,1,'uint32=>double');
    LabelBytes                      = fread(fid,16,'*char');
    CommentBytes                    = fread(fid,256,'*uint8')';
    headers.TimestampsPerSample     = fread(fid,1,'uint32=>double');
    headers.TimestampTimeResolution = fread(fid,1,'uint32=>double');
    origTime                        = fread(fid,8,'uint16=>double')';
    headers.ChannelCount            = fread(fid,1,'uint32=>double')';
    
    % process label
    lt = find(LabelBytes==0,1,'first');
    assert(~isempty(lt),'Label field string must be NULL terminated.');
    LabelBytes = LabelBytes(:)';
    headers.Label = char(LabelBytes(1:lt-1));
    
    % process comment
    lt = find(CommentBytes==0,1,'first');
    assert(~isempty(lt),'Comment field string must be NULL terminated.');
    CommentBytes = CommentBytes(:)';
    headers.Comment = char(CommentBytes(1:lt-1));
    
    % process origin time
    datevec = [origTime([1 2 4 5 6]) origTime(7) + origTime(8)/1000];
    headers.OriginTimeString = datestr(datevec,'dd-mmm-yyyy HH:MM:SS.FFF');
    headers.OriginTimeDatenum = datenum(datevec);
    
    % calculate sampling frequency
    headers.Period = headers.TimestampsPerSample / headers.TimestampTimeResolution;
    headers.Fs = headers.TimestampTimeResolution / headers.TimestampsPerSample;
catch ME
    util.errorMessage(ME);
    fclose(fid);
    return;
end

% close the file
fclose(fid);

% generate outputs
headerLabels = fieldnames(headers);
if nargin==1
    varargout{1} = headers;
else
    varargout = cell(1,length(varargin));
    for kk=1:length(varargin)
        assert(ischar(varargin{kk}),'Must provide list of header labels as ''char'', not ''%s''',class(varargin{kk}));
        idx = find(strcmpi(varargin{kk},headerLabels));
        assert(~isempty(idx),'Invalid header label ''%s''',varargin{kk});
        varargout{kk} = headers.(headerLabels{idx});
    end
end