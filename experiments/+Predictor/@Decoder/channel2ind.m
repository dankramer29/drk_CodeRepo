function [INDXS,UNITS]=channel2ind(obj,channel,indType)

if nargin==2
warning('outputing ind of active features only (not input features)')
indType='active'
end

% return the indices of the specified set of channels;
if isempty(obj.options.FeatureList)
    error('No Feature information in obj.options.FeatureList - Cannot Proceed')
    INDXS=[]; UNITS=[];
    return
end

switch indType
    case 'active'
all_channels=[obj.options.FeatureList(obj.activeFeatures).channel];
all_units=[obj.options.FeatureList(obj.activeFeatures).channel];

    case 'all'
all_channels=[obj.options.FeatureList.channel];
all_units=[obj.options.FeatureList.channel];
end

% find index of Feature for specified channel

INDXS=find(channel==all_channels);
UNITS=all_units(find(channel==all_channels));
