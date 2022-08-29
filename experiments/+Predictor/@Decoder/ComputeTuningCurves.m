function PopVec=ComputeTuningCurves(obj,trainingData,signalProps,varargin)

tic



%% set defaults for varargin
PlotFit=1;
inputArguements=varargin;

% varagin for trainINDXS allows lagged trainINDXS
trainINDXS=trainingData.trainINDXS;

sX=trainingData.sX;
sZ=trainingData.sZ;
x=trainingData.X;
z=trainingData.Z;

while ~isempty(inputArguements)
    switch lower(inputArguements{1})
        case lower('PlotFit')
            PlotFit=inputArguements{2};
            inputArguements(1:2)=[];
        otherwise
            error('Input %s is not a valid arguement, try again ',inputArguements{1})
    end
end


% CV options
cvParams{1}=10; %nFolds
cvParams{2}=1000; %minTrainSize
cvParams{3}=300; %minTestSize
activeFeatures=signalProps.activeFeatures;



% restrict fit to trainINDXs
if trainINDXS(end) > size(sX,2);
    obj.msgName('trainINDXS specifies a indice that extends beyond the range of the data (probably as a result of testing lags?) Removing offending inds')
    trainINDXS(trainINDXS>size(sX,2))=[];
end
obj.decoderParams.trainINDXS=trainINDXS;

sX=sX(:,trainINDXS);
sZ=sZ(:,trainINDXS);
x=x(:,trainINDXS);
z=z(:,trainINDXS);


% Set kinematics
switch obj.decoderParams.TuningFeatures
    case 'xdx' % position and velocity
        %do nothing
        obj.msgName('Fitting Tuning Model to Position and Velocity')
        
    case 'x' % position
        
        sX=sX(1:2:end,:);
        x=x(1:2:end,:);
        obj.msgName('Fitting Tuning Model to Position')
        
    case 'dx' % velocity
        sX=sX(2:2:end,:);
        x=x(2:2:end,:);
        obj.msgName('Fitting Tuning Model to Velocity')
        
    case 'xdxs' % velocity & speed
        foo=sX(2:2:end,:);
        foo=sqrt(foo.^2);
        sX=[sX;foo];
        
        foo=x(2:2:end,:);
        foo=sqrt(foo.^2);
        x=[x;foo];
        obj.msgName('Fitting Tuning Model to Position, Velocity, and Speed')
    case 'dxs' % speed
        foo=sX(2:2:end,:);
        foo=sqrt(foo.^2);
        sX=[sX(2:2:end,:);foo];
        
        foo=x(2:2:end,:);
        foo=sqrt(foo.^2);
        x=[x(2:2:end,:);foo];
        obj.msgName('Fitting Tuning Model to Velocity and Speed')
        
    case 's' % speed
        foo=sX(2:2:end,:);
        foo=sqrt(foo.^2);
        sX=foo;
        
        foo=x(2:2:end,:);
        foo=sqrt(foo.^2);
        x=[foo];
        obj.msgName('Fitting Tuning Model to Speed')
    otherwise
        error('Specified Tuning Features ''%s'' not a valid option',obj.decoderParams.TuningFeatures)
        
end

% sX=[sX;sX.^2];
% x=[x;x.^2];

sX=[sX;(sX(1,:)*0+1)];
x=[x;(x(1,:)*0+1)];
%%

R2_CVmu=nan*zeros(length(activeFeatures),1);
p=ones(length(activeFeatures),1);
R2_CVse=nan*zeros(length(activeFeatures),1);
R2=nan*zeros(length(activeFeatures),1);
H=zeros(length(activeFeatures),size(sX,1));
% Hcv=zeros(length(activeFeatures),size(sX,1),10);
Hse=inf+zeros(length(activeFeatures),size(sX,1));
% stats=zeros(length(activeFeatures),4)*nan;


finalFitType=obj.decoderParams.fitType;

% finalFitType=obj.decoderParams.fitType;
obj.msgName('Fitting each unit ',0)
for i=1:length(activeFeatures);
    if activeFeatures(i)
        % check each active unit for significance
