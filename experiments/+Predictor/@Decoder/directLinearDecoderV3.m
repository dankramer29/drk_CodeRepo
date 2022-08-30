function [Bcf,R2,cv]=directLinearDecoderV3(obj,decoderTMP,varargin)
%%
cv=[];
PopVec=[];
%% set defaults for varargin
PlotFit=0;
inputArguements=varargin;
trainINDXS=obj.decoderParams.trainINDXS;

while ~isempty(inputArguements)
    switch lower(inputArguements{1})
        case lower('PlotFit')
            PlotFit=inputArguements{2};
            inputArguements(1:2)=[];
        otherwise
            error('Input %s is not a valid arguement, try again ',inputArguements{1})
    end
end


sZ = decoderTMP.trainingData.sZ;
sX = decoderTMP.trainingData.sX;
trainINDXS=decoderTMP.trainingData.trainINDXS;
decodeFeatures = decoderTMP.PopVec.decodeFeatures;

if trainINDXS(end) > size(sX,2);
    obj.msgName('trainINDXS specifies a indice that extends beyond the range of the data (probably as a result of testing lags?) Removing offending inds')
    trainINDXS(trainINDXS>size(dX,2))=[];
end

sZ=sZ(decodeFeatures,:);
dt=obj.decoderParams.samplePeriod;

% extract appropriate subset of data
sX=sX(2:2:end,trainINDXS);
sZ=sZ(:,trainINDXS);

sZ=[sZ; (sZ(end,:)*0+1) ]; % append


cond1 = strcmp(obj.decoderParams.fitType,'crossValQuick');
cond2 = size(sX,2)<(obj.decoderParams.cvOptions.minTestSize+obj.decoderParams.cvOptions.minTrainSize) ;
% if cond1 && cond2
%     warning('User specified fitting with crossValQuick but there are not enough data points so switching to lasso');
%     obj.decoderParams.fitType='lasso';
% end

R2str=''; R2cvstr='';

