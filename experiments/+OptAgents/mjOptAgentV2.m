classdef mjOptAgentV2 < handle
    
    % Coinstruct and utilize optimal agent for inferring next optimal state
    % to get to goal.
    properties
        K                            % lqr gain
        A                            % system equation x(t+1)=A*x(t)+B*u(t)
        B
        SamplingInterval ;     % Sampling Interval of the system
        sys
        mjProfile
        dampingValue
        dampingRadius
        filterVal
        isTraining
    end
    
    methods
        
        function obj = mjOptAgentV2(duration,SamplingInterval,dampingRadius)
            obj.filterVal=.25;
            obj.isTraining=1;
            obj.dampingValue=.8;
            %
            % Here we wish to construct an LQR servo controller that is capable of
            % generating the kinematics that we expect the subject is attempting to
            % produce.  Here, the assumption is that optimal feedback control can act
            % as a normative model of desired output.  obj output can than be used to
            % retrain the decoder.
            
            if nargin==0, duration=1.500; end
          
            
            if nargin<2
                SamplingInterval=0.05; obj.SamplingInterval=SamplingInterval; 
            else
                obj.SamplingInterval = SamplingInterval;
            end
            
            if nargin>=3
               obj.dampingRadius=dampingRadius;
            else
                obj.dampingRadius=1;
            end
            
            % % Step 1 : Construct the physical system that the subject is controlling.
            % A=[1 obj.SamplingInterval ; -.05 .85];
            A=[1 obj.SamplingInterval ; 0 0];
            % A=[1 0.15; 0 .3];
            B=[0; 1];
            C=[1 0; 0 1];
            D=0;
            sys=ss(A,B,C,D,obj.SamplingInterval);
            obj.sys=sys; obj.A=A; obj.B=B;
            
            % Optimize gains
            obj.mjProfile=flipud(cumsum(Kinematics.MinJerkKernel(1000*duration, 1000*SamplingInterval)));
            obj.mjProfile=[obj.mjProfile ; zeros(round(.1*length(obj.mjProfile)),1)];
            fminunc(@obj.mjCost,[0 0],optimset('Display','off','Largescale','off'));
            obj.isTraining=0;
            
            obj.K=[.4 -.6];
            obj.dampingValue=1;
        end
        
        function setNewDuration(obj,duration)
                        % OPtimize gains
            obj.mjProfile=flipud(cumsum(Kinematics.MinJerkKernel(1000*duration, 1000*obj.SamplingInterval)));
            obj.mjProfile=[obj.mjProfile ; zeros(round(1*length(obj.mjProfile)),1)];
            fminunc(@obj.mjCost,[0 0],optimset('Display','off','Largescale','off'));
        end
        
        function [states,t]=PlotInitialResponse(obj,x0)
            
            if nargin==1; 
                x0=[1 0]'; 
            else
                if length(x0)==1;
                     x0=[x0;0];
                else
                    x0=x0(:);
                end
            end
            mjProfile=obj.mjProfile*x0(1);
            
            t=[0:length(obj.mjProfile)-1]*obj.SamplingInterval;
            [states, forces]=computeMultipleSteps(obj,x0,0, length(obj.mjProfile));
            states=states';forces=forces';
            
            figure; subplot(3,1,1);
            plot(t,states(:,1),t,mjProfile,'r')
            legend({'OptAgent','MinJerk'})
            xlabel('Time')
            ylabel('Position')
            
            subplot(3,1,2)
            
            plot(t,states(:,2),'.-',t,[diff(mjProfile)/obj.SamplingInterval;0],'r.-')
            legend({'OptAgent','MinJerk'})
            xlabel('Time')
            ylabel('Velocity')
            
                    subplot(3,1,3)
            
            plot( t,forces,'g')
            legend({'Force'})
            xlabel('Time')
            ylabel('Force')
            
        end
        
        function [nextState,u]=computeNextStep(obj,curState,trackingSignal)
            % Compute the next state the dynamical system will be in
            % assuming an optimal controller is controlling the system.
            % multiple dofs can be handled if they are simply concatenated
            % along the rows.
            if length(curState)~=(length(trackingSignal)*2)
                error('Number of dofs and number of goals must match')
            end
            % number of states inferred from curState
            nStates=size(curState,1)/2;
            if nStates==1;
                B=obj.B;
                A=obj.A;
                r=[trackingSignal;0];
                err=r-curState;
                u=obj.K*err;
                
                DesDir=trackingSignal(:)-curState(1:2:end);
                OptVel=B*u;
                
                if util.mnorm(DesDir(:)')==0
                    DesVel = 0;
                else
                    DesVel=DesDir/util.mnorm(DesDir(:)')*util.mnorm(OptVel(2:2:end)');
                end
                 if util.mnorm(DesDir(:)')<obj.dampingRadius && obj.isTraining==0
                    DesVel=DesVel*.5;
                 end
                 OptVel(2:2:end)=DesVel;
                 nextState=A*curState+OptVel;
                 
%                 nextState(2:2:end)=DesVel;   
%                  nextState=A*curState+B*u;
%                 nextState(2:2:end)=DesVel;
%                 if mnorm( nextState(2:2:end))>mnorm( curState(2:2:end))
%                     nextState(2:2:end)=nextState(2:2:end)*.9;
%                 end
%                 disp(DesVel)
            else
                r=zeros(size(curState));
                r(1:2:end)=trackingSignal;
                err=r-curState;
                
                K=util.blkdiagCell(repmat({obj.K},1,nStates));
                u=K*err;
                A=util.blkdiagCell(repmat({obj.A},1,nStates));
                B=util.blkdiagCell(repmat({obj.B},1,nStates));
                
                DesDir=trackingSignal(:)-curState(1:2:end);
                OptVel=B*u;
                
                if util.mnorm(DesDir(:)')==0
                    DesVel = 0;
                else
                    DesVel=DesDir/util.mnorm(DesDir(:)')*util.mnorm(OptVel(2:2:end)');
                end
                
                if ~obj.isTraining && util.mnorm(DesDir(:)')<obj.dampingRadius
                    DesVel=DesVel*obj.dampingValue;
                end
                
                nextState=A*curState+B*u;
                nextState(2:2:end)=DesVel;
                
            end
            
            if any(isnan(trackingSignal))
                u=u*0;
                nextState(1:2:end)=curState(1:2:end);
                nextState(2:2:end)=curState(2:2:end)*0;
            end 
            if ~obj.isTraining
                 nextState(2:2:end)= (1-obj.filterVal)*nextState(2:2:end)+obj.filterVal*curState(2:2:end);
            end
        end
        
           
        
        function [nextState , u]=computeMultipleSteps(obj,curState,trackingSignal, NSteps)
            nextState=curState;  u=repmat(NaN,length(nextState)/2,1);
            if size(trackingSignal,2)==1
                for i=1:NSteps-1
                    [nextState(:,i+1),u(i+1)]=computeNextStep(obj,nextState(:,i),trackingSignal);
                end
            else
                for i=1:NSteps-1
                    [nextState(:,i+1),u(:,i+1)]=computeNextStep(obj,nextState(:,i),trackingSignal(:,i));
                end
            end
        end
        
        function cost=mjCost(obj,params)
            % cost function for fitting gains to minjerk profile
            N=length(obj.mjProfile);
            obj.K=params(1:2);
            states=computeMultipleSteps(obj,[1;0],0, N)';
            
            c=sqrt((states(:,1)-obj.mjProfile).^2); c(round(N/2):end)= c(round(N/2):end)*3;
            cost=sum(c);
        end
        
    end
end
