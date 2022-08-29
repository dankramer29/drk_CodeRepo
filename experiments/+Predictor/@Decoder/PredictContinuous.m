function [nextX,nextIdealX]=PredictContinuous(obj,varargin)

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
if obj.runtimeParams.trialTimer<obj.runtimeParams.reactionTimeDelay
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
    
    
    if isfield(obj.frameworkParams,'useSingleUnit') && obj.frameworkParams.useSingleUnit==1;
        [Vel,iV]=estimateSUVel(obj,curZ,curX);    
    else
        curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures);
        [Vel,iV]=estimateVel(obj,curZ,curX);
    end
    % add instantaneous estimate to buffer.
    obj.DataBuffers.RecentState.add(iV);
    
%     if obj.decoders(cIDX).runtimeParams.removeVelocityBias
%        Vel=Vel-obj.decoders(cIDX).decoderProps.velocityBias; 
%     end
       VelNeural=Vel; 

    
else
    Vel=curX(2:2:end)*0;
    VelNeural=Vel*0;
end


% Do not apply the assistance if ReachObstacle task and effector has
% collided with obstacle
if  strcmp(obj.hFramework.options.runName,'ReachObstacles') && obj.hFramework.hTask.frameId <= obj.hFramework.hTask.params.user.frameLimit
    if strcmp(obj.hFramework.hTask.hTrial.TrialData.tr_type,'blocked') && obj.hFramework.hTask.hObstacle{1}.collided
        Vel=obj.Assist(Vel,nextIdealX(2:2:end),obj.runtimeParams.assistType,0); % assist
    else
        % assist estimate
        Vel=obj.Assist(Vel,nextIdealX(2:2:end),obj.runtimeParams.assistType,obj.runtimeParams.assistLevel); % assist
    end
else
     % assist estimate
    Vel=obj.Assist(Vel,nextIdealX(2:2:end),obj.runtimeParams.assistType,obj.runtimeParams.assistLevel); % assist
end

% apply secondary assistance
if obj.runtimeParams.secondaryAssist.apply && obj.runtimeParams.trialTimer > obj.runtimeParams.secondaryAssist.waitPeriod
    Vel=obj.Assist(Vel,nextIdealX(2:2:end),'WeightedAverage',obj.runtimeParams.secondaryAssist.assistValue); % assist
    obj.runtimeParams.secondaryAssist.assistValue=obj.runtimeParams.secondaryAssist.assistValue+obj.runtimeParams.secondaryAssist.assistIncrement;
    obj.runtimeParams.secondaryAssist.assistValue=min([obj.runtimeParams.secondaryAssist.assistValue 1]);
end


% USe This :
if obj.runtimeParams.trialTimer<obj.runtimeParams.movementDelay
%     Vel=obj.Assist(Vel,nextIdealX(2:2:end)*0,'WeightedAverage',1); % assist
    Vel=Vel*0;
end

% adapt assistance level.
if obj.isTrained && obj.runtimeParams.adaptAssistanceLevel
    adaptAssistance(obj,Vel,nextIdealX(2:2:end),FrameID)
end



% integrate velocity into position - for assisted signal
if isfield(obj.frameworkParams,'enableDecoder') && obj.frameworkParams.enableDecoder==0
    Vel=Vel*0;
end


persistent noiseTerm
if isempty(noiseTerm); noiseTerm=0; end
% So noise term is not added in rancho tasks which use EndPoint control
if ~strcmpi(obj.name,'rancho') 
    alpha=.5;
    noiseTerm=alpha*noiseTerm+(1-alpha)*randn*.2;
end
noiseTerm=0;
Vel=Vel+noiseTerm;
intX=curX;
% Vel=[Vel-0.9];
intX(2:2:end)=Vel;
nextX=obj.runtimeParams.pIntegrator*intX;
% nextX=integrateWithConstraints(obj,curX,Vel);

intXNeural=curX;
intXNeural(2:2:end)=VelNeural;
neuralX=obj.runtimeParams.pIntegrator*intXNeural;
% neuralX=integrateWithConstraints(obj,curX,VelNeural);


nextX=applyConstraints(obj,nextX);
neuralX=applyConstraints(obj,neuralX);

if obj.runtimeParams.plotCursor
    if obj.isTrained
        zSmooth=obj.DataBuffers.RecentNeural.get;
        zSmooth=zSmooth(obj.decoders(cIDX).decoderProps.decodeFeatures,:);
%         Filter=obj.decoders(cIDX).decoderProps.smoothingFilter;
        Filter=Kinematics.MinJerkKernel(1350,50,1);
        zSmooth=obj.ApplyFilter(Filter, zSmooth)*5;
        IA=nextIdealX;
        IA(1:2:end)=intXNeural(1:2:end);
        plotCursor(obj,intXNeural,IA,goal,zSmooth)
    else
        IA=nextIdealX;
        IA(1:2:end)=intXNeural(1:2:end);
        plotCursor(obj,intXNeural,IA,goal)
    end
end




% [x,y]=GetMouse;
% x=x-1920;
% x=x/1920*2-1;
% y=-(y/1080*2-1);
% 
% nextX(1:2:end)=[x,y]*.6;
% nextX(2:2:end)=0;


% if obj.isTrained
% nextX=obj.model2raw(nextX);
% end


% if isfield(obj.runtimeParams,plotResiduals) && obj.runtimeParams.plotResiduals
%     plotResiduals(obj,neuralX,nextIdealX,goal,curZ)
% end

if obj.BufferData
    obj.DataBuffers.Goal.add(goal);
    
    obj.DataBuffers.IdealPrediction.add(nextIdealX);
    obj.DataBuffers.NeuralPrediction.add(neuralX); 
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

