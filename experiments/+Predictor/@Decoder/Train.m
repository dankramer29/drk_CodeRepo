function Train(obj,varargin)

% function to train the linear filter

% x should have dimensions [number of dimensions , number of time points]
% z should have dimensions [nfeatures,ntime_points]


%% initialize variables
name=sprintf('Decoder-%0.2d',length(obj.decoders));
groupName=sprintf('group-1');
x=[]; z=[]; trainINDXS=[]; targ=[]; FrameID=[];
updateDecoder=false;

%% Parse Inputs
inputArguments=varargin;
while ~isempty(inputArguments)
    
    switch lower(inputArguments{1})
        case 'xz'
            x=inputArguments{2};
            z=inputArguments{3};
            
            inputArguments(1:3)=[];
            
        case 'fwfile'
            obj.decoderParams.diffX=0;
            FWfile=inputArguments{2};
            StateInds=inputArguments{3};
            
            Block=load(FWfile);
            x=Block.Data.state(:,StateInds)';
            z=Block.Data.features';
            targ=Block.Data.target';
            inputArguments(1:3)=[];
            
        case 'xzt'
            % x is actual position, targ is goal position, the two
            % combined are used to infer "desired" goal
            x=inputArguments{2};
            z=inputArguments{3};
            targ=inputArguments{4};
            inputArguments(1:4)=[];
        case lower('Name')
            name=inputArguments{2};
            inputArguments(1:2)=[];
        case lower('UpdateDecoder')
            updateDecoder=inputArguments{2};
            inputArguments(1:2)=[];
            
        case lower('FrameID')
            FrameID=inputArguments{2};
            inputArguments(1:2)=[];
            
        case lower('TargetPosition')
            targ=inputArguments{2};
            inputArguments(1:2)=[];
        case lower('groupName')
            groupName=inputArguments{2};
            inputArguments(1:2)=[];
        case lower('trainINDXS')
            trainINDXS=inputArguments{2};
            inputArguments(1:2)=[];
        otherwise
            error('Input %s is not a valid arguement, try again ',inputArguments{1})
    end
    
    
end


nDecoders=length(obj.decoders);
prevDecoder=obj.currentDecoderINDX;
currentDecoderINDX=nDecoders+1;

if isempty(x);
    % use data from buffers for retraining
    switch obj.decoderParams.trainingTarget
        
        case 'IdealPrediction'
            x=obj.DataBuffers.IdealPrediction.get();
            
        case 'IdealPredictionForce'
            x=obj.DataBuffers.IdealPrediction.get();
            F=obj.DataBuffers.IdealForce.get();
            x(2:2:end,:) = F;
            
        case 'AssistedPrediction'
            x=obj.DataBuffers.AssistedPrediction.get();
            
        case 'NeuralPrediction'
            x=obj.DataBuffers.NeuralPrediction.get();
            
        case 'Kinematics'
            x=obj.DataBuffers.Kinematics.get();
            if obj.decoderParams.diffX
                x=obj.position2state(x);
            end
        otherwise
            warning('%s is an invalid type for obj.decoderParams.trainingTarget',obj.decoderParams.trainingTarget);
            return
    end
    nElemX=size(x,2);
    
    
    targ=obj.DataBuffers.Goal.get();
    z=obj.DataBuffers.NeuralData.get();
    FrameID=obj.DataBuffers.FrameID.get;
    
    if size(x,2)~=size(z,2);
        z=z(:,1:nElemX);
        warning('Number of elements in features and neural data are not the same.')
    end
    
    nSamples=size(x,2);
else
    if obj.decoderParams.diffX
        x=obj.position2state(x);
    end
    nSamples=size(x,2);
    
end

if isempty(trainINDXS)
    trainINDXS=1:size(x,2);
end

% save params
decoderTMP.decoderParams=obj.decoderParams;
decoderTMP.name=name;
decoderTMP.groupName=groupName;

% save training data
trainingData.rawX=x;
trainingData.rawZ=z;
trainingData.targ=targ;
trainingData.FrameID=FrameID;
trainingData.trainINDXS=trainINDXS;


% removeOutliers(obj)

