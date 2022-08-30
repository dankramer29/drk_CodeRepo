function preprocess_v0_2(this)

% open the file for reading
srcfile = fullfile(this.SourceDirectory,sprintf('%s%s',this.SourceBasename,this.SourceExtension));
fid = util.openfile(srcfile,'r','seek',12);

% process header bytes
this.SamplingRate       = fread(fid,1,'uint32=>double');
this.BitResolution      = fread(fid,1,'uint8=>double');
this.ChannelCount       = fread(fid,1,'uint64=>double');
this.OriginTime         = BLc.helper.originTimeFromBytes(fread(fid,8,'uint16=>double'));
this.ApplicationName    = BLc.helper.stringFromBytes(fread(fid,32,'*char'));
this.Comment            = BLc.helper.stringFromBytes(fread(fid,256,'*char'));
this.NumSections        = fread(fid,1,'uint16=>double');
fseek(fid,1,'cof'); % seek past checksum
this.hDebug.log(sprintf('Set sampling rate (%d samples/sec)',this.SamplingRate),'debug');
this.hDebug.log(sprintf('Set bit resolution (%d bits)',this.BitResolution),'debug');
this.hDebug.log(sprintf('Set channel count (%d channels)',this.ChannelCount),'debug');
this.hDebug.log(sprintf('Set origin time (%s)',datestr(this.OriginTime)),'debug');
this.hDebug.log(sprintf('Set application name (%s)',this.ApplicationName),'debug');
this.hDebug.log(sprintf('Set comment (%s)',this.Comment),'debug');
this.hDebug.log(sprintf('Set num sections (%d)',this.NumSections),'debug');

% process additional header sections
this.SectionInfo = repmat(struct(...
    'byteStart',nan,...
    'headerLength',nan,...
    'byteLength',nan,...
    'label',''),1,this.NumSections);
for kk=1:this.NumSections
    this.SectionInfo(kk).byteStart = ftell(fid);
    this.SectionInfo(kk).label = BLc.helper.stringFromBytes(fread(fid,16,'*char'));
    this.SectionInfo(kk).headerLength = fread(fid,1,'uint16=>double');
    
    % validate section header
    fseek(fid,this.SectionInfo(kk).byteStart,'bof');
    bytes = fread(fid,this.SectionInfo(kk).headerLength,'*uint8');
    headerChecksum = bytes(end);
    computedChecksum = mod(sum(double(bytes(1:end-1))),256);
    assert(headerChecksum==computedChecksum,'Invalid checksum (found %d but expected %d)',headerChecksum,computedChecksum);
    
    % number of bytes in the whole section (including header)
    this.SectionInfo(kk).byteLength = double(typecast(bytes(19:26),'uint64'));
    
    % seek past this section
    bytesToSeek = this.SectionInfo(kk).byteLength - this.SectionInfo(kk).headerLength;
    fseek(fid,bytesToSeek,'cof');
    
    this.hDebug.log(sprintf('Found section "%s" (%d bytes)',this.SectionInfo(kk).label,this.SectionInfo(kk).byteLength),'debug');
end

% process channel info sections
idxChannelInfo = find(arrayfun(@(x)strcmpi(x.label,'channelinfo'),this.SectionInfo));
this.ChannelInfo = repmat(struct(...
    'ChannelNumber',nan,...
    'Label','',...
    'MinDigitalValue',nan,...
    'MaxDigitalValue',nan,...
    'MinAnalogValue',nan,...
    'MaxAnalogValue',nan,...
    'AnalogUnits',''),1,this.ChannelCount);
for kk=1:length(idxChannelInfo)
    idx = idxChannelInfo(kk);
    
    % figure out where to read and how much to read
    byteStart = this.SectionInfo(idx).byteStart;
    bytesToRead = this.SectionInfo(idx).byteLength;
    
    % slurp in the bytes
    fseek(fid,byteStart,'bof');
    bytes = fread(fid,bytesToRead,'*uint8');
    
    % get number of records in this section
    numRecords = cast(typecast(bytes(27:34),'uint64'),'double');
    
    % loop over channel packets
    currByte = this.SectionInfo(idx).headerLength;
    for nn=1:numRecords
        ch = cast(typecast(bytes(currByte+(1:8)),'uint64'),'double');
        
        % fill out channel info struct info
        this.ChannelInfo(ch).ChannelNumber = ch;
        this.ChannelInfo(ch).Label = BLc.helper.stringFromBytes(bytes(currByte+(9:24)));
        this.ChannelInfo(ch).MinDigitalValue = cast(typecast(bytes(currByte+(25:28)),'int32'),'double');
        this.ChannelInfo(ch).MaxDigitalValue = cast(typecast(bytes(currByte+(29:32)),'int32'),'double');
        this.ChannelInfo(ch).MinAnalogValue = cast(typecast(bytes(currByte+(33:36)),'int32'),'double');
        this.ChannelInfo(ch).MaxAnalogValue = cast(typecast(bytes(currByte+(37:40)),'int32'),'double');
        this.ChannelInfo(ch).AnalogUnits = BLc.helper.stringFromBytes(bytes(currByte+(41:56)));
        
        % update byte pointer
        currByte = currByte + BLc.Properties.ChannelInfoContentLength;
        
        this.hDebug.log(sprintf('Found channel %d (%s)',this.ChannelInfo(ch).ChannelNumber,this.ChannelInfo(ch).Label),'debug');
    end
end

% process data sections
idxDataSections = find(arrayfun(@(x)strcmpi(x.label,'data'),this.SectionInfo));
this.DataInfo = repmat(struct(...
    'SectionIndex',nan,...
    'Timestamp',nan,...
    'NumRecords',nan,...
    'Datetime',nan,...
    'Duration',nan),1,length(idxDataSections));
currDataSection = 1;
for kk=1:length(idxDataSections)
    idx = idxDataSections(kk);
    this.DataInfo(currDataSection).SectionIndex = idx;
    
    % figure out where to read and how much to read
    byteStart = this.SectionInfo(idx).byteStart+26;
    fseek(fid,byteStart,'bof');
    this.DataInfo(currDataSection).NumRecords = fread(fid,1,'uint64=>double');
    this.DataInfo(currDataSection).Timestamp = fread(fid,1,'uint64=>double');
    this.DataInfo(currDataSection).Datetime = BLc.helper.originTimeFromBytes(fread(fid,8,'uint16=>double'));
    this.DataInfo(currDataSection).Duration = duration(0,0,this.DataInfo(currDataSection).NumRecords/this.SamplingRate,'format','dd:hh:mm:ss.SSS');
    
    this.hDebug.log(sprintf('Found data section %d (timestamp %s, %d records, %d seconds)',datestr(this.DataInfo(currDataSection).Timestamp),this.DataInfo(currDataSection).NumRecords,seconds(this.DataInfo(currDataSection).Duration)),'debug');
    
    % update data section pointer
    currDataSection = currDataSection + 1;
end

% set up the data start/end times
this.DataStartTime = this.DataInfo(1).Datetime;
this.DataEndTime = this.DataInfo(end).Datetime + this.DataInfo(end).Duration;