%         obj.msgName(sprintf('%d,',i),0,0)
        obj.decoderParams.fitType='standard';
        [tmpR2cv,tmpB,tmpR2,p(i),cc]=CrossValidate(obj,sX,sZ(i,:),cvParams);
        
        CC_CVmu(i)=mean(cc);
        CC_CVse(i)=std(cc)/sqrt(cvParams{1});
        
        R2_CVmu(i)=mean(cc).^2;
        R2_CVse(i)=std(tmpR2cv)/sqrt(cvParams{1});
        
        R2(i)=mean(tmpR2);
        Hcv{i}=tmpB;
        Hse(i,:)=std(tmpB,[],1)/sqrt(cvParams{1});
        
        obj.decoderParams.fitType=finalFitType;
        [H(i,:),stats(i)]=FitModel(obj,sX,sZ(i,:));
        
    else
        stats(i).R2=NaN;
        stats(i).cc=NaN;
        Hcv{i}=zeros( cvParams{1},size(H,2));
    end
end
obj.msgName('',1,0);



% %%
% if 1==0
% %%
% figure;
% pnl=panel();
% pnl.pack(3,2)
% pnl(1,1).select();
% hold on
% plot(R2_CVmu,'k.-')
% plot(R2,'r.-')
% plot([stats.R2],'g.-');
% plot([0 size(R2,1)],[.1 .1],'k')
% plot([0 size(R2,1)],[.05 .05],'k--')
% title(sprintf('R2 per unit; %d > .1, %d > .05',nnz(R2>.1),nnz(R2>.05) ))
% legend('CV-test', 'CV-train','train')
% xlim([-1 size(Bc,1)+1])
%
% pnl(1,2).select();
% hold on
% plot(sort(R2_CVmu),'k.-')
% plot([0 size(R2,1)],[.1 .1],'k')
% plot([0 size(R2,1)],[.05 .05],'k--')
% title(sprintf('Sorted R2 per unit; %d > .1, %d > .05',nnz(R2>.1),nnz(R2>.05) ))
% legend('CV-test')
% xlim([-1 size(Bc,1)+1])
%
% pnl(3,2).select();
% hold on
% bar(Bc(:,1:end-1)+Hse(:,1:end-1),.2,'linestyle','none')
% bar(Bc(:,1:end-1)-Hse(:,1:end-1),.2,'linestyle','none')
% bar(Bc(:,1:end-1),'linestyle','none')
% xlim([-1 size(Bc,1)+1])
%
% % errorbar(1:size(z,1),H,Hse)
%
% end
switch obj.decoderParams.TuningFeatures
    case 'xdx' % position and velocity
        H(:,[1 3])=[];
        sX([1 3],:)=[];
        x([1 3],:)=[];
end

% Note, For computing residuals (and therefoir Q), use the unsmoothed data.
residuals=z-H*x;
Q = (1/size(x,2))*(residuals)*(residuals)';
% Q = diag(1./[stats.R2]);