% get statistics on training dataset, but only if this is the first time
% the object is trained.
if obj.decoderParams.updateSignalStatisticsOnTrain
    signalProps=obj.SignalStatistics(trainingData);
    decoderTMP.signalProps=signalProps;
end


% convert x & z into a form that will be used for training;
[x,z,~,decoderTMP]=obj.raw2model(x,z,[],decoderTMP);
trainingData.Z=z;
trainingData=PreprocessTrainingData(obj,trainingData);

obj.decoderParams.trainINDXS=trainingData.trainINDXS;
obj.decoderParams.speed=trainingData.sS;
decoderTMP.trainingData=trainingData;
popVecDispersion=obj.decoderParams.popVecDispersion;
%% Construct decoder
if length(obj.decoderParams.lags2Process)>1;
    obj.decoderParams.popVecDispersion=0;
    %     compute decoderProps at different lags to determine optimal lag
    % set up for testing multiple lags
    indx=0;
    fitType=decoderTMP.decoderParams.fitType;
    obj.decoderParams.fitType='crossValQuick'; % perform quick fits when processing at various lags
    
    
    for clag=decoderTMP.decoderParams.lags2Process
        indx=indx+1;
        obj.msgName(sprintf('Latency (%0.1f ms)',clag*decoderTMP.decoderParams.samplePeriod*1000),[1 1]);
        [trainingDataLag(indx)]=ShiftDataStruct(obj,trainingData,clag);
        
        PopVecTMP=ComputeTuningCurves(obj,trainingDataLag(indx),decoderTMP.signalProps);
        PopVecTMP.Lag=clag; PopVecLag(indx)=PopVecTMP;
        
        decoderTMPLag(indx).PopVec=PopVecLag(indx);
        decoderTMPLag(indx).trainingData=trainingDataLag(indx);
        decoderTMPLag(indx).decoderParams=decoderTMP.decoderParams;
        
        decoderTMPLag(indx).decoderProps=MakeDecoder(obj,decoderTMPLag(indx));
        
        [R2str]=R2STR(decoderTMPLag(indx));
        R2(indx,:)=decoderTMPLag(indx).decoderProps.R2;
        obj.msgName(sprintf('%s ',R2str))
    end
    
    if obj.decoderParams.nDOF~=1
        [val,optimalINDX]=max(mean(R2,2));
    else
        [val,optimalINDX]=max(R2);
    end
    clag=obj.decoderParams.lags2Process(optimalINDX);
    obj.msgName(sprintf('Optimal Latency (%0.1f ms) ',clag*obj.decoderParams.samplePeriod*1000),[1 1])
    
    %         Consolidate relevant stats
    PopVecLags=[decoderTMPLag.PopVec];
    LAGDATA.PopR2={PopVecLags.R2_CVmu};
    LAGDATA.PopH={PopVecLags.H};
    dcProps=[decoderTMPLag.decoderProps];
    LAGDATA.R2={dcProps.R2};
    LAGDATA.R2cv={dcProps.R2cv};
    LAGDATA.decodeFeatures={dcProps.decodeFeatures};
    LAGDATA.Bcf={dcProps.Bcf};
    
    decoderTMP.signalProps.LAGDATA=LAGDATA;
    
    obj.decoderParams.fitType=fitType;
    
else
    
    clag=obj.decoderParams.lags2Process;
    obj.msgName(sprintf('Specified Latency (%0.1f ms)   ',clag*obj.decoderParams.samplePeriod*1000))
end

if obj.decoderParams.asynchronous==1
    % combine tuningcurves across multiple lags
    PopVec=CombineAcrossLags(obj,PopVecLags,decoderTMP.signalProps);
else
    obj.decoderParams.popVecDispersion=popVecDispersion;
    trainingDataLag=ShiftDataStruct(obj,trainingData,clag);
    PopVec=ComputeTuningCurves(obj,trainingDataLag,decoderTMP.signalProps);
    PopVec.Lag=clag;
end

