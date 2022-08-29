function PlotBasicStatistics(obj)

% Plot showing why certain features where rendered inactive


subplot(2,2,1)
plot(obj.signalProps.Corrs,'.')
title('Correlations')
legend(obj.stateLabels)

subplot(2,2,2)
plot(obj.signalProps.PeakCorrs,'.')
title('Peak Correlations')
legend(obj.stateLabels)

subplot(2,2,3)
errorbar(obj.signalProps.meanZ/obj.samplePeriod,obj.signalProps.stdZ/obj.samplePeriod/sqrt(obj.signalProps.nSamples),'.')
title('FiringRate - mean/SE')
