function R2=directLinearDecoder(obj,KINEMATICS,FEATURES,PlotFit)
%%

if nargin<4 , PlotFit=1; end
activeFeatures=obj.options.decodeParameters.activeFeatures;
FEATURES=FEATURES(activeFeatures,:);
dt=obj.samplePeriod;
TrainingINDXS=obj.trainINDXS;
SmoothingValue=obj.options.SmoothingValue;

% Step 1
% Smooth the kinematic and neural data to maximize SNR for all fitting
% procedures.

filterCoeff=MakeFilter(SmoothingValue,1,50,0,'b');
% filterCoeff=MakeFilter(9,3,50,0,'b');
% filterCoeff=1;


[cKINEMATICS_smoothed]=filter(filterCoeff,1,KINEMATICS,[],2);
[FEATURES_smoothed]=filter(filterCoeff,1,FEATURES,[],2);
% [cKINEMATICS_smoothed]=filter_mirrored(filterCoeff,1,KINEMATICS,[],2);
% [FEATURES_smoothed]=filter_mirrored(filterCoeff,1,FEATURES,[],2);



Velocity=KINEMATICS(2:2:end,:);
VelocitySmoothed=cKINEMATICS_smoothed(2:2:end,:);


    if nargin>=5 && ~isempty(TrainingINDXS)
        cKINEMATICS_smoothed=cKINEMATICS_smoothed(:,TrainingINDXS);
        FEATURES_smoothed=FEATURES_smoothed(:,TrainingINDXS);
        
        KINEMATICS=KINEMATICS(:,TrainingINDXS);
        FEATURES=FEATURES(:,TrainingINDXS);
        
        Velocity=Velocity(:,TrainingINDXS);
        VelocitySmoothed=VelocitySmoothed(:,TrainingINDXS);
    end
    
    for k=1:size(Velocity,1)
        Vmdl1{k}=LinearModel.fit(FEATURES_smoothed',VelocitySmoothed(k,:)');
        R2(k)=Vmdl1{k}.Rsquared.Ordinary;
        obj.msgName(sprintf('Rsquared = %0.2f  for dof %d with %d samples %d Features',R2(k),k,length(VelocitySmoothed(1,:)),size(FEATURES_smoothed,1)))
    end



