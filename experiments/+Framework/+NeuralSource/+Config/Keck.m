function Keck(ns,varargin)

% process user inputs
[varargin,enable_lfp] = util.argflag('lfp',varargin,false);
[varargin,enable_spike] = util.argflag('spike',varargin,false);
[varargin,gridmap] = util.argkeyval('gridmap',varargin,'');

% set grid map
numNSPs = length(ns.hFramework.options.nsps);
if ~iscell(gridmap),gridmap={gridmap};end
assert(length(gridmap)==numNSPs,'Must provide one grid map per NSP (expected %d but found %d)',numNSPs,length(gridmap));
ns.hGridMap = cell(1,numNSPs);
for kk=1:numNSPs
    if ischar(gridmap{kk})
        assert(exist(gridmap{kk},'file')==2,'Grid map file "%s" does not exist',gridmap{kk});
        ns.hGridMap{kk} = GridMap.Interface(gridmap{kk});
    elseif isa(gridmap{kk},'GridMap.Interface')
        ns.hGridMap{kk} = gridmap{kk};
    end
    assert(~isempty(ns.hGridMap{kk})&&isa(ns.hGridMap{kk},'GridMap.Interface'),'Must provide valid grid map');
end

% set up LFP options
[varargin,lfp_N] = util.argkeyval('N',varargin,1024);
[varargin,lfp_freqbands] = util.argkeyval('lfp_freqbands',varargin,{[12 30],[30 80]});
[varargin,lfp_channels] = util.argkeyval('lfp_channels',varargin,cellfun(@(x)x.ChannelInfo.AmplifierChannel,ns.hGridMap,'UniformOutput',false));
[varargin,lfp_dtMultiple] = util.argkeyval('lfp_dtx',varargin,5); % window size defined in multiples of the Framework timer period

% set up spike options
[varargin,spike_fs] = util.argkeyval('spike_fs',varargin,30e3);
[varargin,spike_channels] = util.argkeyval('spike_channels',varargin,cellfun(@(x)x.ChannelInfo.AmplifierChannel,ns.hGridMap,'UniformOutput',false));
[varargin,spike_type] = util.argkeyval('spike_type',varargin,'unsorted'); % 'sorted', 'unsorted', 'both'
[varargin,spike_dtMultiple] = util.argkeyval('spike_dtx',varargin,1.5); % window size defined in multiples of the Framework timer period

% file recording
[varargin,ns.enableFileStorage] = util.argflag('record',varargin,false);

% make sure no leftover input arguments
util.argempty(varargin);

% window size in framework cycles for spike and lfp
ns.dtMultipleEvent = spike_dtMultiple;
ns.dtMultipleContinuous = lfp_dtMultiple;

% construct feature lists
st_spike.handle = @Framework.FeatureList.Spike;
st_spike.args = {'fs',spike_fs,'channels',spike_channels,'type',spike_type};
st_lfp.handle = @Framework.FeatureList.LFP;
st_lfp.args = {'N',lfp_N,'frequencyBands',lfp_freqbands,'channels',lfp_channels};
if enable_spike && enable_lfp
    ns.featureListConfig = [st_spike st_lfp];
elseif enable_lfp
    ns.featureListConfig = st_lfp;
elseif enable_spike
    ns.featureListConfig = st_spike;
end