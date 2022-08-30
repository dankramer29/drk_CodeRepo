function [ tuned_chs, target ] = tuned_ch( phase_data, task, varargin )
%tuned_ch runs anovas to figure out which channels are tuned and to what
%direction
%   Use the following for input:
% [ phase_data, phase_length]=Analysis.DelayedReach.phase_data(fire_rate, task, params, 'dimension', 1);
%   
% INPUTS:
%     phase_data          =The data broken up into the different phases in
%     a 3d matrix of bins x channels x trials.  See above to get that
%
%     result task, params, debug =The typical inputs from the blackrock
%     code 
%
%     varargin            =Currently doens't have any varargin, but
%     can add later if needed
%   
%Example:
% [ tuned_chs, target ] = Analysis.DelayedReach.tuned_ch( phase_data, task, params, debug );
%   WORKS AS OF 9/21/17



%check if any trials need to be removed
[varargin, trials]=util.argkeyval('trials', varargin, []);
%util.argempty(varargin);

%find out how many phases there are
phases=size(task.phaseNames,2);
%%
%allocate space, keep nans so it doesn't return all the channels on find
%specific
ppiti=nan(phases,size(phase_data{1},2));
ppfixate=nan(phases,size(phase_data{1},2));
target_pp=nan(phases,size(phase_data{1},2));
adjusted_target_pp=nan(phases,size(phase_data{1},2));

%set up the mean for the iti
itibin_mean=nanmean(phase_data{1},1);
itibin_mean=permute(itibin_mean, [3,2,1]);
%set up the mean for the fixate
fixatebin_mean=nanmean(phase_data{2},1);
fixatebin_mean=permute(fixatebin_mean, [3,2,1]);
phase_mean=cell(1,phases);
phase_mean{1}=itibin_mean;
phase_mean{2}=fixatebin_mean;

%%
%make a vector for the targets for the anova of different phases
target=[task.trialparams.targetID]';
target(task.numTrials+1:end)=[];
%remove trials that are errant if needed
if ~isempty(trials)
    [target]=Analysis.DelayedReach.remove_trials(target, trials);
end

%take the mean across the bins per phase
for jj=3:phases
    phasebin_mean=nanmean(phase_data{jj},1);
    phasebin_mean=permute(phasebin_mean, [3,2,1]);
    
    phase_mean{jj}=phasebin_mean;
    %run the anovas to compare means
    %run through the channels of that phase
    for ii=1:size(phasebin_mean,2)
        mean_temp1(:,1)=itibin_mean(:,ii);
        mean_temp1(:,2)=phasebin_mean(:,ii);
        mean_temp2(:,1)=fixatebin_mean(:,ii);
        mean_temp2(:,2)=phasebin_mean(:,ii);
        
        %run the anova1 across each channel for that bin
        ppiti(jj,ii)=anova1(mean_temp1, [], 'off');
        %run the anova1 across each channel for that bin
        ppfixate(jj,ii)=anova1(mean_temp2, [], 'off');
        
        %%
        %run the anova1 across each channel for each target against the
        %other targets and return the p value
        [target_pp(jj,ii), ~, stats_tp{jj,ii}]=anova1(phasebin_mean(:,ii),target,'off');
        %adjust for the iti by subtracting that channels average iti from
        %each bin in that phase
        
        adjusted_phasebin_mean=phasebin_mean(:,ii)-itibin_mean(:,ii);
        
        [adjusted_target_pp(jj,ii), ~, adjusted_stats_tp{jj,ii}]=anova1(adjusted_phasebin_mean,target,'off');
    end      
    
    
end


%%
%set up the outputs
tuned_chs=struct;
nmes=lower(task.phaseNames);
for kk=1:length(nmes)
    tuned_chs.(nmes{kk}).data=phase_data{kk};
    tuned_chs.(nmes{kk}).phasemean=phase_mean{kk};
    tuned_chs.(nmes{kk}).vsiti=ppiti(kk,:);
    [~, tuned_chs.(nmes{kk}).sigchvsiti]=find(ppiti(kk,:)<.05); %returns the column (ch) that is sig
     tuned_chs.(nmes{kk}).vsfixate=ppfixate(kk,:);
    [~, tuned_chs.(nmes{kk}).sigchvsfixate]=find(ppfixate(kk,:)<.05); %returns the column (ch) that is sig
    tuned_chs.(nmes{kk}).vsothertargets=target_pp(kk,:);
    [~, tuned_chs.(nmes{kk}).sigchvsothertargets]=find(target_pp(kk,:)<.05); %returns the column (ch) that is sig
    tuned_chs.(nmes{kk}).vsothertargetsadjusted=adjusted_target_pp(kk,:);
    [~, tuned_chs.(nmes{kk}).sigchvsothertargetsadjusted]=find(adjusted_target_pp(kk,:)<.05); %returns the column (ch) that is sig
end

end

