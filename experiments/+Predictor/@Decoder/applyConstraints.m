function X=applyConstraints(obj,X)


X(1:2:end)=max([obj.runtimeParams.outputMin(:) X(1:2:end)],[],2);
X(1:2:end)=min([obj.runtimeParams.outputMax(:) X(1:2:end)],[],2);
    