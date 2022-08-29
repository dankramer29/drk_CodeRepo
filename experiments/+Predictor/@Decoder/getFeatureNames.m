function [FeatNames,FL,errorMessage]=getFeatureNames(obj,options)

% return a cell array of feature names for elements in FeatureList.
if nargin<2; options=[]; end
    
% when set to true, only return active Features
returnActiveFeatures=Utilities.getInputField(options,'returnActiveFeatures',true);
% when non-empty, only return subset of features
featureInds=Utilities.getInputField(options,'featureInds',[]);

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

FeatNames={FL.name};


