function loadFromNicolet(this)
% LOADFROMNICOLET Load basic information and properties from the source
%
%   LOADFROMNICOLET(THIS)
%   Load basic information about the data to populate properties of the
%   WRITER object THIS.

% set the bit resolution
setBitResolution(this,this.BitResolution);

% decide which channels to care about
if isempty(this.indexChannelToWrite)
    if iscell(this.hMap)
        this.indexChannelToWrite = cellfun(@(x)x.ChannelInfo.AmplifierChannel,this.hMap,'UniformOutput',false);
    else
        this.indexChannelToWrite = {1:this.hMap.NumChannels};
    end
end
for ss=1:length(this.Segment)
    assert(length(this.indexChannelToWrite{ss})==this.hMap{ss}.NumChannels,'In segment %d, number of channels to write (%d) must be equal to number of channels in the grid map (%d)',this.Segment(ss),length(this.indexChannelToWrite{ss}),this.hMap{ss}.NumChannels);
    this.hDebug.log(sprintf('In segment %d, writing channels %s',this.Segment(ss),util.vec2str(this.indexChannelToWrite{ss})),'debug');
end
if ~this.FlagWriteNanChannels
    this.hDebug.log('The capability to look for NaN channels is not yet implemented for Nicolet files','debug');
end

% get channel stats and determine the analog range/units
% note this function runs over the ENTIRE file so it may
% take a while for large files
this.MinAnalogValue = cell(1,length(this.Segment));
this.MaxAnalogValue = cell(1,length(this.Segment));
analogMax = cell(1,length(this.Segment));
for ss=1:length(this.Segment)
    chanMin = floor(nanmin(this.hSource.ChannelMinimum{this.Segment(ss)}(this.indexChannelToWrite{ss})));
    chanMax = ceil(nanmax(this.hSource.ChannelMaximum{this.Segment(ss)}(this.indexChannelToWrite{ss})));
    analogMax{ss} = nanmax(abs(chanMin),chanMax); % enforce centered range
    assert(~any(isnan(analogMax{ss})),'Max value in analog data cannot be NaN');
    this.MinAnalogValue{ss} = -analogMax{ss};
    this.MaxAnalogValue{ss} = analogMax{ss};
    this.hDebug.log(sprintf('In segment %d, set analog min and max to [%.4f, %.4f]',this.Segment(ss),this.MinAnalogValue{ss},this.MaxAnalogValue{ss}),'debug');
end

% load header info
this.Comment = '';
this.ChannelCount = nan(1,length(this.Segment));
this.ChannelInfo = cell(1,length(this.Segment));
this.rangeAnalog = cell(1,length(this.Segment));
this.OriginTime = cell(1,length(this.Segment));
this.SamplingRate = nan(1,length(this.Segment));
this.BytesPerFrame = nan(1,length(this.Segment));
for ss=1:length(this.Segment)
    currSegment = this.Segment(ss);
    this.ChannelCount(ss) = length(this.indexChannelToWrite{ss});
    this.ChannelInfo{ss} = repmat(struct(...
        'ChannelNumber',nan,...
        'Label','',...
        'MinDigitalValue',nan,...
        'MaxDigitalValue',nan,...
        'MinAnalogValue',nan,...
        'MaxAnalogValue',nan,...
        'Units',''),1,this.ChannelCount(ss));
    for cc=1:this.ChannelCount(ss)
        this.ChannelInfo{ss}(cc).ChannelNumber = cc;
        this.ChannelInfo{ss}(cc).Label = this.hMap{ss}.ChannelInfo.Label{cc};
        this.ChannelInfo{ss}(cc).MinDigitalValue = this.MinDigitalValue;
        this.ChannelInfo{ss}(cc).MaxDigitalValue = this.MaxDigitalValue;
        this.ChannelInfo{ss}(cc).MinAnalogValue = -analogMax{ss};
        this.ChannelInfo{ss}(cc).MaxAnalogValue = analogMax{ss};
        this.ChannelInfo{ss}(cc).Units = this.hSource.ChannelUnits{currSegment}{this.indexChannelToWrite{ss}(cc)};
    end
    this.OriginTime{ss} = datetime(this.hSource.segments(currSegment).dateStr);%this.hSource.OriginTime;
    this.BytesPerFrame(ss) = (this.BitResolution/8)*this.ChannelCount(ss);
    
    % according to Angela at Rancho Los Amigos, all of their recordings are
    % set to 512 samples/sec, even though the file reports 256 samples/sec.
    this.SamplingRate(ss) = this.hSource.SamplingRate(currSegment);
    
    % pre-calculate a few items
    this.rangeDigital = this.MaxDigitalValue - this.MinDigitalValue;
    this.rangeAnalog{ss} = 2*analogMax{ss};
    
    % estimate quantization error
    % the idea here is that we'll be rounding in the "digital"
    % domain, e.g., at the quantization determined by the min/max
    % digital values. (Default is 16-bit, i.e., -3276x to 3276x).
    % Rounding will at most destroy 0.5 units out of this
    % quantization, and this will translate to a different amount
    % of voltage depending on how the analog range maps to the
    % digital quantization range. So, here we essentially identify
    % how many volts 0.5 digital units represents, and call that
    % our quantization error. If it's too big, throw an error.
    errorDigital = 0.5;
    errorAnalog = -analogMax{ss} + this.rangeAnalog{ss}*(errorDigital-this.MinDigitalValue)/(this.rangeDigital);
    if strcmpi(this.hSource.ChannelUnits{ss}{1},'mv') % convert to uV
        errorAnalog = errorAnalog*1e3;
    elseif strcmpi(this.hSource.ChannelUnits{ss}{1},'uv') % keep in uV
        errorAnalog = errorAnalog*1e0;
    end
    this.hDebug.log(sprintf('In segment %d, quantization error will be %.2f uV (threshold set at %.2f uV)',this.Segment(ss),errorAnalog,this.MaxQuantizationError),'debug');
    assert(all(errorAnalog<=this.MaxQuantizationError),...
        'In segment %d, quantization error of %.2f uV is greater than the threshold %.2f uV: increase the threshold, reduce the analog range, or increase the digital range',...
        this.Segment(ss),errorAnalog,this.MaxQuantizationError);
end