function decoder=setSAFParams(obj,decoder,multFactor)

if nargin==2
    speedPercentile=decoder.decoderParams.SAF.speedPercentile;
    filterWindow=decoder.decoderParams.SAF.filterWindow;
    Speed=decoder.trainingData.S;
    
    pkspeed=prctile(Speed,speedPercentile);
    decoder.decoderParams.SAF.pkspeed=pkspeed;
    % set smoothing params
    decoder.decoderParams.SAF.smoothingParams(1:2)=decoder.decoderParams.SAF.smoothingMetaParams(1:2);
    decoder.decoderParams.SAF.smoothingParams(3)=decoder.decoderParams.SAF.smoothingMetaParams(3)*pkspeed;
    decoder.decoderParams.SAF.smoothingParams(4)=decoder.decoderParams.SAF.smoothingMetaParams(4)*pkspeed;
    % set gain params
    decoder.decoderParams.SAF.gainParams(1:2)=decoder.decoderParams.SAF.gainMetaParams(1:2);
    decoder.decoderParams.SAF.gainParams(3)=decoder.decoderParams.SAF.gainMetaParams(3)*pkspeed;
    decoder.decoderParams.SAF.gainParams(4)=decoder.decoderParams.SAF.gainMetaParams(4)*pkspeed;
    
    decoder.decoderParams.SAF.detectionFilter=decoder.decoderParams.SAF.detectionFilter;
    
    
else
    decoder.decoderParams.SAF.smoothingParams(3)=decoder.decoderParams.SAF.smoothingParams(3)*mean(multFactor);
    decoder.decoderParams.SAF.smoothingParams(4)=decoder.decoderParams.SAF.smoothingParams(4)*mean(multFactor);
    
    decoder.decoderParams.SAF.gainParams(3)=decoder.decoderParams.SAF.gainParams(3)*mean(multFactor);
    decoder.decoderParams.SAF.gainParams(4)=decoder.decoderParams.SAF.gainParams(4)*mean(multFactor);
    decoder.decoderParams.SAF.pkspeed=decoder.decoderParams.SAF.pkspeed*mean(multFactor);
end

%%
% figure; hold on
% plot(Kinematics.MakeExpFilter(2, .05,.85),'r.-')
%  plot(Kinematics.MakeARFilter(.5, .05, .15))
%  plot(Kinematics.MakeARFilter(.5, .05, .01),'b.-')
% %  
% %  
% %  plot(Kinematics.MakeExpFilter(2, .05,.85),'r')
% % plot(Kinematics.MakeExpFilter(.5, .05,.9),'g')
% %  plot(Kinematics.MakeExpFilter(.5, .05,.7),'b')
%  %%
% figure(28); clf;hold on
% plot(Kinematics.MakeExpFilter(2, .05,.85),'r.-')
% plot(Kinematics.MinJerkKernel(550,.05*1000,1),'g.-');
% % plot(Kinematics.MinJerkKernel(785,.05*1000,1),'k.-');
% plot(Kinematics.MinJerkKernel(950,.05*1000,1),'g.-');
%  plot(Kinematics.MakeARFilter(.5, .05, .01),'b.-');