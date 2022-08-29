function [nfeat,def] = featdef(timestamp,channel,unit,frscale,lag,varargin)
% FEATDEF count features and generate a definition matrix identifying each
%
%   [NFEAT,DEF,LBL] = FEATDEF(TIMESTAMP,CHANNEL,UNIT)
%   Identify and define features represented in TIMESTAMP, CHANNEL, and
%   UNIT. TIMESTAMP should be a vector of all timestamps. CHANNEL (UNIT)
%   should be a vector listing the channel (unit) associated with each
%   timestamp. Provide data from multiple electrode arrays as cell arrays
%   (one electrode array per cell). The number of features will be returned
%   in NFEAT.  Identifying information for each feature (NSP, channel,
%   unit, firing rate, etc.) will be returned in DEF, and the column labels
%   for this matrix in LBL. By default, unsorted and noise units will be
%   included. The firing rate will have units dependent on the units of the
%   timestamps provided (e.g., spikes/sec if timestamps in seconds, or
%   spikes/sample if timestamps in samples).
%
%   FEATDEF(...,'FRSCALE',FRSCALE)
%   Provide a multiplicative scaling factor FRSCALE to convert spike firing
%   rates into units of spikes/sec. In most cases this value will be equal
%   to the sampling rate of the timestamps, if the timestamps are in
%   samples, or 1 if the timestamps are in seconds. If FRSCALE is empty or
%   not provided, the default value is 1.
%
%   FEATDEF(...,'LAG',LAG)
%   Specify a lag between the times in PROCWIN and the timestamps
%   associated with the neural data. The default value is 0 (zero).
%
%   FEATDEF(...,'UNSORTED')
%   FEATDEF(...,'NOISE')
%   Specify that unsorted units and/or noise units should be included in
%   the feature definition.
warning('this function may not be used any more!');

% log function
logfcn = {{@Debug.message},{struct('verbosity',inf)}};
idx = strcmpi(varargin,'logfcn');
if any(idx)
    logfcn = varargin{circshift(idx,1,2)};
    varargin(idx|circshift(idx,1,2)) = [];
end
idx = cellfun(@(x)isa(x,'Debug.Debugger'),varargin);
if any(idx)
    debugger = varargin{idx};
    varargin(idx) = [];
    logfcn = {{@debugger.log},{}};
end

% process inputs
assert(nargin>=3,'Must provide timestamp, channel, and unit inputs');
timestamp = util.ascell(timestamp);
channel = util.ascell(channel);
unit = util.ascell(unit);
if nargin<4||isempty(frscale),frscale=1;end
if nargin<5||isempty(lag),lag=arrayfun(@(x)0,1:length(channel),'UniformOutput',false);end
lag = util.ascell(lag);
assert(length(timestamp)==length(channel)&&length(channel)==length(unit)&&length(lag)==length(channel),'Each of timestamp, channel, and unit must have the same number of cells (i.e. arrays)');
numBlocks = length(timestamp);

% constant since for us it never changes
CHANNELS_PER_NSP = 96;

% check for unsorted/noise requests
flagUnsorted = false;
if any(strncmpi(varargin,'unsorted',6)),flagUnsorted=true;end
flagNoise = false;
if any(strncmpi(varargin,'noise',5)),flagNoise=true;end

% loop over arrays (cells)
lbl = {'nsp','channel','dataset_channel','unit','firing_rate','lag'};
def = nan(1024,length(lbl)); % pre-allocate space for 1024 features
dd = 1;
for block=1:numBlocks
    
    % loop over channels
    channels = unique(channel{block});
    for chidx=1:length(channels)
        dch = channels(chidx);
        
        % determine the nsp
        nsp = floor((dch-1)/CHANNELS_PER_NSP)+1;
        
        % determine the nsp channel
        ch = dch - (nsp-1)*CHANNELS_PER_NSP;
        
        % loop over units
        units = unique(unit{block}(channel{block}==ch));
        if ~flagUnsorted
            units(units==0) = [];
        end
        if ~flagNoise
            units(units==255) = [];
        end
        for unidx=1:length(units)
            un = units(unidx);
            
            % check whether this feature already exists in def
            idx = def(:,strcmpi(lbl,'nsp'))==nsp & ...
                def(:,strcmpi(lbl,'channel'))==ch & ...
                def(:,strcmpi(lbl,'dataset_channel'))==dch & ...
                def(:,strcmpi(lbl,'unit'))==un;
            if nnz(idx)==0
                
                % calculate firing rate over all recording blocks
                idx = cellfun(@(x,y)x==ch&y==un,channel,unit,'UniformOutput',false);
                num_spikes = sum(cellfun(@nnz,idx));
                timestamps = cellfun(@(x,y)x(y),timestamps,idx,'UniformOutput',false);
                timestamp_range = sum(cellfun(@(x)diff(x([1 end])),timestamps,'UniformOutput',false));
                fr = frscale*num_spikes/timestamp_range;
                
                % add this feature to the definition matrix
                def{dd,:} = {nsp,ch,dch,un,fr,lag{nsp}};
                dd = dd+1;
            end
        end
    end
end

% clip out unused entries and count the remaining features
def(dd:end,:) = [];
nfeat = size(def,1);

% report results
proc.helper.log(logfcn,sprintf('Found %d features',nfeat),'info');