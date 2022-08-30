function trainingData=PreprocessTrainingData(obj,trainingData)

% preprocess training data
x=trainingData.rawX;
z=trainingData.Z;
targ=trainingData.targ;

if obj.decoderParams.intentionOptions.useIntention && ~isempty(targ);
    intentionOptions=obj.decoderParams.intentionOptions;
    
%     [x,IntentionState]=getIntendedKinematics(obj,x,targ);
%     trainingData.IntentionState=IntentionState;
    
    [x,trainingData.IntentionState]=Predictor.IntentionEstimation.getIntendedKinematics_BAK(x,targ,intentionOptions);
end

trainingData.X=x;

trainingData.S=util.mnorm(x(2:2:end,:)')';
%%
% smooth kinematics using splines - assumption being that we are removing
% frequencies that are too fast to represent any type of intentional
% correction.
if isfield(obj.decoderParams,'preSmoothKinematics') && obj.decoderParams.preSmoothKinematics==1;
    Samples=.3/obj.decoderParams.samplePeriod;
    span=Samples/size(x,2);
    for i=2:2:size(x,1)
        %     test=smooth(x(i,:)',span,'lowess');
        %     figure(13); clf;plot(x(i,:),'.-'); hold on; plot(test,'r.-')
        x(i,:)=smooth(x(i,:),span,'lowess');
    end
end

% Remove any bias in velocity assuming that avg velocity should be 0;
if obj.decoderParams.preSmoothOptions.deTrendVelocity   
   trend=repmat(mean(x,2),1,size(x,2));
   trend(1:2:end,:)=0;
   x=x-trend;
end

%%
% Step 1
% Smooth the kinematic and neural data to maximize SNR for fits.
if obj.decoderParams.preSmoothOptions.smoothTrainingData;
    
    F=makeSmoothingFilter(obj,obj.decoderParams.preSmoothOptions);
    if obj.decoderParams.preSmoothOptions.causal
        [sX]=util.filter_mirrored(F,1,x,[],2);
        [sZ]=util.filter_mirrored(F,1,z,[],2);
    else
        [sX]=filtfilt(F,1,x')';
        [sZ]=filtfilt(F,1,z')';
    end
    
else
    sX=x;
    sZ=z;
end

if obj.decoderParams.adaptNeuralMean
    % high pass using same settings as adapted neural mean.
    trend= util.expsmooth_mirrored( sZ', 1/obj.decoderParams.samplePeriod, obj.decoderParams.adaptNeuralRate*1000 )';
    sZ=sZ-trend;
    
    trend= util.expsmooth_mirrored( sX', 1/obj.decoderParams.samplePeriod, obj.decoderParams.adaptNeuralRate*1000 )';
    sX=sX-trend;
end



trainingData.sX=sX;
trainingData.sZ=sZ;
trainingData.sS=util.mnorm(trainingData.sX(2:2:end,:)')';
