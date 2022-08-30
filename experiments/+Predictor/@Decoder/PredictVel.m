function [nextX,nextIdealX]=PredictVel(obj,X,Z,goal,varargin)

% predict the current state given the previous state, the current neural
% data, and the Decoder structure.  Here we assume that curX and z_p are in
% the oringinal units (and not e.g. zero meaned) and we allow the Decode
% structure to perform necassary preprocessing.
cIDX=obj.currentDecoderINDX;

FrameID = nan;
if(nargin>=5)
    FrameID = varargin{1};
end

curZ=Z;
curX=X;
% inputs

% Handle Ideal Agent and Goals
if nargin<4 || isempty(goal); goal=curX(1:2:end)*nan; end

if obj.isTrained % convert to decoder coordinate system
    if obj.decoders(cIDX).decoderParams.adaptNeuralMean
        nS = (1-exp( -obj.decoderParams.samplePeriod/(obj.decoders(cIDX).decoderParams.adaptNeuralRate)));
        obj.decoders(cIDX).signalProps.meanZ = (1-nS)*obj.decoders(cIDX).signalProps.meanZ + nS*Z;
    end
end


if obj.decoders(cIDX).decoderParams.applySpeedAdaptiveFilter && ~ obj.DataBuffers.RecentState.isempty ;
    rawVel=obj.DataBuffers.RecentState.get(1);
    curX(2:2:end)=rawVel;
end


% delay when goal information is used for assist function
if obj.runtimeParams.movementDelay>0 && obj.DataBuffers.RecentGoal.numEntries>=obj.runtimeParams.movementDelay;
    assistGoal=obj.DataBuffers.RecentGoal.get(obj.runtimeParams.movementDelay);
    assistGoal=assistGoal(:,1);
else
    assistGoal=goal;
end
obj.DataBuffers.RecentGoal.add(goal);

if length(curX)~=(length(goal)*2)
    error('Number of dofs and number of goals must match')
else
    [nextIdealX,nextIdealForce]=obj.idealAgent.computeNextStep(curX,assistGoal);
end



%% Predict using neural data
if obj.isTrained
    
    [curX,curZ]=obj.raw2model(curX,curZ,[],obj.decoders(cIDX));
    obj.DataBuffers.RecentNeural.add(curZ);

    gain=obj.runtimeParams.outputGain(:);
    
    if any(strcmp(obj.decoders(cIDX).decoderParams.filterType,{'direct','inversion','kalmanfit'}))
        Filter=obj.decoders(cIDX).decoderParams.smoothingFilter;
        curZ=obj.ApplyFilter(Filter, obj.DataBuffers.RecentNeural.get);
         curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures,:);
%         Vel=obj.decoderProps.Ac(2:2:end,:)*curX+gain.*(obj.decoderProps.Bc(2:2:end,:)*[curZ;1]);
        Vel=gain.*(obj.decoders(cIDX).decoderProps.Bcf*[curZ;1]);
        
    elseif strcmp(obj.decoders(cIDX).decoderParams.filterType,{'sskalman'})
        curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures);
        Vel=obj.decoderProps.Ac(2:2:end,:)*curX+gain.*(obj.decoderProps.Bc(2:2:end,:)*[curZ;1]);
    elseif strcmp(obj.decoders(cIDX).decoderParams.filterType,'kalman')   && strcmp(obj.decoders(cIDX).decoderParams.TuningFeatures,'dx')
        curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures);
        Vel=gain.*kalmanStep(obj,curX(2:2:end)./gain,curZ,obj.decoders(cIDX));        
    elseif strcmp(obj.decoders(cIDX).decoderParams.filterType,'kalman')   && strcmp(obj.decoders(cIDX).decoderParams.TuningFeatures,'xdx')
        curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures);
        curX(2:2:end)=curX(2:2:end)./gain;
        tmp=kalmanStep(obj,curX,curZ);
        Vel=gain.*tmp(2:2:end);
    end

else
    Vel=curX(2:2:end);
end


% assist estimate
VelNeural=Vel;
Vel=obj.Assist(Vel,nextIdealX(2:2:end)); % assist


obj.DataBuffers.RecentState.add(Vel);
if obj.decoders(cIDX).decoderParams.applySpeedAdaptiveFilter; % apply speed adaptive smoothing
    RecentVels=obj.DataBuffers.RecentState.get(20);
    Vel=SAF(obj,RecentVels,1);
end




% integrate velocity into position - for assisted signal
intX=curX;
intX(2:2:end)=Vel;
nextX=obj.runtimeParams.pIntegrator*intX; 

if obj.runtimeParams.assistLevel~=0;
    intX=curX;
    intX(2:2:end)=VelNeural;
    neuralX=obj.runtimeParams.pIntegrator*intX; 
else
    neuralX=nextX;
end

nextX=applyConstraints(obj,nextX);
neuralX=applyConstraints(obj,neuralX);

% if obj.isTrained
% nextX=obj.model2raw(nextX);
% end
% plot
if obj.runtimeParams.plotCursor
    plotCursor(obj,neuralX,nextIdealX,goal,curZ)
end



if obj.BufferData
    obj.DataBuffers.Goal.add(goal);
    obj.DataBuffers.IdealPrediction.add(nextIdealX);
    obj.DataBuffers.IdealForce.add(nextIdealForce);
    obj.DataBuffers.NeuralData.add(Z);
    obj.DataBuffers.NeuralPrediction.add(neuralX); % perhaps add this
    obj.DataBuffers.FrameID.add(FrameID);
    obj.DataBuffers.AssistedPrediction.add(nextX);
end

%% Assist



%
% if obj.BufferData
%     obj.DataBuffers.AssistedPrediction.add(nextX);
% end

% %% Adhoc smoothing
% if isfield(obj.options,'adhoc_smooth') && ~isempty(obj.options.adhoc_smooth)
%     nextX=(obj.options.adhoc_smooth)*nextX+(1-obj.options.adhoc_smooth)*curX;
% end

%  Buffers .IdealPrediction .NeuralPrediction .NeuralData .Kinematic .Goal



