function trainPK(obj)


A=obj.options.decodeParameters.A;
W=obj.options.decodeParameters.W;
H=obj.options.decodeParameters.H;
Q=obj.options.decodeParameters.Q;

nDOF=obj.nDOF;

options=obj.options;
P=zeros(size(A));
Kflag = 0;
K = eye(size(A,1),size(H,1));
iter=1;
%%
Pm_save(:,:,iter)=P;
P_save(:,:,iter)=P;
K_save(:,:,iter)=K;
iter=iter+1;


if ~isempty(options.AW_W_velSetting),
    
    W=W*0;
    for i=2:2:obj.nDOF*2;
        W(i,i)=options.AW_W_velSetting;
    end
else
    W=W*options.AW_W_weighting;
end


% step 2
while (~Kflag)
    
    Pm=A*P*A'+W;
    
    
    switch options.PK_type
        case 'shenoy'
            
            Pm(1:2:2*nDOF,:)=0;
            Pm(:,1:2:2*nDOF)=0;
            Pm=Pm.*eye(size(Pm));
        case 'standard'
            
    end
    
    newK=Pm*H'/(H*Pm*H'+Q);
    if(~all(size(newK)==size(K)))
        K=zeros(size(newK));
    end
    
    if(sum( (newK(:)-K(:)).^2 ) < 1e-10 )
        Kflag = 1;
    end
    K = newK;
    
    P=(eye(size(K,1))-K*H)*Pm;
    
    Pm_save(:,:,iter)=Pm;
    P_save(:,:,iter)=P;
    K_save(:,:,iter)=K;
    iter=iter+1;
    
    
end


Ac=(eye(size(A))-K*H)*A;
Ac_orig=Ac;
% 
PositionFeedbackINDXS=[2:2:nDOF*2 ; 1:2:nDOF*2];
for i=1:size(PositionFeedbackINDXS,2)
    INDX=PositionFeedbackINDXS(:,i);
    if Ac(INDX(1),INDX(2))>-.1;
        Ac(INDX(1),INDX(2))=-.1;
    end
end

obj.options.decodeParameters.Ac=Ac;
obj.options.decodeParameters.Ac_orig=Ac_orig;
obj.options.decodeParameters.Bc=K;
obj.options.decodeParameters.K=K;


