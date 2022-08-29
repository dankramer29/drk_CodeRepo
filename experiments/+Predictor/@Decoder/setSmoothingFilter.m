function setSmoothingFilter(obj,params,cIDX)

% sets the smoothing filter for the active (or specified) decoder
if nargin<3;
    cIDX=obj.currentDecoderINDX;
end
if nargin==1;
    params=obj.decoders(cIDX).decoderParams.modelSmoothParams;
end


switch obj.decoders(cIDX).decoderParams.modelSmoothType
    case 'mj'
        F=Kinematics.MinJerkKernel(params,obj.decoderParams.samplePeriod*1000,1);
    case '2pt'
        F=Kinematics.MakeARFilter(params(1),obj.decoderParams.samplePeriod,params(2));
    case 'exp'
        F=Kinematics.MakeExpFilter(params(1), obj.decoderParams.samplePeriod,params(2));
end

obj.decoders(cIDX).decoderParams.smoothingFilter=F;