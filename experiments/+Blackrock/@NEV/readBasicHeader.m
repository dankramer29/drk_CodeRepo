function readBasicHeader(this)

% open the file for reading
try
    nevfile = fullfile(this.SourceDirectory,[this.SourceBasename this.SourceExtension]);
    fid = fopen(nevfile,'r');
catch ME
    util.errorMessage(ME);
    return;
end

% read the basic header data
try
    this.FileTypeID             = fread(fid,8,'*char')';
    this.FileSpecMajor          = fread(fid,1,'uint8=>double');
    this.FileSpecMinor          = fread(fid,1,'uint8=>double');
    this.AdditionalFlags        = fread(fid,1,'*uint16');
    this.BytesInHeaders         = fread(fid,1,'uint32=>double');
    this.BytesPerDataPacket     = fread(fid,1,'uint32=>double');
    this.ResolutionTimestamps   = fread(fid,1,'uint32=>double');
    this.ResolutionSamples      = fread(fid,1,'uint32=>double');
    origTime                    = fread(fid,8,'uint16=>double')';
    ApplicationNameBytes        = fread(fid,32,'*uint8')';
    CommentBytes                = fread(fid,256,'*uint8')';
    this.NumExtendedHeaders     = fread(fid,1,'uint32=>double');
    
    % check additional flags
    if bitget(this.AdditionalFlags,1)
        this.AllSpikeWaveform16Bit = true;
    end
    if any(bitget(this.AdditionalFlags,2:16))
        log(this,'Bits 2:16 of AdditionalFlags (basic header) are reserved and should be set to 0','warn');
    end
    
    % process origin time
    [this.OriginTimeString,this.OriginTimeDatenum] = Blackrock.NEV.systime2datenum(origTime);
    
    % process application name
    lt = find(ApplicationNameBytes==0,1,'first');
    assert(~isempty(lt),'Application name string must be NULL terminated.');
    ApplicationNameBytes = ApplicationNameBytes(:)';
    this.ApplicationName = char(ApplicationNameBytes(1:lt-1));
    
    % process comment
    lt = find(CommentBytes==0,1,'first');
    assert(~isempty(lt),'Comment field string must be NULL terminated.');
    CommentBytes = CommentBytes(:)';
    this.Comment = char(CommentBytes(1:lt-1));
catch ME
    util.errorMessage(ME);
    fclose(fid);
    return;
end

% close the file
fclose(fid);
