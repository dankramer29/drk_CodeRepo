function   Gain=computeVelocityGain(testSig,refSig,percentiles)
    
% computes a gain factor that makes the upper percentile of values of two
% signals matchup

% determine proper scaling
    [refSigSorted,IX] = sort(abs(refSig));
    hv=round(percentiles*length(refSigSorted));
    hvIX=IX(hv(1):hv(2));
    Gain=refSig(hvIX)/testSig(hvIX);
    