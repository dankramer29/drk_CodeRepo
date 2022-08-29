function [itiCheckResults, ch2check] = itiCheck(filtITI, timebin, varargin)
%itiCheck compare the itis to make sure they aren't biased
%  filtITI is the filtered iti data, set up as follows time x alltrialsamongalltouchtypes x ch

[varargin,ms] = util.argkeyval('ms',varargin, 200);  %number of ms to check against
[varargin,fs] = util.argkeyval('fs',varargin, 2000); %sampling rate if not provided
 
tt=timebin(2)-timebin(1);
time_off=ceil((ms/1000)/tt);
ch2check=0;

for kk=1:length(filtITI)
    freqTempF=[];
    freqTempS=[];
    ftemp=[];
    stemp=[];
    ftemp=filtITI{kk};
    %make the iti uniform across frequency bands, meaning at a
    %frequency bin, the value will be the same for all of the time
    ftemp=nanmean(ftemp, 3); %collapse across all trials
    stemp=ftemp(time_off:end, :);
    for ii=1:size(ftemp,2)        
        freqTempF=ftemp(ii,:);
        freqTempS=stemp(ii,:);
        [itiCheckResults{kk}.p(ii,1), itiCheckResults{kk}.h(ii,1)]=ranksum(freqTempF, freqTempS);
        itiCheckResults{kk}.meanF(ii,1)=nanmean(freqTempF);%fullITI collapse across time, so it's one number for each freq bin for the whole time
        itiCheckResults{kk}.ciF(ii,1:2)=bootci(1000, {@mean, freqTempF(1, :)}, 'type', 'cper');
        itiCheckResults{kk}.meanS(ii,1)=nanmean(freqTempS);
        itiCheckResults{kk}.ciS(ii,1:2)=bootci(1000, {@mean, freqTempS(1, :)}, 'type', 'cper');
    end
    
    %check if any h values are true (meaning p was positive)
    idx=1;
    if nnz(itiCheckResults{kk}.h)>0
        ch2check(idx)=kk;
        idx=idx+1;
    end
        
    
end





end

