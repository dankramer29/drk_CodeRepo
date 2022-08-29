function targetPosition=setSUfeature(obj,SUfeatINDX)

obj.msgName(sprintf('Setting SUfeatINDX to %d',SUfeatINDX))




%
cIDX = obj.currentDecoderINDX;
H=obj.decoders(cIDX).PopVec.H(:,1:obj.decoderParams.nDOF);

weight=obj.decoderParams.SingUnitControl.targetDistance/...
    obj.decoderParams.SingUnitControl.desiredDuration;
BcfS=weight*(H'./repmat(Utilities.mnorm(H)',size(H,2),1));
obj.decoders(cIDX).PopVec.BcfS=BcfS;

% set the feature to use internal to the decoder.
obj.frameworkParams.SUfeatINDX=SUfeatINDX;

%determine target location
cIDX=obj.currentDecoderINDX;
vec=obj.decoders(cIDX).PopVec.BcfS(:,SUfeatINDX);
vecNorm=vec/norm(vec);
targetPosition=vecNorm*obj.decoderParams.SingUnitControl.targetDistance;
obj.frameworkParams.SUtargPos=targetPosition;

% Set the Target Position


% % % % % %
% % % % % % THIS WAS IN THE REPOSITORY ROOT DIRECTORY...
% % % % % %
% % % % % % function targetPosition=setSUfeature(obj,SUfeatINDX)
% % % % % % 
% % % % % % obj.msgName(sprintf('Setting SUfeatINDX to %d',SUfeatINDX))
% % % % % % % set the feature to use internal to the decoder.
% % % % % % obj.frameworkParams.SUfeatINDX=SUfeatINDX;
% % % % % % 
% % % % % % 
% % % % % % %determine target location
% % % % % % cIDX=obj.currentDecoderINDX;
% % % % % % vec=obj.decoders(cIDX).PopVec.BcfS(:,SUfeatINDX);
% % % % % % vecNorm=vec/norm(vec);
% % % % % % targetPosition=vecNorm*obj.decoderParams.SingUnitControl.targetDistance;
% % % % % % % obj.frameworkParams.SUtargPos=targetPosition;
% % % % % % 
% % % % % % % Set the Target Position
% % % % % %