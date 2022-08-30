function [nextX,nextIdealX]=PredictVelV2(obj,Xin,Zin,goal,varargin)

% predict the current state given the previous state, the current neural
% data, and the Decoder structure.  Here we assume that curX and z_p are in
% the oringinal units (and not e.g. zero meaned) and we allow the Decode
% structure to perform necassary preprocessing.

% Parse Inputs
curZ=Zin; curX=Xin;
if nargin<4 || isempty(goal); goal=curX(1:2:end)*nan; end
FrameID = nan; if(nargin>=5), FrameID = varargin{1}; end


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



% delay when goal information is used for assist function
if obj.runtimeParams.movementDelay>0 && obj.DataBuffers.RecentGoal.numEntries>=obj.runtimeParams.movementDelay;
    assistGoal=obj.DataBuffers.RecentGoal.get(obj.runtimeParams.movementDelay);
    assistGoal=assistGoal(:,1);
    if ~isequal(assistGoal,goal)
        assistGoal=assistGoal*nan; %during reactiontime, assume no well-defined goal.
    end
else
    assistGoal=goal;
end


% Ideal Agent Response
if length(curX)~=(length(goal)*2)
    error('Number of dofs and number of goals must match')
else    
    [nextIdealX,nextIdealForce]=obj.idealAgent.computeNextStep(curX,assistGoal);
end

% Store Info
obj.DataBuffers.RecentGoal.add(goal);


%% Predict using neural data
if obj.isTrained
    
    [curX,curZ]=obj.raw2model(curX,curZ,[],obj.decoders(cIDX));
    obj.DataBuffers.RecentNeural.add(curZ);
    curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures);
    
    [Vel,iV]=estimateVel(obj,curZ,curX(1:2:end));
    % add instantaneous estimate to buffer.
    obj.DataBuffers.RecentState.add(iV);
    VelNeural=Vel;
else
    Vel=curX(2:2:end);
    VelNeural=Vel*0;
end


% assist estimate
Vel=obj.Assist(Vel,nextIdealX(2:2:end)); % assist

% adapt assistance level.
if obj.isTrained && obj.runtimeParams.adaptAssistanceLevel
    adaptAssistance(obj,Vel,nextIdealX(2:2:end),FrameID)
end



% integrate velocity into position - for assisted signal
if isfield(obj.frameworkParams,'enableDecoder') && obj.frameworkParams.enableDecoder==0
    Vel=Vel*0;
end



intX=curX;
intX(2:2:end)=Vel;
nextX=obj.runtimeParams.pIntegrator*intX;

intX=curX;
intX(2:2:end)=VelNeural;
neuralX=obj.runtimeParams.pIntegrator*intX;

if obj.runtimeParams.plotCursor
    if obj.isTrained
        zSmooth=obj.DataBuffers.RecentNeural.get;
        zSmooth=zSmooth(obj.decoders(cIDX).decoderProps.decodeFeatures,:);
        Filter=obj.decoders(cIDX).decoderProps.smoothingFilter;
        zSmooth=obj.ApplyFilter(Filter, zSmooth);
        plotCursor(obj,intX,IA,goal,zSmooth)
    else
        IA=nextIdealX;
        IA(1:2:end)=intX(1:2:end);
        plotCursor(obj,intX,IA,goal)
    end
end


nextX=applyConstraints(obj,nextX);
neuralX=applyConstraints(obj,neuralX);

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

