obj.frameworkParams.saveOnTrain=0;


%%
obj.msgName(' Fitting STD',1)
decName='Obs-STD';

obj.decoderParams.fitType='standard';
obj.decoderParams.preProcessForSignificance=0;

obj.Train('name',sprintf('%s%s',prefix,decName))

%% 
obj.msgName(' Fitting Reg1',1)
decName='Obs-Thr1';

obj.decoderParams.fitType='lasso';
obj.decoderParams.preProcessForSignificance=1;
obj.decoderParams.preProcessThreshold=.1;

obj.Train('name',sprintf('%s%s',prefix,decName))

% save out results
obj.frameworkParams.saveOnTrain=1;

%%
obj.msgName(' Fitting Reg2',1)
decName='Obs-Thr2';

obj.decoderParams.fitType='lasso';
obj.decoderParams.preProcessForSignificance=1;
obj.decoderParams.preProcessThreshold=.05;

obj.Train('name',sprintf('%s%s',prefix,decName))

% trainingTarget
% preProcessForSignificance
