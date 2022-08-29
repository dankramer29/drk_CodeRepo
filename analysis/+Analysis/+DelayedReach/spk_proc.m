function [ fire_rate, tuned_chs, phase_length, targetmean, gof_stats, overall_stats] = spk_proc( task, params, debug, varargin )
%spk_proc The main processing tool for spikes
%   Will rely heavily on work on spk_LR
% 
% Outputs:
%     spk_rate        =will contain fire_rates, p values for each channel
%     for the different phases, ... spkmeancomp     =output of spkmeanLR,
%     which will split the trials into two categories and compare them with
%     graphs
% 
%[ fire_rate, tuned_chs,  phase_length, targetmean, gof_stats] = Analysis.DelayedReach.spk_proc( task, params, debug );
% if you want to do just a few channels, like this
%[ fire_rate, tuned_chs,  phase_length, targetmean, gof_stats] = Analysis.DelayedReach.spk_proc( task, params, debug, 'ch', [17 26], 'full_grid', false );


%%
%find the channels if specified, if not, only does the first 128 assuming
%the rest is noise
[varargin, ch]=util.argkeyval('ch', varargin, [1 128]);
ch1=ch(1,1);
ch2=ch(1,2);


%%
%find the set up if specified, meaning the channel organization to remove
%noise, standard 1 is 6x10/6 ch/noise, then 2x8/8 ch/noise
[varargin, standard, ~, found]=util.argkeyval('standard', varargin, 1);
if ~found
    fprintf('Unless otherwise specified in standard, set up is 3 10ch micros and 2 8 channel macros next to each other\n');
end
%%
%check if the full grid is turned on or off.  defualt is on, turn off if
%you want to do just select channels.
[varargin, full_grid]=util.argkeyval('full_grid', varargin, true);

%%
%check if any trials need to be removed
[varargin, trials]=util.argkeyval('trials', varargin, []);

%check if all 128 channels (including noise) are to be run
[varargin, all_128_ch]=util.argkeyval('all_128_ch', varargin, false);
%%
%run the binning of firing rates function
[fire_rate, relt, featdef]=proc.task.bin(task,params,debug, 'UNIFORMOUTPUT', true);

% to figure out which channels are blank. if there aren't enough channels, add zeros to the end to make it 128
%channels
%later, if more NSPs are added, will need to change this 128 here and fix
%the set ups in Analysis.DelayedReach.noise_ch
%(hardcoding like a dum dum)
blank_ch=setdiff(1:128,featdef.dataset_channel); %featdef.dataset_channel for the future for multiple nsps
zero_ch=zeros(size(fire_rate,1),1,size(fire_rate,3));
for ii=1:length(blank_ch)
    if blank_ch(ii)<=size(fire_rate,2)        
        fire_rate=cat(2, fire_rate(:,1:blank_ch(ii),:), zero_ch, fire_rate(:,blank_ch(ii)+1:end,:));
    else
        fire_rate=cat(2,fire_rate, zero_ch);
    end
end
tic
%clear the noise channels and channels not specified by the user in 'ch'
if ~all_128_ch
    [ fire_rate ] = Analysis.DelayedReach.noise_ch( fire_rate, 'standard', standard, 'ch', [ch1 ch2]);
end

%remove trials that are errant if needed
if ~isempty(trials)
    [fire_rate]=Analysis.DelayedReach.remove_trials(fire_rate, trials);
end


%%
%break the data up into the phases, by 3d, now in cells
[ phase_data, phase_length]=Analysis.DelayedReach.phase_data(fire_rate, task, params, 'dimension', 1);

%%
%break the data up into tuned channels to find out what is tuned and to
%which direction
[ tuned_chs, target ] = Analysis.DelayedReach.tuned_ch( phase_data, task, params, debug );

%%
%check a pure left vs right NOT NECESSARY ANYMORE
%[ spkmeanLR ] = Analysis.DelayedReach.spk_LR( fire_rate, task, params, debug, 'ch', [ch1 ch2], 'full_grid', full_grid );
%%
%find the tuning curves
[targetmean, gof_stats, data_fit ] = Analysis.DelayedReach.spk_tuningcurve( phase_data, tuned_chs, target, task, 'ch', [ch1 ch2], 'full_grid', full_grid);
%%
%set up the firing rates for the raster plot
[ target_split, featdef_spk] = Analysis.DelayedReach.spkrates_pertarget( task,params,debug, target, 'featdef', featdef);

%%
%plot the polar plot and the data at each target
[ target_data, target_mean_full ] = Analysis.DelayedReach.plot_polar_tuning( fire_rate, targetmean, phase_length, target, task, params, data_fit, 'raster', target_split, 'ch', ch );
%output these values
targetmean.target_data=target_data;
targetmean.target_mean_full=target_mean_full;

%set up for names of phases
nmes=lower(task.phaseNames);
%set up the inputs to the table
overall_stats_temp=cell(4,1);
for ii=1:4
overall_stats_temp{ii}=nan(128,5);
end

for ii=1:length(nmes)
    overall_stats_temp{1}(1:length(tuned_chs.(nmes{ii}).sigchvsiti),ii)=tuned_chs.(nmes{ii}).sigchvsiti';
    overall_stats_temp{2}(1:length(tuned_chs.(nmes{ii}).sigchvsfixate),ii)=tuned_chs.(nmes{ii}).sigchvsfixate';
    overall_stats_temp{3}(1:length(tuned_chs.(nmes{ii}).sigchvsothertargets),ii)=tuned_chs.(nmes{ii}).sigchvsothertargets';
    overall_stats_temp{4}(1:length(tuned_chs.(nmes{ii}).sigchvsothertargetsadjusted),ii)=tuned_chs.(nmes{ii}).sigchvsothertargetsadjusted';
end

overall_stats=table(overall_stats_temp{1}, overall_stats_temp{2}, overall_stats_temp{3}, overall_stats_temp{4}, 'VariableNames', {'sigchvsiti', 'sigchvsfixate', 'sigchvsothertargets', 'sigchvsothertargetsadjusted'});

end