% t = RegressionTree.template('surrogate','on');
% ens = fitensemble(sZ(1:end-1,:)',sX(k,:)','LSBoost',300,t)
% xOut=predict(ens,sZ(1:end-1,:)');
% corr(sX(1,:)',xOut).^2
%
% cv = crossval(ens,'kfold',5);
% figure;
% plot(kfoldLoss(cv,'mode','cumulative'));
% xlabel('Number of trees');
% ylabel('Cross-validated MSE');
% ylim([0.2,2])


for k=1:size(sX,1)
    tic
    Weights=ones(size(sX(k,:)'));
    %     [b,stats] = robustfit(sZ(1:end-1,:)',sX(k,:)');
    %     Weights=stats.w;
    %     clrs={'r','g','b'};
    %     figure(101);hold on; plot(Weights,clrs{k});
    
    switch lower(obj.decoderParams.fitType)
        case 'standard'
            Vmdl1{k}=LinearModel.fit(sZ(1:end-1,:)',sX(k,:)');
            R2(k)=Vmdl1{k}.Rsquared.Ordinary;
            %     %Construct Force Vectors
            Bcf(k,:)=[Vmdl1{k}.Coefficients.Estimate(2:end)', Vmdl1{k}.Coefficients.Estimate(1)];
            
        case 'standardquick'
            Bcf(k,:)=[sZ'\sX(k,:)']';
            R2(k)=corr((Bcf(k,:)*sZ)',sX(k,:)').^2;
            
        case 'crossvalquick'
            
%             if matlabpool('size')>0
                if 1==0
                opts = statset('UseParallel','always');
            else
                opts = statset('UseParallel','never');
            end
            
            [cv.R2{k},cv.Bcf{k},cv.R2ontrain{k},cv.p{k},cv.cc{k}]=crossValQuick(obj,sX(k,:),sZ);
            
            Bcf(k,:)=[sZ'\sX(k,:)']';
            R2(k)=corr((Bcf(k,:)*sZ)',sX(k,:)').^2;
            R2cv(k)=nanmean(cv.cc{k}).^2;
            
            R2cvstr=[R2cvstr, sprintf('%0.2f ',R2cv(k))];
            
            
        case 'robust'
            Vmdl1{k}=LinearModel.fit(sZ(1:end-1,:)',sX(k,:)','RobustOpts','on');
            Bcf(k,:)=[Vmdl1{k}.Coefficients.Estimate(2:end)', Vmdl1{k}.Coefficients.Estimate(1)];
            R2(k)=Vmdl1{k}.Rsquared.Ordinary;
            
            
        case 'lasso'
            obj.msgName(sprintf('Lasso fit for dof %d ...',k),0);
%             if matlabpool('size')>0
%                 opts = statset('UseParallel','always');
%             else
                opts = statset('UseParallel','never');
%             end
            %           [B FitInfo] = lasso(sX(k,:)',sZ','CV',10,'Options',opts);
            
            [B,FitInfo] = lasso(sZ(1:end-1,:)',sX(k,:)','CV',obj.decoderParams.lassoOptions.CV ,'Options',opts,...
                'NumLambda',obj.decoderParams.lassoOptions.NumLambda,'Alpha', obj.decoderParams.lassoOptions.Alpha,...
                'Weights',Weights);
            
            % choose indx
            switch  obj.decoderParams.lassoOptions.optINDX
                case 'mid'
                    OptIndx=round((FitInfo.IndexMinMSE+FitInfo.Index1SE)/2);
                case 'IndexMinMSE'
                    OptIndx=FitInfo.IndexMinMSE;
                case 'Index1SE'
                    OptIndx=FitInfo.Index1SE;
                otherwise
                    OptIndx=round((FitInfo.IndexMinMSE+FitInfo.Index1SE)/2);
            end
            
            Bcf(k,:)=[B(:,OptIndx)',FitInfo.Intercept(OptIndx)];
            R2(k)=corr((Bcf(k,:)*sZ)',sX(k,:)').^2;
            
            MSE=FitInfo.MSE(OptIndx); 
            cv{k}=1-(MSE/var(sX(k,:)));
            
            if obj.decoderParams.lassoPlot
                lassoPlot(B,FitInfo,'PlotType','CV')
            end
            obj.msgName(sprintf('took %0.2f secs',toc),1,0)
            
            
        case 'speedlasso'
            obj.msgName(sprintf('Lasso fit for dof %d ...',k),0)
            if matlabpool('size')>0
                opts = statset('UseParallel','always');
            else
                opts = statset('UseParallel','never');
            end
            
            peakSpeed=prctile(obj.signalProps.speed,99);
            Weights= obj.signalProps.speed./peakSpeed;
            Weights(Weights>1)=1;
            % %         Weights=sqrt(Weights);
            Weights(Weights<.05)=.05;
            
            Weights=Weights.^2;
            Weights=Weights(obj.decoderParams.trainINDXS);
            
            %           [B FitInfo] = lasso(sX(k,:)',sZ','CV',10,'Options',opts);
            
            [B,FitInfo] = lasso(sZ(1:end-1,:)',sX(k,:)','CV',obj.decoderParams.lassoOptions.CV ,'Options',opts,...
                'NumLambda',obj.decoderParams.lassoOptions.NumLambda,'Alpha', obj.decoderParams.lassoOptions.Alpha,...
                'Weights',Weights);
            
            % choose indx
            switch  obj.decoderParams.lassoOptions.optINDX
                case 'mid'
                    OptIndx=round((FitInfo.IndexMinMSE+FitInfo.Index1SE)/2);
                case 'IndexMinMSE'
                    OptIndx=FitInfo.IndexMinMSE;
                case 'Index1SE'
                    OptIndx=FitInfo.Index1SE;
                otherwise
                    OptIndx=round((FitInfo.IndexMinMSE+FitInfo.Index1SE)/2);
            end
            
            Bcf(k,:)=[B(:,OptIndx)',FitInfo.Intercept(OptIndx)];
            R2(k)=corr((Bcf(k,:)*sZ)',sX(k,:)').^2;
            
            if obj.decoderParams.lassoPlot
                lassoPlot(B,FitInfo,'PlotType','CV')
            end
            obj.msgName(sprintf('took %0.2f secs',toc),1,0)
            
            
    end        
    
end



if 1==0
    
    %% Step 2 : Construct Force Vectors
    % construct force vectors
    V_estS=Bcf*sZ;
    
    % determine speedAdaptiveParams
    speedPercentile=obj.decoderParams.SAF.speedPercentile;
    pkspeed=prctile(obj.signalProps.speed,speedPercentile);
    
    obj.decoderParams.SAF.smoothingParams(1:2)=obj.decoderParams.SAF.smoothingMetaParams(1:2);
    obj.decoderParams.SAF.smoothingParams(3)=obj.decoderParams.SAF.smoothingMetaParams(3)*pkspeed;
    obj.decoderParams.SAF.smoothingParams(4)=obj.decoderParams.SAF.smoothingMetaParams(4)*pkspeed;
    
    obj.decoderParams.SAF.gainParams(1:2)=obj.decoderParams.SAF.gainMetaParams(1:2);
    obj.decoderParams.SAF.gainParams(3)=obj.decoderParams.SAF.gainMetaParams(3)*pkspeed;
    obj.decoderParams.SAF.gainParams(4)=obj.decoderParams.SAF.gainMetaParams(4)*pkspeed;
    
    %     = [.01 .15 -.05 .4]; %[minVal maxVal percentSpeedMin percentSpeedMin]
    %     decoderParams.SAF.gainParams = [.5 1 -.05 .25]; %[minVal maxVal percentSpeedMin percentSpeedMin]
    %%
    % fprintf('NEW -------------------- \n')
    %     for j=2:size(z,2)
    %         x_est(:,j)=Bcf*[z(:,j);1];
    %     end
    %     obj.decoderParams.preSmoothOptions.expKernel=.85;
    % filterCoeff=MakeFilter(obj);
    % % filterCoeff=Kinematics.MakeARFilter(1, .05, .01);
    %
    % [x_est2]=Utilities.filter_mirrored(filterCoeff,1,x_est,[],2);
    %
    %    corr(x_est2',sX')
    %
    % % obj.decoderParams.SAF.detectionFilter=Kinematics.MinJerkKernel(850,50,1);
    %
    % obj.decoderParams.preSmoothOptions.expKernel=.7;
    % % filterCoeff=Kinematics.MakeARFilter(1, .05, .01);
    % filterCoeff=MakeFilter(obj);
    % % filterCoeff=Kinematics.MinJerkKernel(750,50,1);
    % [x_est3]=Utilities.filter_mirrored(filterCoeff,1,x_est,[],2);
    %
    % setSAFParams(Speed)
    % x_est3=obj.SAF(x_est3,0);
    %
    %     corr(x_est3',sX')
    %
    %     figure;  plot(sX(1,:),'k'); hold on;plot(x_est2(1,:),'r','linewidth',2); plot(x_est3(1,:),'linewidth',2); hold on;  xlim([650 1150])
    %
    %      jerk= sum(abs(diff(x_est3,1,2)/dt.^2),2)/size(x_est3,2)
    %      jerk= sum(abs(diff(x_est2,1,2)/dt.^2),2)/size(x_est2,2)
    
    % x = lscov(obj.trainingProps.PopVec.H,sZ,obj.trainingProps.PopVec.Q);
    
    %%
    %% Step 3 : Fit dynamical system
    Ac=[];Bc=[];
    if PlotFit
        figure;
        p = panel();p.margin=10;
        p.pack('v',repmat(1/obj.decoderParams.nDOF,1,obj.decoderParams.nDOF));
    end
    
    
    for indx=1:size(dX,1)
        x_est=[0 0]';
        
        switch obj.decoderParams.trainingTarget
            case {'IdealPrediction','AssistedPrediction'}
                A=[1 dt; -.01 obj.decoderParams.modelSmoothVal];
                B=[Bcf(indx,:)*0; (1-obj.decoderParams.modelSmoothVal)*Bcf(indx,:)];
                
            case 'IdealPredictionForce'
                A=[1 dt; -.01 obj.decoderParams.modelSmoothVal];
                B=[Bcf(indx,:)*0; Bcf(indx,:)];
        end
        
        
        % if using high pass, apply high pass to neural data for gain computation
        if obj.decoderParams.applyHighPass
            % high pass using same settings as adapted neural mean.
            trend= Utilities.expsmooth( z', 1/obj.decoderParams.samplePeriod, obj.runtimeParams.adaptNeuralRate*1*1000 )';
            z=z-trend;
        end
        
        
        % generate response to determine scaling factor.
        for j=2:size(z,2)
            x_est(:,j)=A*x_est(:,j-1)+B*[z(:,j);1];
        end
        
        if obj.decoderParams.applySpeedAdaptiveFilter
            obj.setSAFParams(abs(x_est(2,:)));
            x_est2(2,:)=obj.SAF(x_est(2,:),0);
            multFactor(indx)=Kinematics.computeVelocityGain(x_est2(2,:),dX(indx,:),obj.decoderParams.velocityMatchingPercentiles);
        else
            multFactor(indx)=Kinematics.computeVelocityGain(x_est(2,:),dX(indx,:),obj.decoderParams.velocityMatchingPercentiles);
        end
        
        % note that adding a multFactor here is the same as adding a posthoc
        % gain of the same amplitude.
        
        %     B(2,:)=multFactor*B(2,:);
        %     x_est(2,:)=multFactor*x_est(2,:);
        
        
        
        Reconstruction(indx,:)=x_est(2,:);
        
        %     [rest_indxs,move_indxs,threshold]=Kinematics.findMoveRest(mnorm(sX(indx,:)'),0);
        if PlotFit
            %%
            p(indx).select(); cla
            hold on
            %         plot(sX(indx,:)','g'); axis tight
            plot(dX(indx,:)','g'); axis tight
            plot(sX(indx,:)','g--'); axis tight
            %         plot(dX(indx,:)'*(sqrt(sum(sX(indx,:).^2))./sqrt(sum(dX(indx,:).^2))),'g--'); axis tight
            %         plot(V_estS(indx,:)','linewidth',2);
            
            
            %         plot(x_est(2,:)','r'); axis tight
            plot(x_est(2,:)'*multFactor(indx),'r--'); axis tight
            
            t1=corr(dX(indx,:)',x_est(2,:)').^2;
            t2=corr(sX(indx,:)',x_est(2,:)').^2;
            
            if obj.decoderParams.applySpeedAdaptiveFilter
                plot(x_est2(2,:)'*multFactor(indx),'b'); axis tight
                t3=corr(dX(indx,:)',x_est2(2,:)').^2;
                t4=corr(sX(indx,:)',x_est2(2,:)').^2;
                title(sprintf('R2 = %0.2f ,%0.2f ,%0.2f ,%0.2f ',t1,t2,t3,t4))
            else
                
                title(sprintf('R2 = %0.2f ,%0.2f ,%0.2f ',t1,t2))
                
            end
            
            
            %         legend({'Vsmooth','V','Fit','DynSysFit'})
            % s        title('Rsquared = %0.2f (dof %d ; %d samples; %d Features',R2(indx),indx,length(sX(indx,:)),size(sZ,1))
            
            %         xlim([400 1000])
            
            %         figure; hold on
            %          plot(x(indx,:)','g'); axis tight
            %          plot(x_est(1,:)','r--')
        end
        Ac{indx}=A;
        Bc=[Bc;B];
    end
    
    
    multFactor(multFactor<1)=1;
    obj.msgName(sprintf('Computed outputGain = (%s)',sprintf('%.2f ',multFactor)));
    
    obj.runtimeParams.outputGain=multFactor;
    
    if obj.decoderParams.applySpeedAdaptiveFilter
        obj.setSAFParams([],multFactor);
    end
    %
    % %%
    % indx=2;
    %     % high pass using same settings as adapted neural mean.
    %     trend= Utilities.expsmooth( z', 1/obj.decoderParams.samplePeriod, obj.runtimeParams.adaptNeuralRate*1*1000 )';
    %     pz=z-trend;
    %
    %     filterCoeff=MakeFilter(obj);
    %     [pz]=Utilities.filter_mirrored(filterCoeff,1,pz,[],2);
    %
    %
    %     for i=1:size(pz,1)
    %         pz(i,:)=Kinematics.SpeedAdaptiveFilter(pz(i,:),0.05,0);
    %     end
    %
    %     for j=2:size(pz,2)
    %         x_est2(:,j)=Bcf(indx,:)*[pz(:,j);1];
    %     end
    %
    %
    %     multFactor=Kinematics.computeVelocityGain(x_est2,dX(indx,:));
    %     Bcf(indx,:)=multFactor*Bcf(indx,:);
    %
    %       for j=2:size(pz,2)
    %         x_est2(:,j)=Bcf(indx,:)*[pz(:,j);1];
    %     end
    %
    %     plot(x_est2,'b','linewidth',2)
    %     %%
    %
    %
    %
    %
    % %
    %
    %
    %
    %
    %
    % % velE=Kinematics.SpeedAdaptiveFilter(x_est(2,:)-trend,0.05,0); plot(velE,'m--')
    %
    % for indx=1:size(dX,1)
    %     x_est=[0 0]';
    %
    %     switch obj.decoderParams.trainingTarget
    %         case 'IdealPrediction'
    %             A=[1 dt; -.05 obj.decoderParams.modelSmoothVal];
    %             B=[Bcf(indx,:)*0; (1-obj.decoderParams.modelSmoothVal)*Bcf(indx,:)];
    %
    %         case 'IdealPredictionForce'
    %             A=[1 dt; -.05 obj.decoderParams.modelSmoothVal];
    %             B=[Bcf(indx,:)*0; Bcf(indx,:)];
    %     end
    %
    %     % generate response to determine scaling factor.
    %     for j=2:size(z,2)
    %         x_est(:,j)=A*x_est(:,j-1)+B*[pz(:,j);1];
    %     end
    %
    %
    %
    %
    %     % note that adding a multFactor here is the same as adding a posthoc
    %     % gain of the same amplitude.
    %     multFactor=Kinematics.computeVelocityGain(x_est(2,:),dX(indx,:));
    %     B(2,:)=multFactor*B(2,:);
    %
    %     for j=2:size(z,2)
    %         x_est(:,j)=A*x_est(:,j-1)+B*[pz(:,j);1];
    %     end
    %
    %     Reconstruction(indx,:)=x_est(2,:);
    %
    %     %     [rest_indxs,move_indxs,threshold]=Kinematics.findMoveRest(mnorm(sX(indx,:)'),0);
    %     if PlotFit
    %         %%
    %         p(indx).select(); cla
    %         hold on
    %         %         plot(sX(indx,:)','g'); axis tight
    %         plot(dX(indx,:)','g'); axis tight
    %         %         plot(dX(indx,:)'*(sqrt(sum(sX(indx,:).^2))./sqrt(sum(dX(indx,:).^2))),'g--'); axis tight
    %         %         plot(V_estS(indx,:)','linewidth',2);
    %
    %
    %          velE=Kinematics.SpeedAdaptiveFilter(x_est(2,:),0.05,0); plot(velE,'m')
    %
    %
    %
    %         plot(x_est(2,:)','r'); axis tight
    %
    %
    %         t1=corr(dX(indx,:)',x_est(2,:)').^2;
    %         t2=corr( dX(indx,:)',(x_est(2,:)-trend)').^2;
    %         t3=corr(dX(indx,:)',velE').^2;
    %
    %
    %         plot(x_est(2,:)','r--'); axis tight
    %
    %
    %         title(sprintf('R2 = %0.2f ,%0.2f ,%0.2f ',t1,t2,t3))
    %         %         legend({'Vsmooth','V','Fit','DynSysFit'})
    %         % s        title('Rsquared = %0.2f (dof %d ; %d samples; %d Features',R2(indx),indx,length(sX(indx,:)),size(sZ,1))
    %
    %         xlim([400 1000])
    %
    %         %         figure; hold on
    %         %          plot(x(indx,:)','g'); axis tight
    %         %          plot(x_est(1,:)','r--')
    %     end
    %     Ac{indx}=A;
    %     Bc=[Bc;B];
    % end
    %
    
    
    
    %%
    %%
    % mu = 0.0008;            % LMS step size.
    % ha = adaptfilt.lms(32,mu);
    % tic
    % [y,e] = filter(ha,x_est(2,:)',sX(indx,:)');
    %
    % figure;
    % plot(sX(indx,:)','linewidth',2);
    % hold on;
    % plot(x_est(2,:)','r');
    % plot(y,'g');
    %
    % corrcoef(sX(2,5000:end),x_est(2,5000:end)')
    %
    % corrcoef(sX(2,5000:end),y(5000:end))
    %%
    
    
    obj.decoderProps.tmp.decoderProps.Ac=Utilities.blkdiagCell(Ac);
    obj.decoderProps.tmp.decoderProps.Bc=Bc;
    obj.decoderProps.tmp.decoderProps.Reconstruction=Reconstruction;
    obj.decoderProps.tmp.decoderProps.Target=dX;
    
end