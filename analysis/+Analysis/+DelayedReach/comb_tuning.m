function [ comb_target_data, comb_target_mean ] = comb_tuning(fire_rate, targetmean, phase_length, task, params, varargin )
%comb_tuning combines the electrodes that fit together from the micros or
%the macros to show data points for an area
%   
% 
% Sample use:
%      [ comb_target_data, comb_target_mean ] =Analysis.DelayedReach.comb_tuning(fire_rate, targetmean, phase_length, task, params, 'electrode_type', 4, 'ch', [1 10] );
%%
%find the electrode_type used
[varargin, electrode_type]=util.argkeyval('electrode_type', varargin, 1);
%find the channels
[varargin, ch]=util.argkeyval('ch', varargin, [1 10]);
util.argempty(varargin);
ch_total=ch(1,2)-ch(1,1)+1;
%set up for channel naming
ch_nums=ch(1,1):ch(1,2);
  
switch electrode_type %switch between the type of electrodes
    case 1
      
        assert(ch_total==10, 'for electrode_type case 1, micros, needs to be 10 channels, for electrode_type case 2, macros, needs to be 8 channels, for electrode_type 3, macros, needs to be 6 channels, and for electrode_type 4, macros, needs to be 10 channels');
        
    case 2

        assert(ch_total==8, 'for electrode_type case 1, micros, needs to be 10 channels, for electrode_type case 2, macros, needs to be 8 channels, for electrode_type 3, macros, needs to be 6 channels, and for electrode_type 4, macros, needs to be 10 channels');
    case 3
       
        assert(ch_total==6, 'for electrode_type case 1, micros, needs to be 10 channels, for electrode_type case 2, macros, needs to be 8 channels, for electrode_type 3, macros, needs to be 6 channels, and for electrode_type 4, macros, needs to be 10 channels');
    case 4
       
        assert(ch_total==10, 'for electrode_type case 1, micros, needs to be 10 channels, for electrode_type case 2, macros, needs to be 8 channels, for electrode_type 3, macros, needs to be 6 channels, and for electrode_type 4, macros, needs to be 10 channels');
        
end

%set up theta
theta_deg=(0:45:360);
theta_deg=theta_deg';
theta=deg2rad(theta_deg);
%set up target
target=[task.trialparams.targetID]';
target(task.numTrials+1:end)=[];

%set up for labeling
theta_deg=[315; 0; 45; 270; 1; 90; 225; 180; 135];

%set up for names of phases
nmes=lower(task.phaseNames);
temp=ones(9,ch_total);

%preallocate
target_mean_comb=cell(1,8);
target_std_comb=cell(1,8);
%%
n1=size(targetmean.target_data,1);
%%
%setting up for plotting each target at the new channel alignments
for ii=1:8
    %data loaded in so all channels all bins, the 8 trials for each of the
    %8 targets
    target_data{ii}=fire_rate(:,ch(1,1):ch(1,2),target==ii);
    
    if electrode_type==1 %micros
        %target_mean_comb has cells for each target and means associated
        %with each combo of electrodes
        %targetmean.target_mean_full is to eliminate having to reorganize,
        %it's already in that variable

        target_mean_comb{ii}(:,1)=mean(targetmean.target_mean_full{ii}(:,1:3),2);
        target_mean_comb{ii}(:,2)=mean(targetmean.target_mean_full{ii}(:,4:6),2);
        target_mean_comb{ii}(:,3)=mean(targetmean.target_mean_full{ii}(:,7:8),2);
        target_mean_comb{ii}(:,4)=mean(targetmean.target_mean_full{ii}(:,9:10),2);
        %calculate the combined std from a formula I found on the internets,
        %which, inherently, cannot be wrong.
        %target_std_comb has a cell for each channel containing stds for
        %each combo of electrodes
        SD1=std(target_data{ii}(:,1,:),[],3);
        SD2=std(target_data{ii}(:,2,:),[],3);
        SD3=std(target_data{ii}(:,3,:),[],3);
        target_std_comb{ii}(:,1)=((SD1*n1+SD2*n1+SD3*n1) / (n1+n1+n1) ).^0.5;
        SD1=std(target_data{ii}(:,4,:),[],3);
        SD2=std(target_data{ii}(:,5,:),[],3);
        SD3=std(target_data{ii}(:,6,:),[],3);
        target_std_comb{ii}(:,2)=((SD1*n1+SD2*n1+SD3*n1) / (n1+n1+n1) ).^0.5;
        SD1=std(target_data{ii}(:,7,:),[],3);
        SD2=std(target_data{ii}(:,8,:),[],3);
        target_std_comb{ii}(:,3)=((SD1*n1+SD2*n1) / (n1+n1) ).^0.5;
        SD1=std(target_data{ii}(:,9,:),[],3);
        SD2=std(target_data{ii}(:,10,:),[],3);
        target_std_comb{ii}(:,4)=((SD1*n1+SD2*n1) / (n1+n1) ).^0.5;
    else %macros
        %combine the means from the desired channels (already the mean of that channel, at that time bin, for all trials of that target), taking the mean of
        %all channels across that time bin. taget_mean_comb is a mean of
        %that time bin across all desired channels, for that target
        target_mean_comb{ii}(:,1)=mean(targetmean.target_mean_full{ii}(:,ch(1,1):ch(1,2)),2);
        %calculate the combined std from a formula I found on the internets,
        %which, inherently, cannot be wrong.
        for jj=1:ch_total
            SD(:,jj)=std(target_data{ii}(:,jj,:),[],3);
        end
        SD=SD*n1;
        target_std_comb{ii}(:,1)=( sum(SD,2)/ (n1^ch_total) ).^0.5;
    
    end
