function [x_est,obj]=batchPredictOneStep(obj,x,z)


% The predict method only predicts the next state given the current state
% and neural data.  This is a wrapper function allowing for preictions
% given a timeseries of inputs.

% this method feeds back the true value of the state for the onestep
% predictions as opposed to using the estimated state (x_prev=x(:,i-1) not x_prev = x_est(:,i-1))

if size(x,2)~=size(z,2); 
    error('One step prediction requires the same number of time points for x and z')
end
% initialize
x_est(:,1)=x(:,1);

for i=2:size(z,2);
        
        x_prev=x(:,i-1);
        [x_est(:,i),obj]=obj.Predict(x_prev,z(:,i));        
    
end