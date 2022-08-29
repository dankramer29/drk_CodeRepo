function readExtendedHeader(this)
flagWarnThreshold = false;

% open the file for reading
try
    nsfile = fullfile(this.SourceDirectory,[this.SourceBasename this.SourceExtension]);
    fid = fopen(nsfile,'r');
    status = fseek(fid,Blackrock.NSx.BasicHeaderSize,'bof');
    assert(status>=0,'Error reading file: %s',ferror(fid));
catch ME
    util.errorMessage(ME);
    return;
end

% read the extended header data
try
    for cc = 1:this.ChannelCount % one extended header per channel
        Type = fread(fid,2,'*char')';
        Data = fread(fid,64,'*uint8');
        
        switch Type
            case 'CC'
                chid = double(typecast(Data(1:2),'uint16'));
                this.ChannelInfo(chid).ChannelID = chid;
                if ~isempty(this.hArrayMap)
                    this.ChannelInfo(chid).ElectrodeID = this.hArrayMap.ch2el(chid);
                end
                LabelBytes = Data(3:18);
                lt = find(LabelBytes==0,1,'first');
                if isempty(lt)
                    error('Label field string must be NULL terminated.');
                end
                LabelBytes = LabelBytes(:)';
                this.ChannelInfo(chid).Label = char(LabelBytes(1:lt-1));
                this.ChannelInfo(chid).PhysicalConnector = deblank(char(64 + Data(19)));
                this.ChannelInfo(chid).ConnectorPin = double(Data(20));
                this.ChannelInfo(chid).MinDigitalValue = double(typecast(Data(21:22),'int16'));
                this.ChannelInfo(chid).MaxDigitalValue = double(typecast(Data(23:24),'int16'));
                this.ChannelInfo(chid).MinAnalogValue = double(typecast(Data(25:26),'int16'));
                this.ChannelInfo(chid).MaxAnalogValue = double(typecast(Data(27:28),'int16'));
                UnitsBytes = Data(29:44);
                lt = find(UnitsBytes==0,1,'first');
                if isempty(lt)
                    error('Label field string must be NULL terminated.');
                end
                UnitsBytes = UnitsBytes(:)';
                this.ChannelInfo(chid).Units = char(UnitsBytes(1:lt-1));
                this.ChannelInfo(chid).HighFreqCorner = double(typecast(Data(45:48),'uint32'));
                this.ChannelInfo(chid).HighFreqOrder = double(typecast(Data(49:52),'uint32'));
                switch double(typecast(Data(53:54),'uint16'))
                    case 0
                        this.ChannelInfo(chid).HighFilterType = 'None';
                    case 1
                        this.ChannelInfo(chid).HighFilterType = 'Butterworth';
                    otherwise
                        error('Unexpected value for electrode %d HighFilterType: ''%d''',chid,double(typecast(Data(53:54),'uint16')));
                end
                this.ChannelInfo(chid).LowFreqCorner = double(typecast(Data(55:58),'uint32'));
                this.ChannelInfo(chid).LowFreqOrder = double(typecast(Data(59:62),'uint32'));
                switch double(typecast(Data(63:64),'uint16'))
                    case 0
                        this.ChannelInfo(chid).LowFilterType = 'None';
                    case 1
                        this.ChannelInfo(chid).LowFilterType = 'Butterworth';
                    otherwise
                        error('Unexpected value for electrode %d LowFilterType: ''%d''',chid,double(typecast(Data(63:64),'uint16')));
                end
                
            otherwise
                if this.warnCount < this.maxWarnCount
                    log(this,sprintf('Unknown extended header packed ID: ''%s''',Type),'warn');
                    this.warnCount = this.warnCount + 1;
                else
                    flagWarnThreshold = true;
                    assert(~this.exitOnWarnThreshold,'Warning threshold exceeded');
                end
        end
    end
catch ME
    util.errorMessage(ME);
    fclose(fid);
    if flagWarnThreshold && this.exitOnWarnThreshold
        rethrow(ME);
    else
        return;
    end
end

% close the file
fclose(fid);
