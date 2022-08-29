function [useGPU,useParfor] = getGPUParfor(useParfor,useGPU,hasGPU)

if ~isnan(useParfor) && ~isnan(useGPU)
    if useGPU && hasGPU
        useParfor = false;
    elseif useGPU && ~hasGPU
        useGPU = false;
    end
elseif ~isnan(useParfor) && isnan(useGPU)
    if useParfor
        useGPU = false;
    else
        useGPU = hasGPU;
    end
elseif ~isnan(useGPU) && isnan(useParfor)
    if useGPU
        useParfor = false;
    else
        useParfor = ~hasGPU;
    end
elseif isnan(useGPU) && isnan(useParfor)
    useGPU = hasGPU;
    useParfor = ~hasGPU;
end
assert(~(useGPU&&useParfor),'Cannot enable both GPU and parfor loops');
if useGPU,assert(hasGPU,'Cannot use GPU since none is available');end