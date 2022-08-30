function [ spkmeanLR ] = spk_LR( fire_rate, task, params, debug, varargin )
%spk_LR compares a leftmost target and a right most target for spikes (or
%any two classes of data
%   Comparison of the targets directly left and the targets directly right
%   for firing rate on spikes.  This is the spk output of proc.task.bin.
%   The data is arranged as so: bins x channels x trials, e.g.245x128x64
%   which means it's 245 50msec bins, across 128 channels, split into 64
%   trials
%   
%  
% 
%OUTPUT:
%         spkmeanLR      =Structure that contains the output of the
%         trial_sorting (spkmeanLR.typeN.locations) to pull only the trials
%         of interest, and averaging across the data (spkmeanLR.typeN.data)
%        
%   
% To set up:
%   taskfile='C:\Users\Daniel\Documents\DATA\P010\20170830-PH2\Task\20170830-133354-133456-DelayedReach.mat'
%   task=FrameworkTask(taskfile);
%   params=Parameters.Dynamic(@Parameters.Config.BasicAnalysis, 'spk.type', 'nev', 'spk.unsorted', true);
%   debug=Debug.Debugger('testdebug');
%   fire_rate=proc.task.bin(task,params,debug);

% TO DO:
%       will need to remove the channels that are noise

%%
%find the channels if specified
[varargin, ch]=util.argkeyval('ch', varargin, [1 size(fire_rate,2)]);%size(task,2)
ch1=ch(1,1);
ch2=ch(1,2);
%see if user wants to do the whole grid or not
[varargin, full_grid]=util.argkeyval('full_grid', varargin, true);
%%
%check if sort_type was specified, meaning L vs R or up vs down
[varargin, sort_type]=util.argkeyval('sort_type', varargin, 1);

%find the set up if specified, meaning the channel organization to remove
%noise, standard 1 is 6x10/6 ch/noise, then 2x8/8 ch/noise
[varargin, standard, ~, found]=util.argkeyval('standard', varargin, 1);
if ~found
    fprintf('Unless otherwise specified in standard, set up is 3 10ch micros and 2 8 channel macros next to each other\n');
end

%%
%find the trials that are left or right.  
[ sort_data ] = Analysis.DelayedReach.trial_sort( task, params, debug, 'sort_type', sort_type );

%set up the output
spkmeanLR=struct;

spkmeanLR.type1.locations=sort_data.leftLocations;
spkmeanLR.type2.locations=sort_data.rightLocations;



%load the data for each row that is relevant
for ii=1:size(sort_data.leftLocations,2)
    temp1(:,:,ii)=fire_rate(:,:,sort_data.leftLocations(ii).trialNumber);
end
for ii=1:size(sort_data.rightLocations,2)
    temp2(:,:,ii)=fire_rate(:,:,sort_data.rightLocations(ii).trialNumber);
end


%load the data without the noise channels with all 3 dimensions, time
%bins x channels x trials
spkmeanLR.type1.data_full=temp1;
spkmeanLR.type2.data_full=temp2;
%take the mean at that row, from the channels specified, along the
%dimension of the trials
spkmeanLR.type1.data=nanmean(temp1(:, :, :),3);
spkmeanLR.type2.data=nanmean(temp2(:, :, :),3);



%%
%break the data up into the phases
[ phase_data1, phase_length]=Analysis.DelayedReach.phase_data(spkmeanLR.type1.data,  task, params, 'dimension', 2);
[ phase_data2 ]=Analysis.DelayedReach.phase_data(spkmeanLR.type2.data, task, params, 'dimension', 2);


%load the phase_data for output
spkmeanLR.type1.phase_data=phase_data1;
spkmeanLR.type2.phase_data=phase_data2;

%%
%create plots
plot_tr=true;
%plot the depth electrodes together, mac_sz is the size of the macros
%plugged in, can be 10, 8, or 6, macro is the amount of macros of this
%size.
if plot_tr==true
    Analysis.DelayedReach.plt_stereo(spkmeanLR, task, params, phase_length, 'mac_sz', 8, 'macro', 2, 'ch', ch, 'full_grid', full_grid)
end



end

