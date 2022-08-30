function RandData(ns,varargin)
[varargin,numChannels] = util.argkeyval('numChannels',varargin,25);
[varargin,rateMin] = util.argkeyval('rateMin',varargin,0);
[varargin,rateMax] = util.argkeyval('rateMax',varargin,40);
util.argempty(varargin);

%ns.numChannels = 246;
ns.numChannels = numChannels;
ns.rateMin = rateMin;
ns.rateMax = rateMax;

ns.featureListConfig(1).handle = @Framework.FeatureList.EventFeatureList;
ns.featureListConfig(1).args = {};

ns.hFeatureListCollection{1}.featureCount = ns.numChannels;
ns.hFeatureListCollection{1}.dataTypes = {'EVENT'};