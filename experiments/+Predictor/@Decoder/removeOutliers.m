function removeOutliers

warning('Work on outlier removal')
if isfield(obj.decoderParams,'removeOutliers') && obj.decoderParams.removeOutliers~=0;
    for i=1:size(z,1)
        threshVal=mean(sZ(i,:))+obj.decoderParams.removeOutliers*std(sZ(i,:));
        outlierInds=sZ(i,:)>threshVal;
        sZ(i,outlierInds)=threshVal;
        nOutliers(i)=nnz(outlierInds);
    end
    figure; plot(nOutliers/size(z,2)*100,'.')
    title('Percentage of outlier values for each Feature')
    
end