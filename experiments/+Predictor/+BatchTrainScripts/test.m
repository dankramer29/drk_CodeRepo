obj.frameworkParams.saveOnTrain=0;


obj.decoderParams.intentionOptions.useIntention=1;
obj.decoderParams.fitType='lasso';
obj.msgName(' Fitting Using Intentional Correction')
decName='Int-STD';
obj.Train('name',sprintf('%s-%s',name,decName))

obj.decoderParams.intentionOptions.useIntention=0;
obj.decoderParams.fitType='lasso';
% obj.msgName(' Fitting Using Standard Fit')
decName='NoInt-Lasso';
obj.Train('name',sprintf('%s-%s',name,decName))


% save out results
obj.frameworkParams.saveOnTrain=1;

obj.decoderParams.intentionOptions.useIntention=0;
obj.decoderParams.fitType='lasso';
% obj.msgName(' Fitting Using Standard Fit')
decName='NoInt-lasso';
obj.Train('name',sprintf('%s-%s',name,decName))