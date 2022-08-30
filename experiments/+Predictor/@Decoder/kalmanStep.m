function [xOut,decoderProps,eOut,kOut,qOut]=kalmanStep(obj,x,z,decoder, trainMode)

% note, the contribution of individual units can be modiefied by using
% adjustNeuronContribution
if nargin<5,
    trainMode=0;
    qOut=[];
end
%%
decoderProps=decoder.decoderProps;

A=decoderProps.A;
H=decoderProps.H;
d=decoderProps.d;
W=decoderProps.W;
Q=decoderProps.Q;
I=decoderProps.I;

eH=decoderProps.eH;
% P=decoderProps.P;
% K=decoderProps.K;
SIG=decoderProps.SIG;

Kss=decoderProps.Bcf;
SIGss=decoderProps.SIGss;

% activeFeatures=decoderProps.activeFeatures;

errorAlpha=decoderProps.errorAlpha;

% robust params
pQ=decoderProps.pQ;
kalmanErrorWeight=decoderProps.kalmanErrorWeight;
robustWeight=decoderProps.robustWeight;

%%
% xP - x(t-1) Previous value of x
% xM - model estimate of x
% xC - x(t) Current estimate of x

xOut(:,1)=x(:,1);
xP = xOut;

switch lower(decoder.decoderParams.kalman.kalmanType)
    case 'standard'
        
        for i=1:size(z,2);
            %     tic  
            % Predict
            xM=A*xP;
            P=A*SIG*A'+W;
             if strcmp(decoder.decoderParams.kalman.PK_type,'shenoy')
                P(1:2:end,:)=0; P(:,1:2:end)=0; P=P.*eye(size(P));
            end
            % Update
%              case 'shenoy'
%             P(1:2:2*nDOF,:)=0;
%             P(:,1:2:2*nDOF)=0;
%             P=P.*eye(size(P));
            K=P*H'/(H*P*H'+Q);%  K=pinv(H*PT*H'+Q)*H*PT'; KT=KT'; alternate way - slow - BASICALLY SAME VALUES
            e=(z(:,i)-H*xM-d);
            xC=xM+K*e;
            SIG=(I-K*H)*P;
            
%             Using this form we can manipulate gain directly
%             Ac=(eye(2)-K*H)*A;
%             xC=Ac*xP+1.2*K*z(:,i);
            
            % Save
            eOut(:,i)=(z(:,i)-H*xC-d); % Different in firing rate between that estimated from state and the actual value.
            xOut(:,i)=xC; % saveState
            if trainMode
            qOut(:,:,i)=(z(:,i)-H*xC-d)*(z(:,i)-H*xC-d)';
            end
            xP=xC; % update current estimate
        end
        
    case 'robust1'
        % discounts instantaneous outliers
        
        
        for i=1:size(z,2);
            % Predict
            xM=A*xP;
            P=A*SIG*A'+W;
             if strcmp(decoder.decoderParams.kalman.PK_type,'shenoy')
                P(1:2:end,:)=0; P(:,1:2:end)=0; P=P.*eye(size(P));
            end
            GAM=Q;
            
            % Update
            notCoverged=1;
            xT=xM; % test value of state to test for convergence
            while notCoverged
                
                K=P*H'/(H*P*H'+GAM);
                e=(z(:,i)-H*xM-d);
                xC=xM+K*e;
                
                SIG=K*GAM'*K'+(I-K*H)*P'*(I-H'*K');
                eN=(z(:,i)-H*xC-d);                
                
                if sum((xT-xC).^2)<0.001; 
                    % for output, rescale as necassary
                    notCoverged=0;
                    
                    xOut(:,i)=xC; xP=xC;
                    eOut(:,i)=eN;
                    kOut(:,i)=mnorm(K);
                    
                else
                    qI=eN*eN';
                    if trainMode
                            qOut(:,:,i)=qI;
                        end
                    GAM=(robustWeight*Q+qI+H*SIG*H')/(robustWeight+1);
                    xT=xC;
                end

            end
        end
        
            case 'robust2'
        % discounts instantaneous outliers
        %%
        
        for i=1:size(z,2);
            % Predict
            
            xM=A*xP;
            P=A*SIG*A'+W;
             if strcmp(decoder.decoderParams.kalman.PK_type,'shenoy')
                P(1:2:end,:)=0; P(:,1:2:end)=0; P=P.*eye(size(P));
            end
            GAM=Q;
%             
%             Po=A*SIGo*A'+W;
%             Ko=P*H'/(H*P*H'+GAM);
%             SIGo=(I-Ko*H)*Po;
            
            % Update
            notCoverged=1;
            xT=xM; % test value of state to test for convergence
            count=0;
            while notCoverged
                count=count+1;
                K=P*H'/(H*P*H'+GAM);
                
