function [pk, pkLoc] = specGramFreqPeak(data1, data2, varargin)
%psdFreqPeak Evaluate the peaks of the PSD across all channels and all
%times to find the points of maximum power
%   Inputs
%        data1- data needs to be z scored (can be db or not db)
%        data2- iti data.  can be anything as long as it's the same size,
%        otherwise it will cut down the real data instead of the iti

%take non z scored data, subtract it, then zscore that. otherwise you have
%issues with the iti.




[varargin, fs] = util.argkeyval('fs',varargin, 2000); %sampling rate of the signal
[varargin, classicBand]= util.argkeyval('classicBand', varargin, [1 4; 4 8; 8 13; 13 30; 30 50; 50 200]);
[varargin, ff] = util.argkeyval('ff',varargin, []); %freqs for plotting
[varargin, tt] = util.argkeyval('tt',varargin, []); %times for plotting

lblN={'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma', 'HighGamma'}; %set up labeling

%if the iti is not as large as the trial length, add a mirrored end to the
%iti. And if too long for the iti, it's cut down
if size(data2,2)<size(data1,2)
    extr=size(data1,2)-size(data2,2)-1;
    temp=data2(:, end-extr:end, :);
    data2_temp=cat(1,temp, data2);
elseif size(data2,2)>size(data1,2)
    data2_temp=data2(:,1:size(data1,2), :);
else
    data2_temp=data2;
end

%expand the iti (data2) to the same amount of trials as data1, since it's
%uniform, doesn't matter
data2_temp=repmat(data2_temp, [1,1,size(data1,3)]);

%for getting t stats
L1=size(data1,3);
L2=size(data2,3);

%get the real mean difference and sd at each value
mnd1=nanmean(data1,3); %average across trials
mnd2=nanmean(data2_temp,3); 
sd1=std(data1,0,3);
sd2=std(data2_temp,0,3);
spR=sqrt(((L1-1)*sd1.^2+(L2-1)*sd2.^2)./(L1+L2-2));
tstat_R=(mnd1-mnd2)./(spR*sqrt(1/L1+1/L2));
tstat_Rabs=abs(tstat_R); %take absolute for adjustment.  I looked into this, it needs to be absolute value to capture all (ultimately this is a two sided t test, so the tcdf needs to see the absolute value), IT'S POSSIBLE TO FIX THIS IN THE FUTURE IF DESIRED, BUT NEEDS SOME MORE THOUGHT
r_pvalue=2*tcdf(-abs(tstat_Rabs), (L1+L2-2)); %get the p values for adjustment, this formula is straight from ttest2

%% fine which clusters are sig
%allocate
sigclust=zeros(size(tstat_R));
%find the 0.05 level
% temp_tsm=sort(tstat_max);
% thresh=temp_tsm(round(size(tstat_max,1)*.95));
%%
%begin clustering with bwconncomp
thresh_binaryR=r_pvalue<0.01;%find those less than set p value
clustR=bwconncomp(thresh_binaryR,8);
clR=regionprops(clustR); %get the region properties
cl_aR=[clR.Area];
cl_keep=find(cl_aR>100); %get the ones with an area >100 pixels
idxc=1;

%find the peak freq for any large clusters of significant areas
for ii=1:size(cl_keep)
    [pk, pkLoc]=min(r_pvalue(clustR.PixelIdxList{cl_keep(ii)})); %it's always min because finding the lowest p value, so increase or decrease in power, this will find it

end

%store all of the peaks, very noisy 
for ii=1:size(psdBaseAll, 2)
    [pk, pkLoc]=findpeaks(psdBase(:,ii));
    freqPeakAll{ii}=pkLoc; %store the peaks by channel
end

%store the peaks in the canonical bands
for ii=1:size(classicBand, 1)
    [mx, mxLoc]=max(psdBaseAllCh(:, classicBand(ii,1):classicBand(ii,2)));
    freqPeak.(lblN{ii})=mxLoc;
end



end