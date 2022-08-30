function tr=trajectory(ICs,FCs,Duration,SamplingPeriod)

%%  Output=MinJerkTrajectory(ICs,FCs,Duration,SamplingPeriod)
% Generate Trajectories between the initial kinematic state (ICs) to the
% final kinematic state (FCs) that unfold over the specified duration
% (Duration) sampled every SamplingPeriod seconds.  The assumed units of time are ms.


% construct "time" vector baed on desired Duration and Sampling Period
t=(0:SamplingPeriod:Duration)';

% Construct an initial step function representation of the movement.  Once
% smoothed with the minjerk profiles, these movements will look like
% minjerk profiles
y=[ICs;repmat(FCs,length(t)-1,1)];




% generate the minjerk smoothing kernal.
FilterCoefficients=MinJerkKernel(Duration, SamplingPeriod,0);
% tmp=y;

% append the IC to avoid initial condition affects.
y=[repmat(y(1,:),2*length(FilterCoefficients),1);y];

% smooth step function with minjerk kernel
y=filter(FilterCoefficients,1,y);

% remove the leading elements
tr=y(2*length(FilterCoefficients)+1:end,:);


function out=MinJerkKernel(Duration,SR,halffilt)
%%
% Returns a minimum jerk trajectory of spefied duration at the specified
% sampling rate. The output is normalized such that the area under the
% curve is equal to one.
% Duration is in ms.
% inputs are Duration in seconds and sampling rate as n samples per second

if nargin==2
    halffilt=false;
end

nSamples=floor(Duration/SR)+1;

[out] = diff(MinJerk.min_jerk([0;1], nSamples,[],[],[])); out=out-min(out); out=out/sum(out);

if halffilt
    out=out(ceil(length(out)/2):end);
    out=out/sum(out);
    out=out';
end

