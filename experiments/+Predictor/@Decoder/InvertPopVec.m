function [Bcf,CC,cv]=InvertPopVec(obj,decoderTMP,varargin)


cv=[];
PopVec=[];
%% set defaults for varargin
PlotFit=0;
inputArguements=varargin;
trainINDXS=obj.decoderParams.trainINDXS;

while ~isempty(inputArguements)
    switch lower(inputArguements{1})
        case lower('PlotFit')
            PlotFit=inputArguements{2};
            inputArguements(1:2)=[];                
        otherwise
            error('Input %s is not a valid arguement, try again ',inputArguements{1})
    end
end


sZ= decoderTMP.trainingData.sZ;
sX= decoderTMP.trainingData.sX;
trainINDXS=decoderTMP.trainingData.trainINDXS;
decodeFeatures = decoderTMP.PopVec.decodeFeatures;


% load PV
Q=decoderTMP.PopVec.Q;
Q=Q(decodeFeatures,decodeFeatures);

H=decoderTMP.PopVec.H;
H=H(decodeFeatures,:);

[Bcf,CC]=InvertPopVecHELPER(obj,H,Q,sX,sZ);
R2=(CC.^2)';



function [Bcvf,CC]=InvertPopVecHELPER(obj,Hcvf,Q,sX,sZ);

useaddage=1;
if useaddage
    H(:,end)=[]; % Remove offsets term
else
    tmp=zeros(size(Q)+1);
    tmp(1:size(Q,1),1:size(Q,1))=Q;
    Q=tmp;
    H=[H;zeros(1,size(H,2)-1) 1];
end



% determine which features fo into the tuning
%     switch obj.decoderParams.TuningFeatures
%         case 'xdx' % position and velocity
%             H=H(:,2:2:end);
%             warning('Check')
%
%         case 'dx' % velocity
%
%         case 'xdxs' % velocity & speed
%             H=H(:,2:2:end);
%             H=H(:,1:obj.decoderParams.nDOF);
%             warning('Check')
%
%         otherwise
%             error('Unsupported Method.')
%
%     end


if obj.decoderParams.useCov
    Bcf=inv(H'*pinv(Q)*H)*H'*pinv(Q);
else
    Bcf=inv(H'*H)*H';
end


switch obj.decoderParams.TuningFeatures
    case 'xdx' % position and velocity
        Bcf=Bcf(2:2:end,:);
        
    case 'dx' % velocity
        
    case 'xdxs' % velocity & speed
        %             H=H(:,2:2:end);
        %             H=H(:,1:obj.decoderParams.nDOF);
        warning('Check')
        
    otherwise
        error('Unsupported Method.')
        
end

if useaddage
    Bcf=[Bcf,Bcf(:,end)*0];
else
    Bcf(end,:)=[];
end

for k=1:size(X,1)
    CC(k)=corr((Bcf(k,:)*Z)',X(k,:)');
end