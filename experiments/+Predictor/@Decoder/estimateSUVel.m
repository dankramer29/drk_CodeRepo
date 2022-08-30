function [sV,iV,resid]=estimateSUVel(obj,curZ,curX,sResid)

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



SUfeatINDX=obj.frameworkParams.SUfeatINDX;

Betas=obj.decoders(cIDX).PopVec.BcfS(:,SUfeatINDX);
iV=Betas*curZ(SUfeatINDX);


% smoothed estimate of V
if obj.decoders(cIDX).decoderParams.applySpeedAdaptiveFilter; % apply speed adaptive smoothing
    sV=obj.decoders(cIDX).SAF.Estimate([pV,iV],1);
else    
    sV=obj.ApplyFilter(Filter, [pV,iV]);
end

sV=(gain.*sV-obj.decoders(cIDX).decoderParams.PosFB*cP );



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