end

%%
%get data for the polar plot
for ii=1:length(nmes)
    idx=1;
    for kk=ch(1,1):ch(1,2)
        
        %load data for the polar plot
        temp(1:8,idx)=targetmean.(nmes{ii}){kk};
        %add the last value to close the loop on the polar plots
        temp(9,idx)=temp(1,idx);
        idx=idx+1;
    end
    
    if electrode_type==1
        %get means across channels of data aleady combined for the
        %targets, and organized by the phase, all reduced to one number
        comb_target_mean.(nmes{ii})(:,1)=mean(temp(:,1:3),2);
        comb_target_mean.(nmes{ii})(:,2)=mean(temp(:,4:6),2);
        comb_target_mean.(nmes{ii})(:,3)=mean(temp(:,7:8),2);
        comb_target_mean.(nmes{ii})(:,4)=mean(temp(:,9:10),2);
        
        
    else %combine the macro data to make one mean for the polar plot across all the data
        comb_target_data.(nmes{ii})(:,1)=mean(temp(:,1:ch_total),2);
        
        
    end
    
    
end




%%
%set up colors
C=linspecer(36);


%run through all desired channels to plot
%going to need to run through and plot all the channels for one phase
%together, but also then only do the single average.  probably can do it
%with a reference to an array that has the indices you want, or an extra
%for loop.
if electrode_type==1
    elec_amnt=4;
else
    elec_amnt=1;
end
%run this through 4 times total if the micro, otherwise just once to do all
%10 channels
for jj=1:elec_amnt
    mx=[];
    chname=arrayfun(@num2str,ch_nums, 'uniformoutput', false);
    figtitle=[task.subject ' ' task.idString ' ' task.taskName ' Ch ' chname{1,1} ' to ' chname{1,end} ' Combined channels polar plot of each phase and the firing rate throughout the trial'];
    figure('Name', figtitle,'NumberTitle', 'off', 'Position', [1 0 1400 1000]) %x bottom left, y bottom left, x width, y height, will open in the bottom L corner of the screen
    for rr=1:8 %find the max for all the trials so the scaling is the same
        mx(:, rr)=max(squeeze(max(target_data{rr}(phase_length(1,1):end,:,:))));
    end
    mx=max(max(mx));
    for kk=1:9+length(nmes)-2 %this adds the 
        %sets up the targets to align with the subplots
        target_spots=[8;1;2;7;-1;3;6;5;4];
        subplot(4,3,kk)
        
        
           
        if kk<5 %place plots in the first 4 slots before the polar plot
            hold on
            
            %plot data, jj is the channel, kk is the target
            for nn=1:size(target_data{target_spots(kk)},3) %plot each trial
                plot(target_data{target_spots(kk)}(phase_length(1,1):end,:,nn), 'Color', C(11,:));
            end
            shadedErrorBar([], target_mean_comb{target_spots(kk)}(phase_length(1,1):end,jj), target_std_comb{target_spots(kk)}(phase_length(1,1):end,jj),'lineprops', {'om-', 'markerfacecolor', C(5,:)});
            
            title([' Target at ' num2str(theta_deg(kk)) ' degrees']);
            ax=gca;
            %run the labeling function
            plt_labels( mx, phase_length, [], task, ax );
            
        elseif kk==5           
            for ii=1:length(nmes)
                %jj for the micros. comb_target_data is the mean across the
                %desired channels at each target for each phase(ii)
                L=polarplot(theta,comb_target_data.(nmes{ii})(:,jj));
                if ii<3
                    set(L, 'LineWidth', 1, 'LineStyle', ':')
                else
                    set(L, 'LineWidth', 1.5)
                end
                hold on
            end
            ax=gca;
            ax.ThetaZeroLocation = 'top';
            ax.ThetaDir = 'clockwise';
            legend(upper(nmes)) %label the plots.
        elseif kk>5 && kk<10
            hold on
            
            %plot data, jj is the channel, kk is the target
            for nn=1:size(target_data{target_spots(kk)},3) %plot each trial
                plot(target_data{target_spots(kk)}(phase_length(1,1):end,:,nn), 'Color', C(11,:));
            end
            shadedErrorBar([], target_mean_comb{target_spots(kk)}(phase_length(1,1):end,jj), target_std_comb{target_spots(kk)}(phase_length(1,1):end,jj),'lineprops', {'om-', 'markerfacecolor', C(5,:)});
            
            
            title([' Target at ' num2str(theta_deg(kk)) ' degrees']);
            ax=gca;
            %run the labeling function
            plt_labels( mx, phase_length, jj, task, ax );
%         else  %plot the gaussian fits at the bottom
%             pp=kk-7;
%             dfit= data_fit.(nmes{pp}){jj}{1}; %dfit for that channel
%             shift_means= data_fit.(nmes{pp}){jj}{2}(:,1);
%             tgts= data_fit.(nmes{pp}){jj}{2}(:,2);
%             shift_tgts= data_fit.(nmes{pp}){jj}{2}(:,3);
%             %plot(dfit,tgts, shift_means, 'o');
%             shift_tgts(shift_tgts==1)=0;
%             shift_tgts(shift_tgts==2)=45;
%             shift_tgts(shift_tgts==3)=90;
%             shift_tgts(shift_tgts==4)=135;
%             shift_tgts(shift_tgts==5)=180;
%             shift_tgts(shift_tgts==6)=225;
%             shift_tgts(shift_tgts==7)=270;            
%             shift_tgts(shift_tgts==8)=315;
%             ax=gca;
%             ax.XTickLabels=shift_tgts; %this moves the target names over appropriately for the way the gaussian was shifted
%             
%             
        end
        
        
        
    end
end







    

end

