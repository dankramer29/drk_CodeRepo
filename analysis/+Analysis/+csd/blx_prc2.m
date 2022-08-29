function [ flt, flt_lwps, intg_flt, pwr, pwr_lwps ] = blx_prc2( ds_ecog, dsrt, params)

%%
%{
USE THIS ONE 9/19/18

WORKS AS OF 6/21.

TO DO: CHANGE BACK TO GPU AND TEST THE VARIOUS VERSIONS WITH GPU INPUT AND
OUTPUT FOR LARGE DATA
%csd_prc CSD processing
Currently based on Fabricius.  The plots should be flt, int_flt, and
pwr_lwps.
THE ANALYSIS:
Raw voltage with a 0.5 - 70Hz bandpass
Integral with the subtraction of the moving window average
Power of the 0.5-70Hz band and then lowpass filter of 5Hz with a
subsampling of 10

Currently running proc=2 so just the pwr and the 



    Inputs:
        wnd1=       window in seconds for the moving average
        wnd2=       window in seconds for the moving chunk to integrate
        params.bandpass=   [high low] so [0.5 70] to pass through
        dsrt=       downsample rate, should already be a variable as output
                    from the downsample function
        proc=       %how many processing steps to do. 
            %1 - filtered voltage 
            %2 - raw voltage squared (pwr) and then a low pass filter is
                %applied, currently at 5Hz, through subsampling
            %3 - integral of the data and the integral filtered data (intg and
                %intg_flt 
        

    Outputs:
        flt=        the filtered data with a moving window average of size wdw2
        intg=       the data as an integral over a window of size wdw2
        intg_flt=   moving window average of the integrated data based on a
        300s time constant delay
        pwr=        a broad power spectral band of 0.5 to 70Hz which is
        just squared
        pwr_lwps=   a low pass filter added to the pwr by subsampling.
        this is the data you want to plot, not the pwr (?)

Sample:

[ flt, intg, intg_flt, pwr, pwr_lwps ] = csd.blx_prc2( ds_ecog, dsrt);

TO DO:
wdw1 doesn't seem to be used, right now they are the same, but go back and
look to see where it's supposed to be 1 and not 2
    -Resolved(?) it should be in the MA_filter, but might need to double
    check

%}
%%

if nargin==2 || isempty (params)
    params = struct;
    params.ch= [1 size(ds_ecog,2)]; %channels to look at
    params.cuttime= [30 30]; %amount of data to take around the sz, in Min
    params.newfs= 400; %downsample frequency, base is 400 samples/sec (for 200Hz by nyquist)
    params.fltr= 60; %notch filter of 60Hz, does not work on harmonics right now(I think)
    params.proc= 2; %how many processing steps to do. 
        %1 - filtered voltage         
        %2 - 1+raw voltage squared (pwr) and then a low pass filter is
        %applied, currently at 5Hz, through subsampling
        %3 = 2+integral of the data and the integral filtered data (intg and
            %intg_flt
    params.wnd= [300 300]; %wnd1 and wnd2, set at 300s each, wdw 2 is the time constant decay
    params.bandpass= [0.5 70]; %bandpass filter set at 0.5 to 70Hz
    params.lowpass= 5; %the lowpass filter set at 5Hz right now, for 10 samples/second in the pwr analysis
   
    
end

%parameters
bandpass=params.bandpass;
wnd1=params.wnd(1,1);
wnd2=params.wnd(1,2);
proc=params.proc;

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
%create a lowpass filter
%lowfiltobj = designfilt('lowpassiir',...
%    'DesignMethod','butter',...
%    'FilterOrder',8,...
%    'HalfPowerFrequency1',(1/lowpass)/2,...
%    'SampleRate',dsrt);

%the HalfPowerFrequency is your frequency you want to pass under and your
%subsample rate is double that for nyquist. 
lowfiltobj = designfilt('lowpassiir', 'FilterOrder', 8, ...
                        'HalfPowerFrequency', lowpass, 'SampleRate', dsrt, ...
                        'DesignMethod', 'butter');

%allocate the data to the size of the input + the added window ends +1
%cause it adds like that with the mirrored ends except after the filter of
%pwr, which doesn't need the 1.
%'gpuArray' the end if doing in gpu

%{
flt=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2),'single', 'gpuArray');
intg=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2),'single','gpuArray');
intg_flt=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2), 'single', 'gpuArray');
pwr=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2), 'single','gpuArray');
lwps=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2), 'single');
%}
switch proc
    case 1
        flt=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2),'single');        
    case 2
        flt=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2),'single');
        flt_lwps=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2),'single');
        pwr=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2), 'single');
        lwps=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2), 'single');
    case 3
        flt=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2),'single');
        pwr=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2), 'single');
        lwps=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2), 'single');
        intg=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2),'single');
        intg_flt=zeros((size(ds_ecog,1)+wnd2*2+1),size(ds_ecog,2), 'single');
        
