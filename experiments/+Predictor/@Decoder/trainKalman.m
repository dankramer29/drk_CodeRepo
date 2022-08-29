function decoderProps=trainKalman(obj,decoderTMP)


%% extract data
sZ = decoderTMP.trainingData.Z;
sX = decoderTMP.trainingData.sX;
trainINDXS=decoderTMP.trainingData.trainINDXS;
decodeFeatures = decoderTMP.PopVec.decodeFeatures;

if decoderTMP.decoderParams.adaptNeuralMean
    % high pass using same settings as adapted neural mean.
    trend= Utilities.expsmooth_mirrored( sZ', 1/obj.decoderParams.samplePeriod, obj.runtimeParams.adaptNeuralRate*1000 )';
    sZ=sZ-trend;
    
    trend= Utilities.expsmooth_mirrored( sX', 1/obj.decoderParams.samplePeriod, obj.runtimeParams.adaptNeuralRate*1000 )';
    sX=sX-trend;
end

if trainINDXS(end) > size(sX,2);
    obj.msgName('trainINDXS specifies a indice that extends beyond the range of the data (probably as a result of testing lags?) Removing offending inds')
    trainINDXS(trainINDXS>size(dX,2))=[];
end

sZ=sZ(decodeFeatures,:);
dt=obj.decoderParams.samplePeriod;

% extract appropriate subset of data
sX=sX(:,trainINDXS);
sZ=sZ(:,trainINDXS);


%%
decoderProps=decoderTMP.decoderProps;


tic
A=decoderProps.raw.A;
H=decoderProps.raw.H;
W=decoderProps.raw.W;
Q=decoderProps.raw.Q;
decodeFeatures=decoderProps.decodeFeatures;

% obj.decoderProps.tmp.decoderProps.Ap=Utilities.blkdiagCell(repmat({[1 obj.decoderParams.samplePeriod]},obj.decoderParams.nDOF,1));


H=H(decodeFeatures,:);
Q=Q(decodeFeatures,decodeFeatures);


if strcmp(obj.decoderParams.TuningFeatures,'xdx') && size(H,2)==obj.decoderParams.nDOF*2+1
    d=H(:,end);
    H=H(:,1:end-1);
elseif strcmp(obj.decoderParams.TuningFeatures,'dx') && size(H,2)==obj.decoderParams.nDOF+1
    d=H(:,end);
    H=H(:,1:end-1);
else
    d=0;
end
%%

if strcmp(obj.decoderParams.TuningFeatures,'dx')
    sX=sX(2:2:end,:);
    A=A(2:2:end,2:2:end);
    W=W(2:2:end,2:2:end); W=W.*eye(size(W));
end

SIG=zeros(size(A));

decoderProps.A=A;
decoderProps.H=H;
decoderProps.d=d;
decoderProps.W=W;
decoderProps.Q=Q;

decoderProps.eH=H(:,end)*0; % initialized error


decoderProps.pQ=Q*0;
decoderProps.kalmanErrorWeight=obj.decoderParams.kalman.kalmanErrorWeight;
decoderProps.robustWeight=obj.decoderParams.kalman.robustWeight;

decoderProps.I=eye(size(A));
decoderProps.SIG=SIG;
decoderProps.decodeFeatures=decodeFeatures;
decoderProps.errorAlpha = exp( -(obj.decoderParams.samplePeriod*1000)/(obj.decoderParams.kalman.errorTC*1000));





% Get SS values
% init
K=H'*0; indx=1;
while 1
    Pm=A*SIG*A'+W;
    if strcmp(obj.decoderParams.kalman.PK_type,'shenoy')
        Pm(1:2:end,:)=0; Pm(:,1:2:end)=0; Pm=Pm.*eye(size(Pm));
    end
    
    newK=Pm*H'/(H*Pm*H'+Q);
    d=sum( sqrt((newK(:)-K(:)).^2) ) ;
    if d<1e-10, break, end
    K = newK;
    tmp{indx}=K;
    KD(indx)=d;indx=indx+1;
    
    SIG=(eye(size(K,1))-K*H)*Pm;
end

if 1==0
    KD=KD./max(KD); KD=1-KD;
    figure; plot((0:length(KD)-1)*.05,KD)
    xlabel('Time (Secs)')
    ylabel('Distance (Normalized)')
    title('Convergence of Kalman Gain Matrix')
end

% compute time constant for updating error estiamte
decoderProps.Bcf=K;
decoderProps.SIGss=SIG;
decoderProps.Acss=(eye(size(A))-K*H)*A;

decoderTMP.decoderProps=decoderProps;

%% Test


[xOut,decoderProps,eOut]=kalmanStep(obj,sX,sZ,decoderTMP,1);


decoderProps.R2=diag(corr(sX',xOut')).^2;







if 1==0
    
    
    
    %%
    % obj.decoderParams.kalmanType='standard';
    
    testInds=1:size(z,2);
    % pass through training data
    [xOut,eOut]=kalmanStep(obj,x(:,testInds),z(decodeFeatures,testInds));
    obj.decoderProps.tmp.decoderProps.workingCopy=obj.decoderProps.workingCopy;
    %% Compute mean/std of error
    
    %%
    % determine gain to fit xth percentile.
    if strcmp(obj.decoderParams.TuningFeatures,'dx')
        for i=1:size(x,1)
            a=xOut(i,testInds);
            b=Utilities.expsmooth_mirrored(x(i,testInds)', 1/obj.decoderParams.samplePeriod, 85 )';
            %     b=x(i,testInds);
            multFactor(i)=Kinematics.computeVelocityGain(a,b,obj.decoderParams.velocityMatchingPercentiles);
        end
        multFactor(multFactor<1)=1;
        obj.msgName(sprintf('Computed outputGain = (%s)',sprintf('%0.2f ',multFactor)))
        
        obj.runtimeParams.outputGain=multFactor;
    end
    %%
    % simulate
    % xP=x(:,1);
    % for i=1:size(x,2)
    % [xP,eOut2(:,i)]=kalmanStep(obj,xP,z(decodeFeatures,i));
    % xP=xP;
    % xOut2(:,i)=xP;
    % end
    
    %%
    eNorm=zscore(mnorm(  (eOut.*repmat(mnorm(H),1,size(z,2)))' ))';
    
    eNormS=Utilities.expsmooth_mirrored(eNorm', 1/obj.decoderParams.samplePeriod, 85 )';
    b=Utilities.expsmooth_mirrored(mnorm(x')', 1/obj.decoderParams.samplePeriod, 85 )';
    
    
    % compute the smoothed error to determine the mean/std of the smoothed
    % error.
    obj.decoderParams.errorTC=3
    esOut=Utilities.expsmooth_mirrored(eOut', 1/obj.decoderParams.samplePeriod, obj.decoderParams.errorTC*1000 )';
    muEOut=trimmean(esOut',5)';
    sigEOut=mean(trimstd(esOut',5)')+muEOut*0;
    % %%
    % for i=1:size(esOut,1)
    % emptyvec=ones(size(esOut(2,:),2),0);
    % foo=esOut(i,:)';
    %  [muEOut(i),Stats]=robustfit(emptyvec,foo);
    % end
    % figure; plot(muEOutB,'r.'); hold on; plot(muEOut,'b.'); plot(trimmean(esOut',10),'g.')
    % %%
    %
    % sigEOut=std(esOut(:,1:6000),[],2);
    % sigEOut=mean(sigEOut)+sigEOut*0;
    
    decoderProps.muEOut=muEOut;
    decoderProps.sigEOut=sigEOut;
    
    esOutNORM=(esOut-repmat(muEOut,1,size(esOut,2)))./repmat(sigEOut,1,size(esOut,2));
    
    figure; clf;
    subplot(3,1,1)
    plot(esOut')
    title(sprintf('Error per channel with tuning model ; Smoothing = %0.1f ',obj.decoderParams.errorTC))
    axis tight
    subplot(3,1,2); hold on
    avgSmoothedError=mean(abs(esOutNORM'));
    plot((avgSmoothedError-min(avgSmoothedError))*10,'.-'); hold on;
    plot( mnorm(obj.decoderProps.workingCopy.K'/sum(mnorm(obj.decoderProps.workingCopy.K'))*100),'r.-')
    legend('Average Smoothed Channel Error','norm(K)')
    subplot(3,1,3); hold on
    plot(abs(esOutNORM'))
    axis tight
    
    %%
    
    
    %%
    PlotFit=1;
    if PlotFit && strcmp(obj.decoderParams.TuningFeatures,'xdx')
        figure;
        p = panel();  p.margin=10;
        
        
        p.pack('v',{5/6 1/6});
        p(1).pack(obj.decoderParams.nDOF,2);
        p(2).pack('h',3);
        
        dt=obj.decoderParams.samplePeriod;
        dof=0;
        for i=1:2:size(x,1)
            dof=dof+1;
            
            p(1,dof,1).select(); cla
            hold on
            
            plot(x(i,testInds)','g'); axis tight
            plot(xOut(i,testInds)','r--'); axis tight
            
            
            t1=corr(x(i,testInds)',xOut(i,testInds)');
            
            title(sprintf('cc = %0.2f  ',t1))
            xlim([400 1000])
            
            p(1,dof,2).select(); cla
            hold on
            
            plot(x(i+1,testInds)','g'); axis tight
            plot(xOut(i+1,testInds)','r--'); axis tight
            
            
            t1=corr(x(i+1,testInds)',xOut(i+1,testInds)');
            jerk= sum(abs(diff(xOut(i+1,testInds),2)/dt.^2))/length(xOut(i+1,testInds));
            
            title(sprintf('cc = %0.2f  ; jerk = %0.1f ',t1,jerk))
            xlim([400 1000])
            
            
        end
        
        p(2,1).select();  hold on
        plot(zscore(b))
        plot(eNormS,'r')
        xlabel('Time (index)')
        ylabel('Spped/Error (Norm Units)')
        
        p(2,2).select();  hold on
        plot(eNormS,mnorm(x'),'.')
        title(sprintf('Speed Verus Error CC = %0.2f',corr(eNormS',mnorm(x'))))
        xlabel('Norm(FRest-FRact)')
        ylabel('Speed (Norm Units)')
        
        p(2,3).select();  hold on
        plot(esOutNORM')
        title(sprintf('Speed Verus Error CC = %0.2f',corr(eNormS',mnorm(x'))))
        xlabel('INDX')
        ylabel('Normalized Per Channel Error')
        
    end
    
    
    if PlotFit && strcmp(obj.decoderParams.TuningFeatures,'dx')
        figure;
        p = panel();  p.margin=10;
        
        
        p.pack('v',{5/6 1/6});
        p(1).pack('v',obj.decoderParams.nDOF);
        p(2).pack('h',3);
        
        dt=obj.decoderParams.samplePeriod;
        
        for i=1:size(x,1)
            
            
            p(1,i).select(); cla
            hold on
            xOutSA(i,:)=Kinematics.SpeedAdaptiveFilter(xOut(i,testInds),obj.decoderParams.samplePeriod,0);
            
            %         plot(dXsmooth(indx,:)','g'); axis tight
            %         plot(eNorm(testInds)*5,'.','color',[.65 .65 .65],'markersize',5)
            %         plot(eNormS(testInds)*5,'color',[.4 .4 .4])
            plot(x(i,testInds)','g'); axis tight
            plot(xOut(i,testInds)'*multFactor(i),'r--'); axis tight
            plot(xOutSA(i,:)'*multFactor(i),'b--'); axis tight
            
            
            t1=corr(x(i,testInds)',xOut(i,testInds)');
            jerk= sum(abs(diff(xOut(i,testInds),2)/dt.^2))/length(xOut(i,testInds));
            
            t2=corr(x(i,testInds)',xOutSA(i,:)');
            jerk2= sum(abs(diff(xOutSA(i,:),2)/dt.^2))/length(xOut(i,testInds));
            
            
            
            title(sprintf('cc = %0.2f (SA: %0.2f) ; jerk = %0.1f (SA: %0.1f)',t1,t2,jerk,jerk2))
            xlim([400 1000])
            
            
        end
        
        p(2,1).select();  hold on
        plot(zscore(b))
        plot(eNormS,'r')
        xlabel('Time (index)')
        ylabel('Spped/Error (Norm Units)')
        
        p(2,2).select();  hold on
        plot(eNormS,mnorm(x'),'.')
        title(sprintf('Speed Verus Error CC = %0.2f',corr(eNormS',mnorm(x'))))
        xlabel('Norm(FRest-FRact)')
        ylabel('Speed (Norm Units)')
        
        p(2,3).select();  hold on
        plot(esOutNORM')
        title(sprintf('Speed Verus Error CC = %0.2f',corr(eNormS',mnorm(x'))))
        xlabel('INDX')
        ylabel('Normalized Per Channel Error')
        
    end
    
end
%%
%
%
% % note that adding a multFactor here is the same as adding a posthoc
% % gain of the same amplitude.
% multFactor=Kinematics.computeVelocityGain(x_estT(2,:),dX(indx,:),[.8 .95]);
% B(2,:)=multFactor*B(2,:);
% %%
% clf; hold on
% plot(x(1,:)*1,'g')
% plot(x_estT(1,:)*1,'color',[.5 .5 .5]*0)
% corr(x_estT(1,:)',x(1,:)')
% %%
% alphas=0.5:.5:10; indx=0;
% for alph=alphas
%     indx=indx+1;
%     trend= Utilities.expsmooth( x_estT(1,:)', 1/obj.decoderParams.samplePeriod, alph*1000 )';
%     cc(indx)=corr(x_estT(1,:)'-trend',x(1,:)')
% end
% %%
% figure;
% subplot(3,1,1); cla
% plot(err_estT');
%
% subplot(3,1,2)
% plot(cumsum(err_estT')); hold on
%
% magR=sum(abs(KT(2:2:end,:)),1);
% highImpactInds=find(magR>prctile(magR,95));
% plot(cumsum(err_estT(highImpactInds,:)'),'color',[0 0 0],'linewidth',2)
%
% subplot(3,1,3); cla; hold on
% es=Utilities.expsmooth( err_estT', 1/obj.decoderParams.samplePeriod, 60*1000 )';
% plot(es');
% highImpactInds=find(magR>prctile(magR,98));
% plot(es(highImpactInds,:)','color',[0 0 0],'linewidth',2);
%
%
% %%
% plot(x_est(1,:)*3,'k','linewidth', 2)
% corr(x_est(1,:)',x(1,:)')
% corr(x_est(1,9000:12000)',x(1,9000:12000)')
% %% Appropriate Scaling
% for indx=1:size(x_estT,1)
%     % determine proper scaling
%     [dXS,IX] = sort(abs(x(indx,:)));
%     hv=round([.8 .99]*length(dXS));
%     hvIX=IX(hv(1):hv(2));
%     multFactor(indx)=x(indx,hvIX)/x_estT(indx,hvIX)
% end
% %%
% figure; subplot(2,1,1); hold on
% plot(xout(:,1),'r')
% plot(xoutT(:,1),'g')
% plot(x(2,1:i),'k')
% xlim([400 1000])
%
% subplot(2,1,2); hold on
% plot(xout(:,2),'r--')
% plot(xoutT(:,2),'g')
% plot(x(4,:),'g')
% xlim([400 1000])
% %%


%
% % step 2
% while (~Kflag)
%
%     P=A*SIG*A'+W;
%
%
%     switch options.PK_type
%         case 'shenoy'
%
%             P(1:2:2*nDOF,:)=0;
%             P(:,1:2:2*nDOF)=0;
%             P=P.*eye(size(P));
%         case 'standard'
%
%     end
%
%     newK=P*H'/(H*P*H'+Q);
%     if(~all(size(newK)==size(K)))
%         K=zeros(size(newK));
%     end
%
%     if(sum( (newK(:)-K(:)).^2 ) < 1e-10 )
%         Kflag = 1;
%     end
%     K = newK;
%
%     SIG=(eye(size(K,1))-K*H)*P;
%
%     P_save(:,:,iter)=P;
%     SIG_save(:,:,iter)=SIG;
%     K_save(:,:,iter)=K;
%     iter=iter+1;
%
%
% end
%
%
% Ac=(eye(size(A))-K*H)*A;
% Ac_orig=Ac;
% %
% PositionFeedbackINDXS=[2:2:nDOF*2 ; 1:2:nDOF*2];
% for i=1:size(PositionFeedbackINDXS,2)
%     INDX=PositionFeedbackINDXS(:,i);
%     if Ac(INDX(1),INDX(2))>-.1;
%         Ac(INDX(1),INDX(2))=-.1;
%     end
% end
%
% obj.options.decodeParameters.Ac=Ac;
% obj.options.decodeParameters.Ac_orig=Ac_orig;
% obj.options.decodeParameters.Bc=K;
% obj.options.decodeParameters.K=K;


