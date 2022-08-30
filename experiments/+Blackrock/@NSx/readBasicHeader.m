function readBasicHeader(this)

% open the file for reading
try
    nsxfile = fullfile(this.SourceDirectory,[this.SourceBasename this.SourceExtension]);
    fid = fopen(nsxfile,'r');
catch ME
    util.errorMessage(ME);
    return;
end

% read the basic header data
try
    this.FileTypeID                 = fread(fid,8,'*char')';
    this.FileSpecMajor              = fread(fid,1,'uint8=>double');
    this.FileSpecMinor              = fread(fid,1,'uint8=>double');
    this.BytesInHeaders             = fread(fid,1,'uint32=>double');
    LabelBytes                      = fread(fid,16,'*char');
    CommentBytes                    = fread(fid,256,'*uint8')';
    this.TimestampsPerSample        = fread(fid,1,'uint32=>double');
    this.TimestampTimeResolution    = fread(fid,1,'uint32=>double');
    origTime                        = fread(fid,8,'uint16=>double')';
    this.ChannelCount               = fread(fid,1,'uint32=>double')';
catch ME
    Utilities.errorMessage(ME);
    fclose(fid);
    return;
end

% close the file
fclose(fid);

% check file spec
if ~ismember(this.FileSpecMajor,this.AllowedFileSpecMajor) || ~ismember(this.FileSpecMinor,this.AllowedFileSpecMinor)
    log(this,sprintf('This class has not been validated against file spec %d.%d',this.FileSpecMajor,this.FileSpecMinor),'warn');
end

% process label
lt = find(LabelBytes==0,1,'first');
if isempty(lt)
    error('Label field string must be NULL terminated.');
end
LabelBytes = LabelBytes(:)';
this.Label = char(LabelBytes(1:lt-1));

% process comment
lt = find(CommentBytes==0,1,'first');
if isempty(lt)
    error('Comment field string must be NULL terminated.');
end
CommentBytes = CommentBytes(:)';
this.Comment = char(CommentBytes(1:lt-1));

% process origin time
datevec = [origTime([1 2 4 5 6]) origTime(7) + origTime(8)/1000];
this.OriginTimeString = datestr(datevec,'dd-mmm-yyyy HH:MM:SS.FFF');
this.OriginTimeDatenum = datenum(datevec);

% calculate sampling frequency
this.Period = this.TimestampsPerSample / this.TimestampTimeResolution;
this.Fs = this.TimestampTimeResolution / this.TimestampsPerSample;