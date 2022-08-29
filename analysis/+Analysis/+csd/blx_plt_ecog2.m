function  [ttflt, ttpwr, ttint]=blx_plt_ecog2( ds_ecog, flt, flt_lwps, intg_flt, pwr_lwps, map, params, varargin  )
%plt_ecog2 plot all of the ecog files
%{


Per fabricius
The plots should be flt, int_flt, and
pwr_lwps.


%   All inputs need to have done the same amount of channels 
    Inputs:
        %'sz'=     the time from the time stamps.  may want to convert to a
        more specific format like frames later.  enter like '01:41:20'
        %'ch1'=    channel you want to start with
        %'ch2'=    channel you want to end with
                Largely now this is done before processing with the
                blc.reader function, but is still allowable here
        dsrt=   downsample rate, just enter as the frequency, 400
        typically


    Need to do:
        -update the inputs to be the ones from Fabricius
        -figure out how to do a main title better
        -ADJUST THE AXES TO BE TIGHTER
        -get the grids arranged
        -update the figures to include changes in band spectra, or windows,
        or whatever we are changing around.

Sample:

WORKS 3.20.17


With no array specified (the sz time is MD_1232hr)
[ax]=csd.blx_plt_ecog2(  ds_ecog, flt, intg_flt, pwr_lwps, map params, 'sz', CutPre, 'ch1', ch1, 'ch2', ch2, 'dsrt', dsrt );
[ttflt, ttpwr, ttint]=csd.blx_plt_ecog2( ds_ecog, flt, intg_flt, pwr_lwps, map, params, 'sz', 60, 'dsrt', dsrt );

%}

