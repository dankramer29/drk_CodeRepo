function [ gof_stats, data_fit ] = fit_gof( tuned_chs, task, varargin )
%fit_gof runs a fit function and gives a gof_stats and the data_fit to plot
%it

% SAMPLE
%         [ gof_stats, data_fit ] =Analysis.DelayedReach.fit_gof( comb_target_data, task, 'electrode_type', 4 );



%find the electrode_type used
[varargin, electrode_type]=util.argkeyval('electrode_type', varargin, 1);
util.argempty(varargin);

%set up the different channel types
if electrode_type==1
    elec_amnt=4;
else
    elec_amnt=1;
end

%set up names
nmes=lower(task.phaseNames);
%set up target
target=[task.trialparams.targetID]';
target(task.numTrials+1:end)=[];
%set up the fit categories for each target
tgts(1:8,1)=1:8; 
%%
%allocate space for the goodness of fit outputs, one gof for each channel,
%and for the temp cells to hold the different phases, then assign the
%variables to the phases
for nn=1:length(nmes) %run through each phase
    gof_stats.(nmes{nn})=cell(1,size(tuned_chs.iti,2));    
    data_fit.(nmes{nn})=cell(1,size(tuned_chs.iti,2)); 
end
%%

%RIGHT NOW TUNED_CHS= COMB_TARGET_DATA WHICH HAS A SINGLE 9 VALUES FOR THE
%AVERAGES ACROSS ALL THE CHANNELS FOR EACH TARGET, THE POLAR STUFF
%ESSENTIALLY

for nn=1:length(nmes) %run through each phase
    target_data=tuned_chs.(nmes{nn});
    target_data(9,:)=[]; %remove the extra channel
    for kk=1:elec_amnt
        try %this is to skip data that fits so poorly the fit goes to infinity.
            
            %circshift so the max value is in the center to
            %help with the circular data problem.
            
            
            [~, row]=max(target_data(:,kk));
            target_data(:,kk)=circshift(target_data(:,kk), 4-row); %PROBABLY CHANGE THESE TO :,KK IN ORDER TO GO THROUGH THE CORRECT AMOUNT OF GOF
            shift_tgts=circshift(tgts,4-row);
            %make a gaussian fit and store the coefficients a b
            %c, magnitude, mean, and std (width)
            [dfit, data_gof]=fit(tgts,target_data(:,kk),'gauss1');
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
    end
    gof_stats.(nmes{nn}){kk}=data_gof;
    gof_stats.(nmes{nn}){kk}.coefficients=data_gof_coefficients;
    data_fit.(nmes{nn}){kk}.dfit=dfit;
    data_fit.(nmes{nn}){kk}.targets(:,1)=target_data;
    data_fit.(nmes{nn}){kk}.targets(:,2)=tgts;
    data_fit.(nmes{nn}){kk}.targets(:,3)=shift_tgts;
    
    
end
    
  
end

