%%
obj.frameworkParams.saveOnTrain=0;

%%
obj.decoderParams.fitType='lasso';
obj.decoderParams.preProcessForSignificance=1;
obj.decoderParams.preProcessThreshold=.1;
%%
obj.msgName(' Fitting Using Intentional Correction',1)
decName='ReTr-NoInt';

obj.decoderParams.intentionOptions.useIntention=0;

obj.Train('name',sprintf('%s%s',prefix,decName))

%%
obj.msgName(' Fitting Using Intentional Correction',1)
decName='ReTr-NoInt';

obj.decoderParams.intentionOptions.useIntention=0;

obj.Train('name',sprintf('%s%s',prefix,decName))

%% save out results
obj.frameworkParams.saveOnTrain=1;

%%
obj.msgName(' Fitting Using Standard Fit',1)
decName='NoInt-Lasso';

obj.decoderParams.intentionOptions.useIntention=1;

obj.Train('name',sprintf('%s%s',prefix,decName))