%set parameters. CURRENTLY ONLY USING .PROC
if nargin==4 || isempty (params)
    params = struct;
    params.ch= [1 size(ds_ecog,2)]; %channels to look at
    params.cuttime= [30 30]; %amount of data to take around the sz, in Min
    params.newfs= 400; %downsample frequency, base is 400 samples/sec (for 200Hz by nyquist)
    params.fltr= 60; %notch filter of 60Hz, does not work on harmonics right now(I think)
    params.proc= 2; %how many processing steps to do. 
        %1 - filtered voltage 
        %2 - raw voltage squared (pwr) and then a low pass filter is
        %applied, currently at 5Hz, through subsampling
        %3 - integral of the data and the integral filtered data (intg and
            %intg_flt
            
    params.wnd= [300 300]; %wnd1 and wnd2, set at 300s each, wdw 2 is the time constant decay
    params.bandpass= [0.5 70]; %bandpass filter set at 0.5 to 70Hz
    params.lowpass= 5; %the lowpass filter set at 5Hz right now, for 10 samples/second in the pwr analysis
    params.bipolar=true; %to check for bipolar set up
    
end

%%
%check if downsample rate was specified
[varargin, dsrt, ~, found]=util.argkeyval('dsrt', varargin, 2000);
if ~found
    warning('downsample rate set at default 2000 samples/sec');
end

%check if sz time was specified
[varargin, sz, ~, found]=util.argkeyval('sz', varargin, 1);
if ~found
    warning('Seizure origin time not specified, set at the beginning. Specify by stating how much time was taken prior to the seizure, i.e. the CutPre');
end
%  Find the seizure time which will be the CutPre time from 0, so convert to seconds then *dsrt.
%  szrow represents the row of voltage values that it starts as.
szrow=sz*60*dsrt;

%check if number of channels was specified
[varargin, ch1]=util.argkeyval('ch1', varargin, 1);
[varargin, ch2]=util.argkeyval('ch2', varargin, size(ds_ecog,2));
%makes sure that the varargin is processed properly
util.argempty(varargin);


%set up the channel names
if isempty(map)
    chname=ch1:ch2;
    chname=arrayfun(@num2str,chname,'uniformoutput',false);
else
    chname=map.ChannelInfo{ch1:ch2,2};    
end
%%        

%this is used to create a vector of the samples as actual times
%alternatively, since it's so long, could just plot it vs the actual time
%stamps which should be the same length.  It converts the time mark to the
%actual row


%the sampling rate is different for the pwr, the 5 below needs to change if
%the subsampling changes for pwr_lwps under csd processing in the future
pldsrt=dsrt/floor(dsrt/(5*2));

%this goes 0 to the size of the data set (divided by the sampling rate to convert back to seconds), but by every 1/ the sampling rate, so
%1/400, which creates a whole integer every second and then moves it back
%to negative based on the row that the seizure occurs (making it 0)
%ttflt, ttpwr, ttint as outputs to easily graph again when the data is done
tt1=(0:1/dsrt:size(flt,1)/dsrt-1/dsrt)-szrow/dsrt; ttflt=tt1;
tt2=(0:1/dsrt:size(intg_flt,1)/dsrt-1/dsrt)-szrow/dsrt; ttpwr=tt2;
tt3=(0:1/pldsrt:size(pwr_lwps,1)/pldsrt-1/pldsrt)-(szrow/dsrt); ttint=tt3;


%establish the number of channels  you want to go through, switching if
%bipolar or not
if params.bipolar
    grd=ch2-ch1;
else
    grd=ch2-ch1+1;
end


%plot the filterd raw signal, all channels next to each other
figure
hold on
idx=1;
for ii=1:grd
    
    ax(ii)=subplot(grd,1,ii);
    plot(tt1, flt(:,ii));
    %this is set axes, an alternative to the linkaxes, may have to adjust
    %this to make them look good once I get going.
    
    ylim([-0.00001 0.00001]); 
    if params.bipolar
        title(['Ch ' chname{idx,1} '-' chname{idx+1,1}]);
    else
        title(['Ch ' chname{idx,1}]);
    end
    idx=idx+1;
    
    ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
    
    text(0.5, 1,['\bf Filtered raw data across Ch ' chname{1,1} ' to ' chname{end,1}],'HorizontalAlignment','center','VerticalAlignment', 'top', 'FontSize', 12);
   
end

%plot the low passed raw data 
figure
hold on
idx=1;
for ii=1:grd
    
    ax(ii)=subplot(grd,1,ii);
    plot(tt1, flt_lwps(:,ii));
    %this is set axes, an alternative to the linkaxes, may have to adjust
    %this to make them look good once I get going.
    
    ylim([-0.015 0.015]); 
    if params.bipolar
        title([' Ch ' chname{idx,1} '-' chname{idx+1,1}]);
    else
        title([' Ch ' chname{idx,1}]);
    end
    idx=idx+1;
    
    ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
    
    text(0.5, 1,['\bf  Low pass at ' num2str(params.lowpass) ' Hz raw data across Ch ' chname{1,1} ' to ' chname{end,1}],'HorizontalAlignment','center','VerticalAlignment', 'top', 'FontSize', 12);
   
end

if params.proc==2 
    %plot the low passed power signal, all channels next to each other
    figure
    hold on
    idx=1;
    for ii=1:grd
        
        ax(ii)=subplot(grd,1,ii);
        plot(tt3, pwr_lwps(:,ii));
        ylim([-0.025 0.025]); %consider 0.1
        if params.bipolar
            title(['Ch ' chname{idx,1} '-' chname{idx+1,1}]);
        else
            title(['Ch ' chname{idx,1}]);
        end        
        idx=idx+1;        
        ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');        
        text(0.5, 1,['\bf Power with low pass filter Ch ' chname{1,1} ' to ' chname{end,1}],'HorizontalAlignment','center','VerticalAlignment', 'top', 'FontSize', 12);
    end
    
    
elseif params.proc==3
    %plot the low passed power signal, all channels next to each other
    figure
    hold on
    idx=1;
    for ii=1:grd
        
        ax(ii)=subplot(grd,1,ii);
        plot(tt3, pwr_lwps(:,ii));
        ylim([-0.025 0.025]); %consider 0.1
        if params.bipolar
            title(['Ch ' chname{idx,1} '-' chname{idx+1,1}]);
        else
            title(['Ch ' chname{idx,1}]);
        end        
        idx=idx+1;        
        ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');        
        text(0.5, 1,['\bf Power with low pass filter Ch ' chname{1,1} ' to ' chname{end,1}],'HorizontalAlignment','center','VerticalAlignment', 'top', 'FontSize', 12);
    end
    
    %plot the filterd integral signal, all channels next to each other
    figure
    hold on
    idx=ch1;
    for ii=1:grd
        
        ax(ii)=subplot(grd,1,ii);
        plot(tt2, intg_flt(:,ii));
        %ylim([-0.025 0.025]); %consider 0.1
        if params.bipolar
            title([' Ch ' chname{idx,1} '-' chname{idx+1,1}]);
        else
            title([' Ch ' chname{idx,1}]);
        end        
        idx=idx+1;        
        ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');        
        text(0.5, 1,['\bf Filtered integral data across Ch ' chname{1,1} ' to, ' chname{end,1}],'HorizontalAlignment','center','VerticalAlignment', 'top', 'FontSize', 12);
    end
end




end