decoderTMP.PopVec=PopVec;
trainingData=decoderTMP.trainingData;
decoderTMP.trainingData=trainingDataLag;
decoderTMP.decoderProps=MakeDecoder(obj,decoderTMP);
decoderTMP.decoderProps.Lag=clag;

if obj.decoderParams.asynchronous==1
    R2str='Asynch fit - Fit R2 ill-defined';
else
    R2str=R2STR(decoderTMP);
end

obj.msgName(sprintf('%s ',R2str))

% set speed adaptive parameters
decoderTMP.SAF=[];
if obj.decoderParams.applySpeedAdaptiveFilter
    decoderTMP.SAF=SpeedAdaptiveFilter(obj.decoderParams.SAF, obj.decoderParams.samplePeriod,trainingData.sS);
end


% Set smoothing filter
decoderTMP.decoderProps.smoothingFilter=makeSmoothingFilter(obj,obj.decoderParams.modelSmoothOptions);


decoderTMP.runtimeParams=obj.runtimeParams;

% assign decoder
if isempty(obj.decoders)
    obj.decoders=decoderTMP; obj.currentDecoderINDX=1;
else
    obj.decoders(currentDecoderINDX)=decoderTMP;
    obj.currentDecoderINDX=currentDecoderINDX;
end

% plot fit
if isfield(obj.decoderParams,'plotFit') && obj.decoderParams.plotFit==0
    obj.decoders(currentDecoderINDX).trainingData=trainingData;
else
    recon=plotFitResults(obj,decoderTMP);
    obj.decoders(currentDecoderINDX).trainingData=trainingData;
    obj.decoders(currentDecoderINDX).trainingData.Recon=recon;
    obj.decoders(currentDecoderINDX).decoderProps.velocityBias=mean(recon(2:2:end,:),2);
end


% figure; plot(obj.decoderParams.lags2Process, R2L')
%% Test decoder

%% TRAIN elements

if isfield(obj.decoderParams,'saveTrainingData') && obj.decoderParams.saveTrainingData==0
    obj.decoders(currentDecoderINDX).trainingData=[];
else    
    fN=fieldnames(obj.decoders(currentDecoderINDX).trainingData);
    for i=1:length(fN)
        obj.decoders(currentDecoderINDX).trainingData.(fN{i})=single(obj.decoders(currentDecoderINDX).trainingData.(fN{i}));
    end    
end

if obj.frameworkParams.saveOnTrain
    saveDecoder(obj)
end

% update status
obj.isTrained=true;
%

if obj.guiParams.enableGUI
    decoderList = obj.listDecoders;
    handles = guihandles(obj.guiProps.handle);
    set(handles.popupDecoderSelect,'String',decoderList);
    set(handles.popupDecoderSelect,'Enable','on');
    set(handles.editDecoderName,'String',sprintf('Decoder-%0.2d',length(obj.decoders)));
    set(handles.editGain,'String',sprintf('[%s]',num2str(obj.runtimeParams.outputGain)))
end


if updateDecoder || isempty(prevDecoder) || prevDecoder==0
    obj.setDecoderINDX;
else
    obj.setDecoderINDX(prevDecoder);
end



function [R2str,R2]=R2STR(decoderTMP)

if isfield(decoderTMP.decoderProps,'R2cv')
    R2= decoderTMP.decoderProps.R2cv;
    
    R2s1=[sprintf('R2cv ( '), sprintf('%0.2f ',decoderTMP.decoderProps.R2cv),')'];
    R2s2=[sprintf('R2 ( '), sprintf('%0.2f ',decoderTMP.decoderProps.R2),')'];
    
    R2str=[R2s1 ' -- ' R2s2 ' :: ' ...
        sprintf('%d samples / %d Features',size(decoderTMP.trainingData.X,2),nnz(decoderTMP.PopVec.decodeFeatures)) ];
else
    R2= decoderTMP.decoderProps.R2;
    
    R2s1=[sprintf('R2 ( '), sprintf('%0.2f ',decoderTMP.decoderProps.R2),')'];
    R2str=[R2s1 ' :: ' ...
        sprintf('%d samples / %d Features',size(decoderTMP.trainingData.X,2),nnz(decoderTMP.PopVec.decodeFeatures))];
end