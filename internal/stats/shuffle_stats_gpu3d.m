function [ mnd1, mnd2, sd1, sd2, est_p ] = shuffle_stats_gpu3d( data1, data2, varargin )
%shuffle_stats shuffles the data between two data sets takes the mean and
%std to make a distribution of the data to compare the true values to.
%   Takes two vectors of data and shuffles the data points, calculates the
%   means of the two new, shuffled groups, and takes the difference between
%   those means.  Does that xshuffles number of times and tells where your
%   actual difference in means falls on that distribution.
% %OUTPUT:
%     mn- the mean of data1 and data2 
%     sd- the std of data1 and data2 
%     est_p-the percentage of the distribution that is farther out than yours
%     with the assumption that if it's less than 0.05, it's significant

tic;
[varargin, plt]=util.argkeyval('plt', varargin, false); %option to plot the historgram
[varargin, xshuffles]=util.argkeyval('xshuffles', varargin, 10000); %how many shuffles you want to do, default is 10k

util.argempty(varargin); % check all additional inputs have been processed

%calculate the size of the samples you want to take, default is just over
%half
L1=size(data1,3);
%preallocate
difftot=zeros(size(data1,1), size(data1,2), xshuffles, 'single', 'gpuArray');
%difftot=zeros(size(data1,1), size(data1,2), xshuffles);
est_p=struct;



for ii=1:xshuffles
    totdata=cat(3, data1, data2);
    totdata=totdata(:,:,randperm(size(totdata,3)));
    mean1=mean(totdata(:,:,1:L1),3);
    mean2=mean(totdata(:,:,L1+1:end),3);
    difftot(:, :, ii)=abs(mean1-mean2);
     
     
    
    %totdata=vertcat(data1, data2);
    %totdata=totdata(randperm(length(totdata)));
    %temp1=totdata(1:L1);
    %temp2=totdata(L1+1:end);
    %mean1=mean(temp1);
    %mean2=mean(temp2);
    %difftot=mean1-mean2;
   
end

difftot=gather(difftot);
%get the real mean difference and sd at each value
mnd1=mean(data1,3);
mnd2=mean(data2,3);
sd1=std(data1);
sd2=std(data2);
diffR=abs(mnd1-mnd2);
%find which are significant
templog=bsxfun(@lt,difftot,diffR);
est_p.pvalue=sum(templog,3)/size(difftot,3);

% for ii=1:size(difftot,1)
%     parfor jj=1:size(difftot,2)
%         
%         if diffR(ii,jj)<0
%             templog(ii,jj)=nnz(difftot(ii,jj, :)<=diffR(ii,jj))/xshuffles;
%         else
%             templog(ii,jj)=nnz(difftot(ii,jj, :)>=diffR(ii,jj))/xshuffles;
%         end
%     end
% end

est_p.sig=est_p.pvalue<0.05;
est_p.anynonsig=~nnz(est_p.sig);
%%
if plt
    histogram(difftot, xshuffles)
end
toc;    
end

