function [mnd1, mnd2, sd1, sd2, sigclust, rlab] = cluster_timeShift_ActualData(data1, data2, threshold, varargin)
%UNTITLED4 Summary of this function goes here
%   this is to be used with stats.cluster_timeShift_Ttest_gpu3d. Once you
%   establish the threshold there from shuffled data, this is where you can
%   compare each of the actual comparisons you want. The clusters would be
%   compared to the histogram of the shuffle derived baseline.


[varargin, alph]=util.argkeyval('alph', varargin, 0.05); 
[varargin, plt]=util.argkeyval('plt', varargin, false); 


L1 = size(data1, 3);
L2 = size(data2, 3);

%get the real mean difference and sd at each value
mnd1=nanmean(data1,3);
mnd2=nanmean(data2,3); %includes the mirrored part if not the same size
sd1=std(data1,0,3);
sd2=std(data2,0,3);
spR=sqrt(((L1-1)*sd1.^2+(L2-1)*sd2.^2)./(L1+L2-2));
tstat_R=(mnd1-mnd2)./(spR*sqrt(1/L1+1/L2));
tstat_R=gather(tstat_R);
tstat_Rabs=abs(tstat_R); %take absolute for adjustment.  I looked into this, it needs to be absolute value to capture all (ultimately this is a two sided t test, so the tcdf needs to see the absolute value), IT'S POSSIBLE TO FIX THIS IN THE FUTURE IF DESIRED, BUT NEEDS SOME MORE THOUGHT
r_pvalue=2*tcdf(-abs(tstat_Rabs), (L1+L2-2)); %get the p values for adjustment, this formula is straight from ttest2

%% find which clusters are sig
%allocate
sigclust=zeros(size(tstat_R));
%%
%begin clustering with bwconncomp
thresh_binaryR=r_pvalue<alph;%find those less than set p value
clustR=bwconncomp(thresh_binaryR,8);
clR=regionprops(clustR); %get the region properties
cl_aR=[clR.Area];
cl_keep=find(cl_aR>100); %get the ones with an area >100 pixels
idxc=1;
for ii=1:length(cl_keep)
    mat=false(size(thresh_binaryR));
    mat(clustR.PixelIdxList{cl_keep(ii)})=true;    
    tstat_sums(ii)=sum(abs(tstat_R(mat)));
    
    if tstat_sums(ii)>threshold %save the ones that are over the thresh
    sigclust(clustR.PixelIdxList{cl_keep(ii)})=idxc;
    idxc=idxc+1;
    end
end

%for testing
% lab=labelmatrix(clustR);
% lab=lab';
% rlab=label2rgb(lab,@spring,'c','shuffle');
bonc=0.05/(size(mnd1,1)*size(mnd1,2));
rlab=r_pvalue<bonc;
end