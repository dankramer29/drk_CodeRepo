function [targetmean, gof_stats, data_fit ] = spk_tuningcurve( phase_data, tuned_chs, target, task, varargin )
%spk_tuningcurve Summary of this function goes here
%   Plot the tuning curve for each channel across the trials. It will take
%   the phase mean and plot it vs each target option, then get the f values
%   and the goodness of fit for a gaussian fit.  It is intended to take the
%   input from tuned_chs.PHASE.phase_mean


%NEED TO FIGURE OUT THE OUTPUTS.

%set up the fit categories for each target
tgts(1:8,1)=1:8; 
%set up the names
nmes=lower(task.phaseNames);

%%
%to do a subset that isn't the full grid set up
%find the if full_grid true or not
[varargin, full_grid]=util.argkeyval('full_grid', varargin, true);
%find the channels if entered
[varargin, ch]=util.argkeyval('ch', varargin, [1 128]);
%make sure the channels entered is an even number
assert(mod(ch(1,2)-ch(1,1),2)==1, 'must enter even number of channels')

util.argempty(varargin);

%%
%allocate space for the goodness of fit outputs, one gof for each channel,
%and for the temp cells to hold the different phases, then assign the
%variables to the phases
temp_phases=cell(length(nmes),1);
temp_targetmean=cell(length(nmes),1);
for nn=1:length(nmes) %run through each phase
    gof_stats.(nmes{nn})=cell(1,size(phase_data{1},2));
    temp_phases{nn}=double(tuned_chs.(nmes{nn}).phasemean);
    data_fit.(nmes{nn})=cell(1,size(phase_data{1},2)); 
end
%%



for nn=1:length(nmes) %run through each phase
    for kk=1:size(temp_phases{1}, 2)  %run through each channel
        %find the mean of the targets at each channel
        for ii=1:8 %ii=8 targets,kk= channels, nn=phases, find the mean of the targets at each channel
            %load that phase (nn), all targets and all channels (ii, kk)
            temp_targetmean{nn}(ii,kk)=nanmean(temp_phases{nn}(target(:,1)==ii,kk));
        end
    end
    parfor_data=temp_targetmean{nn};
    parfor_gof=cell(1,size(temp_phases{1},2));
    parfor_coefficients=cell(1,size(temp_phases{1},2));
    parfor_targetmean=cell(1,size(temp_phases{1},2));
    for kk=1:size(temp_phases{1}, 2)  %run through each channel
        try %this is to skip data that fits so poorly the fit goes to infinity.
            
            %circshift so the max value is in the center to
            %help with the circular data problem.
            temp=parfor_data(:,kk);
            [~, row]=max(temp);
            temp=circshift(temp, 4-row);
            shift_tgts=circshift(tgts,4-row);
            %make a gaussian fit and store the coefficients a b
            %c, magnitude, mean, and std (width)
            %shifting temp and keeping tgts unshifted is actually the right
            %way to do it (trust me I went through the iterations). Just
            %rename the hashes
            [dfit, data_gof]=fit(tgts,temp,'gauss1');
            data_gof_coefficients=[dfit.a1; dfit.b1; dfit.c1];
            %THIS NEEDS TO BE FIXED THE GOF WILL NEED TO PICK THE RIGHT
            %STAT AND SET THRESHOLDS
            %find the sig curves and return that channel
            %if data_gof<=1;
            %    data_gof.sigch=kk;
            %else
            %    data_gof.sigch=[];
            %end
            
        catch me
            util.errorMessage(me);
            continue
        end
        
        parfor_gof{kk}=data_gof;
        parfor_targetmean{kk}(:,1)=parfor_data(:,kk);
        parfor_coefficients{kk}(:,1)=data_gof_coefficients;
        parfor_dfit{kk}{1}=dfit; %dfit for that channel
        parfor_dfit{kk}{2}(:,1)=temp;
        parfor_dfit{kk}{2}(:,2)=tgts;
        parfor_dfit{kk}{2}(:,3)=shift_tgts;
        
    end
    
    %outputs: for each phase, a goodness of fit for each
    %channel and load the means into targetmean
    
    gof_stats.(nmes{nn})=parfor_gof;
    for kk=1:size(temp_phases{1}, 2)
    gof_stats.(nmes{nn}){kk}.coefficients=parfor_coefficients{kk};
    end
    targetmean.(nmes{nn})=parfor_targetmean;    
    data_fit.(nmes{nn})=parfor_dfit;    
    
end

%{
%%
figtitle2={'L parietal tuning curve gaussian', ...
    'R parietal tuning curve gaussian'};
idx=1;
%Plot macros
for kk=(0:macro-1)*mac_sz+micro*10   %start the channels after the micros
    %figure('Name', figtitle2{idx},'NumberTitle', 'off')
    for mm=1:mac_sz
        %create the micro subplots
        %subplot(mac_sz,1, mm)
        %hold on
        %title([' Ch ' num2str(kk+mm)]);
        for ii=1:8 %ii=8 targets,kk= phases, jj=channels, find the mean of the targets at each channel
            for nn=1:length(nmes) %run through each phase
                targetmean.(nmes{nn})(ii,kk+mm)=nanmean(tuned_chs.(nmes{nn}).phasemean(target(:,1)==ii,kk+mm));
                try %this is to skip data that fits so poorly the fit goes to infinity.
                    %  [data_fit, data_gof]=fit(tgts,double(targetmean.(nmes{nn})(:,kk+mm)),'gauss1'); %gauss instead of gauss1
                catch me
                    util.errorMessage(me);
                    continue
                end
                
                %outputs as, for each phase, a goodness of fit for each
                %channel.
                % gof_stats.(nmes{nn}){kk+mm}=data_gof;
            end%end phases
        end%end targets
        
    end %end that subplot
    
    
    idx=idx+1;
end

%chname=arrayfun(@num2str,ch, 'uniformoutput', false);
%figtitle=['Ch ' chname{1,1} ' - ' chname{1,2} ' tuning curve gaussian'];

%%
idx=1;
%this is to set up the incrementing. Currently it will do a
%subplots by 2, but can change the subplts amount below to adjust
%it.
subplts=2;
ttl=size(phase_data{1},2)/subplts;
for kk=(0:ttl-1)*subplts %to increment s
    % figure('Name', figtitle,'NumberTitle', 'off')
    
    for mm=1:subplts
        
        %create the micro subplots
        %subplot(subplts,1, mm)
        %hold on
        %title([' Ch ' num2str(kk+mm)]);
        for ii=1:8 %ii=8 targets,kk= phases, jj=channels, find the mean of the targets at each channel
            for nn=1:length(nmes) %run through each phase
                targetmean.(nmes{nn})(ii,kk+mm)=nanmean(tuned_chs.(nmes{nn}).phasemean(target(:,1)==ii,kk+mm));
                try %this is to skip data that fits so poorly the fit goes to infinity.
                    %   [data_fit, data_gof]=fit(tgts,double(targetmean.(nmes{nn})(:,kk+mm)),'gauss1'); %gauss instead of gauss1
                catch me
                    util.errorMessage(me);
                    continue
                end
                
                %outputs as, for each phase, a goodness of fit for each
                %channel.
                %gof_stats.(nmes{nn}){kk+mm}=data_gof;
            end%end phases
        end%end targets
        
    end %end that subplot
    idx=idx+1;
    
end
%}
end