end


%intg=nan(size(data,1)-wnd2,1);
%intg_flt=nan(size(data,1)-wnd2,1);



MA_filter=ones(1,wnd1)/wnd1; %a moving window average (divided by the wnd1
Intg_filter=ones(1,wnd2); %not an average, just the sum to make the intergral

for jj=1:size(ds_ecog,2)
    %run the bandpass filter
    dt=filter(filtobj,ds_ecog(:,jj));
    dtdt=dt;
    
    
    %appended mirror ends for convolve
    mbeg=flipud(dt(1:wnd2,1));
    mend=flipud(dt(end-wnd2:end,1));
    dt=vertcat(mbeg,dt);
    dt=vertcat(dt,mend);
    
    %do this again to make dtdt, this if for the gpu array since power will
    %be done outside of the gpu, and you don't want to have to keep
    %bringing in and out of the gpu so you make a duplicate just for the
    %pwr
    %dtdt=vertcat(mbeg,dt);
    %dtdt=vertcat(dt,mend);
    
    tic;
    %dt=gpuArray(dt);
    
    %Run either 1 process, 2 process or all 3
    switch proc
        case 1
            %run the moving window average
            flt(:,jj)=conv(dt,MA_filter,'same');
            %blanks to output
            pwr=[];
            lwps=[];
            intg=[];
            intg_flt=[];
        case 2
            %run the moving window average
            flt(:,jj)=conv(dt,MA_filter,'same');
            %run the moving window average
            flt_lwps(:,jj)=filter(lowfiltobj,dt); %change back to case 1 if needed
            %calculate the integral of a moving window size wnd2
            
            %power of 0.5 to 70Hz, take the bandpass data (dt) and square it.
            %to do gpu, will need to change dt to dtdt.^2
            pwr(:,jj)=dt.^2;            
            %then do another low pass filter
            lwps(:,jj)=filter(lowfiltobj,pwr(:,jj));
            
            intg=[];
            intg_flt=[];
        case 3
            %run the moving window average
            flt(:,jj)=conv(dt,MA_filter,'same');
            
            
            %calculate the integral of a moving window size wnd2
            intg(:,jj)=conv(flt(:,jj),Intg_filter,'same');
            %create a moving window average of the integral data
            intg_flt(:, jj)=intg(:,jj)-conv(intg(:,jj),MA_filter,'same');
            
            
            %power of 0.5 to 70Hz, take the bandpass data (dt) and square it.
            %to do gpu, will need to change dt to dtdt.^2
            pwr(:,jj)=dt.^2;            
            %then do another low pass filter
            lwps(:,jj)=filter(lowfiltobj,pwr(:,jj));
    end
    toc;
            
end
%%
%{
COMMENTED OUT UNTIL I CAN FIGURE OUT HOW TO MAKE THE GPU BUILT FOR SPEEEED
%gather pulls the variables out of the gpu
flt=gather(flt);
intg=gather(intg);
intg_flt=gather(intg_flt);
%}
%%


%remove the mirrored ends, lwps keeps the mirrored ends for a ramp up
%through lowpass (the rest for convolve)
switch proc
    case 1
        
        flt(1:wnd2,:)=[];
        flt(end-wnd2:end,:)=[];
    case 2
        flt(1:wnd2,:)=[];
        flt(end-wnd2:end,:)=[];
        flt_lwps(1:wnd2,:)=[];
        flt_lwps(end-wnd2:end,:)=[];
        lwps(1:wnd2,:)=[];
        lwps(end-wnd2:end,:)=[];
        
        %subsample at the new sampling rate.  you are currently at 400 samples a
        %second and want to make it 10 samples a second, which is to divide the
        %current by 40.
        pwr_lwps=lwps(1:floor(dsrt/(lowpass*2)):end, :);
        
    case 3
        flt(1:wnd2,:)=[];
        flt(end-wnd2:end,:)=[];
        intg(1:wnd2,:)=[];
        intg(end-wnd2:end,:)=[];
        intg_flt(1:wnd2,:)=[];
        intg_flt(end-wnd2:end,:)=[];
        lwps(1:wnd2,:)=[];
        lwps(end-wnd2:end,:)=[];
        
       
        
        %subsample at the new sampling rate.  you are currently at 400 samples a
        %second and want to make it 10 samples a second, which is to divide the
        %current by 40.
        pwr_lwps=lwps(1:floor(dsrt/(lowpass*2)):end, :);
        
end

    


    
end


