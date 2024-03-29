function [ dataCombPosThresh, dataCombNegThresh, threshAlpha, tstat_max ] = cluster_shuffleMeanBaseline_gpu3d( data1, varargin )
%USE THIS ONE OR CLUSTER_PERMUTATION_TTEST_GPU3D
% The idea here is to just figure out the range of normal, then find
% clusters of when it goes over that.

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
%      data1 -matrix  of spectrogram data. data should be the
%      entire data set minus noise
%      (not currently set up for 2d data, but probably should in the
%      future)
%      optional data2 -matrix of data, desiring to compare to this set.
%      this is ideal if you are getting a shuffled derived baseline for
%      iti.
% %OUTPUT:
%     thresh- the threshold a cluster needs to be above to be significant
%     
%       [testT] = stats.cluster_shuffleMeanBaseline_gpu3d(S1, 'data2', S2, 'trialLength', size(S2,2));


[varargin, data2]=util.argkeyval('data2', varargin, []); %can input a second data set to compare. 
[varargin, SDsize]=util.argkeyval('SDsize', varargin, 0); %how many SDs above the mean you want to set your "positive" at
[varargin, shuffleOn]=util.argkeyval('shuffleOn', varargin, 1); %toggle on to take a bunch of shuffles from the data
[varargin, comparisonOn]=util.argkeyval('comparisonOn', varargin, 1); %toggle on to compare a data set to the threshold.
[varargin, trialLength]=util.argkeyval('trialLength', varargin, []); %give a trial length the size of the data chunks. make the size of the epochs in samples

[varargin, plt]=util.argkeyval('plt', varargin, false); %option to plot the historgram
[varargin, xshuffles]=util.argkeyval('xshuffles', varargin, 100); %how many shuffles you want to do, default is 5k
[varargin, alph]=util.argkeyval('alph', varargin, 0.05); %alpha for calculating the histogram 
[varargin, gpuOn]=util.argkeyval('gpuOn', varargin, false); %turn on gpu or not
[varargin, tt]=util.argkeyval('tt', varargin, []); %include a tplot if you want to plot
[varargin, ff]=util.argkeyval('ff', varargin, []); %include a freq if you want to plot
[varargin, threshAlpha]=util.argkeyval('thresh', varargin, []); %allow a threshold from a shuffle run to fill this in.


util.argempty(varargin); % check all additional inputs have been processed

if isempty(threshAlpha) && shuffleOn == 0
    error('need to either run shuffleOn or provide threshold')
end

alph = 1-alph;


dataMeanAllt = mean(data1,2);
dataMeanAll = repmat(dataMeanAllt, 1, trialLength);


dataSDAllt = std(data1, [], 2);
dataSDAll = repmat(dataSDAllt, 1, trialLength);


dataCombPosThresh = dataMeanAll + dataSDAll*SDsize;

dataCombNegThresh = dataMeanAll - dataSDAll*SDsize;



if shuffleOn

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
%don't think i neeed any of this
%     %if the iti is not as large as the trial length, add a mirrored end to the iti. NOT SET UP FOR OTHER WAY
%     %AROUND AS IF THE TRIAL IS NOT LONG ENOUGH, MIRRORING WOULD OVER ESTIMATE
%     %THE NOISE IN THE ITI, I THINK.
%     if size(data2,1)<size(data1,1)
%         extr=size(data1,1)-size(data2,1)-1;
%         temp=data2(end-extr:end, :, :);
%         data2_temp=cat(1,temp, data2);
%     else
%         data2_temp=data2;
%     end
% 
%     L1 = size(data1, 3);
%     L2 = size(data2, 3);

    

    profile on
    %%
    tt=tic;
    no_sig=0;
    for ii=1:xshuffles
        clear rct
        clear rct_d
        clear clust_sum
        clear thresh_binaryP; clear thresh_binaryN;
        dataSh = stats.shuffleDerivedBaseline(data1, 'trialLength', trialLength, 'trials', 18);
        dataShMean = mean(dataSh, 3);
        

        dataShSD = std(dataSh, [], 3);
        %check if any is above or below the threshold
        thresh_binaryP = dataShMean - dataShSD*2 > dataCombPosThresh; 
        thresh_binaryN = dataShMean + dataShSD*2 < dataCombNegThresh; 

        thresh_binary = thresh_binaryP + thresh_binaryN;

% 
%         
%         tstat_res(:,:, ii)=(mean1-mean2)./(sp*sqrt(1/L1+1/L2));
%         tsr_p=2*tcdf(-abs(tstat_res(:,:,ii)), (L1+L2-2)); %get the p values for adjustment, taking abs because it won't matter here whether + or -
% 
%         %% find the max t stat mass (meaning the sum of the t stats in the max area using image recognition using bwconncomp)
%         thresh_binary=tsr_p<0.01; %this is where it counts how many shuffled chunks are large enough to meet criteria

        if nnz(thresh_binary)==0
            no_sig=no_sig+1; %count how many times no significant t stats show up
            continue
        else
%             tstat_temp=gather(tstat_res(:,:,ii));
%             thresh_binaryd=gather(thresh_binary); %there is a gpu version that is not as fast or as good.
            clust=bwconncomp(thresh_binary,8);
            cl=regionprops(clust); %get the region properties
            cl_a=[cl.Area];
            [~,max_idx]=max(cl_a); %get the index of the largest cluster
            max_mat=false(size(thresh_binary));
            max_mat(clust.PixelIdxList{max_idx})=true;
            tstat_max(ii)=sum(abs(dataShMean(max_mat))); %get the sum of the power in that max area
        end
    end
    toc(tt)

    tstat_max=gather(tstat_max);

    %find the alpha level
    temp_tsm=sort(tstat_max);
    threshAlpha=temp_tsm(round(size(tstat_max,1)*alph));

    %%
    if plt
        figure
        histogram(temp_tsm, xshuffles)
    end
end
%%
if comparisonOn
    data2Mean = mean(data2, 3);
    data2SD = std(data2, [], 3);
    %check if any is above or below the threshold
    thresh_binaryP = data2Mean - data2SD*2 > dataCombPosThresh;
    thresh_binaryn = data2Mean + data2SD*2 < dataCombNegThresh;

    thresh_binary = thresh_binaryP + thresh_binaryN;
    %%
    sigclust=zeros(size(dataShMean));

    %%
    %begin clustering with bwconncomp
    
    clustR=bwconncomp(thresh_binary,8);
    clR=regionprops(clustR); %get the region properties
    cl_aR=[clR.Area];
    cl_keep=find(cl_aR>100); %get the ones with an area >100 pixels
    idxc=1;
    for ii=1:length(cl_keep)
        mat=false(size(thresh_binaryR));
        mat(clustR.PixelIdxList{cl_keep(ii)})=true;
        tstat_sums(ii)=sum(abs(dataShMean(mat)));

        if tstat_sums(ii)>threshAlpha %save the ones that are over the thresh
            sigclust(clustR.PixelIdxList{cl_keep(ii)})=idxc;
            idxc=idxc+1;
        end
    end
end

end