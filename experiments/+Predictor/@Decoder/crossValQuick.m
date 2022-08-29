function [R2cv,B,R2,p,cc]=crossValQuick(obj,x,Z,cvParams)


% by default enforce train size>=2500
Nsamples=size(x,2)-1;

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

% I want the test set to be contiguous in time,
%%
testStartInd=linspace(1,Nsamples,nFolds+1);
%%
for i=1:length(testStartInd)-1;
    testingSets=floor(testStartInd(i):testStartInd(i+1)-2);
    trainingSets=setdiff(1:Nsamples,testingSets);
    
    % [obj(i),fitMeas(i)]=bmi_offLineTest(x, z,trainingSets{i},testingSets{i},filterOptions);
    
    B(i,:)=[Z(:,trainingSets)'\x(trainingSets)']';
    
    cc(i)=corr((B(i,:)*Z(:,testingSets))',x(testingSets)');
    R2cv(i)=cc(i).^2;
    R2(i)=corr((B(i,:)*Z(:,trainingSets))',x(trainingSets)').^2;
    
end

% test
[h,p,ci,stats]=ttest(cc);