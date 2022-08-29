function [ specpeakall, allpeaks ] = specpeak( specPower, Nstep, Nwin, tplot, varargin )
%specpeak- goes through the average across a spectrum and finds the highest
%trapz integral of a window Nwin, stepping Nstep
%   

% Inputs:
%     specPower= output of artsens_proc and specifically freqbandPower
%     Nstep=  how much to step in SECONDS (so 0.005 or whatever)
%     Nwin=   how big a window to check in SECONDS (so 0.2 or whatever)

% Outputs
%     specpeakall:    a struct with the names of the touches, then the bands.  
%                                 access like this: 
%                                     xx=specpeakall.SoftTouch.Alpha(:,1);
%                                 
%     allpeaks:       a struct with the names of touches, then the bands, with the integral values, can plot to see that it matches up.   
% 
% Example:
%     [ speckpeakall, allpeaks]=ArtSens.specpeak( specPowerBM2, 0.005, 0.2, specgramcBM2.SoftTouch.t);



%ALL OF THE TIMING GETS COMPLICATED, SEE BELOW AT TEMPTABLE FOR AN
%EXPLANATION OF THE ADJUSTMENT 

[varargin, totaltime]=util.argkeyval('totaltime',varargin, 2.5); %total time from beginning of interval to end, typically 0.5s before and 2s after
[varargin, prepost]=util.argkeyval('prepost',varargin, [0.5 2]); %the window we want to look at based on what's graphed
[varargin, plot_buff]=util.argkeyval('plot_buff',varargin,[-0.1 1.6]); %this will dictate how much of the graph before 0 and after to show (e.g. time window total (prepost) is 0.5 to 2 and you only care about 0-1.5, give a [0.1 1.6] s buffer so it shows -0.1 to 1.6)
[varargin, window]=util.argkeyval('window',varargin,[0.2 0.005]); %this is to adjust the time stamps for the intergral based on the timing already set up for tplot and the actual data.




allpeaks=struct;
specpeakall=struct;
%%
touch=fieldnames(specPower);
dlt=[];
for ii=1:size(touch,1)
    if isempty(strfind(touch{ii},'Touch'))
        dlt=ii;
    end
end
if ~isempty(dlt); touch(dlt)=[]; end

nmes=fieldnames(specPower.(touch{1})); %get the subfield names
N=size(specPower.(touch{1})(1,1).(nmes{1}),1); %should all be the same size
bnsz=totaltime/N; %bin size in seconds
NstepB=round(Nstep/bnsz); %convert seconds to bins
NwinB=round(Nwin/bnsz); %convert seconds to bins
winstart=1:NstepB:N; %create the list of starting points
intsz=totaltime/length(winstart); %get the size of each integral window





T=table;
T.Channels=(1:size(specPower.(touch{1}),2))';

%THIS IS A BIT OF DUCT TAPE SINCE I'M ONLY DOING 0.5 AND 0.2 WINDOWS, IT
%HAS TO DO WITH THE ISSUE THAT A 0.5 WINDOW AND A 0.5 PREBUFFER PUTS THE
%FIRST ROW AS 0
if prepost(1)==window(1) %adjust for 0.5 window
    st=1;
    endsp=round(plot_buff(2)/intsz);
else    
    st=round(plot_buff(1,1)/intsz+prepost(1)/intsz);%get the range you are looking at 0.4 (which is -0.1) to 2.1 (which is 1.6)
    endsp=round(plot_buff(1,2)/intsz+prepost(1)/intsz);
end

%%
for rr=1:size(touch,1)
    for kk=1:size(nmes,1) %run through freq bands
        for jj=1:size(specPower.(touch{rr}),2) %run through the channels
            for ii=1:length(winstart) %run through the windows
                temp=specPower.(touch{rr})(jj).(nmes{kk});
                if winstart(ii)+NwinB<N
                    allpeaks.(touch{rr})(jj).(nmes{kk})(ii)=trapz(temp(winstart(ii):winstart(ii)+NwinB));
                else
                    allpeaks.(touch{rr})(jj).(nmes{kk})(ii)=trapz(temp(winstart(ii):end));
                end
            end

            
            %find the row of the max and the min based on the time we are
            %looking at(rest of time is a ramp up and ramp down)(reports it
            %as index from the start of the range, meaning row 1 of the mx
            %result (for mxi) is actually the index for st from the full
            %thing.  This is corrected for below.
            
            [mx, mxi]=max(allpeaks.(touch{rr})(jj).(nmes{kk})(st:endsp)); 
            [mn, mni]=min(allpeaks.(touch{rr})(jj).(nmes{kk})(st:endsp));
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
        
         T.(nmes{kk})=temptable;
%         if ~isempty(ch)
%             for jj=1:length(ch)
%                 
%             end
%         end
        specpeakall.(touch{rr})=T;
%         statsigpeaks=Trel
        
    end
end








end

