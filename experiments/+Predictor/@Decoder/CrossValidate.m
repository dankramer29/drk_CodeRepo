function [R2cv,B,R2,p,cc,resid]=CrossValidate(obj,PRED,RESP,cvParams)


% by default enforce train size>=2500
Nsamples=size(RESP,2)-1;

if nargin<4
    minTestSize=obj.decoderParams.cvOptions.minTestSize;
    nFolds=obj.decoderParams.cvOptions.nFolds;
    minTrainSize=obj.decoderParams.cvOptions.minTrainSize;
else
    nFolds=cvParams{1};
    minTrainSize=cvParams{2};
    minTestSize=cvParams{3};
end

% if (minTestSize+minTrainSize)>Nsamples
%     error(obj.frameworkParams.msgName, 'crossValQuick Not enough data to perform cross validation using specified or default number of samples for training and testing sets')
%     return
% end
%
% if Nsamples/nFolds<minTestSize
%     error(obj.frameworkParams.msgName,'crossValQuick Too many folds given number of samples and required minTestSize; massage nFolds,minTestSize, amount of data')
%     return
% end
%
% if Nsamples/nFolds*(nFolds-1)<minTrainSize
%     error(obj.frameworkParams.msgName, 'crossValQuick Too many folds given number of samples and required minTrainSize; massage nFolds,minTrainSize, amount of data')
%     return
% end

% use crossvalidation to pick a k.

% I want the test set to be contiguous in time,
testStartInd=linspace(1,Nsamples,nFolds+1);
%%
for i=1:length(testStartInd)-1;
    testingSets=floor(testStartInd(i):testStartInd(i+1)-2);
    trainingSets=setdiff(1:Nsamples,testingSets);
    
    % compute betas
    B(i,:)=FitModel(obj,PRED(:,trainingSets),RESP(trainingSets));
    
    % reconstruct signal
    xFit=(B(i,:)*PRED(:,testingSets))';
    xTrue=RESP(testingSets)';
    
    cc(i)=corr(xFit,xTrue);
    R2cv(i)=cc(i).^2;
    
    R2(i)=corr((B(i,:)*PRED(:,trainingSets))',RESP(trainingSets)').^2;
    
    resid(i,:)=B(i,:)*PRED(:,trainingSets)-RESP(trainingSets);
    
end

% test
[h,p,ci,stats]=ttest(cc);