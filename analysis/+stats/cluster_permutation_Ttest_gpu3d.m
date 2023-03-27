function [ mnd1, mnd2, sd1, sd2, sigclust, centroid, tstatSum, rlab ] = cluster_permutation_Ttest_gpu3d( data1, data2, varargin )
%USE THIS ONE
% 
% shuffle_stats shuffles the data between two data sets takes the mean and
%std to make a distribution of the data to compare the true values to using
%
%a cluster approach
%   Takes two vectors of data and shuffles the data points, calculates the
%   means of the two new, shuffled groups, and takes the difference between
%   those means.  Does that xshuffles number of times and tells where your
%   actual difference in means falls on that distribution.
% %OUTPUT:
%     mn- the mean of data1 and data2 
%     sd- the std of data1 and data2 
%     est_p-the percentage of the distribution that is farther out than yours
%     with the assumption that if it's less than 0.05, it's significant


[varargin, plt]=util.argkeyval('plt', varargin, false); %option to plot the historgram
[varargin, xshuffles]=util.argkeyval('xshuffles', varargin, 100); %how many shuffles you want to do, default is 5k
%adjust the alpha level that the permutations are compared to, meaning the percentile on the histogram, over which something is considered positive
%0.00024 is 0.05/(64*3+20) the number of electrodes for the real touch
[varargin, alph]=util.argkeyval('alph', varargin, 0.05); %sets the alpha for the shuffle (NOT THE HISTOGRAM)
[varargin, alphaHisto]=util.argkeyval('alphaHisto', varargin, 0.05); %sets the alpha for histogram (i.e. the real alpha)
[varargin, gpuOn]=util.argkeyval('gpuOn', varargin, false); %turn on gpu or not
[varargin, tt]=util.argkeyval('tt', varargin, []); %include a tplot if you want to plot
[varargin, ff]=util.argkeyval('ff', varargin, []); %include a freq if you want to plot
[varargin, splitPosNeg]=util.argkeyval('splitPosNeg', varargin, 1); %if you want to split positive and negative deflections into own one tailed ttest. 0 is no and will do one tailed ttest on abs of data


util.argempty(varargin); % check all additional inputs have been processed

alphaHistoAdj = 1-alphaHisto;
alphaHistoHalf = alphaHistoAdj+(alphaHisto/2); %two tailed split

%calculate the size of the samples you want to take, default is just over
%half

%preallocate
if gpuOn
    tstat_res=zeros(size(data1,1), size(data1,2), xshuffles, 'single', 'gpuArray');
    tstat_max=zeros(xshuffles,1, 'single', 'gpuArray');
else
    tstat_res=zeros(size(data1,1), size(data1,2), xshuffles, 'single');
    tstat_max=zeros(xshuffles,1, 'single');
end

tstat_maxP = tstat_max; tstat_maxN = tstat_max;
%difftot=zeros(size(data1,1), size(data1,2), xshuffles);
est_p=struct;
centroid = []; centroidPos = []; centroidNeg = [];

%if the iti is not as large as the trial length, add a mirrored end to the iti.
if size(data2,2)<size(data1,2)
    extr=ceil(size(data1,2)/size(data2,2));
    data2_temp = data2;
    for ii = 1:extr
        if mod(ii,2) %if odd numbered
            temp = flip(data2,2);
        else
            temp = data2;
        end
        data2_temp = cat(2,data2_temp, temp);
    end
    
    data2_temp(:,size(data1,2)+1:end,:) = [];
else
    data2_temp = data2;
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
    tsr_pNeg=2*tcdf((tstat_res(:,:,ii)), (L1+L2-2)); %get the p values for adjustment, for just negative deflections
    tsr_pPos=2*tcdf(-(tstat_res(:,:,ii)), (L1+L2-2)); %get the p values for adjustment, for just positive deflections
    tsr_p=2*tcdf(-abs(tstat_res(:,:,ii)), (L1+L2-2)); %if want to combine, do abs because it won't matter here whether + or -

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
                [~,max_idxP]=max(cl_aP); %get the index of the largest cluster
                max_matP=false(size(thresh_binarydP));
                max_matP(clustP.PixelIdxList{max_idxP})=true;
                tstat_maxP(ii)=sum(abs(tstat_temp(max_matP))); %get the sum of the stats in that max area
            else
                tstat_maxP(ii) = 1;
            end

            %cluster negative deflections separately
            clustN=bwconncomp(thresh_binarydN,8);
            if clustN.NumObjects>=1
                clN=regionprops(clustN); %get the region properties
                cl_aN=[clN.Area];
                [~,max_idxN]=max(cl_aN); %get the index of the largest cluster
                max_matN=false(size(thresh_binarydN));
                max_matN(clustN.PixelIdxList{max_idxN})=true;
                tstat_maxN(ii)=sum(abs(tstat_temp(max_matN))); %get the sum of the stats in that max area
            else
                tstat_maxN(ii) = 1;
            end
        else
            %cluster two tailed (both positive and negative) separately
            if clust.NumObjects>=1
                clust=bwconncomp(thresh_binaryd,8);
                cl=regionprops(clust); %get the region properties
                cl_a=[cl.Area];
                [~,max_idx]=max(cl_a); %get the index of the largest cluster
                max_mat=false(size(thresh_binaryd));
                max_mat(clust.PixelIdxList{max_idx})=true;
                tstat_max(ii)=sum(abs(tstat_temp(max_mat))); %get the sum of the stats in that max area
            else
                tstat_max(ii) = 1;
            end
        end
    end
