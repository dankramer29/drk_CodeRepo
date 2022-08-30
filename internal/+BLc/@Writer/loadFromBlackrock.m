function loadFromBlackrock(this)
% LOADFROMBLACKROCK Load basic information and properties from the source
%
%   LOADFROMBLACKROCK(THIS)
%   Load basic information about the data to populate properties of the
%   WRITER object THIS.

% set the bit resolution
setBitResolution(this,this.BitResolution);

% decide which channels to care about
assert(~isempty(this.indexChannelToWrite),'Must provide indices of the channels to process');
this.hDebug.log(sprintf('Writing channels %s',util.vec2str(this.indexChannelToWrite{1})),'debug');
if ~this.FlagWriteNanChannels
    this.hDebug.log('The capability to look for NaN channels is not yet implemented for Blackrock files','debug');
end

% get channel stats and determine the analog range/units
% note this function runs over the ENTIRE file so it may
% take a while for large files
assert(max(this.indexChannelToWrite{1})<=length(this.hSource.ChannelInfo),'Found %d data channels, but requested %d channels',length(this.hSource.ChannelInfo),length(this.indexChannelToWrite{1}));
channelMinimums = [this.hSource.ChannelInfo(this.indexChannelToWrite{1}).MinAnalogValue];
assert(numel(unique(channelMinimums))==1,'Require all channels to be digitized equivalently');
channelMaximums = [this.hSource.ChannelInfo(this.indexChannelToWrite{1}).MaxAnalogValue];
assert(numel(unique(channelMaximums))==1,'Require all channels to be digitized equivalently');
channelUnits = {this.hSource.ChannelInfo(this.indexChannelToWrite{1}).Units};
channelUnits(cellfun(@isempty,channelUnits)) = [];
channelLabels = {this.hSource.ChannelInfo(this.indexChannelToWrite{1}).Label};
channelLabels(cellfun(@isempty,channelLabels)) = [];
assert(numel(unique(channelUnits))==1,'Require all channels to be digitized equivalently');
chanMin = floor(nanmin(channelMinimums));
chanMax = ceil(nanmax(channelMaximums));
analogMax = nanmax(abs(chanMin),chanMax); % enforce centered range
assert(~any(isnan(analogMax)),'Max value in analog data cannot be NaN');
this.MinAnalogValue = -analogMax;
this.MaxAnalogValue = analogMax;
this.hDebug.log(sprintf('Set analog min and max to [%.4f, %.4f]',this.MinAnalogValue,this.MaxAnalogValue),'debug');

% load header info
this.Comment = '';
this.ChannelCount = length(this.indexChannelToWrite{1});
this.ChannelInfo = repmat(struct(...
    'ChannelNumber',nan,...
    'Label','',...
    'MinDigitalValue',nan,...
    'MaxDigitalValue',nan,...
    'MinAnalogValue',nan,...
    'MaxAnalogValue',nan,...
    'Units',''),1,this.ChannelCount);
for cc=1:this.ChannelCount
    this.ChannelInfo(cc).ChannelNumber = cc;
    this.ChannelInfo(cc).Label = channelLabels{cc};
    this.ChannelInfo(cc).MinDigitalValue = this.MinDigitalValue;
    this.ChannelInfo(cc).MaxDigitalValue = this.MaxDigitalValue;
    this.ChannelInfo(cc).MinAnalogValue = -analogMax;
    this.ChannelInfo(cc).MaxAnalogValue = analogMax;
    this.ChannelInfo(cc).Units = channelUnits{cc};
end
this.SamplingRate = this.hSource.Fs;
this.OriginTime = datetime(this.hSource.OriginTimeDatenum,'convertFrom','datenum');
this.BytesPerFrame = (this.BitResolution/8)*this.ChannelCount;

% pre-calculate a few items
this.rangeDigital = this.MaxDigitalValue - this.MinDigitalValue;
this.rangeAnalog = 2*analogMax;

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
if this.FlagExecuteSafetyChecks
    errorDigital = 0.5;
    errorAnalog = -analogMax + this.rangeAnalog*(errorDigital-this.MinDigitalValue)/this.rangeDigital;
    if strcmpi(channelUnits{1},'mv') % convert to uV
        errorAnalog = errorAnalog*1e3;
    elseif strcmpi(channelUnits{1},'uv') % keep in uV
        errorAnalog = errorAnalog*1e0;
    end
    this.hDebug.log(sprintf('Quantization error will be %.2f uV (threshold set at %.2f uV)',errorAnalog,this.MaxQuantizationError),'debug');
    assert(all(errorAnalog<=this.MaxQuantizationError),...
        'Quantization error of %.2f uV is greater than the threshold %.2f uV: increase the threshold, reduce the analog range, or increase the digital range',...
        errorAnalog,this.MaxQuantizationError);
else
    this.hDebug.log('Skipping quantization error safety check','warn');
end