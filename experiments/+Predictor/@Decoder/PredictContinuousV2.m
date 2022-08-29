function [nextX,nextIdealX]=PredictContinuousV2(obj,varargin)

% predict the current state given the previous state, the current neural
% data, and the Decoder structure.  Here we assume that curX and z_p are in
% the oringinal units (and not e.g. zero meaned) and we allow the Decode
% structure to perform necassary preprocessing.

Arguements=varargin{:};

% Parse Inputs
Xin=Arguements{1};
Zin=Arguements{2};

curZ=Zin; curX=Xin;
if length(Arguements)<3 || isempty(Arguements{3}); 
    goal=curX(1:2:end)*nan; 
else
    goal=Arguements{3};    
end

if length(Arguements)<4 || isempty(Arguements{4}); 
   FrameID = nan;
else
    FrameID =Arguements{4};    
end




cIDX=obj.currentDecoderINDX;
if isempty(cIDX) &&  length(obj.decoders)>=1;
    obj.currentDecoderINDX=1;
    cIDX=1;
end


% Update Estimate of Mean For Adaptive Mean
if obj.isTrained && obj.decoders(cIDX).decoderParams.adaptNeuralMean
    nS = (1-exp( -obj.decoderParams.samplePeriod/(obj.decoders(cIDX).decoderParams.adaptNeuralRate)));
    obj.decoders(cIDX).signalProps.meanZ = (1-nS)*obj.decoders(cIDX).signalProps.meanZ + nS*Zin;
end


% Track trial duration.
if isequal(goal,obj.DataBuffers.RecentGoal.get(1)) && ~any(isnan(goal));
    obj.runtimeParams.trialTimer= obj.runtimeParams.trialTimer+1;
else
    obj.runtimeParams.trialTimer=1;
    obj.runtimeParams.secondaryAssist.assistValue=0; 
end

% if trialTime less than movement , do not propagate goal to ideal agent
if obj.runtimeParams.trialTimer<obj.runtimeParams.movementDelay
    assistGoal=goal*nan;
else
    assistGoal=goal;
end


% Ideal Agent Response
[nextIdealX,nextIdealForce]=obj.idealAgent.computeNextStep(curX,assistGoal);


% Store Info
obj.DataBuffers.RecentGoal.add(goal);


%% Predict using neural data
if obj.isTrained
    
    [curX,curZ]=obj.raw2model(curX,curZ,[],obj.decoders(cIDX));
    obj.DataBuffers.RecentNeural.add(curZ);
    curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures);
    
    [Vel,iV]=estimateif strcmp(obj.Params.TimeCollapseMethod,'BlockMean')
     NumBins=obj.Params.NumBins;
    if obj.verbosity<=1
        fprintf('Pruning Time Bins to %d:(end-1) \n',NumBins)
    end
   
    
    if iscell(NeuralData)
        % Each Cell is an observation.  Within Each cell, Matrix (nFeatures x NTimePoints)
        
        for i=1:length(NeuralData)
            MeanNeuralData(:,i)=mean(NeuralData{i}(:,end-NumBins+1:end)./obj.Params.binSizeInSecs,2);
        end
    else
        MeanNeuralData=mean(NeuralData(:,end-NumBins+1:end)./obj.Params.binSizeInSecs,2);
    end
    Vel(obj,curZ,curX);
    
    % add instantaneous estimate to buffer.
    obj.DataBuffers.RecentState.add(iV);
    
    if obj.decoders(cIDX).runtimeParams.removeVelocityBias
       Vel=Vel-obj.decoders(cIDX).decoderProps.velocityBias; 
    end
     
else
    iV=curX(2:2:end)*0;
    Vel=curX(2:2:end)*0;
end

if isfield(obj.frameworkParams,'enableDecoder') && obj.frameworkParams.enableDecoder==0
    Vel=Vel*0;
end


% integrate velocity into position - for assisted signal
for kk=1:obj.decodeParams.nDOF
    obj.runtimeParams.pIntegrator(2*kk,2*kk)=.75;
end %obj.runtimeParams.pIntegrator(4,4)=.75;
force=obj.runtimeParams.outputGain(:).*iV;
nextX=obj.runtimeParams.pIntegrator*curX+[0;force(1);0;force(2)];

intX=nextX;


% assist estimate
nextX(2:2:end)=obj.Assist(nextX(2:2:end),nextIdealX(2:2:end),obj.runtimeParams.assistType,obj.runtimeParams.assistLevel); % assist

% Pos Corr
% nextX(1:2:end)=obj.Assist(nextX(1:2:end)-curX(1:2:end),nextIdealX(1:2:end),obj.runtimeParams.assistType,obj.runtimeParams.assistLevel); % assist


if obj.runtimeParams.plotCursor
    if obj.isTrained
        zSmooth=obj.DataBuffers.RecentNeural.get;
        zSmooth=zSmooth(obj.decoders(cIDX).decoderProps.decodeFeatures,:);
        Filter=obj.decoders(cIDX).decoderProps.smoothingFilter;
        zSmooth=obj.ApplyFilter(Filter, zSmooth);
        IA=nextIdealX;
        IA(1:2:end)=intX(1:2:end);
        plotCursor(obj,intX,IA,goal,zSmooth)
    else
        IA=nextIdealX;
        IA(1:2:end)=intX(1:2:end);
        plotCursor(obj,intX,IA,goal)
    end
end


nextX=applyConstraints(obj,nextX);

% if obj.isTrained
% nextX=obj.model2raw(nextX);
% end

% plot


% if isfield(obj.runtimeParams,plotResiduals) && obj.runtimeParams.plotResiduals
%     plotResiduals(obj,neuralX,nextIdealX,goal,curZ)
% end

if obj.BufferData
    obj.DataBuffers.Goal.add(goal);
    
    obj.DataBuffers.IdealPrediction.add(nextIdealX);
    obj.DataBuffers.AssistedPrediction.add(nextX);
    obj.DataBuffers.IdealForce.add(nextIdealForce);
    obj.DataBuffers.Kinematics.add(Xin) 
    
    obj.DataBuffers.NeuralData.add(Zin);
    obj.DataBuffers.FrameID.add(FrameID);
    
end

% %% Adhoc smoothing
% if isfield(obj.options,'adhoc_smooth') && ~isempty(obj.options.adhoc_smooth)
%     nextX=(obj.options.adhoc_smooth)*nextX+(1-obj.options.adhoc_smooth)*curX;
% end

