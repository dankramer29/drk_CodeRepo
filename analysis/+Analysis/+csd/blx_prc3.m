function [ proc_data1, proc_data2,  tt ] = blx_prc3( ds_ecog, sz, figtitle, params)

%%
%{

CSD processing optional steps
%csd_prc CSD processing


Input
    sz=     the time before the seizure, in minutes.  so if the data starts
            30 min prior to seizure, put in 30

Sample:
params=[];
[lowpass05, integral_lowpass05, ttBP3070] = csd.blx_prc3( ds_ecog1, 60, 'SGR Sz 4 lowpass 0.05Hz PSG6-10', params);


%}
%%

if nargin==2 || isempty (params)
    params = struct;
    params.ch= [6 9]; %channels to look at
    params.newfs= 400; %downsample frequency, base is 400 samples/sec (for 200Hz by nyquist)
    params.proc= 2; 
    %proc 1 is a bandpass
        %can do a moving window within this, change .movwdw=true
        %can do an integral filter within this, change .integral=true
    %proc 2 is a lowpass
    %proc 3 is a power filter
    
    params.wnd= [300 300]; %wnd1 and wnd2, set at 300s each, wdw 2 is the time constant decay
    params.bandpass= [0.5 70]; %bandpass filter 
    params.lowpass= 1; %the lowpass filter set at 5Hz right now, for 10 samples/second in the pwr analysis
    params.movwdw=false; %if you want to run a moving window average of the data of some kind, this is the output proc_data2
    params.integral=false; %if you want to run the integral (per fabricius: time integral of the ECoG signal followed by a subtraction of the general slope of the integral (300 s time constant decay)
    params.plot=true; %if you want to plot
end

%parameters
bandpass=params.bandpass;
wnd1=params.wnd(1,1);
wnd2=params.wnd(1,2);
proc=params.proc;
dsrt=params.newfs;
ch=params.ch;
chs=ch(1,2)-ch(1,1)+1;

%%
%this is the new sampling rate you want for the lowpass filter for the
%power analysis, so change here in the future if need be. In hz for the
%eventual low pass of 5hz, meaning you will want 10 samples a second.
lowpass=params.lowpass;
%%
%convert the window input, in seconds, to match the downsample rate
wnd1=round(wnd1*dsrt);
wnd2=round(wnd2*dsrt);

%%
%create a bandpass filter
filtobj = designfilt('bandpassiir',...
    'DesignMethod','butter',...
    'FilterOrder',8,...
    'HalfPowerFrequency1',bandpass(1,1),...
    'HalfPowerFrequency2',bandpass(1,2),...
    'SampleRate',dsrt);

%%
%the HalfPowerFrequency is your frequency you want to pass under and your
%subsample rate is double that for nyquist. 
lowfiltobj = designfilt('lowpassiir', 'FilterOrder', 8, ...
                        'HalfPowerFrequency', lowpass, 'SampleRate', dsrt, ...
                        'DesignMethod', 'butter');

%%
switch proc
    case 1
        proc_data1=zeros((size(ds_ecog,1)+wnd2*2+1),chs,'single');        
    case 2
        proc_data1=zeros((size(ds_ecog,1)+wnd2*2+1),chs,'single');
        proc_data2=zeros((size(ds_ecog,1)+wnd2*2+1),chs,'single');
    case 3
        Temp=zeros((size(ds_ecog,1)+wnd2*2+1),chs,'single');
        
end

%%
MA_filter=ones(1,wnd1)/wnd1; %a moving window average (divided by the wnd1
Intg_filter=ones(1,wnd2); %not an average, just the sum to make the intergral
%%
idx=1;
for jj=ch(1,1):ch(1,2)
    
    dt=ds_ecog(:,jj);
    
    %appended mirror ends for convolve
    mbeg=flipud(dt(1:wnd2,1));
    mend=flipud(dt(end-wnd2:end,1));
    dt=vertcat(mbeg,dt);
    dt=vertcat(dt,mend);
    
    tic;
    
    %Run either proc 1, 2 or 3 and then a further analysis if needed
    switch proc;
        case 1
            %run the bandpass filter
            proc_data1(:,idx)=filter(filtobj,dt);
            if params.movwdw
                %run the moving window average
                proc_data2(:,idx)=conv(proc_data1(:,idx),MA_filter,'same');
            else
                proc_data2=[];
            end
            if params.integral
                %calculate the integral of a moving window size wnd2
                proc_data2(:,idx)=conv(proc_data1(:,idx),Intg_filter,'same');
                %create a moving window average of the integral data
                proc_data2(:, idx)=proc_data2(:,idx)-conv(proc_data2(:,idx),MA_filter,'same');
            else
                proc_data2=[];
            end
        case 2
            %low pass filter
            proc_data1(:,idx)=filter(lowfiltobj,dt);
            if params.integral
                %calculate the integral of a moving window size wnd2
                proc_data2(:,idx)=conv(proc_data1(:,idx),Intg_filter,'same');
                %create a moving window average of the integral data
                proc_data2(:, idx)=proc_data2(:,idx)-conv(proc_data2(:,idx),MA_filter,'same');
            else
                proc_data2=[];
            end
            
        case 3
            
            %run the bandpass filter
            Temp=filter(filtobj,dt);
            %power
            Temp(:,idx)=dt.^2;
            
            %then do another low pass filter (based on low pass above
            Temp(:,idx)=filter(lowfiltobj,proc_data1(:,idx));
            %remove ends prior to subsample
            Temp(1:wnd2,idx)=[];
            Temp(end-wnd2:end,idx)=[];
            %subsample at the new sampling rate.  you are currently at 400 samples a
            %second and want to make it 10 samples a second, which is to divide the
            %current by 40.
            proc_data1(:,idx)=Temp(1:floor(dsrt/(lowpass*2)):end, idx);
    end
    toc;
    idx=idx+1;
end
%%
szrow=sz*60*dsrt;
switch proc
    case 1
        proc_data1(1:wnd2,:)=[];
        proc_data1(end-wnd2:end,:)=[];
        tt=(0:1/dsrt:size(proc_data1,1)/dsrt-1/dsrt)-szrow/dsrt;
        if params.movwdw
            proc_data2(1:wnd2,:)=[];
            proc_data2(end-wnd2:end,:)=[];
        else
            proc_data2=[];
        end
        if params.integral
            proc_data2(1:wnd2,:)=[];
            proc_data2(end-wnd2:end,:)=[];
        else
            proc_data2=[];
        end
    case 2
        proc_data1(1:wnd2,:)=[];
        proc_data1(end-wnd2:end,:)=[];
        tt=(0:1/dsrt:size(proc_data1,1)/dsrt-1/dsrt)-szrow/dsrt;
        if params.integral
            proc_data2(1:wnd2,:)=[];
            proc_data2(end-wnd2:end,:)=[];
        else
            proc_data2=[];
        end
    case 3
        proc_data2=[];
        %the sampling rate is different for the pwr, the 5 below needs to change if
        %the subsampling changes for pwr_lwps under csd processing in the future
        pldsrt=dsrt/floor(dsrt/(lowpass*2));
        tt=(0:1/pldsrt:size(pwr_lwps,1)/pldsrt-1/pldsrt)-(szrow/dsrt);        
end

if params.plot
    csd.quickplot(proc_data1, tt, 'ch', ch, 'figtitle', figtitle);  
end


    
end


