function [out]=ShiftDataStruct(obj,in,lag)

% shift x with respect to z without associating unknown values.
% anchor trainINDXs to the neural data.  If the neural data associated with
% the trainINDX is removed do to shifting, remove that trainINDX


out=in;
[out.X,out.Z,out.trainINDXS]=ShiftData(in.X,in.Z,in.trainINDXS,lag);
[out.sX,out.sZ]=ShiftData(in.sX,in.sZ,in.trainINDXS,lag);
[out.rawX,out.rawZ]=ShiftData(in.rawX,in.rawZ,in.trainINDXS,lag);

[out.S,~]=ShiftData(in.S,in.rawZ,in.trainINDXS,lag);
[out.sS,~]=ShiftData(in.sS,in.rawZ,in.trainINDXS,lag);



function [xlag,zlag,trainINDXs]=ShiftData(X,Z,trainINDXs,lag)

nSamples=size(X,2);
%     ys=circshift_NaN(y,[0,lag]);
if lag<0
    xlag=X(:,(abs(lag)+1):end);
    zlag=Z(:,1:size(xlag,2));
    trainINDXs(trainINDXs>size(xlag,2))=[];
elseif lag>0
    zlag=Z(:,(abs(lag)+1):end);
    xlag=X(:,1:size(zlag,2));
    
    
    trainINDXs=trainINDXs-abs(lag);
    trainINDXs(trainINDXs<1)=[];
    
else
    xlag=X;
    zlag=Z;
end
