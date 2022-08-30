function F=MakeExpFilter(Duration, samplePeriod,expKernel)


L=Duration;L=round(L/samplePeriod);
F=zeros(L,1);
for i=(0:L-1); F(i+1)=expKernel^i ; end

%normalize
F=F-min(F);
F=F/sum(F);