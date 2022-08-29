function [ phase_data, phase_length ] = phase_data( data, task, params, varargin )
%phase_data groups the data based on the phase
%   Detailed explanation goes here
%   st=     the start time after the tm.bufferpre, can be entered by hand
%           or by figured out
%   NOTE: THIS IS THE AVERAGE AMOUNT OF PHASES IN EACH TRIAL AND NEEDS TO BE FIXED FOR ANY CONTINUOUS DATA
%   [ phase_data]=Analysis.DelayedReach.phase_data(data, params, st );


%%
%find bin width
bin=params.spk.binwidth;
%find the amount of phases
ph=task.numPhases;

%%
%check if start time was specified
[varargin, st, ~, found]=util.argkeyval('st', varargin, []); 
if ~found
    st=params.tm.bufferpre/bin;
end

%%
%check if start time was specified
[varargin, dimension, ~, found]=util.argkeyval('dimension', varargin, 1); 
if ~found
    fprintf('data broken up into phases in 3D\n');
end


%%
%find the length of each phase adjusted for the trial, then divide by bins
%to see how many bins in each phase, then round to make even bins.   
phase_length(1,1)=1;
%Since the trials are collapsed together, find the mean and round that.
%Keep in mind that on average, it adds a bin of 50ms
phase_length(1,2:ph)=round(mean(diff(task.phaseTimes,1,2)/bin));
phase_length=cumsum(phase_length);
%add the start time
phase_length=phase_length+st;
phase_length(1,end+1)=length(data);

%%
%get the correct things into their bins.

switch dimension
    case 1
        %get the correct things into their bins on the 3D data.
        for jj=1:size(phase_length,2)-1
            phase_data{jj}=data(phase_length(1,jj):phase_length(1,jj+1),:,:);
        end
        
    case 2
        %get the correct things into their bins on the 2D data
        for jj=1:size(phase_length,2)-1
            phase_data{jj}=data(phase_length(1,jj):phase_length(1,jj+1),:);
        end
        
end

end

