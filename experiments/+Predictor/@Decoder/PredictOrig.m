function [nextX,nextIdealX]=PredictOrig(obj,X,Z,goal,varargin)

% predict the current state given the previous state, the current neural
% data, and the Decoder structure.  Here we assume that curX and z_p are in
% the oringinal units (and not e.g. zero meaned) and we allow the Decode
% structure to perform necassary preprocessing.

FrameID = nan;
if(nargin>=5)
    FrameID = varargin{1};
end

curZ=Z;
curX=X;
% inputs
% curX    % previous state
% curZ    % current observation

% Handle Ideal Agent and Goals
if nargin<4 || isempty(goal);
    goal=curX(1:2:end)*nan;
end


if length(curX)~=(length(goal)*2)
    error('Number of dofs and number of goals must match')
else
    [nextIdealX,nextIdealForce]=obj.idealAgent.computeNextStep(curX,goal);
end

outputGain=ones(obj.decoderParams.nDOF*2,1);
outputGain(2:2:obj.decoderParams.nDOF*2)=obj.runtimeParams.outputGain(:);

outputMin=-inf*ones(obj.decoderParams.nDOF*2,1);
outputMin(1:2:obj.decoderParams.nDOF*2)=obj.runtimeParams.outputMin(:);

outputMax=inf*ones(obj.decoderParams.nDOF*2,1);
outputMax(1:2:obj.decoderParams.nDOF*2)=obj.runtimeParams.outputMax(:);

%% Predict using neural data
if obj.isTrained
    [curX,curZ]=obj.raw2model(curX,curZ);
    
    curZ=curZ(obj.decoderProps.decodeFeatures);

    
    if any(strcmp(obj.decoderParams.filterType,{'kalman','direct'}))
        nextX=obj.decoderProps.Ac*curX+outputGain.*(obj.decoderProps.Bc*[curZ;1]);
    elseif strcmp(obj.decoderParams.filterType,'kalmanb')   && strcmp(obj.decoderParams.TuningFeatures,'dx')
        Vel=kalmanStep(obj,curX(2:2:end),curZ);
        
        nextX=curX;
        nextX(2:2:end)=Vel;
        nextX(1:2:end)=obj.decoderProps.Ap*curX;
        
        
    elseif strcmp(obj.decoderParams.filterType,'kalmanb')   && strcmp(obj.decoderParams.TuningFeatures,'xdx')
       nextX=kalmanStep(obj,curX,curZ);
    end
    
    nextX=obj.model2raw(nextX);
    
    % post processing
    nextX=max([outputMin nextX],[],2);
    nextX=min([outputMax nextX],[],2);
    
    % % update estimates of neural mean and average velocity for possible
    % % use
    % nV=obj.runtimeParams.adaptVelocityRate*60/obj.decoderParams.samplePeriod/3;
    % muVel=obj.decoderParams.velocityOffset;
    % obj.decoderParams.velocityOffset= muVel + (nextX(2:2:end)-muVel)/nV;
    
    % update estimate of firing rate
    nS = (1-exp( -obj.decoderParams.samplePeriod/(obj.runtimeParams.adaptNeuralRate*60)));
    obj.signalProps.meanZ = obj.signalProps.meanZ;% + (Z-muNeur)*nS;
    
    % % subtract
    % if obj.decoderParams.adaptVelocityOffset
    %     nextX=nextX-velocityOffset;
    % end
    
else
    nextX = curX;
end

if obj.BufferData
    obj.DataBuffers.Goal.add(goal);
    obj.DataBuffers.IdealPrediction.add(nextIdealX);
    obj.DataBuffers.IdealForce.add(nextIdealForce);
    obj.DataBuffers.NeuralData.add(Z);
    obj.DataBuffers.NeuralPrediction.add(nextX);
    obj.DataBuffers.FrameID.add(FrameID);
end

%% Assist

if obj.runtimeParams.plotCursor
    plotCursor(obj,nextX,nextIdealX,goal)
end

nextX=obj.Assist(nextX,nextIdealX);

%
% if obj.BufferData
%     obj.DataBuffers.AssistedPrediction.add(nextX);
% end

% %% Adhoc smoothing
% if isfield(obj.options,'adhoc_smooth') && ~isempty(obj.options.adhoc_smooth)
%     nextX=(obj.options.adhoc_smooth)*nextX+(1-obj.options.adhoc_smooth)*curX;
% end

%  Buffers .IdealPrediction .NeuralPrediction .NeuralData .Kinematic .Goal



