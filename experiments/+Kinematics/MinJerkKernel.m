function [kernel,signalSmoothed]=MinJerkKernel(Duration, SR,halffilt,signal,causal)
%%
% Returns a minimum smoothing minjerk smoothing kernel and optionally
% applies the kernel to the specified signal.
% Inputs
%  Duration : Duration of kernel (arbitrary units - must match SamplingPeriod' e.g. 500 ms.)
%  SR       : Amount of Time per Sample (e.g. 50 ms or .05 s)
%  halffilt : whether the kernel should be full or half minjerk kernel (half would be used for a causal filter to avoid excessive phase delays.)
%  signal   : signal to be smoothed - smooths across the second dimension
%  causal   : defines whether the smoothing is causal (e.g. the value at
%               data point N contains information from future data points.)

if nargin<3
    halffilt=false;
end

nSamples=floor(Duration/SR)+1;

[kernel] = diff(MinJerk.min_jerk([0;1], nSamples,[],[],[]));



if halffilt
    kernel=kernel(ceil(length(kernel)/2):end);
    kernel=kernel/sum(kernel);
    kernel=kernel';
else
    kernel=kernel/sum(kernel);
end

signalSmoothed=[];
if nargin>3
    if nargin<5; causal=0; end
    if causal
        [signalSmoothed]=Utilities.filter_mirrored(kernel,1,signal,[],2);
    else
        signalSmoothed=filtmirr(kernel,signal,2,'zeroPhase');        
    end
end