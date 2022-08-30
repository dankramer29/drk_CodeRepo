function [obj,fitComp]=Validate(obj, KINEMATICS, FEATURES,trainINDXS,testIndices,plotResults)

% [obj,fitComp]=Validate(obj, KINEMATICS, FEATURES,trainINDXS,testIndices,plotResults)
% two modes: if trainINDXS is not empty, train decoder on trainINDXS
% data and validate on testIndices data.  if it is empty, apply currently
% trained decoder on testIndices

if nargin==5; plotResults=false; end
if isempty(trainINDXS) & ~obj.isTrained
    error('Decode object is not trained, specify trainINDXS or train object')
end

% if trainingIndices are provided, retrain filter on trainINDXS
if ~isempty(trainINDXS)
    obj.Train('xz',KINEMATICS,FEATURES,'trainINDXS',trainINDXS);
end

x_test=obj.raw2raw(KINEMATICS(:,testIndices));

% x_test=KINEMATICS(:,testIndices);
z_test=FEATURES(:,testIndices);


x_fit=obj.batchPredict([],z_test);

residuals=(x_fit-x_test);


% Compute mean jerk of the solution.
% jerk=mean(abs(diff(Utilities.mnorm(x_fit(2:2:end,:)'),2)/(obj.samplePeriod.^2)));
%%


if plotResults
    figure; clf
end

plotINDX=1;
for posDims=1:size(x_test,1);
    
%     dof=floor(posDims./2);
%     der=rem(posDims,2);
    
    CC=corrcoef(x_test(posDims,:),x_fit(posDims,:));CC=CC(1,2);
    RMSE=mean(abs(x_test(posDims,:)-x_fit(posDims,:)));
    
    
    
    CC_(posDims)=CC;
    RMSE_(posDims)=RMSE;
    
    
    
    if plotResults
        subplot(obj.nDOF,2,posDims)
        hold on
        plot(x_test(posDims,:)','k')
        plot(x_test(posDims,:)','k.','markersize',1)
        plot(x_fit(posDims,:)','r')
        title(sprintf('CC = %0.2f ; RMSE = %0.2f ',CC,RMSE))
        axis tight
    end
    
end
% 
% if plotResults
%     subplot(obj.nDOF,4,posDims+1)
%     
%     hist(residuals(1:obj.nDOF,:)',20)
%     legend('dim1','dim2')
%     title('Position Error')
%     
%     subplot(obj.nDOF,4,posDims+2)
%     
%     hist(residuals(obj.nDOF+1:end,:)',20)
%     legend('dim1','dim2')
%     title('Velocity Error')
%     
%     
% end
%%
fitComp.residuals=residuals;
fitComp.R2=CC_.^2;
fitComp.RMSE=RMSE_;
fitComp.Estimate=x_fit;
% fitComp.MeanJerk=jerk;

%%