function [ target_split, featdef_spk] = spkrates_pertarget( task, params, debug, target, varargin)
%spkrates_pertarget breaks the spike firing times up into a cell array by
%channel, with cells for the target locations filled with the firing rate
%times next to the trial.  Plotting with 'linestyle', 'none' gives a
%histogram
%   
%
%pull the proc.task.timestamps to get task specific time stamps of spikes
%ts=a cell of size trials, and in each cell is the  time stamp of
%the firing rate in that channel, relative to the uniform start time.
%Relt= the whole time stamp, from 1 sec before to 1 sec after, 
%fs = the sampling rate
%
%
%EXAMPLES:
% target=[task.trialparams.targetID]';
% target(task.numTrials+1:end)=[];
%   [ target_split, featdef] = Analysis.DelayedReach.spkrates_pertarget( task,params,debug, target);


%get rid of "sorted data" if desired, default is to do this, if we start
%doing sorted data, will need to do that
[varargin, sorted]=util.argkeyval('sorted', varargin, false);
%%
%check if any trials need to be removed
[varargin, trials]=util.argkeyval('trials', varargin, []);
%%
%remove the prebuffer timestamps if you want
[varargin, prebuffer]=util.argkeyval('prebuffer', varargin, false);
%%
%include the featdef from proc.task.bin to compare
[varargin, featdef]=util.argkeyval('featdef', varargin, []);
util.argempty(varargin);

%featdef= a table of the channels and trials etc.
[ts,relt,fs,featdef_spk,trialdef] = proc.task.timestamps(task,params,debug);

%remove the prebuffer
for kk=1:length(ts)
    ts{kk} = cellfun(@(x)x(x>0),ts{kk},'UniformOutput',false);
end


if sorted
    sorted_trials=find(featdef_spk.unit==0);
    for jj=1:length(ts)
        for ii=1:length(sorted_trials)
            ts{jj}{1,sorted_trials(ii)}=[];%empty them
            
           
        end
         if ~isempty(trials) && ismember(trials,jj)
                ts{jj}=[];
         end    
    ts{jj}(cellfun('isempty',ts{jj}))=[]; %delete them
    end
else
    sorted_trials=find(featdef_spk.unit~=0);
    for jj=1:length(ts)
        for ii=1:length(sorted_trials)
            ts{jj}{1,sorted_trials(ii)}=[];%empty them
            %for some reason, it's changing the size, better to add nothing
            %than to have the sized different, can uncommment below later
            %and figure it out.
            
        end
        %delete trials that are unwanted as user input for trials.
        if ~isempty(trials) && ~isempty(ismember(trials,jj));
                ts{jj}=[];
        end
    ts{jj}(cellfun('isempty',ts{jj}))=[]; %delete them
    end 
end

 


        
            
        
%%
%split the data up for an output to be plotted in the polar plot later
%check if the featdef is included and make the channel total equal to that
%ts is ts{trials, kk}{channels,ii}(firing rates)
if ~isempty(featdef.dataset_channel);
    ch_tot=length(featdef.dataset_channel);
    %find the channels that are not included in the featdef from proc.task.bin
    missing_ch=setdiff(featdef.dataset_channel,featdef_spk.dataset_channel); %should only find ones missing, not ones duplicated
else
    ch_tot=length(ts{1});
    missing_ch=[];
end
%create fake spike data to fill any missing channel
fake_spks=relt(params.tm.bufferpre*task.eventFs+1:1000:end-params.tm.bufferpost*task.eventFs,1);
trial_zero=zeros(size(fake_spks));
%%
target_split=cell(1, ch_tot);
for ii=1:ch_tot %run through each channel
    
    for jj=1:8 %run through target locations
        trl=1; ch_pertarget=[]; temp=[];
        if ~ismember(ii,missing_ch)
            for kk=1:length(ts) %run through the trials
                %if that trial(kk)'s target is target jj, go into ts{that
                %trial, kk}{channel, ii} and make temp
                %this is verified to work 11/16/17.
                if target(kk,1)==jj
                    temp=ts{kk}{ii};
                    %add the trial number for that target
                    target_num=ones(length(ts{kk}{ii}),1)*trl;
                    temp(:,2)=target_num;
                    ch_pertarget=vertcat(ch_pertarget, temp); %concat the matrix for plotting each trial of that channel
                    trl=trl+1;
                end
            end
        elseif ismember(ii,missing_ch)
            
            temp(:,1)=fake_spks;
            temp(:,2)=trial_zero;
            ch_pertarget=temp;
        end
        target_split{ii}{jj}=ch_pertarget; %ii channel, and jj is the target, plot like this: plot(ch_pertarget(:,1),ch_pertarget(:,2),'marker','.','linestyle','none','color', 'b');
        
    end
    
    
    
end


end

