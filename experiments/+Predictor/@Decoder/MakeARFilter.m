function kernel=MakeARFilter(Duration, samplePeriod, Factor)

% This filter shape is a compromise between MinJerk and Exponential
% filters.

L=Duration;L=L/samplePeriod;
v=[-.1 1]; v=v/sum(v)*(1-Factor); f=[v Factor]; 
sig=zeros(L+2,1); sig(3)=1;

for i=3:length(sig); sig(i)=f*sig(i-2:i); end
kernel=sig(3:end); kernel=kernel-min(kernel); kernel=kernel/sum(kernel);
