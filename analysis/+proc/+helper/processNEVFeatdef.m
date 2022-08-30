function [nfeat,def] = processNEVFeatdef(timestamp,channel,unit,varargin)
% PROCESSNEVFEATDEF count features and generate a definition matrix identifying each
%
%   [NFEAT,DEF,LBL] = PROCESSNEVFEATDEF(TIMESTAMP,CHANNEL,UNIT)
%   Identify and define features represented in TIMESTAMP, CHANNEL, and
%   UNIT. The number of features will be returned in NFEAT.  Identifying
%   information for each feature (NSP, channel, unit, firing rate, etc.)
%   will be returned in DEF, and the column labels for this matrix in LBL.
%   By default, unsorted and noise units will be included. The firing rate
%   will have units dependent on the units of the timestamps provided
%   (e.g., spikes/sec if timestamps in seconds, or spikes/sample if
% timestamps in samples).
%
%   PROCESSNEVFEATDEF(...,'FRSCALE',FRSCALE)
%   Provide a multiplicative scaling factor FRSCALE to convert spike firing
%   rates into units of spikes/sec. In most cases this value will be equal
%   to the sampling rate of the timestamps, if the timestamps are in
%   samples, or 1 if the timestamps are in seconds. If FRSCALE is empty or
%   not provided, the default value is 1.
%
%   PROCESSNEVFEATDEF(...,'LAG',LAG)
%   Specify a lag between the times in PROCWIN and the timestamps
%   associated with the neural data. The default value is 0 (zero).
%
%   PROCESSNEVFEATDEF(...,'UNSORTED')
%   PROCESSNEVFEATDEF(...,'NOISE')
%   Specify that unsorted units and/or noise units should be included in
%   the feature definition.

% verify the minimum inputs
assert(nargin>=3,'Must provide timestamp, channel, and unit inputs');
timestamp = util.ascell(timestamp);
channel = util.ascell(channel);
unit = util.ascell(unit);
numArrays = 1; % hard-coded for now

% default values
FlagUniformOutput = false;
lag = arrayfun(@(x)0,1:numArrays,'UniformOutput',false);
dtclass = unique(cellfun(@class,timestamp,'UniformOutput',false));
assert(length(dtclass)==1,'No support for multiple distinct classes of data: %s',strjoin(dtclass,', '));
dtclass = dtclass{1};
frscale = 1;
flagUnsorted = false;
flagNoise = false;

% process user input
[idx,FlagUniformOutput,~,lag,dtclass] = proc.helper.processCommonInputs(FlagUniformOutput,[],lag,dtclass,numArrays,varargin{:});
varargin(idx) = [];
[idx,frscale,flagUnsorted,flagNoise] = processLocalInputs(frscale,flagUnsorted,flagNoise,varargin{:});
varargin(idx) = [];
assert(isempty(varargin),'Unknown inputs');

% validate
assert(length(timestamp)==length(channel)&&length(channel)==length(unit),'Each of timestamp, channel, and unit must have the same number of cells (i.e. arrays)');
numBlocks = length(timestamp);
timestamp_range = cellfun(@(x)diff(x([1 end])),timestamp);
timestamp_range = timestamp_range/frscale;

% construct a master list of channel/unit pairs
% first, get list of channels in every block
channel_list = cellfun(@(x)unique(x),channel,'UniformOutput',false);
channel_unit_list = cell(1,numBlocks);
for bb=1:numBlocks
    numChannels = length(channel_list{bb});
    
    % find units associated with this channel and construct list of
    % channel/unit pairs
    channel_unit_list{bb} = cell(1,numChannels);
    for cc=1:numChannels
        unit_list = unique(unit{bb}(channel{bb}==channel_list{bb}(cc)));
        if ~flagUnsorted
            unit_list(unit_list==0) = [];
        end
        if ~flagNoise
            unit_list(unit_list==255) = [];
        end
        channel_unit_list{bb}{cc} = [repmat(channel_list{bb}(cc),length(unit_list),1) unit_list(:)];
    end
    channel_unit_list{bb} = cat(1,channel_unit_list{bb}{:});
end

% Provide a single table (FlagUniformOutput=true) or cell array of tables
% (FlagUniformOutput=false) identifying the channel/unit pairs.
if FlagUniformOutput
    
    % unique channel/unit combinations across all blocks
    channel_unit_list = unique(cat(1,channel_unit_list{:}),'rows');
    numFeatures = size(channel_unit_list,1);
    fd = struct('feature',nan,'nsp',nan,'dataset_channel',nan,'channel',nan,'unit',nan,'lag',nan,'firing_rate',nan); % set variable order
    fd.dataset_channel = channel_unit_list(:,1);
    fd.unit = channel_unit_list(:,2);
    fd.nsp = ones(size(fd.dataset_channel)); % hard-coded for now
    fd.channel = fd.dataset_channel; % hard-coded for now
    fd.lag = arrayfun(@(x)cast(lag{x},dtclass),fd.nsp);
    
    % calculate firing rate for each feature over all blocks
    fd.firing_rate = nan(numFeatures,1);
    for ff=1:numFeatures
        idx = cellfun(@(x,y)x==fd.dataset_channel(ff)&y==fd.unit(ff),channel,unit,'UniformOutput',false);
        num_spikes = sum(cellfun(@nnz,idx));
        fd.firing_rate(ff) = num_spikes/sum(timestamp_range);
    end
    
    % add in feature index
    fd.feature = (1:numFeatures)';
    
    % construct feature definition table
    def = struct2table(fd);
    def = sortrows(def,{'nsp','dataset_channel','unit'});
    nfeat = numFeatures;
else
    
    % unique channel/unit combinations per block
    def = cell(1,numBlocks);
    nfeat = nan(1,numBlocks);
    for bb=1:numBlocks
        numFeatures = size(channel_unit_list{bb},1);
        fd = struct('feature',nan,'nsp',nan,'dataset_channel',nan,'channel',nan,'unit',nan,'lag',nan,'firing_rate',nan); % set variable order
        fd.dataset_channel = channel_unit_list{bb}(:,1);
        fd.unit = channel_unit_list{bb}(:,2);
        fd.nsp = 1; % hard-coded for now
        fd.channel = fd.dataset_channel;
        fd.lag = arrayfun(@(x)cast(lag{x},dtclass),fd.nsp);
        
        % calculate firing rate for each feature in this block
        fd.firing_rate = nan(numFeatures,1);
        for ff=1:numFeatures
            idx = channel{bb}==fd.dataset_channel(ff)&unit{bb}==fd.unit(ff);
            num_spikes = nnz(idx);
            fd.firing_rate(ff) = num_spikes/timestamp_range(bb);
        end
        
        % add in feature index
        fd.feature = (1:numFeatures)';
        
        % construct feature definition table
        def{bb} = struct2table(fd);
        def{bb} = sortrows(def{bb},{'nsp','dataset_channel','unit'});
        nfeat(bb) = numFeatures;
    end
end




function [idxAll,frscale,flagUnsorted,flagNoise] = processLocalInputs(frscale,flagUnsorted,flagNoise,varargin)

% keep track of varargin indices for the inputs
idxAll = false(size(varargin));

% process frscale
idx = strcmpi(varargin,'frscale');
if any(idx)
    frscale = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end

% check for unsorted/noise requests
idx = strncmpi(varargin,'unsorted',6);
if any(idx)
    flagUnsorted = true;
    idxAll = idxAll|idx;
end
idx = strncmpi(varargin,'noise',5);
if any(idx)
    flagNoise = true;
    idxAll = idxAll|idx;
end