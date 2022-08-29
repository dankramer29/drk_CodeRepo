function [ target_data, target_mean_full ] = plot_polar_tuning( fire_rate, targetmean, phase_length, target, task, params, data_fit, varargin )
%plot_polar_tuning Creates a subplot with a polar plot in the center of the
%average firing rate at each location with each color indicating a
%different phase
%   OUTPUT:
%         target_data=        the raw fire_rate split into each target
%         target_mean_full=   the mean of all of the trials for that target put together



%%
%create theta.  
theta_deg=(0:45:360);
theta_deg=theta_deg';
theta=deg2rad(theta_deg);
%set up for labeling
theta_deg=[315; 0; 45; 1; 1; 1; 270; 1; 90; 1; 1; 1; 225; 180; 135];

%set up for names of phases
nmes=lower(task.phaseNames);
%set up the total channel size
ch_total=size(targetmean.iti,2);

%%
[varargin, ch]=util.argkeyval('ch', varargin, (1:ch_total));
%set up for channels
ch_nums=ch(1,1):ch(1,2);

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
[varargin, full_grid]=util.argkeyval('full_grid', varargin, false);

%if raster entered, include the output of spkrates_pertarget (comes as
%channels in cells filled with a cell per target filled with spk times next
%to their trial
[varargin, raster]=util.argkeyval('raster', varargin, []);


%break up the data into targets, but still continuous
for ii=1:8
    target_data{ii}=fire_rate(:,:,target==ii);
    
    %get the mean across those trials for each target
    target_mean_full{ii}=mean(target_data{ii},3);
    stdall{ii}=std(target_data{ii},[],3);
end


%%
%set up colors
C=linspecer(36);


%run through all desired channels to plot
for jj=1:ch_total
    chname=arrayfun(@num2str,ch_nums, 'uniformoutput', false);
    figtitle=[task.subject ' ' task.idString ' ' task.taskName ' Ch ' chname{1,jj} ' Polar plot of each phase and the firing rate throughout the trial'];
    figure('Name', figtitle,'NumberTitle', 'off', 'Position', [1 0 1400 1000]) %x bottom left, y bottom left, x width, y height
    for rr=1:8 %find the max for all the trials so the scaling is the same
        mx(rr)=max(max(target_data{rr}(phase_length(1,1):end,jj,:)));
    end
    mx=max(mx);
    xl=length(target_data{1})-phase_length(1,1);
    target_spots=[8;1;2;8;1;2;7;-1;3;7;-1;3;6;5;4;6;5;4];
    subaxis={};
    for kk=1:18+length(nmes)-2 %adds the gaussian plots at the end, depending on how many phases
        %sets up the targets to align with the subplots
        
        subaxis{kk}=subplot(7,3,kk); 
       
        %space for the target plots, rasters below, the polar in the middle and the gaussian at the bottom
        if kk<=3 || kk==7 || kk==9 || kk==13 || kk==14 || kk==15 %place plots in the first 4 slots before the polar plot
            
            hold on
            
            %plot data, jj is the channel, kk is the target
            for nn=1:size(target_data{target_spots(kk)},3) %plot each trial
                plot(target_data{target_spots(kk)}(phase_length(1,1):end,jj,nn), 'Color', C(11,:));
            end
            shadedErrorBar([], target_mean_full{target_spots(kk)}(phase_length(1,1):end,jj), stdall{target_spots(kk)}(phase_length(1,1):end,jj),'lineprops', {'og-', 'markerfacecolor', C(5,:)});
            
            title([' Target at ' num2str(theta_deg(kk)) ' degrees']);
            ax=gca;
            %run the labeling function
            plt_labels( mx, phase_length, jj, task, ax, xl );
            if kk<=3 %make the positions look good                
                subaxis{kk}.Position(4)=0.12; %make it larger vertically
            elseif kk==7 || kk==9                
                subaxis{kk}.Position(4)=0.12;
            elseif kk==13 || kk==14 || kk==15                
                subaxis{kk}.Position(4)=0.12;
             %   subaxis{kk}.Position(2)=.31;%move it down below the polar
            end
        elseif kk==4 || kk==5 || kk==6 
            raster_plot(raster{jj}{target_spots(kk)})
            subaxis{kk}.Position(2)=.75; %move it closer to the plot above
        elseif kk==10 || kk==12 
            raster_plot(raster{jj}{target_spots(kk)})
            subaxis{kk}.Position(2)=.50; %move it closer to the plot above
        elseif kk==16 || kk==17 || kk==18
            raster_plot(raster{jj}{target_spots(kk)})
            %subaxis{kk}.Position(2)=.22; %move it closer to the plot above    
            
        elseif kk==8 
            continue
        elseif kk==11
            subplot(7,3,[8 11]);
            ch_respond=[];
            for ii=1:length(nmes) %for each phase, get the means at that channel
                ch_respond(:,ii)=targetmean.(nmes{ii}){:,jj};
            end
            %add the 1st value to the end in order to close the
            %loop
            ch_respond(9,:)=ch_respond(1,:);
            
            for ii=1:length(nmes)
                L=polarplot(theta,ch_respond(:,ii));
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
            pL=legend(upper(nmes)); %label the plots.
            pL.Position=[0.6105 0.6435 0.0521 0.0358];           
        
                
        elseif kk==19 || kk==20 ||kk==21  %plot the gaussian fits at the bottom
            pp=kk-16;
            dfit= data_fit.(nmes{pp}){jj}{1}; %dfit for that channel jj
            shift_means= data_fit.(nmes{pp}){jj}{2}(:,1); %the means shifted to the center
            tgts= data_fit.(nmes{pp}){jj}{2}(:,2);
            shift_tgts= data_fit.(nmes{pp}){jj}{2}(:,3);
            plot(dfit,tgts, shift_means, 'o'); %must plot against the targets to keep everything centered, then change the names at the bottom
            shift_tgts(shift_tgts==1)=0;
            shift_tgts(shift_tgts==2)=45;
            shift_tgts(shift_tgts==3)=90;
            shift_tgts(shift_tgts==4)=135;
            shift_tgts(shift_tgts==5)=180;
            shift_tgts(shift_tgts==6)=225;
            shift_tgts(shift_tgts==7)=270;            
            shift_tgts(shift_tgts==8)=315;
            ax=gca;   
            ax.XTick=[0:8];
            ax.XTickLabels=shift_tgts; %this moves the target names over appropriately for the way the gaussian was shifted
            
        end
        
        
        
    end
    
    subaxis{16}.Position(2)=.22;
    subaxis{17}.Position(2)=.22;
    subaxis{18}.Position(2)=.22;
    subaxis{13}.Position(2)=.31;
    subaxis{14}.Position(2)=.31;
    subaxis{15}.Position(2)=.31;
    subaxis{19}.Position(2)=0.09; subaxis{19}.Position(4)=0.12;
    subaxis{20}.Position(2)=0.09; subaxis{20}.Position(4)=0.12;
    subaxis{21}.Position(2)=0.09; subaxis{21}.Position(4)=0.12;
end


end

