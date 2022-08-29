      %%
obj.Params.frameworkParams.saveOnTrain=0;
obj.Params.frameworkParams.saveOnTrain=1;
%%
obj.msgName(' Fitting ReTr-Ideal',1)
decName='ReTr-Ideal';

obj.Params.intentionOptions.useIntention=1;
obj.Params.trainingTarget = 'IdealPrediction';
obj.Train('TrainingData','Buffers')

% obj.msgName(' Fitting ReTr-IdealRetrain',1)
% decName='ReTr-IdealIntent';
% 
% obj.Params.intentionOptions.useIntention=1;
% obj.Params.trainingTarget = 'IdealPrediction';
% obj.Train('name',sprintf('%s%s',prefix,decName),TrainingData,'Buffers')
% 
% obj.Params.frameworkParams.saveOnTrain=1;
% 
% obj.msgName(' Fitting ReTr-Assited',1)
% decName='ReTr-Assisted';
% % 
% obj.Params.intentionOptions.useIntention=1;
% obj.Params.trainingTarget = 'AssistedPrediction';
% obj.Train('name',sprintf('%s%s',prefix,decName),TrainingData,'Buffers')
% %%
% obj.msgName(' Fitting ReTr-Intent-rV',1)
% decName='ReTr-Intent-rV';
% diffX=obj.decoderParams.diffX;
% obj.decoderParams.diffX=0;
% 
% obj.decoderParams.intentionOptions.targetzone_thresh=0.05;
% obj.decoderParams.intentionOptions.useIntention=1;
% obj.decoderParams.trainingTarget = 'Kinematics';
% obj.decoderParams.intentionOptions.scaleType='rotVel';
% obj.Train('name',sprintf('%s%s',prefix,decName))
% %%
% obj.msgName(' Fitting ReTr-Intent-sD',1)
% decName='ReTr-Intent-sD';
% obj.decoderParams.intentionOptions.useIntention=1;
% obj.decoderParams.trainingTarget = 'Kinematics';
% obj.decoderParams.intentionOptions.scaleType='scaleDir';
% obj.Train('name',sprintf('%s%s',prefix,decName))
% %%
% obj.frameworkParams.saveOnTrain=1;
% 
% obj.msgName(' Fitting ReTr-Intent-dP',1)
% decName='ReTr-Intent-dP';
% obj.decoderParams.intentionOptions.useIntention=1;
% obj.decoderParams.trainingTarget = 'Kinematics';
% obj.decoderParams.intentionOptions.scaleType='distProp';
% obj.Train('name',sprintf('%s%s',prefix,decName))
%%
% obj.decoderParams.diffX=diffX;
