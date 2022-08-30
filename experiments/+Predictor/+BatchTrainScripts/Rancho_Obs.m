obj.frameworkParams.saveOnTrain=0;

obj.decoderParams.trainingTarget = 'AssistedPrediction';
%%
obj.msgName(' Fitting Obs-STD',1)
decName='Obs-STD';

obj.decoderParams.plotFit=0;
obj.decoderParams.fitType='standard';
obj.decoderParams.preProcessForSignificance=1;
obj.decoderParams.preProcessThreshold=.1;

obj.Train('name',sprintf('%s%s',prefix,decName))

% %% 
% obj.frameworkParams.saveOnTrain=1;
% 
% obj.msgName(' Fitting Obs-Lasso',1)
% decName='Obs-Lasso';
% 
% obj.decoderParams.fitType='lasso';
% obj.decoderParams.preProcessForSignificance=1;
% obj.decoderParams.preProcessThreshold=.1;
% 
% obj.Train('name',sprintf('%s%s',prefix,decName))

%% 
obj.frameworkParams.saveOnTrain=1;

obj.msgName(' Fitting Obs-Lasso',1)
decName='Obs-IC';

obj.decoderParams.filterType='inversion';
obj.decoderParams.useCov=1;
obj.decoderParams.preProcessForSignificance=1;
obj.decoderParams.preProcessThreshold=.1;

obj.Train('name',sprintf('%s%s',prefix,decName))
%% 
obj.frameworkParams.saveOnTrain=1;

obj.msgName(' Fitting Obs-Lasso',1)
decName='Obs-InoC';

obj.decoderParams.filterType='inversion';
obj.decoderParams.useCov=0;
obj.decoderParams.preProcessForSignificance=1;
obj.decoderParams.preProcessThreshold=.1;

obj.Train('name',sprintf('%s%s',prefix,decName))

% save out results


