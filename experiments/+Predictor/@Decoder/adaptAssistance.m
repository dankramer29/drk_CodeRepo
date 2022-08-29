function adaptAssistance(obj,v1,v2,frameID)
%%
% angle between neural and ideal



if strcmp(obj.runtimeParams.assistAdaptationType,'angularError')
    % compute/smooth angular error
    angularError=180/pi*acos(dot(v1,v2)./(norm(v1)*norm(v2)+eps));
    
    nS = (1-exp( -obj.decoderParams.samplePeriod/(obj.runtimeParams.errorTC)));
    angularError = (1-nS)*obj.runtimeParams.angularError + nS*angularError;
    
    
    if rem(frameID,100)==0; % update every 50 time steps
        
        if angularError>obj.runtimeParams.targetError
            obj.runtimeParams.assistLevel=obj.runtimeParams.assistLevel+obj.runtimeParams.assistStep;
        else
            obj.runtimeParams.assistLevel=obj.runtimeParams.assistLevel-obj.runtimeParams.assistStep;
        end
        
        if obj.runtimeParams.assistLevel<0; obj.runtimeParams.assistLevel=0; end
        if obj.runtimeParams.assistLevel>1; obj.runtimeParams.assistLevel=1; end
        
    end
    
    obj.runtimeParams.angularError=angularError;
    
    
    if rem(frameID,100)==0; % display assistance level every 200 steps
        obj.msgName(sprintf('Average angular error = %0.1f; Assistance @ %0.2f',angularError,obj.runtimeParams.assistLevel))
    end
    
end

% obj.runtimeParams.adaptAssistanceLevel  - whether to adapt assistance or not
% obj.runtimeParams.errorTC - time constant of error estimate
% obj.runtimeParams.assistStep - amount to adjust assistance level by on update
% obj.runtimeParams.targetError -
% obj.runtimeParams.assistAdaptationType -
% obj.runtimeParams.angularError - averge angular error