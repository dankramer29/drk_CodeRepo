function [ powerpeaks, continuousPowerMean, continuousPower, continuousPowerdB ] = powerPeak( bandsfilt, Nstep, Nwin, varargin )
%powerPeak- will take the power in filtered bands and convert to db, then
%find the max and min for the trials, as well as smooth the data.
% NOTE: THE OUTPUT OF ARTSENS_PROC DOES THE DB ALREADY, SO TO GET THAT OUTPUT, JUST RUN IT WITH FILBANDPOWERdB INSTEAD OF JUST FILTBANDPOWER
%   

% Inputs:
%     bandsfilt= output of artsens_proc and specifically freqbandPower
%     Nstep=  how much to step in SECONDS (so 0.005 or whatever)
%     Nwin=   how big a window to check in SECONDS (so 0.2 or whatever)

% varargin

% Outputs
%     powerpeaks:    a struct with the names of the touches, then the bands.  
%                                 access like this: 
%                                     xx=specpeakall.SoftTouch.Alpha(:,1);
%
%     continuousPowerMean:       a struct with the names of subjects, touches, bands, and mean for all trials in column1 and dB in column 2   

%     continuousPower:       a struct with the names of subjects, touches, bands, and time by trials for that touch. 

%     continuousPowerdB:      only needs an output if dB not done in artsens_proc (currently dB already done, so no need to have this output) a struct with the names of subjects, touches, bands, and time by trials for that touch but in db form. . 

% 
% Example:
%     [ powerpeaks, continuousPowerMean, continuousPower]=ArtSens.powerPeak( filtbandPower, 0.005, 0.05, 'tplot', tt2);
%     [ powerpeaks, continuousPowerMean, continuousPowerdB]=ArtSens.powerPeak( filtbandPowerdB, 0.005, 0.05, 'tplot', tt2);





%ALL OF THE TIMING GETS COMPLICATED, SEE BELOW AT TEMPTABLE FOR AN
%EXPLANATION OF THE ADJUSTMENT 

[varargin, totaltime]=util.argkeyval('totaltime',varargin, 2.5); %total time from beginning of interval to end, typically 0.5s before and 2s after
[varargin, prepost]=util.argkeyval('prepost',varargin, [0.5 2]); %the window we want to look at based on what's graphed
[varargin, plot_buff]=util.argkeyval('plot_buff',varargin,[-0.1 1.6]); %this will dictate how much of the graph before 0 and after to show (e.g. time window total (prepost) is 0.5 to 2 and you only care about 0-1.5, give a [0.1 1.6] s buffer so it shows -0.1 to 1.6)
[varargin, window]=util.argkeyval('window',varargin,[0.05 0.005]); %this is to adjust the time stamps for the intergral based on the timing already set up for tplot and the actual data.
[varargin, tplot]=util.argkeyval('tplot',varargin, []); 
[varargin, dB]=util.argkeyval('dB',varargin, false);  %if you need to convert to dB.  CURRENTLY, ARTSENSE_PROC TAKES CARE OF IT FOR NORMALIZED


continuousPower=struct;
continuousPowerdB=struct;
continuousPowerMean=struct;
powerpeaks=struct;

%%
nmes=fieldnames(bandsfilt);
touch=fieldnames(bandsfilt.bm);
bands=fieldnames(bandsfilt.bm(1).SoftTouch);

% dlt=[];
% for ii=1:size(touch,1)
%     if isempty(strfind(touch{ii},'Touch'))
%         dlt=ii;
%     end
% end
% if ~isempty(dlt); touch(dlt)=[]; end

