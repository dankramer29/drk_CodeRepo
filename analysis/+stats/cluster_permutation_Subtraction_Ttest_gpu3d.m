function [ mnd1, mnd2, sd1, sd2, largestCluster, tstatPos_sumsStatSig, tstatNeg_sumsStatSig, thresholds] = cluster_permutation_Subtraction_Ttest_gpu3d( data1, data1iti, data2, data2iti, varargin )
%USE THIS ONE
% 
% shuffle_stats shuffles the data between two data sets takes the mean and
%std to make a distribution of the data to compare the true values to using
% SPECIFICALLY THIS ONE WILL TAKE A SUBTRACTION OF TOTAL CLUSTER AMOUNT AND
% THEN COMPARE THOSE SUBTRACTIONS AGAINST SHUFFLED SUBTRACTIONS. THE IDEA
% IS TO COMPARE CLUSTERS THAT DON'T NEED TO OVERLAP OR HAVE MORE SUBTLE
% DIFFERENCES, I.E. AN EFFECT AT BOTH POINTS.
%a cluster approach
%   Takes two vectors of data and shuffles the data points, calculates the
%   means of the two new, shuffled groups, and takes the difference between
%   those means.  Does that xshuffles number of times and tells where your
%   actual difference in means falls on that distribution.
% %OUTPUT:
%     mn- the mean of data1 and data2 
%     sd- the std of data1 and data2 
%     sigclust- the mask of the significant clusters (the largest cluster)
%     of positive. if you want to know if one of them is statistically
%     significant it is recorded here.
%     centroid- the centroid of the largest clusters
%     tstatSum- the sum of the tstat in the largest cluster
%     boundingBox - bounding box of the largest cluster
%     allClusterNumbers- 
%     tstatDiff- the subtraction of the tstat of the largest clusters for
%     data 1 and data 2
%     dataLargerPos/Neg- says whether data1 or data2 is larger for the
%     positive and the negative clusters
%     thresholds- if you make a single threshold from the iti data and want
%     to return that to be used for future iterations.
%     sigclustNeg- option to output the negative clusters which currently
%     i'm not using


[varargin, plt]=util.argkeyval('plt', varargin, false); %option to plot the historgram
[varargin, xshuffles]=util.argkeyval('xshuffles', varargin, 1000); %how many shuffles you want to do, default is 5k
%adjust the alpha level that the permutations are compared to, meaning the percentile on the histogram, over which something is considered positive
%0.00024 is 0.05/(64*3+20) the number of electrodes for the real touch
[varargin, alph]=util.argkeyval('alph', varargin, 0.05); %sets the alpha for the shuffle (NOT THE HISTOGRAM)
[varargin, alphaHisto]=util.argkeyval('alphaHisto', varargin, 0.05); %sets the alpha for histogram (i.e. the real alpha)
[varargin, gpuOn]=util.argkeyval('gpuOn', varargin, true); %turn on gpu or not. appears to be faster as of 2023
[varargin, tt]=util.argkeyval('tt', varargin, []); %include a tplot if you want to plot
[varargin, ff]=util.argkeyval('ff', varargin, []); %include a freq if you want to plot
[varargin, splitPosNeg]=util.argkeyval('splitPosNeg', varargin, 1); %if you want to split positive and negative deflections into own one tailed ttest. 0 is no and will do one tailed ttest on abs of data
[varargin, percentageOfMaxCluster]=util.argkeyval('percentageOfMaxCluster', varargin, 0.25); %sometimes clusters cover nearly the entire time frequency plot (all connected) so this gives them a size max. Set the percentage of the total possible that they can be
[varargin, HzThresholdPos]=util.argkeyval('HzThresholdPos', varargin, 20); %if there is a lot of large clusters at the lower frequencies due to smearing, cut off any where the centroid is below this value, make it 1 if you don't want any.
[varargin, HzThresholdNeg]=util.argkeyval('HzThresholdNeg', varargin, 1); %if there is a lot of large clusters at the lower frequencies due to smearing, cut off any where the centroid is below this value, make it 1 if you don't want any.
[varargin, zscoreAcrossAllData]=util.argkeyval('zscoreAcrossAllData', varargin, 1); %z score across the whole data set instead of later by section
[varargin, flipData]=util.argkeyval('flipData', varargin, 1); %flip some of the data on the time axis to really shuffle it up.
[varargin, timeSmearMean]=util.argkeyval('timeSmearMean', varargin, 0); %this is an option to take the mean and std across time. the point here is the the comparison group of itis may have random ups and downs at specific time points, so this equalizes the mean and variance for one frequency across time.
[varargin, allITIdata]=util.argkeyval('allITIdata', varargin, 1); %this makes the shuffled data entirely built on iti

%an option to build a histogram where you enter data1 and data2 as just
%itis or itis and all trials and then just shuffle it up to build the
%histogram and then it will load in the thresholds, provide a set of either
%the one threshold if positive and negative not set or the positive and the
%negative thresholds
[varargin, histogramBuiltThresholds]=util.argkeyval('histogramBuiltThresholds', varargin, []); 

largestCluster = struct; %for output

util.argempty(varargin); % check all additional inputs have been processed

alphaHistoAdj = 1-alphaHisto;
alphaHistoHalf = alphaHistoAdj+(alphaHisto/2); %two tailed split


%% if setting up thresholds built from clusters in pure iti
if ~isempty(histogramBuiltThresholds)
    if splitPosNeg
        if size(histogramBuiltThresholds,2) < 4
            error('need two entries for histogramBuiltThresholds, one for positive and one for negative')
        end
        threshP1 = histogramBuiltThresholds(1,1); threshP2 = histogramBuiltThresholds(1,2);
        threshN1 = histogramBuiltThresholds(2,1); threshN2 = histogramBuiltThresholds (2,2);

        if ~splitPosNeg
            thresh = histogramBuiltThresholds;
        end
    end
end

