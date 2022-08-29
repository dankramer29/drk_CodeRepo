function model = buildNaiveBayesClassifier(feat, featGroup, regWeight)
    %works like Matlab's classify function to build a multivariate normal,
    %generative classifier model that assumes the features are generated by mvn
    %distributions, one for each class. applyMvnGenerativeClassifier then
    %uses Bayesian logic, assuming equal priors, to compute the likelihood
    %of each feature vector coming from each of the distributions,
    %selecting the most likely one
    
    %feat is an MxN feature matrix, where each row is a feature vector
    %featGroup is an Mx1 grouping vector, where each entry indicates the
    %class of the corresponding feature vector
    %type can be "linear" or "quadratic"
    
    % grp2idx sorts a numeric grouping var ascending, and a string grouping
    % var by order of first occurrence
    nModels = size(featGroup,2);
    for m=1:nModels
        [gIndex, ~, classNames] = grp2idx(featGroup(:,m));
        nGroups = max(gIndex);
        nanIdx = find(isnan(gIndex) | any(isnan(feat),2));
        if ~isempty(nanIdx)
            feat(nanIdx,:) = [];
            gIndex(nanIdx) = [];
        end
        gSize = hist(gIndex,1:nGroups);

        %compute mean of groups
        nDim = size(feat,2);
        nObs = size(feat,1);
        gMeans = NaN(nGroups, nDim);
        for k = 1:nGroups
            gMeans(k,:) = mean(feat(gIndex==k,:),1);
        end

        gStd = std(feat);

        model(m).gMeans = gMeans*regWeight;
        model(m).gStd = gStd;
        model(m).classNames = classNames;
    end
end