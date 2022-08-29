%%
obj.frameworkParams.saveOnTrain=0;

%%
obj.decoderParams.fitType='lasso';
obj.decoderParams.preProcessForSignificance=1;
obj.decoderParams.preProcessThreshold=.1;
%%
obj.msgName(' Fitting ReTr-Ideal',1)
decName='ReTr-Ideal';

obj.decoderParams.intentionOptions.useIntention=0;
obj.decoderParams.trainingTarget = 'IdealPrediction';
obj.Train('name',sprintf('%s%s',prefix,decName))

%%
obj.frameworkParams.saveOnTrain=1;

obj.msgName(' Fitting ReTr-Intent',1)
decName='ReTr-Intent';
obj.decoderParams.intentionOptions.useIntention=1;
obj.decoderParams.trainingTarget = 'IdealPrediction';


obj.Train('name',sprintf('%s%s',prefix,decName))

