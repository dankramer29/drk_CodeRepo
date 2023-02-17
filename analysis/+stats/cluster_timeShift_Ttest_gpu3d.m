function [ thresh, tstat_max ] = cluster_timeShift_Ttest_gpu3d( data, varargin )
%USE THIS ONE OR CLUSTER_PERMUTATION_TTEST_GPU3D
% This one is used for grabbing time shifted data and creating a histogram
% to compare to the actual means of real data. This is best used when you
% don't have a true ITI and want to just take a bunch of epochs from the
% data take the average. To be used with a second function that then can
% take the mean between the real data and a mean, and then put the clusters
% into the histogram.

%I think, but don't know, that using NON zscored data is better (the data
%is the same but the values are larger for the ttest)

% shuffle_stats shuffles the data between two data sets takes the mean and
%std to make a distribution of the data to compare the true values to using
%
%a cluster approach
%   Takes two vectors of data and shuffles the data points, calculates the
%   means of the two new, shuffled groups, and takes the difference between
%   those means.  Does that xshuffles number of times and tells where your
%   actual difference in means falls on that distribution.
% %INPUT:  
%      data1 -matrix or vector of data, where the 3rd dimension is trials
%      (not currently set up for 2d data, but probably should in the future
%      optional data2 -matrix or vector of data
% %OUTPUT:
%     thresh- the threshold a cluster needs to be above to be significant
%     t

[varargin, data2]=util.argkeyval('data2', varargin, []); %can input a second data or create it from the first set

[varargin, plt]=util.argkeyval('plt', varargin, false); %option to plot the historgram
[varargin, xshuffles]=util.argkeyval('xshuffles', varargin, 100); %how many shuffles you want to do, default is 5k
%adjust the alpha level that the permutations are compared to, meaning the percentile on the histogram, over which something is considered positive
%0.00024 is 0.05/(64*3+20) the number of electrodes for the real touch
[varargin, alph]=util.argkeyval('alph', varargin, 0.05); 
[varargin, gpuOn]=util.argkeyval('gpuOn', varargin, false); %turn on gpu or not
[varargin, tt]=util.argkeyval('tt', varargin, []); %include a tplot if you want to plot
[varargin, ff]=util.argkeyval('ff', varargin, []); %include a freq if you want to plot




util.argempty(varargin); % check all additional inputs have been processed

%calculate the size of the samples you want to take, default is just over
%half

if isempty(data2)
    trials = size(data,3);
    data1 = data(:, :, 1:floor(trials/2));
    data2 = data(:, :, floor(trials/2)+1:end);
end

alph = 1-alph;

%preallocate
if gpuOn
    tstat_res=zeros(size(data1,1), size(data1,2), xshuffles, 'single', 'gpuArray');
    tstat_max=zeros(xshuffles,1, 'single', 'gpuArray');
else
    tstat_res=zeros(size(data1,1), size(data1,2), xshuffles, 'single');
    tstat_max=zeros(xshuffles,1, 'single');
end
%difftot=zeros(size(data1,1), size(data1,2), xshuffles);
est_p=struct;

%if the iti is not as large as the trial length, add a mirrored end to the iti. NOT SET UP FOR OTHER WAY
%AROUND AS IF THE TRIAL IS NOT LONG ENOUGH, MIRRORING WOULD OVER ESTIMATE
%THE NOISE IN THE ITI, I THINK.
if size(data2,1)<size(data1,1)
    extr=size(data1,1)-size(data2,1)-1;
    temp=data2(end-extr:end, :, :);
    data2_temp=cat(1,temp, data2);
else
    data2_temp=data2;
end

L1 = size(data1, 3);
L2 = size(data2, 3);

profile on
%%
tt=tic;
no_sig=0;
for ii=1:xshuffles
   clear rct
   clear rct_d
   clear clust_sum
    %combine the data
    totdata=cat(3, data1, data2_temp);
    %shuffle it randomly
    totdata=totdata(:,:,randperm(size(totdata,3)));
    %take the means
    mean1=nanmean(totdata(:,:,1:L1),3);
    mean2=nanmean(totdata(:,:,L1+1:end),3);
    %run the guts of a ttest2 (much faster than the built in function)
    sp=sqrt(((L1-1)*std(totdata(:,:,1:L1),0,3).^2+(L2-1)*std(totdata(:,:,L1+1:end),0,3).^2)./(L1+L2-2));
    tstat_res(:,:, ii)=(mean1-mean2)./(sp*sqrt(1/L1+1/L2));        
    tsr_p=2*tcdf(-abs(tstat_res(:,:,ii)), (L1+L2-2)); %get the p values for adjustment, taking abs because it won't matter here whether + or -
   
    %% find the max t stat mass (meaning the sum of the t stats in the max area using image recognition using bwconncomp)
    thresh_binary=tsr_p<0.01; %this is where it counts how many shuffled chunks are large enough to meet criteria
    
    if nnz(thresh_binary)==0
        no_sig=no_sig+1; %count how many times no significant t stats show up
        continue
    else
        tstat_temp=gather(tstat_res(:,:,ii));
        thresh_binaryd=gather(thresh_binary); %there is a gpu version that is not as fast or as good.
        clust=bwconncomp(thresh_binaryd,8);
        cl=regionprops(clust); %get the region properties
        cl_a=[cl.Area];
        [~,max_idx]=max(cl_a); %get the index of the largest cluster
        max_mat=false(size(thresh_binaryd));
        max_mat(clust.PixelIdxList{max_idx})=true;
        tstat_max(ii)=sum(abs(tstat_temp(max_mat))); %get the sum of the stats in that max area        
    end
end
toc(tt)

tstat_max=gather(tstat_max);

%find the alpha level
temp_tsm=sort(tstat_max);
thresh=temp_tsm(round(size(tstat_max,1)*alph));

%%
if plt
    figure
    histogram(temp_tsm, xshuffles)
end

   
end
