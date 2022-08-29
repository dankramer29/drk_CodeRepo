function [sV,iV,resid]=estimateVel(obj,curZ,curX,sResid)

cP=curX(1:2:end);
cV=curX(2:2:end);
% Steps
% 1 - Compute instantaneous estimate of V (iV)
% 2 - Combine iV with previous estimates of V (pV) and smooth.
% 3 - use estimated velocity to generate estimate of firing rates.
% 4 - Compare actual and estimated firing rates to determine outliers.
resid=[];
cIDX=obj.currentDecoderINDX;
gain=obj.runtimeParams.outputGain(:);
Filter=obj.decoders(cIDX).decoderProps.smoothingFilter;
pV=obj.DataBuffers.RecentState.get(length(Filter));



% Instantaneous estimate of V
obj.decoders(cIDX).decoderProps.useConsensus=0;
if obj.decoders(cIDX).decoderProps.useConsensus
    
    decodeFeatures=obj.decoders(cIDX).decoderProps.decodeFeatures;
    H=obj.decoders(cIDX).PopVec.H(decodeFeatures,1:end-1);
    Q=obj.decoders(cIDX).PopVec.Q(decodeFeatures,decodeFeatures);
    iQ1=Q*0; iQ2=Q*0; iQ3=Q*0;
    
    indx=1;
    pZ=obj.DataBuffers.RecentNeural.get(20);
    % Initial Estimate
    QW=[0 1 0];QW=QW/sum(QW);
    [iV,stdx,mse,S]= lscov(H,curZ,Q); 
    sV=obj.ApplyFilter(Filter, [pV,iV]);
    
   
    %%
    while 1; % loop until converged
        pSV=sV;
        
        zHat=H*[sV];
        
        cResid=zHat-obj.ApplyFilter(Filter, [pZ(decodeFeatures,:),curZ]);
        iQ1=cResid*cResid';
%         iQ1=diag(cResid.^2);
        if obj.DataBuffers.RecentResiduals.numEntries>=20;
            cResid2=mean(obj.DataBuffers.RecentResiduals.get(20),2);
            iQ2=cResid2*cResid2';
%             iQ2=diag(cResid2.^2);
            
        end
        if obj.DataBuffers.RecentResiduals.numEntries>=100;
            cResid3=mean(obj.DataBuffers.RecentResiduals.get(100),2);
            iQ3=cResid3*cResid3';
%             iQ3=diag(cResid3.^2);
        end
        
        a=.95;
        newQ=a*Q+(1-a)*(QW(1)*iQ1+QW(2)*iQ2+QW(3)*iQ3);
        [iV,stdx,mse,S]= lscov(H,curZ,newQ);
        sV=obj.ApplyFilter(Filter, [pV,iV]);
        
        indx=indx+1;
%         disp([indx; sV(:);pSV]')
        if mnorm([sV-pSV]')<1; break; end
    end
    %%
   disp([indx, sV(:)'])
%     figure(3); imagesc([a*Q,(1-a)*[QW(1)*iQ1,QW(2)*iQ2,QW(3)*iQ3]])
    obj.DataBuffers.RecentResiduals.add(cResid);
    
else
    iV=obj.decoders(cIDX).decoderProps.Bcf*[curZ;1];
end


% g=.8;
% V=g*obj.decoders(cIDX).PopVec.Q+(1-g)*sResid;
% iV = lscov(obj.decoders(cIDX).PopVec.H,curZ,V);


% smoothed estimate of V
if obj.decoders(cIDX).decoderParams.applySpeedAdaptiveFilter; % apply speed adaptive smoothing
    sV=obj.decoders(cIDX).SAF.Estimate([pV,iV],1);
else    
    sV=obj.ApplyFilter(Filter, [pV,iV]);
end

sV=(gain.*sV(1:2)-obj.decoders(cIDX).decoderParams.PosFB*cP );



% Plot Residuals.
% if isfield(obj.runtimeParams,'plotResiduals') && obj.runtimeParams.plotResiduals==1
%     
%     decodeFeatures=obj.decoders(cIDX).decoderProps.decodeFeatures;
%     H=obj.decoders(cIDX).PopVec.H(decodeFeatures,:);
%     z_est=H*[sV;1];
%     
%     
%     sResiduals=curZ-z_est;
%     
%     % map to cont Channels
%     residMapped=zeros(96,1);
%     residMapped(decodeFeatures)=sResiduals;
%     obj.runtimeParams.RHM.plotResiduals(residMapped);
%     drawnow;
%     smoothQ = (1/size(x,2))*(sResiduals)*(sResiduals)';
%     
%     % Q=smoothQ;
% end
% compute estimate of firing rate
% fr_est=obj.decoders.PopVec.H*[sV;1];
% resid=(fr_est-curZ)*(fr_est-curZ)';




% mp1=Blackrock.ArrayMap('Y:\data\Spenser\SN1025-001022.cmp');
% mp2=Blackrock.ArrayMap(Analyze.getMapFiles(2));
%
% tmp1=mp1.ch2layout(1:96);
% tmp2=mp2.ch2layout(1:96);
% figure
% imagesc([tmp1 ,nan(10,1), tmp2 ]); axis image










%
%
%
%
% if obj.isTrained
%
%     [curX,curZ]=obj.raw2model(curX,curZ,[],obj.decoders(cIDX));
%     obj.DataBuffers.RecentNeural.add(curZ);
%
%     gain=obj.runtimeParams.outputGain(:);
%
%     if any(strcmp(obj.decoders(cIDX).decoderParams.filterType,{'direct','inversion','kalmanfit'}))
%         Filter=obj.decoders(cIDX).decoderParams.smoothingFilter;
%         curZ=obj.ApplyFilter(Filter, obj.DataBuffers.RecentNeural.get);
%          curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures,:);
% %         Vel=obj.decoderProps.Ac(2:2:end,:)*curX+gain.*(obj.decoderProps.Bc(2:2:end,:)*[curZ;1]);
%         Vel=gain.*(obj.decoders(cIDX).decoderProps.Bcf*[curZ;1]);
%
%     elseif strcmp(obj.decoders(cIDX).decoderParams.filterType,{'sskalman'})
%         curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures);
%         Vel=obj.decoderProps.Ac(2:2:end,:)*curX+gain.*(obj.decoderProps.Bc(2:2:end,:)*[curZ;1]);
%     elseif strcmp(obj.decoders(cIDX).decoderParams.filterType,'kalman')   && strcmp(obj.decoders(cIDX).decoderParams.TuningFeatures,'dx')
%         curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures);
%         Vel=gain.*kalmanStep(obj,curX(2:2:end)./gain,curZ,obj.decoders(cIDX));
%     elseif strcmp(obj.decoders(cIDX).decoderParams.filterType,'kalman')   && strcmp(obj.decoders(cIDX).decoderParams.TuningFeatures,'xdx')
%         curZ=curZ(obj.decoders(cIDX).decoderProps.decodeFeatures);
%         curX(2:2:end)=curX(2:2:end)./gain;
%         tmp=kalmanStep(obj,curX,curZ);
%         Vel=gain.*tmp(2:2:end);
%     end
%
% else
%     Vel=curX(2:2:end);
% end