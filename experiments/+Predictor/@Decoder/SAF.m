function V=SAF(obj,Velocity,OneOff)
 
% speed adaptive filter built into decoder


% This function applies variable smoothing dependent on the local history of speed.
% it adjusts both the magnitude and gain.
 
cIDX=obj.currentDecoderINDX;

samplePeriod=obj.decoderParams.samplePeriod;

smoothingParams =obj.decoders(cIDX).decoderParams.SAF.smoothingParams;
gainParams =obj.decoders(cIDX).decoderParams.SAF.gainParams;
detectionFilter =obj.decoders(cIDX).decoderParams.SAF.detectionFilter;
 
 for j=1:size(Velocity,1)
        V(j,:)=Kinematics.SpeedAdaptiveFilterV2(Velocity(j,:),samplePeriod,smoothingParams,gainParams,detectionFilter,OneOff);      
 end
     
