% obj.frameworkParams.saveOnTrain=0;

obj.decoderParams.trainingTarget = 'IdealPrediction';
%%
obj.msgName(' Fitting Squeeze',1)
decName='Squeeze-Basic';

obj.decoderParams.fitType='standard';
obj.decoderParams.preProcessForSignificance=0;
obj.decoderParams.preProcessThreshold=.1;

%%
SqueezeState=obj.hFramework.buffers.get('SqueezeState',inf);
features=obj.hFramework.buffers.get('features',inf);
features=features(1:end-1,:)';
SqueezeState=[SqueezeState,SqueezeState]';
obj.decoderParams.diffX=0;
obj.decoderParams.lags2Process=[-6:2:6];
obj.Train('name',sprintf('%s',decName),'xz',SqueezeState,features)
obj.decoderParams.diffX=1;
%% 

