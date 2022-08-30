function [x,z,goal,decoder]=raw2model(obj,x,z,goal,decoder)

% decoder is either a struct or an index
if isstruct(decoder)
    signalProps=decoder.signalProps;
    decoderParams=decoder.decoderParams;
else
    signalProps=obj.decoders(curDecoderIndx).signalProps;
    decoderParams=obj.decoders(curDecoderIndx).decoderParams;
end

% unit conversions to transform raw kinematics/ neural data to the
% processed form that is used by the decoder.
if decoderParams.demeanX
error('Need to make sure I didnt break this')
    %     x = x - repmat(signalProps.meanX,1,size(x,2));
%     if nargin==4 && ~isempty(goal)
%        goal = goal - repmat(signalProps.meanX(1:2:end),1,size(x,2)); 
%     end
end


if nargin>2 && ~isempty(z)% there is neural data
    
    if obj.decoderParams.adaptNeuralMean;
        meanZ=signalProps.meanZ;
    else        
        meanZ=signalProps.origStats.meanZ;    
    end
    
    % process neural data
    if decoderParams.zscoreZ
        %         normalize such that the deviations about the mean have the same energy for all channels.
        z = z - repmat(meanZ,1,size(z,2));
        z=z./repmat(signalProps.stdZ,1,size(z,2));
    else
        % if normalizing, do not demean
        if decoderParams.demeanZ
            z = z - repmat(meanZ,1,size(z,2));
        end
    end
    
    % splitNeuralData
%     Z1=z; Z1(Z1<0)=0;
%     Z2=z; Z2(Z2>0)=0;
%     z=[ Z1;Z2];
%     decoder.signalProps.activeFeatures=[decoder.signalProps.activeFeatures;decoder.signalProps.activeFeatures];
%     
else
    z=[];
end


end

%%

