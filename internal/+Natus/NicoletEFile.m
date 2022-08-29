classdef NicoletEFile < NicoletFile & handle
    
    properties
        OriginTime
        SamplingRate
        DataChannels
        NumDataPoints
        ChannelMinimum
        ChannelMaximum
        ChannelUnits
        SourceDirectory
        SourceBasename
        SourceExtension
        NumSegments
    end % END properties
    
    methods
        function this = NicoletEFile(varargin)
            this = this@NicoletFile(varargin{:});
            [this.SourceDirectory,this.SourceBasename,this.SourceExtension] = fileparts(this.fileName);
            this.NumSegments = length(this.segments);
            
            % set origin time
            this.OriginTime = datetime(this.segments(1).dateStr);
            
            % infer common data sampling rate
            Fs = nan(1,length(this.segments));
            for ss=1:length(this.segments)
                tmpFs = median(this.segments(ss).samplingRate);
                assert(isfinite(tmpFs)&&isscalar(tmpFs),'Sampling rate must be finite, numeric, scalar');
                assert(tmpFs-round(tmpFs)==0,'Must have integer sampling rate');
                Fs(ss) = tmpFs;
            end
            if numel(unique(Fs))~=1
                warning('Different segments have different sampling rates!');
            end
            %assert(all(Fs==512),'Sampling rate must be 512');
            this.SamplingRate = Fs;
            
            % choose channel subset with common sampling rate
            DataChannelNames = cell(1,length(this.segments));
            NumPointsPerSegment = nan(1,length(this.segments));
            for ss=1:length(this.segments)
                DataChannelNames{ss} = this.segments(ss).chName(this.segments(ss).samplingRate==this.SamplingRate(ss));
                isValid = this.checkValidChannels(ss,1:length(DataChannelNames{ss}));
                if ~all(isValid),warning('In segment %d, only %d out of %d channels are valid',ss,nnz(isValid),numel(isValid));end
                DataChannelNames{ss} = DataChannelNames{ss}(isValid);
                NumPointsPerSegment(ss) = this.segments(ss).duration*this.SamplingRate(ss);
            end
            assert(sum(NumPointsPerSegment)>0,'No data points to process');
            this.DataChannels = DataChannelNames;
            this.NumDataPoints = NumPointsPerSegment;
            
            % get channel units
            this.ChannelUnits = cell(1,length(this.segments));
            for ss=1:length(this.segments)
                this.ChannelUnits{ss} = cell(1,length(this.DataChannels{ss}));
                for cc=1:length(this.DataChannels{ss})
                    idxSigInfo = ismember({this.sigInfo.sensorName},this.DataChannels{ss}{cc});
                    if ~any(idxSigInfo)
                        warning('No transducer information for channel "%s" (assuming %s)',this.DataChannels{ss}{cc},char([181 86]));
                        this.ChannelUnits{ss}{cc} = 'uV';
                    else
                        if strcmpi(this.sigInfo(idxSigInfo).transducer,char(uint8([181 86])))
                            this.ChannelUnits{ss}{cc} = 'uV';
                        elseif strcmpi(this.sigInfo(idxSigInfo).transducer,'bpm')
                            this.ChannelUnits{ss}{cc} = 'bpm';
                        else
                            warning('Unknown transducer type "%s"',this.sigInfo(idxSigInfo).transducer);
                            keyboard;
                        end
                    end
                end
            end
            
            % read all data and compute min/max
            hWaitbar = waitbar(0/sum(NumPointsPerSegment),sprintf('Computing global min/max (segment 1) (0/%d)',sum(NumPointsPerSegment)));
            hWaitbarTitle = get(get(findobj(hWaitbar,'Type','figure'),'currentaxes'),'title');
            set(hWaitbarTitle,'interpreter','none'); % no special interpretation of text
            this.ChannelMinimum = cell(1,length(this.segments));
            this.ChannelMaximum = cell(1,length(this.segments));
            for ss=1:length(this.segments)
                
                % get dimensions of a single frame
                data_channels = ismember(this.segments(ss).chName,this.DataChannels{ss});
                try
                    data = this.getdata(ss,[1 1],data_channels);
                catch ME
                    util.errorMessage(ME);
                    keyboard
                end
                info = whos('data');
                bytesPerN = round(1.5*info.bytes);
                
                % read data out of the file
                if ~ispc
                    maxPointsInMemory = 1e6; % no way to check mem on mac/linux
                else
                    [~,maxPointsInMemory] = util.memcheck([1 1],bytesPerN,'avail',0.8);
                end
                maxPointsInMemory = min(maxPointsInMemory,1e7);
                
                % initialize min/max
                this.ChannelMinimum{ss} = inf(1,length(this.DataChannels{ss}));
                this.ChannelMaximum{ss} = -inf(1,length(this.DataChannels{ss}));
                numPointsToReadPerIteration = min(NumPointsPerSegment(ss),maxPointsInMemory);
                
                % calculate min/max
                lastPointRead = 0;
                while lastPointRead < NumPointsPerSegment(ss)
                    numPointsToReadThisIteration = min(numPointsToReadPerIteration,NumPointsPerSegment(ss)-lastPointRead);
                    try
                        data = this.getdata(ss,lastPointRead + [1 numPointsToReadThisIteration], data_channels);
                    catch ME
                        util.errorMessage(ME);
                        keyboard
                    end
                    lastPointRead = lastPointRead + numPointsToReadThisIteration;
                    this.ChannelMinimum{ss} = nanmin(this.ChannelMinimum{ss},min(data,[],1));
                    this.ChannelMaximum{ss} = nanmax(this.ChannelMaximum{ss},max(data,[],1));
                    waitbar(sum(NumPointsPerSegment(ss+1:end))+NumPointsPerSegment(ss)-lastPointRead/sum(NumPointsPerSegment));
                    set(hWaitbarTitle,'String',sprintf('Computing global min/max (segment %d/%d) (%d/%d)',ss,length(NumPointsPerSegment),sum(NumPointsPerSegment(ss+1:end))+NumPointsPerSegment(ss)-lastPointRead,sum(NumPointsPerSegment)));
                end
            end
            close(hWaitbar);
        end % END function NicoletEFile
    end % END methods
end % END classdef NicoletEFile