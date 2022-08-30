function PlotBadFeatures(obj)

% Plot showing why certain features where rendered inactive

figure; hold on;

plot(obj.signalProps.hasInf,'.')
plot(obj.signalProps.hasNans*1.2,'ro')
plot(obj.signalProps.noModulation*1.4,'g*')
plot(obj.signalProps.lowFiring*1.6,'ks')

legend({'hasInf','hasNans','noModulation',sprintf('FR<%0.1d',obj.options.Feature_freqCutOff)})
