function readExtendedHeader(this)

% open the file for reading
try
    nevfile = fullfile(this.SourceDirectory,[this.SourceBasename this.SourceExtension]);
    fid = fopen(nevfile,'r');
    status = fseek(fid,Blackrock.NEV.BasicHeaderSize,'bof');
    assert(status==0,'Error reading file: %s',ferror(fid));
catch ME
    util.errorMessage(ME);
    return;
end

% read the extended header data
try
    commentIdx = 0; % index into cell array of 'ECOMMENT' ("extra comment")
    for kk = 1:this.NumExtendedHeaders
        PacketID = fread(fid,8,'*char')';
        Data = fread(fid,24,'*uint8')';
        
        switch PacketID
            case 'ARRAYNME'
                this.ArrayName = deblank(char(Data));
                
            case 'ECOMMENT'
                commentIdx = commentIdx + 1;
                this.ExtraComment{commentIdx} = deblank(char(Data));
                
            case 'CCOMMENT'
                this.ExtraComment{commentIdx} = [this.ExtraComment{commentIdx} deblank(char(Data))];
                
            case 'MAPFILE'
                this.ExtHeaderIndicatedMapFile = deblank(char(Data));
                
            case 'NEUEVWAV'
                chid = double(typecast(Data(1:2),'uint16'));
                this.ChannelInfo(chid).ChannelID = chid;
                this.ChannelInfo(chid).PhysicalConnector = deblank(char(64 + Data(3)));
                this.ChannelInfo(chid).ConnectorPin = double(Data(4));
                this.ChannelInfo(chid).DigitizationFactor = double(typecast(Data(5:6),'uint16'));
                this.ChannelInfo(chid).EnergyThreshold = double(typecast(Data(7:8),'uint16'));
                this.ChannelInfo(chid).HighThreshold = double(typecast(Data(9:10),'int16'));
                this.ChannelInfo(chid).LowThreshold = double(typecast(Data(11:12),'int16'));
                this.ChannelInfo(chid).NumSortedUnits = double(Data(13));
                this.ChannelInfo(chid).BytesPerWaveformSample = double(Data(14));
                this.ChannelInfo(chid).SpikeWidthSamples = double(typecast(Data(15:16),'uint16'));
                if ~isempty(this.hArrayMap)
                    this.ChannelInfo(chid).ElectrodeID = this.hArrayMap.ch2el(chid);
                end
                
            case 'NEUEVLBL'
                chid = double(typecast(Data(1:2),'uint16'));
                this.ChannelInfo(chid).Label = deblank(char(Data(3:18)));
                
            case 'NEUEVFLT'
                chid = double(typecast(Data(1:2),'uint16'));
                this.ChannelInfo(chid).HighFreqCorner = double(typecast(Data(3:6),'uint32'));
                this.ChannelInfo(chid).HighFreqOrder = double(typecast(Data(7:10),'uint32'));
                switch double(typecast(Data(11:12),'uint16'))
                    case 0
                        this.ChannelInfo(chid).HighFilterType = 'None';
                    case 1
                        this.ChannelInfo(chid).HighFilterType = 'Butterworth';
                    otherwise
                        error('Unexpected value for channel %d HighFilterType: ''%d''',chid,double(typecast(Data(11:12),'uint16')));
                end
                this.ChannelInfo(chid).LowFreqCorner = double(typecast(Data(13:16),'uint32'));
                this.ChannelInfo(chid).LowFreqOrder = double(typecast(Data(17:20),'uint32'));
                switch double(typecast(Data(21:22),'uint16'))
                    case 0
                        this.ChannelInfo(chid).LowFilterType = 'None';
                    case 1
                        this.ChannelInfo(chid).LowFilterType = 'Butterworth';
                    otherwise
                        error('Unexpected value for channel %d LowFilterType: ''%d''',chid,double(typecast(Data(21:22),'uint16')));
                end
                
            case 'DIGLABEL'
                if isempty(this.DigitalInfo)
                    idx = 1;
                else
                    idx = length(this.DigitalInfo)+1;
                end
                this.DigitalInfo(idx).Label = deblank(char(Data(1:16)));
                switch Data(17)
                    case 0
                        this.DigitalInfo(idx).Mode = 'serial';
                    case 1
                        this.DigitalInfo(idx).Mode = 'parallel';
                    otherwise
                        error('Unexpected value for digital channel mode: ''%d''',Data(17));
                end
                
            case 'VIDEOSYN'
                if isempty(this.VideoInfo)
                    idx = 1;
                else
                    idx = length(this.VideoInfo)+1;
                end
                this.VideoInfo(idx).SourceIDs = double(typecast(Data(1:2),'uint16'));
                this.VideoInfo(idx).Source = deblank(char(Data(3:18)));
                this.VideoInfo(idx).FrameRate = double(typecast(Data(19:22),'single'));
                
            case 'TRACKOBJ'
                if isempty(this.TrackingInfo)
                    idx = 1;
                else
                    idx = length(this.TrackingInfo)+1;
                end
                switch double(typecast(Data(1:2),'uint16'))
                    case 0
                        TypeString = 'Undefined';
                    case 1
                        TypeString = '2D Rigid body tracked with marker(s)';
                    case 2
                        TypeString = '2D Rigid body border tracked with blob';
                    case 3
                        TypeString = '3D Rigid body tracked with marker(s)';
                    case 4
                        TypeString = '2D boundary for visual event definition';
                    otherwise
                        error('Unexpected value for digital channel mode: ''%d''',double(typecast(Data(1:2),'uint16')));
                end
                this.TrackingInfo(idx).Type = TypeString;
                this.TrackingInfo(idx).ID = double(typecast(Data(3:4),'uint16'));
                this.TrackingInfo(idx).PointCount = double(typecast(Data(5:6),'uint16'));
                this.TrackingInfo(idx).VideoSource = deblank(char(Data(7:22)));
                
            otherwise
                log(this,sprintf('Unknown extended header packed ID: ''%s''',PacketID),'warn');
        end
    end
catch ME
    util.errorMessage(ME);
    fclose(fid);
    return;
end

% close the file
fclose(fid);
