function [nextX,nextIdealX]=PredictExp(obj,X,Z,goal,varargin)

% predict the current state given the previous state, the current neural
% data, and the Decoder structure.  Here we assume that curX and z_p are in
% the oringinal units (and not e.g. zero meaned) and we allow the Decode
% structure to perform necassary preprocessing.

FrameID = nan;
if(nargin>=5)
    FrameID = varargin{1};
end

<<<<<<< .mine
[X,Z,goal]=obj.raw2model(X,Z,goal);
=======
if obj.isTrained
    [X,Z,goal]=obj.raw2model(X,Z,goal);
end
>>>>>>> .r1033

curZ=Z;

% if we are applying the speed adaptive filter, we want to use the version
% of the state that has not been modified by the speed adaptive filter as
% the state that gets propagated.
if obj.decoderParams.applySpeedAdaptiveFilter && ~ obj.DataBuffers.RecentState.isempty ;
    rawVel=obj.DataBuffers.RecentState.get(1);
    curX=X;
    curX(2:2:end)=rawVel;
else
    curX=X;
end


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

% velocityOffset=zeros(obj.decoderParams.nDOF*2,1);
% velocityOffset(1:2:obj.decoderParams.nDOF*2)=obj.runtimeParams.velocityOffset(:);
% apply high pass filter via updating of baseline firing rate.

%% Predict using neural data
if obj.isTrained
    
    
    if obj.runtimeParams.adaptNeuralMean
        nS = (1-exp( -obj.decoderParams.samplePeriod/(obj.runtimeParams.adaptNeuralRate)));
        obj.signalProps.meanZ = obj.signalProps.meanZ + (Z-obj.signalProps.meanZ)*nS;
    end
    
    
    curZ=curZ(obj.decoderProps.decodeFeatures);
    
    
    switch lower(obj.decoderParams.filterType)
        case {'kalman','direct'}
            curZ=[curZ;1];
            if 1==1
                
                nextX=curX*0;
                Vel=obj.decoderProps.Ac(2:2:end,:)*curX+outputGain(2:2:end).*((obj.decoderProps.Bc(2:2:end,:))*curZ);
                
                Vel=obj.Assist(Vel,nextIdealX(2:2:end));
                
                
                % keep a record of the recent state estimates
                obj.DataBuffers.RecentState.add(Vel);
                if obj.decoderParams.applySpeedAdaptiveFilter; % apply speed adaptive smoothing
                    RecentVels=obj.DataBuffers.RecentState.get();
                    for indx=1:length(Vel);
                        Vel(indx)=Kinematics.SpeedAdaptiveFilter(RecentVels(indx,:),obj.decoderParams.samplePeriod,1);
                    end
                end
                
                curX(2:2:end)=Vel;
                Pos=obj.decoderProps.Ac(1:2:end,:)*curX;
                
                nextX(1:2:end)=Pos;
                nextX(2:2:end)=Vel;
            else % old way of handling things.
                % note, posityion is formed with current position estimate
                % and previous velocity estimate.
                nextX=obj.decoderProps.Ac*curX+outputGain.*(obj.decoderProps.Bc*curZ);
            end
            
        case 'kalmanb'
            if strcmp(obj.decoderParams.TuningFeatures,'dx')
                Vel=obj.kalmanStep(curX(2:2:end),curZ)-.05*curX(1:2:end);
            else
                error('unsupported fit type for kalman')
            end
            
            % keep a record of the recent state estimates
            obj.DataBuffers.RecentState.add(Vel);
            if obj.decoderParams.applySpeedAdaptiveFilter; % apply speed adaptive smoothing
                RecentVels=obj.DataBuffers.RecentState.get();
                for indx=1:length(Vel);
                    Vel(indx)=Kinematics.SpeedAdaptiveFilter(RecentVels(indx,:),obj.decoderParams.samplePeriod,1);
                end
            end
            
            nextX=curX;
            nextX(2:2:end)=Vel;
            nextX(1:2:end)=obj.decoderProps.Ap*curX;
            
    end
    
else
    nextX = curX*0;
    Vel=obj.Assist(curX(2:2:end),nextIdealX(2:2:end));
    curX(2:2:end)=Vel;
    Pos=[1 0.05 0 0 ; 0 0 1 0.05]*curX;
    nextX(1:2:end)=Pos;
    nextX(2:2:end)=Vel;
end

if obj.isTrained
nextX=obj.model2raw(nextX);
<<<<<<< .mine
nextIdealX=obj.model2raw(nextIdealX);
goal=obj.model2raw(goal);

=======
end
>>>>>>> .r1033
% post processing
nextX=max([outputMin nextX],[],2);
nextX=min([outputMax nextX],[],2);

if obj.BufferData
    obj.DataBuffers.Goal.add(goal);
    obj.DataBuffers.IdealPrediction.add(nextIdealX);
    obj.DataBuffers.IdealForce.add(nextIdealForce);
    obj.DataBuffers.NeuralData.add(Z);
    obj.DataBuffers.NeuralPrediction.add(nextX);
    obj.DataBuffers.FrameID.add(FrameID);
end

%% Assist

% nextX=obj.Assist(nextX,nextIdealX);


%
% if obj.BufferData
%     obj.DataBuffers.AssistedPrediction.add(nextX);
% end

% %% Adhoc smoothing
% if isfield(obj.options,'adhoc_smooth') && ~isempty(obj.options.adhoc_smooth)
%     nextX=(obj.options.adhoc_smooth)*nextX+(1-obj.options.adhoc_smooth)*curX;
% end

%  Buffers .IdealPrediction .NeuralPrediction .NeuralData .Kinematic .Goal