end
toc(tt)

%%
%get the real mean difference and sd at each value
mnd1=nanmean(data1,3);
mnd2=nanmean(data2_temp,3); %includes the mirrored part if not the same size
sd1=std(data1,0,3);
sd2=std(data2_temp,0,3);
spR=sqrt(((L1-1)*sd1.^2+(L2-1)*sd2.^2)./(L1+L2-2));
tstat_R=(mnd1-mnd2)./(spR*sqrt(1/L1+1/L2));
tstat_R=gather(tstat_R);
%tstat_Rabs=abs(tstat_R); %take absolute for adjustment. makes negative deflections and positive deflections of equal value. don't do this if there is a difference between the degrees of positive and negative deflections
%% find which clusters are sig
%allocate
sigclust=zeros(size(tstat_R));
%%
if splitPosNeg
    sigclustPos=zeros(size(tstat_R));
    sigclustNeg=zeros(size(tstat_R));
    tstat_maxP=gather(tstat_maxP);
    tstat_maxN=gather(tstat_maxN);
    r_pvalueNeg=2*tcdf((tstat_R), (L1+L2-2)); %Gets the p values for negative deflections (two tailed), straight from ttest
    r_pvaluePos=2*tcdf(-(tstat_R), (L1+L2-2)); %Gets the p values for positive deflections (two tailed),

    %% find the 0.05 level
    temp_tsmP=sort(tstat_maxP);
    threshP=temp_tsmP(round(size(tstat_maxP,1)*alphaHistoHalf));
    temp_tsmN=sort(tstat_maxN);
    threshN=temp_tsmN(round(size(tstat_maxN,1)*alphaHistoHalf));


    %%
    %begin clustering with bwconncomp
    thresh_binaryRPos=r_pvaluePos<alph/2;%find those less than set p value
    thresh_binaryRNeg=r_pvalueNeg<alph/2;%find those less than set p value

    %REPEAT THIS FOR EACH
    clustRPos=bwconncomp(thresh_binaryRPos,8);
    clRPos=regionprops(clustRPos, 'all'); %get the region properties
    cl_aRPos=[clRPos.Area];
    cl_keepPos=find(cl_aRPos>100); %get the ones with an area >100 pixels
    idxc=1; idxd=1;
    tstat_sumsP = []; tstat_sumsN = [];
    for ii=1:length(cl_keepPos)
        matPos=false(size(thresh_binaryRPos));
        matPos(clustRPos.PixelIdxList{cl_keepPos(ii)})=true;
        tstat_sumsPos(ii)=sum(abs(tstat_R(matPos)));

        if tstat_sumsPos(ii)>threshP %save the ones that are over the thresh
            sigclustPos(clustRPos.PixelIdxList{cl_keepPos(ii)})=idxd;
            centroidPos(idxc,1:2) = clRPos(cl_keepPos(ii)).Centroid;
            tstat_sumsP(idxc,1) = tstat_sumsPos(ii);
            idxc=idxc+1; idxd=idxd+1;
        end
    end
    clustRNeg=bwconncomp(thresh_binaryRNeg,8);
    clRNeg=regionprops(clustRNeg); %get the region properties
    cl_aRNeg=[clRNeg.Area];
    cl_keepNeg=find(cl_aRNeg>100); %get the ones with an area >100 pixels
    idxc=1;
    for ii=1:length(cl_keepNeg)
        matNeg=false(size(thresh_binaryRNeg));
        matNeg(clustRNeg.PixelIdxList{cl_keepNeg(ii)})=true;
        tstat_sumsNeg(ii)=sum(abs(tstat_R(matNeg)));

        if tstat_sumsNeg(ii)>threshN %save the ones that are over the thresh
            sigclustNeg(clustRNeg.PixelIdxList{cl_keepNeg(ii)})=idxd;
            centroidNeg(idxc,1:2) = clRNeg(cl_keepNeg(ii)).Centroid;
            tstat_sumsN(idxc,1) = tstat_sumsNeg(ii);
            idxc=idxc+1; idxd=idxd+1;
        end
    end
    centroid = vertcat(centroidPos, centroidNeg);
    tstatSum = vertcat(tstat_sumsP, tstat_sumsN);
    sigclust = sigclustPos + sigclustNeg;
else
    tstat_max=gather(tstat_max);
    temp_tsm=sort(tstat_max);
    thresh=temp_tsm(round(size(tstat_max,1)*alphaHistoAdj));
    r_pvalue=2*tcdf(-abs(tstat_R), (L1+L2-2)); %get the p values for both adjustments (makes it one tailed), this formula is straight from ttest2

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

        if tstat_sums(ii)>thresh %save the ones that are over the thresh
            sigclust(clustR.PixelIdxList{cl_keep(ii)})=idxc;
            centroid(idxc,1:2) = clR(cl_keep(ii)).Centroid;
            tstatSum(idxc,1) = tstat_sums(ii);
            idxc=idxc+1;
        end
    end
end




%for testing
% lab=labelmatrix(clustR);
% lab=lab';
% rlab=label2rgb(lab,@spring,'c','shuffle');
% bonc=0.05/(size(mnd1,1)*size(mnd1,2));
% rlab=r_pvalue<bonc;
%%
if plt
    figure
    histogram(tstat_maxP, xshuffles)
end


end
