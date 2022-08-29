function SmFilt=MakeFilter(obj)

% get parameters
maxSamples=obj.decoderParams.preSmoothOptions.maxSamples;
plotFilter=obj.decoderParams.preSmoothOptions.plotFilter;
lineSpec=obj.decoderParams.preSmoothOptions.lineSpec;
filterType=obj.decoderParams.preSmoothOptions.filterType;

if strcmp(filterType,'exp')
    
    expKernel =obj.decoderParams.preSmoothOptions.expKernel;
    for i=(0:maxSamples-1); SC(i+1)=expKernel^i ; end
    
    %normalize
    SC=SC-min(SC);
    SmFilt=SC/sum(SC);
    %     foo=(1-sum(SC))/length(SC);
    %     SmFilt=SC+foo;
    
else
    %      FilterOrder
    % FilterDurations
    h = ones(1,FilterOrder); h=h/sum(h);
    binomialCoeff = conv(h,h);
    
    for n = 1:FilterDurations
        binomialCoeff = conv(binomialCoeff,h);
    end
    
    binomialCoeff=fliplr(binomialCoeff(1:ceil(length(binomialCoeff)/2)));
    
    if length(binomialCoeff)>maxSamples;
        binomialCoeff=binomialCoeff(1:maxSamples);
    end
    
    binomialCoeff=binomialCoeff-min(binomialCoeff);
    
    binomialCoeff=binomialCoeff/sum(binomialCoeff);
    SmFilt=binomialCoeff;
    
    %     foo=(1-sum(binomialCoeff))/length(binomialCoeff);
    %     SmFilt=binomialCoeff+foo;
    
    
end


if plotFilter
    plot(obj.decoderParams.samplePeriod*(-(length(SmFilt)-1):0),fliplr(SmFilt),lineSpec)
    axis tight
end