%% Step 2 : Construct Force Vectors
% construct force vectors
for k=1:size(Velocity,1)
    %     Bcf(k,:)=[Vmdl1{k}.Coefficients.Estimate(2:end)', Vmdl1{k}.Coefficients.Estimate(1)];
    Bcf(k,:)=[Vmdl1{k}.Coefficients.Estimate(2:end)'];
end

% FEATURES_AUG_S=[FEATURES_smoothed; (FEATURES_smoothed(end,:)*0+1) ];
% FEATURES_AUG=[FEATURES; (FEATURES(end,:)*0+1) ];
FEATURES_AUG_S=[FEATURES_smoothed ];
FEATURES_AUG=[FEATURES ];


V_est=Bcf*FEATURES_AUG;
V_estS=Bcf*FEATURES_AUG_S;

%% Step 3 : Fit dynamical system

Ac=[];
Bc=[];
for indx=1:size(Velocity,1)
    y=VelocitySmoothed(indx,:)';
    %     y=Velocity(indx,:)';
    u=V_est(indx,:)';
    
    opt = n4sidOptions('Focus','simulation' );
    % data = iddata(y(2:end),u(1:end-1),dt);
    data = iddata(y,u,dt);
    sys = n4sid(data,1,'Form','canonical',opt);
    
    % without the below lines, it fits the smoothness param, but we can enforce
    % it explicitly
    sys.Structure.a.Value(1)=SmoothingValue;
    sys.Structure.a.Free(1)=0;
    sys=pem(data,sys);
    %
    
    yEst(indx,1)=Velocity(indx,1);
    A=sys.A; B=sys.B;
    Params(indx,:)=[A,B];
    
    for j=2:length(V_est)
        yEst(indx,j)=A*yEst(indx,j-1)+B*u(j);
    end
    
    Ac{indx}=[1 dt; -.1 Params(indx,1)];
    Bc=[Bc; [Bcf(indx,:)*0; Bcf(indx,:)*Params(indx,2) ]];
    
    
    if PlotFit
        figure; hold on
        plot(VelocitySmoothed(indx,:)','g'); axis tight
        plot(Velocity(indx,:)'*.75,'g--'); axis tight
        plot(Vmdl1{indx}.Fitted','linewidth',2);
        plot(yEst(indx,:)','r--'); axis tight
        legend({'Vsmooth','V','Fit','DynSysFit'})
% s        title('Rsquared = %0.2f (dof %d ; %d samples; %d Features',R2(indx),indx,length(VelocitySmoothed(indx,:)),size(FEATURES_smoothed,1))
        
        xlim([1000 1500])
    end
    
end
%
%
%
% Ac=[1 dt; -.1 Params(1,1)];
% Bc=[Bcf*0; Bcf(1,:)*Params(1,2) ];



signifFeatures=logical(ones(size(find(activeFeatures))));
obj.options.decodeParameters.Ac=Utilities.blkdiagCell(Ac);
obj.options.decodeParameters.Bc=Bc;
obj.options.decodeParameters.signifFeatures=signifFeatures;


% figure; plot(V_estS');  hold on; plot(VelocitySmoothed','--')
% figure; plot(yEst');  hold on; plot(VelocitySmoothed','--')
%%
% indx=1;
% y=[cKINEMATICS_smoothed(indx,:)',VelocitySmoothed(indx,:)' ];
% u=[V_est(indx,:)'] ;
%
% tic
% opt = n4sidOptions('Focus','simulation' ,'Display', 'on')
% data = iddata(y,u,dt);
% sys = n4sid(data,2,'Form','canonical',opt);
% sys=pem(data,sys);
% toc


%% Alternate method for computing Ac and Bc
% y=[cKINEMATICS_smoothed',VelocitySmoothed' ];
% u=[V_est'] ;
%
% tic
% opt = n4sidOptions('Focus','simulation' ,'Display', 'on');
% data = iddata(y,u,dt);
% sys = n4sid(data,4,'Form','canonical',opt);
%
% sys.Structure.b.Value(1:2,1:2)=0;
% sys.Structure.b.Free(1:2,1:2)=0;
% sys.Structure.b.Value(4,1)=0;
% sys.Structure.b.Free(4,1)=0;
% sys.Structure.b.Value(3,2)=0;
% sys.Structure.b.Free(3,2)=0;
%
% sys.Structure.a.Value(1:2,1:4)=[1 0 dt 0 ; 0 1 0 dt];
% sys.Structure.a.Free(1:2,1:4)=0;
%
%
% sys=pem(data,sys,opt);
% toc
%
% Ac=sys.A;
% foo=[Bcf*0;Bcf];
%
%
% Bc=[Bcf*0; Bcf(1,:)*sys.B(3,1) ; Bcf(2,:)*sys.B(4,2)];


function SmFilt=MakeFilter(FilterOrder,FilterDurations,MaxDuration,PlotFilter,figopts)

if nargin < 5 ; figopts='k'; end

if FilterOrder>1;
    h = ones(1,FilterOrder); h=h/sum(h);
    binomialCoeff = conv(h,h);
    
    for n = 1:FilterDurations
        binomialCoeff = conv(binomialCoeff,h);
    end
    
    binomialCoeff=fliplr(binomialCoeff(1:ceil(length(binomialCoeff)/2)));
    
    if length(binomialCoeff)>MaxDuration;
        binomialCoeff=binomialCoeff(1:MaxDuration);
    end
    
    binomialCoeff=binomialCoeff-min(binomialCoeff);
    
    binomialCoeff=binomialCoeff/sum(binomialCoeff);
    
    SmFilt=binomialCoeff;
    
else
    
    
    inds=0:100;
    for i=inds; SC(i+1)=FilterOrder^i ; end
    
    if length(SC)>MaxDuration;
        SC=SC(1:MaxDuration);
    end
    
    SC=SC-min(SC);
    SC=SC/sum(SC);
    
    SmFilt=SC;
end


if PlotFilter
    plot(50*(-(length(SmFilt)-1):0),fliplr(SmFilt),figopts)
    axis tight
end


