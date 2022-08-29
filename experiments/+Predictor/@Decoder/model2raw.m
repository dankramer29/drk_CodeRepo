function [x,z]=raw2model(obj,x,z,curDecoderIndx)

% unit conversions to transform raw kinematics/ neural data to the
% processed form that is used by the decoder.

% remove mean from x
% if obj.options.demeanX
% x = x + repmat(obj.signalProps.meanX,1,size(x,2));
% end

signalProps=obj.decoders(curDecoderIndx).signalProps;
decoderParams=obj.decoders(curDecoderIndx).decoderParams;



% if normalizing, do not demean
if decoderParams.demeanX
    x = x + repmat(signalProps.meanX,1,size(x,2));
end
