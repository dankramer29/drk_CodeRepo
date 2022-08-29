function [x_est,xIdeal_est]=batchPredict(obj,x,z,varargin)

% The predict method only predicts the next state given the current state
% and neural data.  This is a wrapper function allowing for preictions
% given a timeseries of inputs.



obj.msgName(sprintf('Batch predicting with decoder indx %d - %s',obj.currentDecoderINDX, obj.decoders(obj.currentDecoderINDX).name))


% initialize variables
goal=[]; % iniformation about the location of the goal
useGoal=0; % passes the goal information to the predictor (if assistance is on, will affect prediction)

simulate=0; % playback collected data

% Plotting information
plotResults=0; % whether to plot fit
pltclr='b'; % color of plot
plotVelocityOnly=1; % only plots velocity (not position)
plotX=1;  % plot the ideal signal
plotX_est=1; % plot the reconstruction
plotGoal=0; % plot the location of the goal 

plotCursor=0; % will animate the decoded cursor

if nargin<4 || isempty(goal); useGoal=0; plotGoal=0; end

inputArguments=varargin;
while ~isempty(inputArguments)
    
    switch lower(inputArguments{1})
        case lower('plotX')
            plotX=inputArguments{2};
            inputArguments(1:2)=[];
               case lower('simulate')
            simulate=inputArguments{2};
            inputArguments(1:2)=[];
            
        case lower('goal')
            goal=inputArguments{2};
            inputArguments(1:2)=[];
        case lower('plotGoal')
            plotGoal=inputArguments{2};
            inputArguments(1:2)=[];
        case lower('useGoal')
            useGoal=inputArguments{2};
            inputArguments(1:2)=[];
                    case lower('plotResults')
            plotResults=inputArguments{2};
            inputArguments(1:2)=[];
                    case lower('pltclr')
            pltclr=inputArguments{2};
            inputArguments(1:2)=[];
            
              case lower('plotCursor')
            plotCursor=inputArguments{2};
            inputArguments(1:2)=[];
              case lower('plotVelocityOnly')
            plotVelocityOnly=inputArguments{2};
            inputArguments(1:2)=[];
            
        case lower('trainINDXS')
            trainINDXS=inputArguments{2};
            inputArguments(1:2)=[];
        otherwise
            error('Input %s is not a valid arguement, try again ',inputArguments{1})
    end
    
    
end


if size(x,1)==obj.decoderParams.nDOF && obj.decoderParams.diffX ;  x=obj.position2state(x); end
if useGoal
    if size(x,1)~=(size(goal,1)*2)
        error('Number of dofs and number of goals must match - ignoring goals');
    end
end
if isempty(x); plotX=0; x=zeros(obj.decoderParams.nDOF*2,1); end
% if size(x,2)~=size(z,2); plotX=0;  end
%% iterate though and predict for each timestep
x_est(:,1)=x(:,1);
if useGoal;
    xIdeal_est=x(:,1);
else,
    xIdeal_est=[];
end


% save decoder options.
bufferData=obj.BufferData;

if ~simulate
    obj.BufferData=0;
end

if plotCursor
    pC=obj.runtimeParams.plotCursor;
    obj.runtimeParams.plotCursor=1;
else
    pC=obj.runtimeParams.plotCursor;
    obj.runtimeParams.plotCursor=0;
end


for i=2:size(z,2);
    if plotCursor
        t=GetSecs;
    end
    if simulate
    x_prev=x(:,i-1);
    else
    x_prev=x_est(:,i-1);    
    end
    if useGoal
        [x_est(:,i),xIdeal_est(:,i)]=obj.Predict(x_prev,z(:,i),goal(:,i));
    else
        [x_est(:,i)]=obj.Predict(x_prev,z(:,i));
    end
    
    if plotCursor % animate in realish time
        drawnow;
        WaitSecs('UntilTime', t+obj.decoderParams.samplePeriod);
    end
    
end

obj.runtimeParams.plotCursor=pC;
obj.BufferData=bufferData;
%% Plot the results if requested
if plotResults
    if isfield(obj.figureHandles,'batchPredict')
        figure(obj.figureHandles.batchPredict);
        hold on
        
    else
        obj.figureHandles.batchPredict=plt.fig('units','inches','width',18,'height',6,'font','Cambria','fontsize',16);
    end
    
    
    for posDims=1:size(x,1);
        
        if rem(posDims,2)==1 && plotVelocityOnly; continue; end
        %     dof=floor(posDims./2);
        %     der=rem(posDims,2);
        
        if plotX
            if size(x(posDims,:),2) == size(x_est(posDims,:),2)
                CC=corrcoef(x(posDims,:),x_est(posDims,:));CC=CC(1,2);
                RMSE=mean(abs(x(posDims,:)-x_est(posDims,:)));
                CC_(posDims)=CC;
                RMSE_(posDims)=RMSE;
            else
                warning('x~=z so cant compute fit')
            end
            
        end
        if plotVelocityOnly
            subplot(obj.decoderParams.nDOF,1,max([posDims/2 1]))
        else
            subplot(obj.decoderParams.nDOF,2,posDims)
        end
        hold on
        if plotX && size(x(posDims,:),2) == size(x_est(posDims,:),2)
            plot(x(posDims,:)','k')
            if rem(posDims,2)==1
                title(sprintf('CC = %0.2f ; RMSE = %0.2f ',CC,RMSE))
            else
                jerk=sum( abs( zscore(diff(x_est(posDims,:),2)/obj.decoderParams.samplePeriod.^2)))/length(x_est(posDims,:));
                title(sprintf('CC = %0.2f ; RMSE = %0.2f ; Jerk = %0.2f ',CC,RMSE,jerk))
            end
        else
            
        end
        
        plot(x_est(posDims,:)',pltclr)
        
        if rem(posDims,2)==1 && plotGoal
            indx=floor(posDims/2)+1;
            plot(goal(indx,:)','g')
        end
        
        axis tight
        
    end
end