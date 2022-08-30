function [FeatNames,errorMessage]=getFeatureInfo(obj,options)

% return a cell array of feature names for elements in FeatureList.
if nargin<2; options=[]; end
    
% when set to true, only return active Features
returnActiveFeatures=getInputField(options,'returnActiveFeatures',true);
% when non-empty, only return subset of features
featureInds=getInputField(options,'featureInds',[]);

% preliminary checks to make sure the data is reasonable
FL=obj.options.FeatureList;

if isempty(FL)
    FeatNames=[];
    errorMessage='Feature List is Empty';
    return
end

if length(obj.activeFeatures)~=length(FL)
    FeatNames=[];
    errorMessage='activeFeatues and FeatureList are not the same length - multiple possible causes';
    return
end

% prune
if returnActiveFeatures
    FL=FL(obj.activeFeatures);
end

if ~isempty(featureInds)
    FL=FL(featureInds);
end

%  check to see if there are multiple units per channel; if so, must output
%  both channel and unit info
multiUnit=logical(sum(diff([FL.unit])));


for i=1:length(FL)
    if multiUnit
    FeatNames{i}=sprintf('%d_%d',FL(i).channel,FL(i).unit);
    else
        FeatNames{i}=sprintf('%d',FL(i).channel);
    end
end
