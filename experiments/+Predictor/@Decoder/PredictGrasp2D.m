function [nextX,nextIdealX]=PredictGrasp2D(obj,varargin)

% predict the current state given the previous state, the current neural
% data, and the Decoder structure.  Here we assume that curX and z_p are in
% the oringinal units (and not e.g. zero meaned) and we allow the Decode
% structure to perform necassary preprocessing.

Arguements=varargin{:};

% Parse Inputs
Xin=Arguements{1};
Zin=Arguements{2};
Zin=Zin(1:192); % only use neural features

curZ=Zin; curX=Xin;

cIDX=obj.currentDecoderINDX;
if isempty(cIDX) &&  length(obj.decoders)>=1;
    obj.currentDecoderINDX=1;
    cIDX=1;
end


% Update Estimate of Mean For Adaptive Mean
% if obj.isTrained && obj.decoders(cIDX).decoderParams.adaptNeuralMean
%     nS = (1-exp( -obj.decoderParams.samplePeriod/(obj.decoders(cIDX).decoderParams.adaptNeuralRate)));
%     obj.decoders(cIDX).signalProps.meanZ = (1-nS)*obj.decoders(cIDX).signalProps.meanZ + nS*Zin;
% end
% 

% % Track trial duration.
% if isequal(goal,obj.DataBuffers.RecentGoal.get(1)) && ~any(isnan(goal));
%     obj.runtimeParams.trialTimer= obj.runtimeParams.trialTimer+1;
% else
%     obj.runtimeParams.trialTimer=1;
%     obj.runtimeParams.secondaryAssist.assistValue=0;
% end
% 
% % if trialTime less than movement , do not propagate goal to ideal agent
% if obj.runtimeParams.trialTimer<obj.runtimeParams.movementDelay
%     assistGoal=goal*nan;
% else
%     assistGoal=goal;
% end


% Ideal Agent Response
% [nextIdealX,nextIdealForce]=obj.idealAgent.computeNextStep(curX,assistGoal);


% Store Info
% obj.DataBuffers.RecentGoal.add(goal);


%% Predict using neural data
if obj.isTrained
    
    [curX,curZ]=obj.raw2model(curX,curZ,[],obj.decoders(cIDX));
    obj.DataBuffers.RecentNeural.add(curZ);
    curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures);
    
    [Vel,iV]=estimateVel(obj,curZ,curX);
    
    % add instantaneous estimate to buffer.
    obj.DataBuffers.RecentState.add(iV);    
            
else
    Vel=curX(2:2:end)*0;    
end



% integrate velocity into position - for assisted signal
if isfield(obj.frameworkParams,'enableDecoder') && obj.frameworkParams.enableDecoder==0
    Vel=Vel*0;
end

% Logic on state Transitions

%%
% curX=[1 0 1 0]';
% curX(2:2:end)=[0;1];
% Vel=[1 0];
% VelTresh=[.7 .2];

curWeight=curX(2:2:end);
VelTresh=obj.decoders(cIDX).decoderProps.VelTresh;



threshLogic=[Vel>VelTresh];

% fprintf('weightStart - [%d %d]\n',curWeight)
% fprintf('threshLogic - [%d %d]\n',threshLogic)

if all(threshLogic) || all(~threshLogic)
    % If both high or both low, don't do anything.
elseif threshLogic(1) & ~curWeight(1)
    curWeight(1)=1;
    curWeight(2)=0;
    
elseif threshLogic(2) & ~curWeight(2)
    curWeight(1)=0;
    curWeight(2)=1;
    
end

% fprintf('weightEND   - [%d %d]\n',curWeight)
% fprintf('-- \n')



nextX=curX;
nextX(1:2:end)=Vel;
nextX(2:2:end)=curWeight;

nextIdealX=nextX;
%%
% if obj.BufferData
%     obj.DataBuffers.Goal.add(goal);
%
%     obj.DataBuffers.IdealPrediction.add(nextIdealX);
%     obj.DataBuffers.NeuralPrediction.add(neuralX);
%     obj.DataBuffers.AssistedPrediction.add(nextX);
%     obj.DataBuffers.IdealForce.add(nextIdealForce);
%     obj.DataBuffers.Kinematics.add(Xin)
%
%     obj.DataBuffers.NeuralData.add(Zin);
%     obj.DataBuffers.FrameID.add(FrameID);
%
% end



