function nextX=integrateWithConstraints(obj,curX,Vel)

% integrates velocity 
% if resulting position falls outside circle, use previous position.
intX=curX;
intX(2:2:end)=Vel;
nextX=obj.runtimeParams.pIntegrator*intX(1:2);

effectorRadius=Utilities.mnorm(nextX(1:2:end)');
c1Radius=abs(max(obj.runtimeParams.outputMin(:)));
c2Radius=abs(min(obj.runtimeParams.outputMax(:)));

% if length(curX(1:2:end)) ~= length(nextX(1:2:end))
%     keyboard;
% end
if (effectorRadius > c1Radius) || (effectorRadius > c2Radius)
%     nextX(1:2:end)=curX(1:2:end);
    nextX = curX;
end