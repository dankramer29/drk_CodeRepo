function loadFromXLTekTxt(this)
% LOADFROMXLTEKTXT Load basic information and properties from the source
%
%   LOADFROMXLTEKTXT(THIS)
%   Load basic information about the data to populate
%   properties of the WRITER object THIS.
assert(ischar(this.hSource.Units),'Units must be char, not "%s"',class(this.hSource.Units));
assert(any(strcmpi(this.hSource.Units,{'V','mV','uV'})),'Units must be "V", "mV", or "uV", not "%s"',this.hSource.Units);
if length(this.indexChannelToWrite)>1
    warning('Ignoring multiple map files');
end
this.indexChannelToWrite = this.indexChannelToWrite{1};
this.hMap = this.hMap{1};

% set the bit resolution
setBitResolution(this,this.BitResolution);

% decide which channels to care about
if isempty(this.indexChannelToWrite)
    this.indexChannelToWrite = 1:this.hMap.NumChannels;
end
assert(length(this.indexChannelToWrite)==this.hMap.NumChannels,'Number of channels to write (%d) must be equal to number of channels in the grid map (%d)',length(this.indexChannelToWrite),this.hMap.NumChannels);
if ~this.FlagWriteNanChannels
    this.indexChannelToWrite(isnan(this.hSource.ChannelAverage(this.indexChannelToWrite))) = [];
end
this.hDebug.log(sprintf('Writing channels %s',util.vec2str(this.indexChannelToWrite)),'debug');

% get channel stats and determine the analog range/units
% note this function runs over the ENTIRE file so it may
% take a while for large files
chanMin = floor(nanmin(this.hSource.ChannelMinimum(this.indexChannelToWrite)));
chanMax = ceil(nanmax(this.hSource.ChannelMaximum(this.indexChannelToWrite)));
analogMax = nanmax(abs(chanMin),chanMax); % enforce centered range
assert(~any(isnan(analogMax)),'Max value in analog data cannot be NaN');
this.MinAnalogValue = -analogMax;
this.MaxAnalogValue = analogMax;
this.hDebug.log(sprintf('Set analog min and max to [%.4f, %.4f]',this.MinAnalogValue,this.MaxAnalogValue),'debug');

% load header info
this.Comment = '';
this.ChannelCount = length(this.indexChannelToWrite);
this.ChannelInfo = repmat(struct(...
    'ChannelNumber',nan,...
    'Label','',...
    'MinDigitalValue',nan,...
    'MaxDigitalValue',nan,...
    'MinAnalogValue',nan,...
    'MaxAnalogValue',nan,...
    'Units',''),1,this.ChannelCount);
for cc=1:this.ChannelCount
    this.ChannelInfo(cc).ChannelNumber = this.indexChannelToWrite(cc);
    this.ChannelInfo(cc).Label = this.hMap.ChannelInfo.Label{cc};
    this.ChannelInfo(cc).MinDigitalValue = this.MinDigitalValue;
    this.ChannelInfo(cc).MaxDigitalValue = this.MaxDigitalValue;
    this.ChannelInfo(cc).MinAnalogValue = -analogMax;
    this.ChannelInfo(cc).MaxAnalogValue = analogMax;
    this.ChannelInfo(cc).Units = this.hSource.Units;
end
this.SamplingRate = this.hSource.SamplingRate;
this.OriginTime = this.hSource.OriginalStart;
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
errorDigital = 0.5;
errorAnalog = -analogMax + this.rangeAnalog*(errorDigital-this.MinDigitalValue)/(this.rangeDigital);
if strcmpi(this.hSource.Units,'mv') % convert to uV
    errorAnalog = errorAnalog*1e3;
elseif strcmpi(this.hSource.Units,'uv') % keep in uV
    errorAnalog = errorAnalog*1e0;
end
this.hDebug.log(sprintf('Quantization error will be %.2f uV (threshold set at %.2f uV)',errorAnalog,this.MaxQuantizationError),'debug');
assert(all(errorAnalog<=this.MaxQuantizationError),...
    'Quantization error of %.2f uV is greater than the threshold %.2f uV: increase the threshold, reduce the analog range, or increase the digital range',...
    errorAnalog,this.MaxQuantizationError);