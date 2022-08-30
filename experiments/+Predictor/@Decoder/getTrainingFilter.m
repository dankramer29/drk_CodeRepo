function F=makeSmoothingFilter(obj,filterOptions)
%%
% sets the training filter for the active (or specified) decoder
causal=filterOptions.causal;
params=filterOptions.params;
switch filterOptions.SmoothType
    case 'mj'
        F=Kinematics.MinJerkKernel(params,obj.decoderParams.samplePeriod*1000,causal);
        F=F(:);
    case '2pt'
        F=Kinematics.MakeARFilter(params(1),obj.decoderParams.samplePeriod,params(2));
        F=F(:);
        if ~causal
            F=[flipud(F);F(2:end)];
            F=F/sum(F);
        end
    case 'exp'
        F=Kinematics.MakeExpFilter(params(1), obj.decoderParams.samplePeriod,params(2));
        F=F(:);
        if ~causal
            F=[flipud(F);F(2:end)];
            F=F/sum(F);
        end
end