%find a max cluster size that it shouldn't be over. this prevents a cluster
%from being some weird noise thing that makes a cluster be 50% or more of
%the time frequency plot
maxCluster = size(data1,1) * size(data1,2);
maxClusterPercentage = maxCluster*percentageOfMaxCluster; %cluster shouldn't be bigger than 50%

%preallocate
if gpuOn %last check on gpu was 34 without and 8 with. bwconncomp doesn't work with gpu...
    tstat_res=zeros(size(data1,1), size(data1,2), xshuffles, 'single');
    tstat_max=zeros(xshuffles,1, 'single');
    tstat_res = gpuArray(tstat_res);
    tstat_max = gpuArray(tstat_max);
else
    tstat_res=zeros(size(data1,1), size(data1,2), xshuffles, 'single');
    tstat_max=zeros(xshuffles,1, 'single');
end

%tstat1_maxP = tstat_max; tstat1_maxN = tstat_max; tstat2_maxP = tstat_max; tstat2_maxN = tstat_max;
%difftot=zeros(size(data1,1), size(data1,2), xshuffles);
est_p=struct;
centroid = []; centroidPos = []; centroidNeg = []; boundingBox = []; boundingBoxPos = []; boundingBoxNeg = [];
allClusterNumbers = []; allClusterNumbersPos = []; allClusterNumbersNeg = []; 

%if the iti is not as large as the trial length, add a mirrored end to the iti.
if size(data1iti,2)<size(data1,2)
    extr=ceil(size(data1,2)/size(data1iti,2));
    data1iti_temp = data1iti;
    for ii = 1:extr
        if mod(ii,2) %if odd numbered
            temp = flip(data1iti,2);
        else
            temp = data1iti;
        end
        data1iti_temp = cat(2,data1iti_temp, temp);
    end
    
    data1iti_temp(:,size(data1,2)+1:end,:) = [];
else
    data1iti_temp = data1iti;
end

%if the iti is not as large as the trial length, add a mirrored end to the iti.
if size(data2iti,2)<size(data2,2)
    extr=ceil(size(data2,2)/size(data2iti,2));
    data2iti_temp = data2iti;
    for ii = 1:extr
        if mod(ii,2) %if odd numbered
            temp = flip(data2iti,2);
        else
            temp = data2iti;
        end
        data2iti_temp = cat(2,data2iti_temp, temp);
    end
    
    data2iti_temp(:,size(data2,2)+1:end,:) = [];
else
    data2iti_temp = data2iti;
end


L1 = size(data1, 3);
L1iti = size(data1iti, 3);
L2 = size(data2, 3);
L2iti = size(data2iti, 3);

%option to z score across all the data.
if zscoreAcrossAllData
    a1Temp = mean(data1,3);
    a1 = mean(a1Temp, 2);
    a2Temp = mean(data1iti_temp,3);
    a2 = mean(a2Temp,2);
    %combined means
    combined_a = (a1+a2)/2;
    for jj= 1:size(data1,1)
        temp = data1(jj,:,:);
        stdT = std(temp(:));
        b1(jj,1) = stdT;
    end
    for jj= 1:size(data1iti_temp,1)
        temp = data1iti(jj,:,:);
        stdT = std(temp(:));
        b2(jj,1) = stdT;
    end
    %combined standard deviation formula
    combined_b = sqrt(((L1 - 1) * b1.^2 + (L1iti - 1) * b2.^2) / (L1 + L1iti - 2));
    data1T = (data1-combined_a)./combined_b;
    data1itiT = (data1iti_temp-combined_a)./combined_b;

    % data 2
    a1Temp = mean(data2,3);
    a1 = mean(a1Temp, 2);
    a2Temp = mean(data2iti_temp,3);
    a2 = mean(a2Temp,2);
    %combined means
    combined_a = (a1+a2)/2;
    for jj= 1:size(data2,1)
        temp = data2(jj,:,:);
        stdT = std(temp(:));
        b1(jj,1) = stdT;
    end
    for jj= 1:size(data2iti_temp,1)
        temp = data2iti(jj,:,:);
        stdT = std(temp(:));
        b2(jj,1) = stdT;
    end
    %combined standard deviation formula
    combined_b = sqrt(((L2 - 1) * b1.^2 + (L2iti - 1) * b2.^2) / (L2 + L2iti - 2));
    data2T = (data2-combined_a)./combined_b;
    data2itiT = (data2iti_temp-combined_a)./combined_b;
else
    data1T = data1;
    data1itiT = data1iti_temp;
    data2T = data2;
    data2itiT = data2iti_temp;
end

%CHANGE HERE back to data1 and data1iti_temp to go back to what it was.
if gpuOn
    data1 = gpuArray(data1T);
    data1iti_temp = gpuArray(data1itiT);
    data2 = gpuArray(data2T);
    data2iti_temp = gpuArray(data2itiT);
end

