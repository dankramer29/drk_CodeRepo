function PopVec=CombineAcrossLags(obj,PopVecLags,signalProps)


PopR2=cell2mat({PopVecLags.R2_CVmu});

% find optimal lag for each channel
[bestLagR2,bestLagINDX]=max(PopR2');



%%
posLags=sort([PopVecLags.Lag]);
for chanINDX=1:length(bestLagR2)
    lagINDX=bestLagINDX(chanINDX);
    
    R2_CVmu(chanINDX)=PopVecLags(lagINDX).R2_CVmu(chanINDX);
    R2_CVse(chanINDX)=PopVecLags(lagINDX).R2_CVmu(chanINDX);
    R2(chanINDX)=PopVecLags(lagINDX).R2_CVmu(chanINDX);
    
    Lag(chanINDX)=PopVecLags(lagINDX).Lag;
    
    H(chanINDX,:)=PopVecLags(lagINDX).H(chanINDX,:);
    Hse(chanINDX,:)=PopVecLags(lagINDX).Hse(chanINDX,:);
    pValue(chanINDX)=PopVecLags(lagINDX).pValue(chanINDX);
    
    % note that residuals will be different lengths based on fact that
    % lagging data alters number of time points.
    residuals{chanINDX}=PopVecLags(lagINDX).residuals(chanINDX,:);
    sResiduals{chanINDX}=PopVecLags(lagINDX).sResiduals(chanINDX,:);
    
    
    
    muEOut(chanINDX)=PopVecLags(lagINDX).muEOut(chanINDX);
    sigEOut(chanINDX)=PopVecLags(lagINDX).sigEOut(chanINDX);
    
    
end

%%
% match up residuals & compute Q
clear R
for i=1:length(residuals)
    switch sign(Lag(i))
        case -1
            r=residuals{i}((abs(posLags(1))+1+Lag(i)):end-abs(posLags(end)));
            R(i,:)=r;
            
            r=sResiduals{i}((abs(posLags(1))+1+Lag(i)):end-abs(posLags(end)));
            sR(i,:)=r;
        case 1
            r=residuals{i}((abs(posLags(1))+1):end-abs(posLags(end))+Lag(i));
            R(i,:)=r;
            
            r=sResiduals{i}((abs(posLags(1))+1):end-abs(posLags(end))+Lag(i));
            sR(i,:)=r;
        case 0
            r=residuals{i}((abs(posLags(1))+1):end-abs(posLags(end)));
            R(i,:)=r;
            
            r=sResiduals{i}((abs(posLags(1))+1):end-abs(posLags(end)));
            sR(i,:)=r;
    end
end

Q = (1/size(R,2))*(R)*(R)';
smoothQ = (1/size(sR,2))*(sR)*(sR)';

%%
% need to respecify signifFeatures and decodeFeatures
activeFeatures=signalProps.activeFeatures;

% signifFeatures=(R2_CVmu(:)>obj.decoderParams.preProcessThreshold);
signifFeatures=(pValue<obj.decoderParams.preProcessThreshold);

if obj.decoderParams.preProcessForSignificance
    decodeFeatures = activeFeatures(:) & signifFeatures(:);
else
    decodeFeatures = activeFeatures;
end


% zTest=sZ(decodeFeatures,:); zTest=[zTest;zTest(end,:)*0+1];

if obj.decoderParams.popVecDispersion
    obj.msgName('Dispersing population vector... ',0)
    
    newH=dispersePopVec(obj,H(decodeFeatures,1:end-1));
    newH=[newH,H(decodeFeatures,end)];
    
    obj.msgName('DONE',1,0)
    Bcf = IPV(obj.decoderParams, newH, Q(decodeFeatures,decodeFeatures), [], []);
else
    [Bcf]=IPV(obj.decoderParams,H(decodeFeatures,:),Q(decodeFeatures,decodeFeatures),[],[]);
end




%%

PopVec.IV.Bcf=Bcf;
PopVec.signifFeatures=signifFeatures;
PopVec.decodeFeatures=decodeFeatures;

PopVec.R2_CVmu=R2_CVmu;
PopVec.R2_CVse=R2_CVse;
PopVec.R2=R2;
PopVec.H=H;
PopVec.Hse=Hse;
PopVec.Q=Q;
PopVec.smoothQ=smoothQ;
PopVec.pValue=pValue;
PopVec.Lag=Lag;

PopVec.residuals=residuals;
PopVec.sResiduals=sResiduals;

if obj.decoderParams.popVecDispersion
    PopVec.Hdispersion=newH;
end

function [Bcf,CC]=IPV(decoderParams,H,Q,X,Z)

useaddage=1;

if useaddage
    H(:,end)=[]; % Remove offsets term
else
    tmp=zeros(size(Q)+1);
    tmp(1:size(Q,1),1:size(Q,1))=Q;
    Q=tmp;
    H=[H;zeros(1,size(H,2)-1) 1];
end


if decoderParams.useCov
    Bcf=inv(H'*pinv(Q)*H)*H'*pinv(Q);
else
    Bcf=inv(H'*H)*H';
end


switch decoderParams.TuningFeatures
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
