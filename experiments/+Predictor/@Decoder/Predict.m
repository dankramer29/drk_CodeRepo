function [nextX,nextIdealX]=Predict(obj,varargin)

% predict the current state given the previous state, the current neural
% data, and the Decoder structure.  Here we assume that curX and z_p are in
% the oringinal units (and not e.g. zero meaned) and we allow the Decode
% structure to perform necassary preprocessing.



% Determine the predict function
cIDX=obj.currentDecoderINDX;
if ~isempty(cIDX) && cIDX>0
    % Pull decoder Function from specific decoder
    PredictFunction=obj.decoders(cIDX).decoderParams.PredictFunction;    
else
    % Pull decoder Function from default options
    PredictFunction=obj.decoderParams.PredictFunction;
end


[nextX,nextIdealX]=feval(PredictFunction,obj,varargin);



% Buffer Results to Framework
bufferFrameworkData(obj,0);  