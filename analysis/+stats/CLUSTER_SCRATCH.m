xx = totdata(:,:,1);
xxx = flip(xx,2);
figure
imagesc(normalize(xxx,2)); axis xy;

[ mnd1, mnd2, sd1, sd2, sigclust, centroid, tstatSum, rlab, thresholds] = stats.cluster_permutation_Ttest_gpu3d( itiDataEm, itiDataId, 'xshuffles', 100);

matPos=false(size(thresh_binaryRPos));
matPos(clustRPos.PixelIdxList{cl_keepPos(2)})=true;

mean1n = normalize(mean1,2);
mean2n = normalize(mean2,2);
figure
subplot(4,1,1)
imagesc(mean1n); axis xy;
subplot(4,1,2)
imagesc(mean2n); axis xy;
subplot(4,1,3)
imagesc(tsr_p); axis xy;
subplot(4,1,4)
imagesc(max_matP); axis xy;

%TAKE THE STANDARD DEVIATION ACROSS THE FREQUENCIES AND THE MEAN ACROSS THE
%FREQUENCIES AND SEE IF THAT CHANGES WHAT IS POSITIVE.
figure
subplot(4,1,1)
imagesc(normalize(mnd1,2)); axis xy;
subplot(4,1,2)
imagesc(normalize(mnd2,2)); axis xy;
subplot(4,1,3)
imagesc(thresh_binaryRPos); axis xy;
subplot(4,1,4)
imagesc(tstat_R); axis xy;


figure
imagesc(normalize(sd1,2)); axis xy;

mean2Temp = nanmean(mnd2,2);
mean2T = repmat(mean2Temp, 1, size(mean2,2));
sd2Temp = std(sd2,0,2);
sd2T = repmat(sd2Temp, 1, size(mean2,2));

mnd1=nanmean(data1,3);
mnd2=nanmean(data2_temp,3); %includes the mirrored part if not the same size
sd1=std(data1,0,3);
sd2=std(data2_temp,0,3);

spR=sqrt(((L1-1)*sd1.^2+(L2-1)*sd2T.^2)./(L1+L2-2));
tstat_R=(mnd1-mean2T)./(spR*sqrt(1/L1+1/L2));
tstat_R=gather(tstat_R);
%tstat_Rabs=abs(tstat_R); %take absolute for adjustment. makes negative deflections and positive deflections of equal value. don't do this if there is a difference between the degrees of positive and negative deflections
%% find which clusters are sig
%allocate
sigclust=zeros(size(tstat_R));


sigclustPos=zeros(size(tstat_R));
    sigclustNeg=zeros(size(tstat_R));
    tstat_maxP=gather(tstat_maxP);
    tstat_maxN=gather(tstat_maxN);
    r_pvalueNeg=2*tcdf((tstat_R), (L1+L2-2)); %Gets the p values for negative deflections (two tailed), straight from ttest
    r_pvaluePos=2*tcdf(-(tstat_R), (L1+L2-2)); %Gets the p values for positive deflections (two tailed),

%begin clustering with bwconncomp
    thresh_binaryRPos=r_pvaluePos<alph/2;%find those less than set p value
    thresh_binaryRNeg=r_pvalueNeg<alph/2;%find those less than set p value

    %REPEAT THIS FOR EACH
    clustRPos=bwconncomp(thresh_binaryRPos,8);
    clRPos=regionprops(clustRPos, 'all'); %get the region properties
    cl_aRPos=[clRPos.Area];
    cl_aRPos(cl_aRPos>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
    cl_keepPos=find(cl_aRPos>100); %get the ones with an area >100 pixels

 matPos=false(size(thresh_binaryRPos));
        matPos(clustRPos.PixelIdxList{cl_keepPos(4)})=true;

        figure
subplot(4,1,1)
imagesc(normalize(mnd1,2)); axis xy;
subplot(4,1,2)
imagesc(normalize(mnd2,2)); axis xy;
subplot(4,1,3)
imagesc(thresh_binaryRPos); axis xy;
subplot(4,1,4)
imagesc(sigclust); axis xy;
    %%
figure
imagesc(mean2); axis xy;

figure
imagesc(mean2T(:,:)); axis xy;
totdata=cat(3, data1, data2_temp);
    %shuffle it randomly
    totdata=totdata(:,:,randperm(size(totdata,3)));
    totdata = normalize(totdata,2);
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
                cl_aN(cl_aN>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
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
                cl_a(cl_a>maxClusterPercentage) = 1; %remove any that are over the cluster max percentage (meaning not massive clusters that are the whole time frequency analysis)
                [~,max_idx]=max(cl_a); %get the index of the largest cluster
                max_mat=false(size(thresh_binaryd));
                max_mat(clust.PixelIdxList{max_idx})=true;
                tstat_max(ii)=sum(abs(tstat_temp(max_mat))); %get the sum of the stats in that max area
            else
                tstat_max(ii) = 1;
            end
        end
    end