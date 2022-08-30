function signalProps = SignalStatistics(obj,trainingData)

% Compute properties of the signals x and z for use in raw2model.  Examples
% include the mean of x and z.  Additional properties, for instance params
% necassary for dimensionality reduction etc. should also be computed here.

x=trainingData.rawX;
z=trainingData.rawZ;
trainINDXS=trainingData.trainINDXS;

% get the indices that will be used for computing statistics

nDOF=obj.decoderParams.nDOF;



%% Basic statistics
nStates=nDOF+nDOF*obj.decoderParams.diffX;
Corrs=corrcoef([x(:,trainINDXS);z(:,trainINDXS)]');
signalProps.Corrs=Corrs(1:nStates,nStates+1:end);
[~,peakCorrINDX]=max(abs(signalProps.Corrs),[],1);
for i=1:length(peakCorrINDX)
    signalProps.PeakCorrs(i)=signalProps.Corrs(peakCorrINDX(i),i);
end

% signal means and std. % assume velocity is zero mean
meanX=mean(x(:,trainINDXS),2); meanX(2:2:end)=0;
signalProps.meanX = meanX;
signalProps.meanZ = mean(z(:,trainINDXS),2);
signalProps.stdX = std(x(:,trainINDXS),[],2);
signalProps.stdZ = std(z(:,trainINDXS),[],2);

signalProps.nSamples = length(trainINDXS);

% we allow adaptive updating of means if requested.  Below we preserve what
% the original values are.
signalProps.origStats.meanX = meanX;
signalProps.origStats.meanZ = signalProps.meanZ;
signalProps.origStats.stdX = signalProps.stdX;
signalProps.origStats.stdZ = signalProps.stdZ;
signalProps.origStats.nSamples = signalProps.nSamples;


signalProps.velocityOffset = meanX(2:2:end)*0;



%% Feature Checks
% ensure nothing too screwy with training data
signalProps.hasInf=any(isinf(z(:,trainINDXS)'))';
signalProps.hasNans=sum(isnan(z(:,trainINDXS)),2)>0;
signalProps.noModulation=sum(abs(diff(z(:,trainINDXS),1,2)),2)==0;

% for threshold on firing rate, check in general, and also during times of
% movement.  If either says that the unit is not low firing, than it should
% not be marked as low firing.
lowFiringA=mean(z(:,trainINDXS)')'/obj.decoderParams.samplePeriod<obj.decoderParams.minFiringRate;


% find periods of movement and look at firing rate.
speed=util.mnorm(x(2:2:end,trainINDXS)');
[refSigSorted,IX] = sort(abs(speed));
hv=round([.7 1]*length(refSigSorted));
move_indxs=IX(hv(1):hv(2));
% [~,move_indxs,~]= Kinematics.findMoveRest(speed);
lowFiringB=mean(z(:,trainINDXS(move_indxs))')'/obj.decoderParams.samplePeriod<obj.decoderParams.minFiringRate;


%%
signalProps.lowFiring=lowFiringA;
% signalProps.lowFiring=~(~lowFiringA|~lowFiringB);


activeFeatures=~[signalProps.lowFiring | signalProps.noModulation|signalProps.hasNans|signalProps.hasInf];

% only apply activefeatures cirteria to non lfp features
if ~isempty(obj.featureProps.featType)
    lfpINDX=find(obj.featureProps.featType==1);
    activeFeatures(lfpINDX)=~signalProps.noModulation(lfpINDX);
end

% check to see if some features are specified to be excluded
if isempty(obj.decoderParams.validFeatures); 
    validFeatures=true(size(z,1),1); 
    signalProps.validFeatures=validFeatures;
else
    validFeatures=obj.decoderParams.validFeatures; 
end

% limit to lfp or spiking features if specified
if ~isempty(obj.featureProps.featType)
   if ~obj.decoderParams.useLFP
       lfpINDX=find(obj.featureProps.featType==1);
       validFeatures(lfpINDX)=0;
   end
   
   if ~obj.decoderParams.useSpiking
       spikeINDX=find(obj.featureProps.featType==2);
       validFeatures(spikeINDX)=0;
   end
end



activeFeatures = validFeatures & activeFeatures;

signalProps.activeFeatures=activeFeatures(:);

obj.msgName(sprintf(' %d/%d features meet minimal feature criteria ',nnz(activeFeatures),length(activeFeatures)),[1 1])






% 
% 
% %% Compare w/wo feature reduction ; w/wo Covariance
% % % significant featuers before or after
% Ht=H(signifFeatures,:);
% Bct1=pinv(Ht'*Ht)*Ht';
% 
% Bc1=pinv(H'*H)*H';
% Bc1=Bc1(:,signifFeatures);
% 
% 
% 
% figure; 
% p=panel();
% p.pack(3,2)
% p(1,1).select();
% 
% bar([Bct1(2,:);Bc1(2,:)]')
% c=corrcoef([Bct1(2,:);Bc1(2,:)]');
% title(sprintf('Compare before/after (CC = %0.2f)',c(2)))
% legend({'before','after'})
% p(2,1).select();
% bar([Bct1(4,:);Bc1(4,:)]')
% c=corrcoef([Bct1(4,:);Bc1(4,:)]');
% title(sprintf('Compare before/after (CC = %0.2f)',c(2)))
% legend({'before','after'})
% p(3,1).select();
% bar([Bct1(5,:);Bc1(5,:)]')
% c=corrcoef([Bct1(5,:);Bc1(5,:)]');
% title(sprintf('Compare before/after (CC = %0.2f)',c(2)))
% legend({'before','after'})
% 
% 
% Ht=H(signifFeatures,:);
% Bct1=pinv(Ht'*pinv(Q(signifFeatures,signifFeatures))*Ht)*Ht'*pinv(Q(signifFeatures,signifFeatures));
% 
% Bc1=pinv(H'*pinv(Q)*H)*H'*pinv(Q);
% Bc1=Bc1(:,signifFeatures);
% 
% p(1,2).select();
% bar([Bct1(2,:);Bc1(2,:)]')
% c=corrcoef([Bct1(2,:);Bc1(2,:)]');
% title(sprintf('Compare before/after (CC = %0.2f)',c(2)))
% 
% p(2,2).select();
% bar([Bct1(4,:);Bc1(4,:)]')
% c=corrcoef([Bct1(4,:);Bc1(4,:)]');
% title(sprintf('Compare before/after (CC = %0.2f)',c(2)))
% 
% p(3,2).select();
% bar([Bct1(5,:);Bc1(5,:)]')
% c=corrcoef([Bct1(5,:);Bc1(5,:)]');
% title(sprintf('Compare before/after (CC = %0.2f)',c(2)))
% 
% 
% %% Compare w/wo position ; w/wo Covariance
% H_NoPosition=H(:,[2,4,5]);
% Bct1=pinv(H_NoPosition'*H_NoPosition)*H_NoPosition';
% % with or without position information
% Bc1=pinv(H'*H)*H';
% 
% figure; 
% p=panel();
% p.pack(3,2)
% p(1,1).select();
% bar([Bct1(1,:);Bc1(2,:)]')
% c=corrcoef([Bct1(1,:);Bc1(2,:)]');
% title(sprintf('Compare w/wo position (CC = %0.2f)',c(2)))
% legend({'woPos','wPos'})
% p(2,1).select();
% bar([Bct1(2,:);Bc1(4,:)]')
% c=corrcoef([Bct1(2,:);Bc1(4,:)]');
% title(sprintf('Compare w/wo position (CC = %0.2f)',c(2)))
% legend({'woPos','wPos'})
% p(3,1).select();
% bar([Bct1(3,:);Bc1(5,:)]')
% c=corrcoef([Bct1(3,:);Bc1(5,:)]');
% title(sprintf('Compare w/wo position (CC = %0.2f)',c(2)))
% legend({'woPos','wPos'})
% 
% 
% H_NoPosition=H(:,[2,4,5]);
% Bct1=pinv(H_NoPosition'*pinv(Q)*H_NoPosition)*H_NoPosition'*pinv(Q);
% % with or without position information
% Bc1=pinv(H'*pinv(Q)*H)*H'*pinv(Q);
% p(1,2).select();
% bar([Bct1(1,:);Bc1(2,:)]')
% c=corrcoef([Bct1(1,:);Bc1(2,:)]');
% title(sprintf('Compare w/wo position w COV (CC = %0.2f)',c(2)))
% legend({'woPos','wPos'})
% p(2,2).select();
% bar([Bct1(2,:);Bc1(4,:)]')
% c=corrcoef([Bct1(2,:);Bc1(4,:)]');
% title(sprintf('Compare w/wo position w COV (CC = %0.2f)',c(2)))
% legend({'woPos','wPos'})
% p(3,2).select();
% bar([Bct1(3,:);Bc1(5,:)]')
% c=corrcoef([Bct1(3,:);Bc1(5,:)]');
% title(sprintf('Compare w/wo position w COV (CC = %0.2f)',c(2)))
% legend({'woPos','wPos'})
% %%
% %
% % Bc1=pinv(H'*H)*H';
% % Bc1=Bc1(:,signifFeatures);
% % figure; bar([Bct1(2,:);Bc1(2,:)]')
% % corrcoef([Bct1(2,:);Bc1(2,:)]')
% 
% %%
% Bc1=pinv(H'*H)*H';
% Bc1=pinv(Ht'*Ht)*Ht';
% 
% 




end

