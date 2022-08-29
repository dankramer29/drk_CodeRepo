function State=plotFitResults(obj,decoderTMP)

if nargin==1
    decoderTMP=obj.decoders(obj.currentDecoderINDX);
end

% get data (as it looks after passing through raw2modl)
z=decoderTMP.trainingData.Z;
x=decoderTMP.trainingData.sX;


% detrend
if obj.decoderParams.adaptNeuralMean
    trend= Utilities.expsmooth_mirrored( z', 1/decoderTMP.decoderParams.samplePeriod, decoderTMP.decoderParams.adaptNeuralRate*1000 )';
    z=z-trend;
end

State=zeros(decoderTMP.decoderParams.nDOF*2,1);

cIDX=obj.currentDecoderINDX;

if isfield(obj.runtimeParams,'plotResiduals')
    pR=obj.runtimeParams.plotResiduals;
    obj.runtimeParams.plotResiduals=0;
end

aSAF= obj.decoders(cIDX).decoderParams.applySpeedAdaptiveFilter;
obj.decoders(cIDX).decoderParams.applySpeedAdaptiveFilter=0;
 obj.runtimeParams.outputGain(:)=obj.runtimeParams.outputGain(:)*0+1;
 
% simulate the forward estimatuion process and plot the fit results
if any(strcmp(decoderTMP.decoderParams.filterType,{'direct','inversion','kalmanfit'}))
    Filter=decoderTMP.decoderProps.smoothingFilter;
    z=z(decoderTMP.decoderProps.decodeFeatures,:);
    obj.emptyRecentBuffers;
    cState=zeros(obj.decoderParams.nDOF*2,1);
    sResid=[];
    for i=1:size(z,2)-1;
        [sV,iV,resid]=estimateVel(obj,z(:,i),cState,sResid);
        obj.DataBuffers.RecentState.add(iV);
        
        cState(2:2:end)=sV;
        cState=obj.runtimeParams.pIntegrator*cState;
        State(:,end+1)=cState(:);
    end
end

 obj.decoders(cIDX).decoderParams.applySpeedAdaptiveFilter=aSAF;

 if isfield(obj.runtimeParams,'plotResiduals')
    obj.runtimeParams.plotResiduals=pR;
end
 
for indx=2:2:size(x,1);
    multFactor(indx)=Kinematics.computeVelocityGain(State(indx,:),x(indx,:),obj.decoderParams.velocityMatchingPercentiles);
    State(indx,:)=State(indx,:)*multFactor(indx);
end
obj.runtimeParams.outputGain=multFactor(2:2:end);

%% Compute gain to match up high velocity segments
%         indx=1;
%         for i=2:2:size(x,1);
%             multFactor(indx)=Kinematics.computeVelocityGain(State(i,:),x(i,:),obj.decoderParams.velocityMatchingPercentiles);
%             indx=indx+1;
%         end
%         multFactor(multFactor<1)=1;
%         obj.msgName
%         fprintf('Computed outputGain = ('), fprintf(' %0.2f ',multFactor); fprintf(')\n')
%
%         obj.runtimeParams.outputGain=multFactor;
%

% figure -- plot residuals of tuning model

% %%
% obj.figureHandles.FitPlot=figure;
% p = panel();  p.margin=10;
% p.pack('v',{5/6 1/6});
% p(1).pack(obj.decoderParams.nDOF,2);
% p(2).pack('h',3);
% 
% 
% dt=obj.decoderParams.samplePeriod;
% dof=0;
% for i=1:2:size(x,1)
%     dof=dof+1;
%     
%     p(1,dof,1).select(); cla
%     hold on
%     
%     plot(x(i,:)','g'); axis tight
%     plot(State(i,:)','r--'); axis tight
%     
%     
%     t1=corr(x(i,:)',State(i,:)');
%     
%     title(sprintf('cc = %0.2f  ',t1))
%     %             xlim([400 1000])
%     
%     p(1,dof,2).select(); cla
%     hold on
%     
%     plot(x(i+1,:)','g'); axis tight
%     plot(State(i+1,:)','r--'); axis tight
%     
%     
%     t1=corr(x(i+1,:)',State(i+1,:)');
%     jerk= sum(abs(diff(State(i+1,:),2)/dt.^2))/length(State(i+1,:));
%     
%     title(sprintf('cc = %0.2f  ; jerk = %0.1f ',t1,jerk))
%     %             xlim([400 1000])
%     
% %     figure; plot(x(i+1,:)',State(i+1,:)')
% end


%%
% 
% 
%    r=decoderTMP.PopVec.residuals(decoderTMP.decoderProps.decodeFeatures,:);
% 
%     decoderTMP.decoderParams.errorTC=1;
%     sR=Utilities.expsmooth_mirrored(r', 1/decoderTMP.decoderParams.samplePeriod, decoderTMP.decoderParams.errorTC*1000 )';
% 
%    plot(sR');
%    axis tight;
%    yl=ylim;
%    hold on; plot(decoderTMP.trainingData.trainINDXS,yl(1),'r.')
%    %%
% 
% 
% 
%     filterCoeff=MakeFilter(obj);
%     [pX]=Utilities.filter_mirrored(filterCoeff,1,x,[],2);
%     [pZ]=Utilities.filter_mirrored(filterCoeff,1,z,[],2);
% 
%     ex=decoderTMP.decoderProps.Bcf(:,1:end-1)*z(decoderTMP.decoderProps.decodeFeatures,:);
%     filterCoeff=Kinematics.MakeARFilter(1, .05, .1);
%     [seX]=Utilities.filter_mirrored(filterCoeff,1,ex,[],2);
%     seX2=decoderTMP.decoderProps.Bcf(:,1:end-1)*sZ(decoderTMP.decoderProps.decodeFeatures,:);
% 
% 
% figure; plot(obj.decoderParams.lags2Process, R2L')

% the objective is to push the average velocity (or neural activity) to
% zero.
%
% the adaptive mean is like proportional control -