jerk=sum(abs(diff(z',2)/obj.decoderParams.samplePeriod.^2))/size(z,1);

% used smoothed data to compute Q - necassary in circumstances where there
% is very little signal.
sResiduals=sZ-H*sX;
smoothQ = (1/size(x,2))*(sResiduals)*(sResiduals)';

% Q=smoothQ;

muEOut=mean(residuals,2);
sigEOut=std(residuals,[],2);




% some notes, removing significant features before or after inverting
% does not seem to make a difference

signifFeatures=(p<obj.decoderParams.preProcessThreshold & R2_CVmu(:)>.01) & sum(abs(H(:,1:end-1)),2)>0;;
signifFeatures=p<.5;
% signifFeatures=(p<obj.decoderParams.preProcessThreshold) & sum(abs(H(:,1:end-1)),2)>0;
% signifFeatures=sum(abs(H(:,1:end-1)),2)>0;
% note that the inclusion of the sum across H is necassary as the final fit
% using a lasso may squlch the beta values to zero.



%%

% if 1==1 && obj.decoderParams.nDOF==2;
%     foo=R2_CVmu;
%     foo(~signifFeatures)=nan;
%     obj.figureHandles.TuningPlot=figure(110); clf
%     subplot(2,3,1); hold on
%     plot(R2_CVmu,'.')
%     plot(foo,'go')
%     subplot(2,3,4)
%     plot(sort(R2_CVmu),'.')
%     subplot(2,3,[2 3 5 6])
%     Analyze.plotHB(H(:,1:end-1)',find(signifFeatures),2);
% end

% if obj.decoderParams.preProcessForSignificance
%     decodeFeatures = activeFeatures & signifFeatures;
% else
%     decodeFeatures = activeFeatures;
% end


  decodeFeatures = activeFeatures;

%%

if nnz(decodeFeatures)==0
    error('No Signif features...')
end

% restructure cross validated tuning curves
for j=1:length(Hcv)
    for i=1:size(Hcv{1},1);
        CV_H{i}(j,:)=Hcv{j}(i,:);
    end
end

switch obj.decoderParams.TuningFeatures
    case 'xdx' % position and velocity
        for i=1:length(CV_H);
            CV_H{i}(:,[1 3])=[];
        end
end

% switch obj.decoderParams.TuningFeatures
%     case 'xdx' % position and velocity
%         sX=sX(2:2:end,:);
%         x=x(2:2:end,:);
% end
%%
% Crossvalidated test of inversion
Nsamples=size(sX,2);
testStartInd=linspace(1,Nsamples,cvParams{1}+1);
for i=1:length(testStartInd)-1;
    testingSets=floor(testStartInd(i):testStartInd(i+1)-2);
    trainingSets=setdiff(1:Nsamples,testingSets);
    
    
    xTest=sX(:,testingSets);
    zTest=sZ(:,testingSets);
    
    xTrain=sX(:,trainingSets);
    zTrain=sZ(:,trainingSets);
    
    HCV=CV_H{i};
    
    residCV=zTrain-HCV*xTrain;
    QCV = (1/size(x,2))*(residCV)*(residCV)';
    
    HCV=HCV(decodeFeatures,:);
    QCV=QCV(decodeFeatures,decodeFeatures);
    
    zTest=zTest(decodeFeatures,:); zTest=[zTest;zTest(end,:)*0+1];
    
    [Bcf_CV{i},CC_CV{i}]=IPV(obj.decoderParams,HCV,QCV,xTest(1:end-1,:),zTest);
    
end
CC_CV_mean=mean(cell2mat(CC_CV'),1);
%%

zTest=sZ(decodeFeatures,:); zTest=[zTest;zTest(end,:)*0+1];


if obj.decoderParams.popVecDispersion
    obj.msgName('Dispersing population vector... ',0)
    
    newH=dispersePopVec(obj,H(decodeFeatures,1:end-1));
    newH=[newH,H(decodeFeatures,end)];
    PopVec.newH=newH;
    obj.msgName('DONE',1,0)
    %     Bcf = IPV(obj.decoderParams, newH, Q(decodeFeatures,decodeFeatures), [], []);
    [Bcf,DC_CC]=IPV(obj.decoderParams,newH,Q(decodeFeatures,decodeFeatures),sX(1:end-1,:),[sZ(decodeFeatures,:);sZ(end,:)*0+1]);
else
    [Bcf,DC_CC]=IPV(obj.decoderParams,H(decodeFeatures,:),Q(decodeFeatures,decodeFeatures),sX(1:end-1,:),[sZ(decodeFeatures,:);sZ(end,:)*0+1]);
end
% [Bcf,DC_CC]=IPV(obj.decoderParams,H(decodeFeatures,:),Q(decodeFeatures,decodeFeatures),sX(1:end-1,:),sZ(decodeFeatures,:));


%%
plotResiduals=0;
if plotResiduals
    
    redResiduals=residuals(decodeFeatures,:);
    
    kinEst=Bcf*[sZ(decodeFeatures,:);(1+0*sZ(end,:))];
    kinResid=sX(1:end-1,:)-kinEst;
    
    
    figure(131);
    p=panel();
    p.pack(4,5)
    
    p(1,1).select(); hold on
    plot(redResiduals')
    axis tight
    redResiduals=sResiduals(decodeFeatures,:);
    
    p(2,1).select(); hold on
    plot(redResiduals')
    
    axis tight
    p(3,1).select();
    trend= Utilities.expsmooth_mirrored( redResiduals',...
        1/obj.decoderParams.samplePeriod, 1*1000 )';
    plot(trend')
    title('Resids (\tau = 1)')
    
    axis tight
    
    
    p(3,2).select();
    trend= Utilities.expsmooth_mirrored( redResiduals',...
        1/obj.decoderParams.samplePeriod, 20*1000 )';
    title('Resids (\tau = 20)')
    plot(trend')
    axis tight
    p(1,2).select();
    trend= Utilities.expsmooth_mirrored( redResiduals',...
        1/obj.decoderParams.samplePeriod, 5*1000 )';
    title('Resids (\tau = 5)')
    plot(trend')
    axis tight
    p(2,2).select();
    trend= Utilities.expsmooth_mirrored( redResiduals',...
        1/obj.decoderParams.samplePeriod, 10*1000 )';
    title('Resids (\tau = 10)')
    plot(trend')
    axis tight
    %%
    %     dur=10;
    %     for featINDX=11:42;
    %     nSamps=size(redResiduals,2);
    %     span=dur/obj.decoderParams.samplePeriod/nSamps;
    %     r=smooth(redResiduals(featINDX,:),span,'rloess');
    %     clf; hold on
    %     plot(redResiduals(featINDX,:)); hold on;
    %     plot(r,'r','linewidth',3); plot(trend(featINDX,:),'g','linewidth',3)
    %
    %     pause(.1)
    %
    %     end
    %%
    
    xW=redResiduals.*repmat(Bcf(1,1:end-1)',1,size(redResiduals,2));
    yW=redResiduals.*repmat(Bcf(2,1:end-1)',1,size(redResiduals,2));
    p(1,3).select();
    trend= Utilities.expsmooth_mirrored( xW',...
        1/obj.decoderParams.samplePeriod, 1*1000 )';
    plot(trend')
    title('X Weighted Resids (\tau = 1)')
    axis tight
    p(2,3).select();
    trend= Utilities.expsmooth_mirrored( yW',...
        1/obj.decoderParams.samplePeriod, 1*1000 )';
    plot(trend')
    title('Y Weighted Resids (\tau = 1)')
    axis tight
    p(3,3).select();
    trend= Utilities.expsmooth_mirrored( xW',...
        1/obj.decoderParams.samplePeriod, 20*1000 )';
    plot(trend')
    title('X Weighted Resids (\tau = 20)')
    axis tight
    p(4,3).select();
    trend= Utilities.expsmooth_mirrored( yW',...
        1/obj.decoderParams.samplePeriod, 20*1000 )';
    plot(trend')
    title('Y Weighted Resids (\tau = 20)')
    
    
    axis tight
    
    
    p(4,1).select();
    trend= Utilities.expsmooth_mirrored( xW',...
        .5/obj.decoderParams.samplePeriod, 1*1000 )';
    plot(trend')
    title('X Weighted Resids (\tau = .5)')
    axis tight
    p(4,2).select();
    trend= Utilities.expsmooth_mirrored( yW',...
        .5/obj.decoderParams.samplePeriod, 1*1000 )';
    plot(trend')
    title('Y Weighted Resids (\tau = .5)')
    axis tight
    
    
    
    
    
    
    p(4,5).select();
    trend= Utilities.expsmooth_mirrored( redResiduals',...
        1/obj.decoderParams.samplePeriod, 10*1000 )';
    title('FiringRate (\tau = 10)')
    plot(trend')
    
    xW=redResiduals.*repmat(Bcf(1,1:end-1)',1,size(redResiduals,2))*.05;
    yW=redResiduals.*repmat(Bcf(2,1:end-1)',1,size(redResiduals,2))*.05;
    p(1,4).select();
    trend= cumsum(redResiduals')';
    plot(trend')
    title('Cumulative Errors')
    axis tight
    p(2,4).select();
    plot(cumsum(xW'))
    title('Cumulative Errors - X Weighted')
    axis tight
    p(3,4).select();
    plot(cumsum(yW'))
    title('Cumulative Errors - Y Weighted')
    axis tight
    
    p(1,5).select();
    hold on
    plot(sX(1,:)',kinEst(1,:),'.')
    plot(sX(2,:)',kinEst(2,:),'r.')
    mx=max([abs(sX(:)); abs(kinEst(:))]);
    xlim([-mx, mx])
    ylim([-mx, mx])
    
    title('Systematic Errors')
    xlabel('Kinematic Value')
    ylabel('Kinematic Estimate')
    axis tight
    p(2,5).select(); hold on
    plot(sX(1,:)',kinResid(1,:),'.')
    plot(sX(2,:)',kinResid(2,:),'r.')
    
    title('Systematic Errors')
    xlabel('Kinematic Value')
    ylabel('Kinematic Residual')
    axis tight
    p(3,5).select(); hold on
    plot(kinEst(1,:)',kinResid(1,:),'.')
    plot(kinEst(2,:)',kinResid(2,:),'r.')
    
    title('Systematic Errors')
    xlabel('Kinematic Value')
    ylabel('Kinematic Residual')
    axis tight
end

% %%
% if isfield(obj.decoderParams,'SingUnitControl')
%
%     weight=obj.decoderParams.SingUnitControl.targetDistance/...
%         obj.decoderParams.SingUnitControl.desiredDuration;
%         % Single Unit Bcf
% %         [~,SUfeatINDX]=max(Utilities.mnorm(H(:,1:end-1)));
% %         setSUfeature(obj,SUfeatINDX)
%         BcfS=weight*(H(:,1:end-1)'./repmat(Utilities.mnorm(H(:,1:end-1))',size(H,2)-1,1));
%         PopVec.BcfS=BcfS;
%
%
% end
%%
obj.msgName(sprintf(' %d features significantly tuned (@ zero latency)',nnz(signifFeatures)))

PopVec.signifFeatures=signifFeatures;
PopVec.decodeFeatures=decodeFeatures;

PopVec.R2_CVmu=R2_CVmu;
PopVec.R2_CVse=R2_CVse;
PopVec.R2=R2;
PopVec.H=H;
PopVec.Hcv=Hcv;
PopVec.Hse=Hse;
PopVec.Q=Q;
PopVec.smoothQ=smoothQ;
PopVec.pValue=p;

% PopVec.residuals=residuals;
% PopVec.sResiduals=sResiduals;

PopVec.IV.R2_CVmu=CC_CV_mean.^2;
PopVec.IV.R2_CV=cellfun(@(x)x.^2, CC_CV,'UniformOutput' , 0);
PopVec.IV.R2=DC_CC.^2;
PopVec.IV.Bcf_CV=Bcf_CV;
PopVec.IV.Bcf=Bcf;


PopVec.muEOut=muEOut;
PopVec.sigEOut=sigEOut;


function [Bcf,CC]=IPV(decoderParams,H,Q,X,Z)

useaddage=1;

if useaddage
    H(:,end)=[]; % Remove offsets term
else
    tmp=zeros(size(Q)+1);
    tmp(1:size(Q,1),1:size(Q,1))=Q;
    Q=tmp;
    H=[H;zeros(1,size(H,2)-1) 1];
end

Q=Q.*eye(size(Q,1));
if decoderParams.useCov
    Bcf=inv(H'*pinv(Q)*H)*H'*pinv(Q);
else
    Bcf=inv(H'*H)*H';
end


switch decoderParams.TuningFeatures
    case 'xdx' % position and velocity
        %         Bcf=Bcf(2:2:end,:);
        %         X=X(2:2:end,:);
    case 'dx' % velocity
        
    case 'xdxs' % velocity & speed
        %             H=H(:,2:2:end);
        %             H=H(:,1:obj.decoderParams.nDOF);
        warning('Check')
        
    case 'x'
        warning('was previously unsupported, but this doesn''t seem to do anything...');
        
    otherwise
        error('Unsupported Method.')
        
end

if useaddage
    Bcf=[Bcf,Bcf(:,end)*0];
else
    Bcf(end,:)=[];
end

for k=1:size(X,1)
    CC(k)=corr((Bcf(k,:)*Z)',X(k,:)');
end
%%
