function assignDataBuffers(obj,varargin)


obj.emptyBuffers;

inputArguments=varargin;
while ~isempty(inputArguments)
    
    switch (inputArguments{1})
        case 'NeuralData'
            z=inputArguments{2};
            obj.DataBuffers.NeuralData.add(z);
            inputArguments(1:2)=[];
            
        case 'IdealPrediction'
            x=inputArguments{2};  
            obj.DataBuffers.IdealPrediction.add(x);
            inputArguments(1:2)=[];
            
        case 'AssistedPrediction'
            x=inputArguments{2};  
            obj.DataBuffers.AssistedPrediction.add(x);
            inputArguments(1:2)=[];
            
        case 'NeuralPrediction'
            x=inputArguments{2};  
            obj.DataBuffers.NeuralPrediction.add(x);
            inputArguments(1:2)=[];
            
        case 'Kinematics'
            x=inputArguments{2};  
            obj.DataBuffers.Kinematics.add(x);
            inputArguments(1:2)=[];
            
            
        case ('FrameID')
            x=inputArguments{2};  
            obj.DataBuffers.FrameID.add(x);
            inputArguments(1:2)=[];

        case ('Goal')
            x=inputArguments{2};  
            obj.DataBuffers.Goal.add(x);
            inputArguments(1:2)=[];
            
        case ('FrameID')
            x=inputArguments{2};  
            obj.DataBuffers.Kinematics.add(x);
            inputArguments(1:2)=[];
            
        otherwise
            error('Input %s is not a valid arguement, try again ',inputArguments{1})
    end
    
    
end