%                 kGain(i)=Ko(:)'/K(:)';
% %                 repmat(diag(Ko/K),1,38);
%                 K=K.*repmat(diag(Ko/K),1,38);
%                 
                e=(z(:,i)-H*xM-d);
                xC=xM+K*e;
                
                SIG=K*GAM'*K'+(I-K*H)*P'*(I-H'*K');
                eN=(z(:,i)-H*xC-d);                
                count=count+1;
                if sum((xT-xC).^2)<0.0001 & count>1; 
                    % for output, rescale as necassary
                    notCoverged=0;
%                     pQ=pQe;
                    xOut(:,i)=xC; xP=xC;
                    eOut(:,i)=eN;
                    kOut(:,i)=mnorm(K);
                    
                    eH=errorAlpha*eH+(1-errorAlpha)*eN;
                    
%                     kCorr(i)=corr(K(:),Ko(:));
%                     kGain(i)=Ko(:)'/K(:)';
%                     figure(101); cla; plot(K','r'); hold on; plot(Ko','b'); ylim([-2 2])
%                     title(num2str(i))
% %                     figure(101);imagesc([K',Ko']); title(sprintf('%0.3f',corr(K(:),Ko(:))));
%                     pause(.1)
                    
                else
                    pQe=(1-kalmanErrorWeight)*eN*eN'+kalmanErrorWeight*eH*eH';
                    
                    GAM=(robustWeight*Q+pQe+H*SIG*H')/(robustWeight+1);
%                     GAM=(robustWeight*Q+pQe)/(robustWeight+1);
                    
                    xT=xC;
                    
                end

            end
        end
        
        
        case 'robust3'
        % discounts instantaneous outliers
        %%
        
        for i=1:size(z,2);
            % Predict
            
            xM=A*xP;
            P=A*SIGss*A'+W; % start with SS SIG (we want eH to carry memory, not SIG)
             if strcmp(decoder.decoderParams.kalman.PK_type,'shenoy')
                P(1:2:end,:)=0; P(:,1:2:end)=0; P=P.*eye(size(P));
            end
            GAM=Q;
            
            % Update
            notCoverged=1;
            xT=xM; % test value of state to test for convergence
            count=0;
            while notCoverged
                count=count+1;
                K=P*H'/(H*P*H'+GAM);
                
%                 kGain(i)=Ko(:)'/K(:)';
%                 repmat(diag(Ko/K),1,38);
                Km=K.*repmat(diag(Kss/K),1,size(K,2));
                
                e=(z(:,i)-H*xM-d);
                xC=xM+Km*e;
                
                SIG=K*GAM'*K'+(I-K*H)*P'*(I-H'*K');
                eN=(z(:,i)-H*xC-d);                
                count=count+1;
                if sum((xT-xC).^2)<0.0001 & count>1; 
                    % for output, rescale as necassary
                    notCoverged=0;
%                     pQ=pQe;
                    xOut(:,i)=xC; xP=xC;
                    eOut(:,i)=eN;
                    kOut(:,i)=mnorm(K);

                    eH=errorAlpha*eH+(1-errorAlpha)*eN;
                    
%                     kCorr(i)=corr(K(:),Ko(:));
%                     kGain(i)=Ko(:)'/K(:)';
%                     figure(101); cla; plot(K','r'); hold on; plot(Ko','b'); ylim([-2 2])
%                     title(num2str(i))
% %                     figure(101);imagesc([K',Ko']); title(sprintf('%0.3f',corr(K(:),Ko(:))));
%                     pause(.1)
%                     disp(count)
                else
                    pQe=(1-kalmanErrorWeight)*eN*eN'+kalmanErrorWeight*eH*eH';
                    
                    GAM=(robustWeight*Q+pQe+H*SIG*H')/(robustWeight+1);
%                     GAM=(robustWeight*Q+pQe)/(robustWeight+1);
                    
                    xT=xC;
                    
                end

            end
        end
        
    otherwise
        error('Unsupported Kalman Filter Type')
end

% write back values
% decoderProps.W=W;
decoderProps.Q=Q;
decoderProps.pQ=pQ;
decoderProps.P=P;
decoderProps.K=K;
decoderProps.SIG=SIG;
decoderProps.eH=eH;