profile on
%%
no_sig=0;
%can toggle on and build one histogram of shuffled clusters
if isempty(histogramBuiltThresholds)
    tt=tic;
    for ii=1:xshuffles
        clear rct
        clear rct_d
        clear clust_sum
        %combine the data
        %shuffle it randomly
        if allITIdata == 1 %toggle on if you want an entirely iti built cluster difference. keeps the L1 the same which shouldn't be an issue
            totdata=cat(3, data1iti_temp, data1iti_temp);
        else
            totdata=cat(3, data1, data1iti_temp);
        end

        totdata=totdata(:,:,randperm(size(totdata,3)));
        %flip half of the data around to really mix it up
        if flipData
            for rr = 1:size(totdata,3)/2
                kk = randi(size(totdata,3));
                totdata(:,:,kk) = flip(totdata(:,:,kk),2);
            end
        end
        %take the means
        mean1=nanmean(totdata(:,:,1:L1),3);
        mean2=nanmean(totdata(:,:,L1+1:end),3);
        %option to smear across time so fluctuations in the iti data don't
        %alter the primary data clusters.
        if timeSmearMean
            mean2temp = nanmean(mean2,2);
            mean2All = repmat(mean2temp, 1, size(mean2,2));
            stdev1 = std(totdata(:,:,1:L1),0,3);
            stdev2 = std(totdata(:,:,L1+1:end),0,3);
            stdev2temp = std(stdev2, 0, 2);
            stdev2All = repmat(stdev2temp, 1, size(stdev2,2));
            sp=sqrt(((L1-1)*stdev1.^2+(L1iti-1)*stdev2All.^2)./(L1+L1iti-2));
            tstat_res(:,:, ii)=(mean1-mean2All)./(sp*sqrt(1/L1+1/L1iti));
        else
            %run the guts of a ttest2 (much faster than the built in function)
            sp=sqrt(((L1-1)*std(totdata(:,:,1:L1),0,3).^2+(L1iti-1)*std(totdata(:,:,L1+1:end),0,3).^2)./(L1+L1iti-2));
            tstat_res(:,:, ii)=(mean1-mean2)./(sp*sqrt(1/L1+1/L1iti));
        end

        tsr_pNeg=2*tcdf((tstat_res(:,:,ii)), (L1+L1iti-2)); %get the p values for adjustment, for just negative deflections
        tsr_pPos=2*tcdf(-(tstat_res(:,:,ii)), (L1+L1iti-2)); %get the p values for adjustment, for just positive deflections
        tsr_p=2*tcdf(-abs(tstat_res(:,:,ii)), (L1+L1iti-2)); %if want to combine, do abs because it won't matter here whether + or -

        %% find the max t stat mass (meaning the sum of the t stats in the max area using image recognition using bwconncomp)
        thresh_binaryN = tsr_pNeg<alph/2; %finds the negative deflections
        thresh_binaryP = tsr_pPos<alph/2; %finds the positive deflections
        thresh_binary=tsr_p<alph; %this is where it counts how many shuffled chunks are large enough to meet criteria

        if nnz(thresh_binary)==0
            no_sig=no_sig+1; %count how many times no significant t stats show up
            continue
        else
            tstat_temp=gather(tstat_res(:,:,ii));
            thresh_binaryd=gather(thresh_binary);%there is a gpu version that is not as fast or as good.
            thresh_binarydP=gather(thresh_binaryP);
            thresh_binarydN=gather(thresh_binaryN);


            if splitPosNeg
                %cluster positive deflections separately
                clustP=bwconncomp(thresh_binarydP,8);
                if clustP.NumObjects>=1
                    clP=regionprops(clustP); %get the region properties
                    cl_aP=[clP.Area];
                    cl_aP(cl_aP>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
                    for cii = 1:height(clP)
                        if clP(cii).Centroid(1,2)<20 %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
                            cl_aP(cii) = 1;
                            xx(cii) = cii;
                        end
                    end
                    [~,max_idxP]=max(cl_aP); %get the index of the largest cluster
                    max_matP=false(size(thresh_binarydP));
                    max_matP(clustP.PixelIdxList{max_idxP})=true;
                    tstat1_maxP(ii)=sum(abs(tstat_temp(max_matP))); %get the sum of the stats in that max area
                    %for test plotting
                    % mean1n = normalize(mean1,2);
                    % mean2n = normalize(mean2,2);
                    % if ii == 1
                    %     figure
                    % end
                    % subplot(4,1,1)
                    % imagesc(mean1n); axis xy;
                    % subplot(4,1,2)
                    % imagesc(mean2n); axis xy;
                    % subplot(4,1,3)
                    % imagesc(thresh_binaryP); axis xy;
                    % subplot(4,1,4)
                    % imagesc(max_matP); axis xy;
                    %put a stop just below here and open tstat_maxP to see how
                    %each fake cluster is falling.
                else
                    tstat1_maxP(ii) = 1;
                end

                %cluster negative deflections separately
                clustN=bwconncomp(thresh_binarydN,8);
                if clustN.NumObjects>=1
                    clN=regionprops(clustN); %get the region properties
                    cl_aN=[clN.Area];
                    cl_aN(cl_aN>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
                    [~,max_idxN]=max(cl_aN); %get the index of the largest cluster
                    max_matN=false(size(thresh_binarydN));
                    max_matN(clustN.PixelIdxList{max_idxN})=true;
                    tstat1_maxN(ii,1)=sum(abs(tstat_temp(max_matN))); %get the sum of the stats in that max area
                else
                    tstat1_maxN(ii,1) = 1;
                end
            else
                %cluster two tailed (both positive and negative) separately
                if clust.NumObjects>=1
                    clust=bwconncomp(thresh_binaryd,8);
                    cl=regionprops(clust); %get the region properties
                    cl_a=[cl.Area];
                    cl_a(cl_a>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
                    [~,max_idx]=max(cl_a); %get the index of the largest cluster
                    max_mat=false(size(thresh_binaryd));
                    max_mat(clust.PixelIdxList{max_idx})=true;
                    tstat1_max(ii)=sum(abs(tstat_temp(max_mat))); %get the sum of the stats in that max area
                else
                    tstat_max(ii) = 1;
                end
            end
        end
        %% do this again for data 2
        clear rct
        clear rct_d
        clear clust_sum
        %combine the data
        %shuffle it randomly
        if allITIdata == 1 %toggle on if you want an entirely iti built cluster difference. keeps the L1 the same which shouldn't be an issue
            totdata2=cat(3, data2iti_temp, data2iti_temp);
        else
            totdata2=cat(3, data2, data2iti_temp);
        end
        totdata2=totdata2(:,:,randperm(size(totdata2,3)));
        %flip half of the data around to really mix it up
        if flipData
            for rr = 1:size(totdata2,3)/2
                kk = randi(size(totdata2,3));
                totdata2(:,:,kk) = flip(totdata2(:,:,kk),2);
            end
        end
        %take the means
        mean1=nanmean(totdata2(:,:,1:L2),3);
        mean2=nanmean(totdata2(:,:,L2+1:end),3);
        %option to smear across time so fluctuations in the iti data don't
        %alter the primary data clusters.
        if timeSmearMean
            mean2temp = nanmean(mean2,2);
            mean2All = repmat(mean2temp, 1, size(mean2,2));
            stdev1 = std(totdata2(:,:,1:L2),0,3);
            stdev2 = std(totdata2(:,:,L2+1:end),0,3);
            stdev2temp = std(stdev2, 0, 2);
            stdev2All = repmat(stdev2temp, 1, size(stdev2,2));
            sp=sqrt(((L2-1)*stdev1.^2+(L2iti-1)*stdev2All.^2)./(L2+L2iti-2));
            tstat_res(:,:, ii)=(mean1-mean2All)./(sp*sqrt(1/L2+1/L2iti));
        else
            %run the guts of a ttest2 (much faster than the built in function)
            sp=sqrt(((L2-1)*std(totdata2(:,:,1:L2),0,3).^2+(L2iti-1)*std(totdata2(:,:,L2+1:end),0,3).^2)./(L2+L2iti-2));
            tstat_res(:,:, ii)=(mean1-mean2)./(sp*sqrt(1/L2+1/L2iti));
        end

        tsr_pNeg=2*tcdf((tstat_res(:,:,ii)), (L2+L2iti-2)); %get the p values for adjustment, for just negative deflections
        tsr_pPos=2*tcdf(-(tstat_res(:,:,ii)), (L2+L2iti-2)); %get the p values for adjustment, for just positive deflections
        tsr_p=2*tcdf(-abs(tstat_res(:,:,ii)), (L2+L2iti-2)); %if want to combine, do abs because it won't matter here whether + or -

        %% find the max t stat mass (meaning the sum of the t stats in the max area using image recognition using bwconncomp)
        thresh_binaryN = tsr_pNeg<alph/2; %finds the negative deflections
        thresh_binaryP = tsr_pPos<alph/2; %finds the positive deflections
        thresh_binary=tsr_p<alph; %this is where it counts how many shuffled chunks are large enough to meet criteria

        if nnz(thresh_binary)==0
            no_sig=no_sig+1; %count how many times no significant t stats show up
            continue
        else
            tstat_temp=gather(tstat_res(:,:,ii));
            thresh_binaryd=gather(thresh_binary);%there is a gpu version that is not as fast or as good.
            thresh_binarydP=gather(thresh_binaryP);
            thresh_binarydN=gather(thresh_binaryN);
            

            if splitPosNeg
                %cluster positive deflections separately
                clustP=bwconncomp(thresh_binarydP,8);
                if clustP.NumObjects>=1
                    clP=regionprops(clustP); %get the region properties
                    cl_aP=[clP.Area];
                    cl_aP(cl_aP>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
                    for cii = 1:height(clP)
                        if clP(cii).Centroid(1,2)<20 %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
                            cl_aP(cii) = 1;
                            xx(cii) = cii;
                        end
                    end
                    [~,max_idxP]=max(cl_aP); %get the index of the largest cluster
                    max_matP=false(size(thresh_binarydP));
                    max_matP(clustP.PixelIdxList{max_idxP})=true;
                    tstat2_maxP(ii,1)=sum(abs(tstat_temp(max_matP))); %get the sum of the stats in that max area
                    %for test plotting
                    % mean1n = normalize(mean1,2);
                    % mean2n = normalize(mean2,2);
                    % if ii == 1
                    %     figure
                    % end
                    % subplot(4,1,1)
                    % imagesc(mean1n); axis xy;
                    % subplot(4,1,2)
                    % imagesc(mean2n); axis xy;
                    % subplot(4,1,3)
                    % imagesc(thresh_binaryP); axis xy;
                    % subplot(4,1,4)
                    % imagesc(max_matP); axis xy;
                    %put a stop just below here and open tstat_maxP to see how
                    %each fake cluster is falling.
                else
                    tstat2_maxP(ii,1) = 1;
                end
                %do the subtraction of the two cluster sizes
                tstat_maxPDiff(ii,1) = tstat1_maxP(ii)- tstat2_maxP(ii);

                %cluster negative deflections separately
                clustN=bwconncomp(thresh_binarydN,8);
                if clustN.NumObjects>=1
                    clN=regionprops(clustN); %get the region properties
                    cl_aN=[clN.Area];
                    cl_aN(cl_aN>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
                    [~,max_idxN]=max(cl_aN); %get the index of the largest cluster
                    max_matN=false(size(thresh_binarydN));
                    max_matN(clustN.PixelIdxList{max_idxN})=true;
                    tstat2_maxN(ii,1)=sum(abs(tstat_temp(max_matN))); %get the sum of the stats in that max area


                else
                    tstat2_maxN(ii,1) = 1;
                end
                %do the subtraction of the two cluster sizes
                tstat_maxNDiff(ii,1) = tstat1_maxN(ii,1)- tstat2_maxN(ii,1);
            else
                %cluster two tailed (both positive and negative) separately
                if clust.NumObjects>=1
                    clust=bwconncomp(thresh_binaryd,8);
                    cl=regionprops(clust); %get the region properties
                    cl_a=[cl.Area];
                    cl_a(cl_a>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
                    [~,max_idx]=max(cl_a); %get the index of the largest cluster
                    max_mat=false(size(thresh_binaryd));
                    max_mat(clust.PixelIdxList{max_idx})=true;
                    tstat2_max(ii,1)=sum(abs(tstat_temp(max_mat))); %get the sum of the stats in that max area
                else
                    tstat2_max(ii,1) = 1;
                end
                %do the subtraction of the two cluster sizes
                tstat_maxDiff(ii,1) = tstat1_max(ii,1)- tstat2_max(ii,1);
            end
        end
    end
        toc(tt)
end

%%
%get the real mean difference and sd at each value
%Time smear takes the mean and time across everything. not using anymore. 
if timeSmearMean 
    mnd1=nanmean(data1,3);
    mnd2=nanmean(data1itiT,3); %includes the mirrored part if not the same size
    mean2temp = nanmean(mnd2,2);
    mean2All = repmat(mean2temp, 1, size(mnd2,2));
    sd1=std(data1,0,3);
    sd2=std(data1itiT,0,3);
    stdev2temp = std(sd2, 0, 2);
    std2All = repmat(stdev2temp, 1, size(sd2,2));
    sp=sqrt(((L1-1)*sd1.^2+(L1iti-1)*std2All.^2)./(L1+L1iti-2));
    tstat_R=(mnd1-mean2All)./(sp*sqrt(1/L1+1/L1iti));
    tstat_R=gather(tstat_R);
else
    mnd1=nanmean(data1,3);
    mnd2=nanmean(data1itiT,3); %includes the mirrored part if not the same size
    sd1=std(data1,0,3);
    sd2=std(data1itiT,0,3);
    spR=sqrt(((L1-1)*sd1.^2+(L1iti-1)*sd2.^2)./(L1+L1iti-2));
    tstat_R=(mnd1-mnd2)./(spR*sqrt(1/L1+1/L1iti));
    tstat_R=gather(tstat_R);
end
%tstat_Rabs=abs(tstat_R); %take absolute for adjustment. makes negative deflections and positive deflections of equal value. don't do this if there is a difference between the degrees of positive and negative deflections



%% find which clusters are sig
%% first data set
%allocate
sigclust=zeros(size(tstat_R));
%%
if splitPosNeg
    sigclustPos=zeros(size(tstat_R));
    sigclustNeg=zeros(size(tstat_R));
    tstat1_maxP=gather(tstat1_maxP);
    tstat1_maxN=gather(tstat1_maxN);
    r_pvalueNeg=2*tcdf((tstat_R), (L1+L1iti-2)); %Gets the p values for negative deflections (two tailed), straight from ttest
    r_pvaluePos=2*tcdf(-(tstat_R), (L1+L1iti-2)); %Gets the p values for positive deflections (two tailed),

    %%
    %begin clustering with bwconncomp
    thresh_binaryRPos=r_pvaluePos<alph/2;%find those less than set p value
    thresh_binaryRNeg=r_pvalueNeg<alph/2;%find those less than set p value

    %REPEAT THIS FOR EACH
    clustRPos1=bwconncomp(thresh_binaryRPos,8);
    clRPos1=regionprops(clustRPos1, 'all'); %get the region properties
    cl_aRPos1=[clRPos1.Area];
    cl_aRPos1(cl_aRPos1>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
    for cii = 1:height(clRPos1)
        if clRPos1(cii).Centroid(1,2)<HzThresholdPos %remove any that are below the 20hz threshold
            cl_aRPos1(cii) = 1;
            xx(cii) = cii;
        end
    end
    cl_keepPos1=find(cl_aRPos1>50); %get the ones with an area >50 pixels   
    tstatPos_sumsStatSig = []; tstat_sumsN = [];   
    if ~isempty(cl_keepPos1)
        for ii=1:length(cl_keepPos1)
            matPos=false(size(thresh_binaryRPos));
            matPos(clustRPos1.PixelIdxList{cl_keepPos1(ii)})=true;
            tstat1_sumsPos(ii,1)=sum(abs(tstat_R(matPos)));
        end
    else
        tstat1_sumsPos = 0;
    end
    %% for plotting if you want
    figure
    subplot(5,2,1)
    title('mean of data 1')
    imagesc(normalize(mnd1,2)); axis xy;
    subplot(5,2,3)
    title('mean of iti data 1')
    imagesc(normalize(mnd2,2)); axis xy;
    subplot(5,2,5)
    title('positive pixels data 1')
    imagesc(thresh_binaryRPos); axis xy;    
    %%
    clustRNeg1=bwconncomp(thresh_binaryRNeg,8);
    clRNeg1=regionprops(clustRNeg1); %get the region properties
    cl_aRNeg1=[clRNeg1.Area];
    cl_aRNeg1(cl_aRNeg1>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
    for cii = 1:height(clRNeg1)
        if clRNeg1(cii).Centroid(1,2)<HzThresholdNeg %remove any that are below the a hz threshold
            cl_aRNeg1(cii) = 1;
            xx(cii) = cii;
        end
    end
    cl_keepNeg1=find(cl_aRNeg1>50); %get the ones with an area >100 pixels
    if ~isempty(cl_keepNeg1)
        for ii=1:length(cl_keepNeg1)
            matNeg=false(size(thresh_binaryRNeg));
            matNeg(clustRNeg1.PixelIdxList{cl_keepNeg1(ii)})=true;
            tstat1_sumsNeg(ii,1)=sum(abs(tstat_R(matNeg)));
        end
    else
        tstat1_sumsNeg = 0;
    end
   
    
else
    if isempty(histogramBuiltThresholds)
        tstat1_max=gather(tstat1_max);
        temp_tsm=sort(tstat1_max);
        thresh=temp_tsm(round(size(tstat1_max,1)*alphaHistoAdj));
    end
    r_pvalue=2*tcdf(-abs(tstat_R), (L1+L1iti-2)); %get the p values for both adjustments (makes it one tailed), this formula is straight from ttest2

    thresh_binaryR=r_pvalue<alph;%find those less than set p value
    clustR1=bwconncomp(thresh_binaryR,8);
    clR1=regionprops(clustR1); %get the region properties
    cl_aR1=[clR1.Area];
    cl_aR1(cl_aR1>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
    for cii = 1:height(clR1)
        if clR1(cii).Centroid(1,2)<HzThresholdPos %remove any that are below the 20hz threshold
            cl_aR1(cii) = 1;
            xx(cii) = cii;
        end
    end
    cl_keep1=find(cl_aR1>50); %get the ones with an area >100 pixels
    idxc=1;
    for ii=1:length(cl_keep1)
        mat=false(size(thresh_binaryR));
        mat(clustR1.PixelIdxList{cl_keep1(ii)})=true;
        tstat_sums(ii)=sum(abs(tstat_R(mat)));

        if tstat_sums(ii)>thresh %save the ones that are over the thresh
            sigclust(clustR1.PixelIdxList{cl_keep1(ii)})=idxc;
            centroid(idxc,1:2) = clR1(cl_keep1(ii)).Centroid;
            boundingBox(idxc,1:4) = clR1(cl_keep1(ii)).BoundingBox;
            allClusterNumbers{idcx,1} =  clR1(cl_keepNeg1(ii));
            tstatSum(idxc,1) = tstat_sums(ii);
            idxc=idxc+1;
        end
    end
    thresholds = thresh;
end

%% second data set

if timeSmearMean 
    mnd1=nanmean(data2,3);
    mnd2=nanmean(data2itiT,3); %includes the mirrored part if not the same size
    mean2temp = nanmean(mnd2,2);
    mean2All = repmat(mean2temp, 1, size(mnd2,2));
    sd1=std(data2,0,3);
    sd2=std(data2itiT,0,3);
    stdev2temp = std(sd2, 0, 2);
    std2All = repmat(stdev2temp, 1, size(sd2,2));
    sp=sqrt(((L2-1)*sd1.^2+(L2iti-1)*std2All.^2)./(L2+L2iti-2));
    tstat_R=(mnd1-mean2All)./(sp*sqrt(1/L2+1/L2iti));
    tstat_R=gather(tstat_R);
else
    mnd1=nanmean(data2,3);
    mnd2=nanmean(data2itiT,3); %includes the mirrored part if not the same size
    sd1=std(data2,0,3);
    sd2=std(data2itiT,0,3);
    spR=sqrt(((L2-1)*sd1.^2+(L2iti-1)*sd2.^2)./(L2+L2iti-2));
    tstat_R=(mnd1-mnd2)./(spR*sqrt(1/L2+1/L2iti));
    tstat_R=gather(tstat_R);
end
%tstat_Rabs=abs(tstat_R); %take absolute for adjustment. makes negative deflections and positive deflections of equal value. don't do this if there is a difference between the degrees of positive and negative deflections
%% find which clusters are sig
%allocate
sigclust=zeros(size(tstat_R));
%%
if splitPosNeg
    sigclustPos=zeros(size(tstat_R));
    sigclustNeg=zeros(size(tstat_R));
    tstat2_maxP=gather(tstat2_maxP);
    tstat2_maxN=gather(tstat2_maxN);
    r_pvalueNeg=2*tcdf((tstat_R), (L2+L2iti-2)); %Gets the p values for negative deflections (two tailed), straight from ttest
    r_pvaluePos=2*tcdf(-(tstat_R), (L2+L2iti-2)); %Gets the p values for positive deflections (two tailed),

    %% find the histogram alpha of differences for each
    if isempty(histogramBuiltThresholds)
        %this is for positive deflections and then can be either positive
        %(data1>data2) or reverse 
        temp_tsmP=sort(tstat_maxPDiff);
        threshP1=temp_tsmP(round(size(tstat_maxPDiff,1)*alphaHistoHalf)); %this is positive so means data 1 is > data 2
        threshP2=temp_tsmP(round(size(tstat_maxPDiff,1)*(1-alphaHistoHalf))); %this is negative so means data 1 is < data 2
        %this is for negative deflections and then can be either positive
        %(data1>data2) or reverse
        temp_tsmN=sort(tstat_maxNDiff);        
        threshN1=temp_tsmN(round(size(tstat_maxNDiff,1)*alphaHistoHalf));%this is positive so means data 1 is > data 2
        threshN2=temp_tsmN(round(size(tstat_maxNDiff,1)*(1-alphaHistoHalf))); %this is negative so means data 1 is < data 2
    end
    thresholds(1,1) = threshP1; thresholds(1,2) = threshP2;
    thresholds(2,1) = threshN1; thresholds(2,2) = threshN2;   
  

    %%
    %begin clustering with bwconncomp
    thresh_binaryRPos=r_pvaluePos<alph/2;%find those less than set p value
    thresh_binaryRNeg=r_pvalueNeg<alph/2;%find those less than set p value

    %REPEAT THIS FOR EACH
    clustRPos2=bwconncomp(thresh_binaryRPos,8);
    clRPos2=regionprops(clustRPos2, 'all'); %get the region properties
    cl_aRPos2=[clRPos2.Area];
    cl_aRPos2(cl_aRPos2>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
    for cii = 1:height(clRPos2)
        if clRPos2(cii).Centroid(1,2)<HzThresholdPos %remove any that are below the 20hz threshold
            cl_aRPos2(cii) = 1;
            xx(cii) = cii;
        end
    end
    cl_keepPos2=find(cl_aRPos2>50); %get the ones with an area >50 pixels
    if ~isempty(cl_keepPos2)
        for ii=1:length(cl_keepPos2)
            matPos=false(size(thresh_binaryRPos));
            matPos(clustRPos2.PixelIdxList{cl_keepPos2(ii)})=true;
            tstat2_sumsPos(ii,1)=sum(abs(tstat_R(matPos)));
        end
    else
        tstat2_sumsPos(1,1) = 0;
    end
    %% will want to take the biggest cluster and subtract the biggest
    %%cluster here. 
    [maxP1, maxP1i] = max(tstat1_sumsPos);
    [maxP2, maxP2i] = max(tstat2_sumsPos);
    %for testing, comment out when not in use
    % figure
    % subplot(2,1,1)
    % matPosT=false(size(thresh_binaryRPos));
    % matPosT(clustRPos1.PixelIdxList{cl_keepPos1(maxP1i)})=true;
    % imagesc(matPosT), axis xy;
    % subplot(2,1,2)
    % matPosT2=false(size(thresh_binaryRPos));
    % matPosT2(clustRPos2.PixelIdxList{cl_keepPos2(maxP2i)})=true;
    % imagesc(matPosT2), axis xy;


    tstatDiff_Pos = max(tstat1_sumsPos) - max(tstat2_sumsPos);
    %this is to save the two biggest positive clusters. this can be used
    %for plotting or for saving.
    idxT = 1;
    sigclustPosTemp1 = false(size(thresh_binaryRPos));
    sigclustPosTemp2 = false(size(thresh_binaryRPos));
    if tstat1_sumsPos==0 %in the event there are no clusters that meet criteria
        largestCluster.Positive(1).ClusterPixels = 0; %save the cluster list
        largestCluster.Positive(1).Tstat_Sum = 0;
        largestCluster.Positive(1).Centroid(1,1:2) = 0;
        largestCluster.Positive(1).BoundingBox(1,1:4) = 0;
    else
        sigclustPosTemp1(clustRPos1.PixelIdxList{cl_keepPos1(maxP1i)})=idxT; %the idxT here is an option to do more than one cluster (start it at 1 and change as you go)
        idxT = idxT+1;
        largestCluster.Positive(1).ClusterPixels = sigclustPosTemp1; %save the cluster list
        largestCluster.Positive(1).Tstat_Sum = tstat1_sumsPos(maxP1i);
        largestCluster.Positive(1).Centroid(1,1:2) = clRPos1(cl_keepPos1(maxP1i)).Centroid;
        largestCluster.Positive(1).BoundingBox(1,1:4) = clRPos1(cl_keepPos1(maxP1i)).BoundingBox;
    end
    if tstat2_sumsPos == 0
        largestCluster.Positive(2).ClusterPixels = 0; %save the cluster list
        largestCluster.Positive(2).Tstat_Sum = 0;
        largestCluster.Positive(2).Centroid(1,1:2) = 0;
        largestCluster.Positive(2).BoundingBox(1,1:4) = 0;
    else
        sigclustPosTemp2(clustRPos2.PixelIdxList{cl_keepPos2(maxP2i)})=idxT;
        largestCluster.Positive(2).ClusterPixels = sigclustPosTemp2;
        largestCluster.Positive(2).Tstat_Sum = tstat2_sumsPos(maxP2i);
        largestCluster.Positive(2).Centroid(1,1:2) = clRPos2(cl_keepPos2(maxP2i)).Centroid;
        largestCluster.Positive(2).BoundingBox(1,1:4) = clRPos2(cl_keepPos2(maxP2i)).BoundingBox;
    end
    if tstatDiff_Pos>threshP1 %save if over the thresh for data 1 (tail of data1>data2)
        tstatPos_sumsStatSig = 1; %mark whether it's data 1 that is positive or data 2
    elseif tstatDiff_Pos<threshP2 %save if over the thresh for data 2 (tail of data1<data2)
        tstatPos_sumsStatSig = 2;        
    else       
        tstatPos_sumsStatSig = 0;
    end
    largestCluster.Positive(1).TstatDiff = tstatDiff_Pos;
    largestCluster.Positive(2).TstatDiff = tstatPos_sumsStatSig; %record which one is the significant
    %% for plotting if you want
    % figure
    % subplot(4,1,1)
    % imagesc(normalize(mnd1,2)); axis xy;
    % subplot(4,1,2)
    % imagesc(normalize(mnd2,2)); axis xy;
    % subplot(4,1,3)
    % imagesc(thresh_binaryRPos); axis xy;
    % subplot(4,1,4)
    % imagesc(matPos); axis xy;\
    
    %this is another plotting strategy that will show the data1 left and
    %data2 right
    subplot(5,2,2)
    title('same data 2')
    imagesc(normalize(mnd1,2)); axis xy;
    subplot(5,2,4)
    imagesc(normalize(mnd2,2)); axis xy;
    subplot(5,2,6)
    imagesc(thresh_binaryRPos); axis xy;

    %the biggest clusters
    subplot(5,2,7)
    title('positive biggest cluster')
    matPosT=false(size(thresh_binaryRPos));
    if ~isempty(cl_keepPos1)
        matPosT(clustRPos1.PixelIdxList{cl_keepPos1(maxP1i)})=true;
    end
    imagesc(matPosT), axis xy;
    subplot(5,2,8)
    matPosT2=false(size(thresh_binaryRPos));
    if ~isempty(cl_keepPos2)
        matPosT2(clustRPos2.PixelIdxList{cl_keepPos2(maxP2i)})=true;
    end
    imagesc(matPosT2), axis xy;


    clustRNeg2=bwconncomp(thresh_binaryRNeg,8);
    clRNeg2=regionprops(clustRNeg2); %get the region properties
    cl_aRNeg2=[clRNeg2.Area];
    cl_aRNeg2(cl_aRNeg2>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
    for cii = 1:height(clRNeg2)
        if clRNeg2(cii).Centroid(1,2)<HzThresholdNeg %remove any that are below the a hz threshold
            cl_aRNeg2(cii) = 1;
            xx(cii) = cii;
        end
    end
    cl_keepNeg2=find(cl_aRNeg2>50); %get the ones with an area >100 pixels
    if ~isempty(cl_keepNeg2)
        for ii=1:length(cl_keepNeg2)
            matNeg=false(size(thresh_binaryRNeg));
            matNeg(clustRNeg2.PixelIdxList{cl_keepNeg2(ii)})=true;
            tstat2_sumsNeg(ii,1)=sum(abs(tstat_R(matNeg)));
        end
    else
        tstat2_sumsNeg(1,1) = 0;
    end
    [maxN1, maxN1i] = max(tstat1_sumsNeg);
    [maxN2, maxN2i] = max(tstat2_sumsNeg);
    tstatDiff_Neg = max(tstat1_sumsNeg) - max(tstat2_sumsNeg); %DOUBLE CHECK THIS NEEDS TO BE ABS OR NOT. I THINK NOT
    %TO DO, SAVE ALL BIGGEST CLUSTERS, WHETHER OR NOT THEY ARE POSITIVE SO
    %YOU CAN GROUP THEM ALL LATER. ALSO BUILD IN TO MAKE THE CLUST DIFF
    %JUST THE ITI
    idxT = 1;
    sigclustNegTemp1 = false(size(thresh_binaryRPos));
    sigclustNegTemp2 = false(size(thresh_binaryRPos));
    if tstat1_sumsNeg==0 %in the event no clusters meet criteria for negative deflections
        largestCluster.Negative(1).ClusterPixels = 0;
        largestCluster.Negative(1).Tstat_Sum = 0;
        largestCluster.Negative(1).Centroid(1,1:2) = 0;
        largestCluster.Negative(1).BoundingBox(1,1:4) = 0;        
    else
        sigclustNegTemp1(clustRNeg1.PixelIdxList{cl_keepNeg1(maxN1i)})=idxT; %the idxT here is an option to do more than one cluster (start it at 1 and change as you go)
        idxT = idxT+1;
        largestCluster.Negative(1).ClusterPixels = sigclustNegTemp1; %save the cluster list
        largestCluster.Negative(1).Tstat_Sum = tstat1_sumsNeg(maxN1i);
        largestCluster.Negative(1).Centroid(1,1:2) = clRNeg1(cl_keepNeg1(maxN1i)).Centroid;
        largestCluster.Negative(1).BoundingBox(1,1:4) = clRNeg1(cl_keepNeg1(maxN1i)).BoundingBox;
    end
    if tstat2_sumsNeg==0
        largestCluster.Negative(2).ClusterPixels = 0;
        largestCluster.Negative(2).Tstat_Sum = 0;
        largestCluster.Negative(2).Centroid(1,1:2) = 0;
        largestCluster.Negative(2).BoundingBox(1,1:4) = 0;        
    else
        sigclustNegTemp2(clustRNeg2.PixelIdxList{cl_keepNeg2(maxN2i)})=idxT;
        largestCluster.Negative(2).ClusterPixels = sigclustNegTemp2;
        largestCluster.Negative(2).Tstat_Sum = tstat2_sumsNeg(maxN2i);
        largestCluster.Negative(2).Centroid(1,1:2) = clRNeg2(cl_keepNeg2(maxN2i)).Centroid;
        largestCluster.Negative(2).BoundingBox(1,1:4) = clRNeg2(cl_keepNeg2(maxN2i)).BoundingBox;
    end
    if tstatDiff_Neg>threshN1 %save if over the thresh for data 1 (tail of data1>data2)
        tstatNeg_sumsStatSig = 1; %mark whether it's data 1 that is positive or data 2
    elseif tstatDiff_Neg<threshN2 %save if over the thresh for data 2 (tail of data1<data2)
        tstatNeg_sumsStatSig = 2;        
    else       
        tstatNeg_sumsStatSig = 0;
    end
    largestCluster.Negative(1).TstatDiff = tstatDiff_Neg;
    largestCluster.Negative(2).TstatDiff = tstatNeg_sumsStatSig; %record which one is the significant
    
else %have not fixed this (so commented out)! generally splitting positive and negative right now
    % if isempty(histogramBuiltThresholds)
    %     tstat_max=gather(tstat_max);
    %     temp_tsm=sort(tstat_max);
    %     thresh=temp_tsm(round(size(tstat_max,1)*alphaHistoAdj));
    % end
    % r_pvalue=2*tcdf(-abs(tstat_R), (L1+L1iti-2)); %get the p values for both adjustments (makes it one tailed), this formula is straight from ttest2
    % 
    % thresh_binaryR=r_pvalue<alph;%find those less than set p value
    % clustR1=bwconncomp(thresh_binaryR,8);
    % clR1=regionprops(clustR1); %get the region properties
    % cl_aR1=[clR1.Area];
    % cl_aR1(cl_aR1>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
    % for cii = 1:size(clR1)
    %     if clR1(cii).Centroid(1,2)<HzThresholdPos %remove any that are below the 20hz threshold
    %         cl_aR1(cii) = 1;
    %         xx(cii) = cii;
    %     end
    % end
    % cl_keep1=find(cl_aR1>50); %get the ones with an area >100 pixels
    % idxc=1;
    % for ii=1:length(cl_keep1)
    %     mat=false(size(thresh_binaryR));
    %     mat(clustR1.PixelIdxList{cl_keep1(ii)})=true;
    %     tstat_sums(ii)=sum(abs(tstat_R(mat)));
    % 
    %     if tstat_sums(ii)>thresh %save the ones that are over the thresh
    %         sigclust(clustR1.PixelIdxList{cl_keep1(ii)})=idxc;
    %         centroid(idxc,1:2) = clR1(cl_keep1(ii)).Centroid;
    %         boundingBox(idxc,1:4) = clR1(cl_keep1(ii)).BoundingBox;
    %         allClusterNumbers{idcx,1} =  clR1(cl_keepNeg1(ii));
    %         tstatSum(idxc,1) = tstat_sums(ii);
    %         idxc=idxc+1;
    %     end
    % end
    % thresholds = thresh;
end


%for testing
% lab=labelmatrix(clustR);
% lab=lab';
% rlab=label2rgb(lab,@spring,'c','shuffle');
% bonc=0.05/(size(mnd1,1)*size(mnd1,2));
% rlab=r_pvalue<bonc;
%%
%if plt
    subplot(5,2,9)
    title('histogram, red = ns blue = sig')
    histogram(tstat_maxPDiff, xshuffles)
    hold on
    if tstatPos_sumsStatSig>0 
        plot([tstatDiff_Pos, tstatDiff_Pos], [0, 20], 'Color', 'b', 'LineWidth', 1)
    else
        plot([tstatDiff_Pos, tstatDiff_Pos], [0, 20], 'Color', 'r', 'LineWidth', 1)
    end
%end





end