%%
%run through all of the subjects
for mm=1:length(nmes)
    
    N=size(bandsfilt.(nmes{mm})(1).(touch{1}).(bands{1}),1); %should all be the same size


    bnsz=totaltime/N; %bin size in seconds
    NstepB=round(Nstep/bnsz); %convert seconds to bins
    NwinB=round(Nwin/bnsz); %convert seconds to bins
    winstart=1:NstepB:N; %create the list of starting points
    intsz=totaltime/length(winstart); %get the size of each integral window
    
    %make a time to be able to plot. since this is the actual data, it's
    %prepost(1):prepost(2)
    tt=-prepost(1):totaltime/(length(winstart)):prepost(2)-totaltime/(length(winstart));
    
    fs=N/totaltime;
 %%   
    
    T=table;
    T.Channels=(1:size(bandsfilt.(nmes{mm}),2))';

  
    st=round(plot_buff(1,1)/intsz+prepost(1)/intsz);%get the range you are looking at 0.4 (which is -0.1) to 2.1 (which is 1.6)
    endsp=round(plot_buff(1,2)/intsz+prepost(1)/intsz);
    
    %%
    for rr=1:size(touch,1)
        T=table;
        T.Channels=(1:size(bandsfilt.(nmes{mm}),2))';
        for kk=1:size(bands,1) %run through freq bands
            temptable=zeros(size(bandsfilt.(nmes{mm}),2),4);
            temp=[]; temptrap=[];
            for jj=1:size(bandsfilt.(nmes{mm}),2) %run through the channels
                
                %temp is now all trials, for one subject (mm), one
                %channel (jj), one type of touch(rr), and one freqband
                %(kk)
                temp=bandsfilt.(nmes{mm})(jj).(touch{rr}).(bands{kk});
                %mirrored ends
                temp=vertcat(temp, flipud(temp(end-fs:end,:)));                
                for ii=1:length(winstart) %run through the windows              
                    
                    
                    if dB
                        tempdB=10*log10(temp);
                    end
                    
                    temptrap(ii,:)=trapz(temp((winstart(ii):winstart(ii)+NwinB),:));
                    
                    if dB
                        temptrapdB(ii,:)=trapz(tempdB((winstart(ii):winstart(ii)+NwinB),:));
                    end                  
                    
                    
                end
                %the winstart length makes it so it only loads in the part
                %without the mirrored ends
                continuousPower.(nmes{mm})(jj).(touch{rr}).(bands{kk})=temptrap;
                if dB
                    continuousPowerdB.(nmes{mm})(jj).(touch{rr}).(bands{kk})(ii,:)=temptrapdB;
                end
                
                continuousPowerMean.(nmes{mm})(jj).(touch{rr}).(bands{kk})(:,1)=mean(continuousPower.(nmes{mm})(jj).(touch{rr}).(bands{kk}),2);
                if dB
                    continuousPowerMean.(nmes{mm})(jj).(touch{rr}).(bands{kk})(:,2)=mean(continuousPowerdB.(nmes{mm})(jj).(touch{rr}).(bands{kk}),2);
                end
                
                
                %find the row of the max and the min based on the time we are
                %looking at(rest of time is a ramp up and ramp down)(reports it
                %as index from the start of the range, meaning row 1 of the mx
                %result (for mxi) is actually the index for st from the full
                %thing.  This is corrected for below.
                
                [mx, mxi]=max(continuousPowerMean.(nmes{mm})(jj).(touch{rr}).(bands{kk})(st:endsp,1));
                [mn, mni]=min(continuousPowerMean.(nmes{mm})(jj).(touch{rr}).(bands{kk})(st:endsp,1));
                %TIME ADJUSTMENT VERY COMPLICATED, VERIFIED 5/3/18, EXPLANATION
                %AS FOLLOWS: the time appears to be already adjusted based on
                %tplot, the x axis time series created for plotting.  from
                %there, row 1=0 of the data, which is actually -prepost(1) in
                %the time series, but moved forward the length of the window,
                %since the window is adjusted to make the time start at the end
                %of the spec window (which makes it so power is presented as
                %following that window, not in the middle or before)
                
                temptable(jj,1)=(mxi+st-1)*intsz+(-prepost(1)+window(1));
                %temptable(jj,1)=(mxi+st+NwinB)*intsz-prepost(1); %convert to seconds and adjust to make it the middle of the window, need to subtract the pre window
                temptable(jj,2)=mx;
                temptable(jj,3)=(mni+st-1)*intsz+(-prepost(1)+window(1));
                %temptable(jj,3)=(mni+st+NwinB)*intsz-prepost(1);
                temptable(jj,4)=mn;
            end
            
            T.(bands{kk})=temptable;
        end
        powerpeaks.(nmes{mm}).(touch{rr})=T;
    end
    
    
    
end




end