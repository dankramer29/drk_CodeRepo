function [H,Q]=trainHQ(obj,x,z)
%%rain H and Q for the kalman filter.
% H is the mapping between kinematic state and neural activity and
% Q is the model error (z=H*x+Q)
options=obj.decoderParams.kalman;
trainINDXS = obj.decoderParams.trainINDXS;
activeFeatures=obj.signalProps.activeFeatures;
z=z(activeFeatures,:);
switch options.HQ_H_FitMethod
    
    case {'standard','robust'}
        
        %%
        % initialize params
        b=zeros(size(z,1),size(x,1)+1);
        p=ones(size(z,1),size(x,1)+1);
        cb=ones(size(z,1),size(x,1)+1)*inf;
        
        p_all=ones(size(z,1),1);
        R2=zeros(size(z,1),1);
        
        Full_MDL=cell(size(z,1),1);
        
        clear mdl
        
        %% fit valid features
        for indx=1:size(z,1);
            
            switch options.HQ_H_FitMethod
                case 'standard'
                    mdl = LinearModel.fit(x(:,trainINDXS)',z(indx,trainINDXS)');
                case 'robust'
                    mdl = LinearModel.fit(x(:,trainINDXS)',z(indx,trainINDXS)','RobustOpts','on');
            end
            
            % coefficient values and associated significance
            b(indx,:)=mdl.Coefficients.Estimate;
            p(indx,:)=mdl.Coefficients.pValue;
            cb(indx,:)=mdl.Coefficients.SE*1.96;
            
            % overall fit measures
            p_all(indx)=mdl.coefTest;
            R2(indx)=mdl.Rsquared.Adjusted;
            
            Full_MDL{indx}=mdl;
            
        end
        
%         if options.reduceFeatures
%             signifFeatures=p_all<options.featureSignificanceLevel;
%         else
%             signifFeatures=logical(ones(size(find(activeFeatures))));
%         end
        
        signifFeatures=logical(ones(size(find(activeFeatures))));
        if options.HQ_augmentedForm
            H = [b(:,2:end),b(:,1)];
            P=[p(:,2:end),p(:,1)];
            CB=[cb(:,2:end),cb(:,1)];
        else
            H = b(:,2:end);
            P = p(:,2:end);
            CB=cb(:,2:end);
            Intercept=b(:,1);
        end
        obj.trainingProps.Hstats.P=P;
        obj.trainingProps.Hstats.CB=CB;
        obj.trainingProps.Hstats.P_fullmodel=p_all;
        obj.trainingProps.Hstats.R2=R2;
        obj.trainingProps.Hstats.Full_MDL=Full_MDL;
        obj.trainingProps.Hstats.Intercept=Intercept;
        obj.trainingProps.Hstats.H_full=H;
        
        H=H(signifFeatures,:);
        
    otherwise
        error('Unsupported Htype')
end





M=length(trainINDXS);
% calculate Q, the covariance of noise in the measured features
if options.HQ_augmentedForm
    
    % we stripped augmented x earlier, put it back for Q calculation
    x_aug=[x;ones(1,size(x,2))];
    z_pred=H*x_aug(:,trainINDXS);
    z_actual=z(signifFeatures,trainINDXS);
    
    residuals=z_actual-z_pred;
    
    %     residuals=residuals.*repmat(options.Weights,size(residuals,1),1);
    
    
    Q = (1/M)*(residuals)*(residuals)';
    
    
else
    z_pred=H*x(:,trainINDXS);
    z_actual=z(signifFeatures,trainINDXS);
    
    residuals=z_actual-z_pred;
    %     residuals=residuals.*repmat(options.Weights,size(residuals,1),1);
    
    
    Q = (1/M)*(residuals)*(residuals)';
    
    
end

obj.decoderProps.tmp.decoderProps.H=H;
obj.decoderProps.tmp.decoderProps.Q=Q;
obj.decoderProps.tmp.decoderProps.signifFeatures=signifFeatures;



function LassoFit(x,z,trainINDXS,validFeatures)


xp=x(:,trainINDXS)';
% initialize H
if options.augmentedForm
    H_full=zeros(size(z,1),size(x,1)+1);
else
    H_full=zeros(size(z,1),size(x,1));
end


%% fit valid Features
for indx=find(validFeatures)';
    
    [B FitInfo] = lasso(xp,z(indx,trainINDXS)','CV',10,'Options',opts);
    
    OptIndx=FitInfo.IndexMinMSE;
    %OptIndx=FitInfo.Index1SE;
    
    if options.augmentedForm
        H_full(indx,:)=[B(:,OptIndx),FitInfo.Intercept(OptIndx)];
        
    else
        H_full(indx,:)=B(:,OptIndx);
        Intercept(indx)=FitInfo.Intercept(OptIndx);
        
    end
    
    
end

if options.reduceFeatures
    signifFeatures=logical(sum(H_full(:,:),2));
else
    signifFeatures=logical(ones(size(find(options.validFeatures))));
end


Hstats=[];
H=H_full(signifFeatures,:);

Hstats.Intercept=Intercept;