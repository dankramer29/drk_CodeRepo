function activeFeatures=combineValidAndSignifFeatures(validFeatures,signifFeatures)
%%
% validFeatures designates features that are useable as determined by
% looking at each Feature individually.  In otherwords, remove features
% that have nans, are constant throughout etc.

% signifFeatures designates features that are significantly related to the
% signal we are interested in decoding as determined by fitting.

% activeFeatures designates features that will be used for decoding and is
% constructed from signifFeatures and validFeatures

% this function combines signifFeatures and validFeatures into
% activeFeatures.  This is non-trivial as signifFeatures is only defined
% for validFeatures==true.  To solve, we find the invalid Features and
% insert them into signifFeatures


activeFeatures=signifFeatures;

insertInds=find(~validFeatures); 

% based on valid Features.  Insert elements into activeFeatures
for i=1:length(insertInds)
    ind=insertInds(i);
    activeFeatures=[activeFeatures(1:ind-1,:); activeFeatures(1,:)*0; activeFeatures(ind:end,:)];
end

activeFeatures=activeFeatures;