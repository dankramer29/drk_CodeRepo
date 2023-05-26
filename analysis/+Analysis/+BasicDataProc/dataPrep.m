function [filtData, params, dataFinalCB, bandfilter, filterClassBand] = dataPrep(data, varargin)
%dataPrep basic data prep
%   notch filter, common average rereference to remove dc offset, bandpass
%   filters


%[filtData] = Analysis.BasicDataProc.dataPrep(data); %if the filters are not made
%already
%[filtData] = Analysis.BasicDataProc.dataPrep(data, 'bandfilterA', bandfilter); %if the filters are made

%Output
%     filtData= struct with all of the outputs (note dataFinalCB is redundant with .ClassicBand in this struct, it's for easier use outputting)
%     params= parameters used for spectrogram
%     dataFinalCB= the classic band filtered data, redundant with what's in filtData
%     bandfilter= the band filters you make if you aren't doing spectrogram
%     filterClassBand= the classic band filters if they haven't already been made. It's an input if you are doing this multiple times, so you don't need to keep making filters
%     
    %Things to do
%   check if this is the right order to do things
%   run against a known piece of data to see if it actually works and why
%   the band passed looks so terrible

%% varargin parameters
[varargin, fs] = util.argkeyval('fs',varargin, 2000); %sampling rate

%% basic running parameters

[varargin, needsCombfilter] = util.argkeyval('needsCombfilter',varargin, true); % option to comb filter/bandpass filter the data
[varargin, commonAverage] = util.argkeyval('commonAverage',varargin, false); % option to do a common average rereference
[varargin, dBPower] = util.argkeyval('dBPower',varargin, true); % option to turn to dB
[varargin, zScore] = util.argkeyval('zScore',varargin, true); % option to turn on Z scoring
[varargin, itiProc] = util.argkeyval('itiProc',varargin, false); % option to make an iti, which averages across it before doing dB etc
[varargin, convWin] = util.argkeyval('convWin',varargin, 60); % what convolve window to use on either FIR or IIR filtered data.  30 to 60 seems right.  Doesn't affect lower freq, largely affects higher freq in a positive smoothing way.

% option to add a mirrored end for ramp up with band filters, in seconds,
% so .5 is .5 seconds, and make 0 if want none
[varargin, mirroredEnd] = util.argkeyval('mirroredEnd',varargin, .3); 

%% Filters
[varargin, Spectrogram] = util.argkeyval('Spectrogram',varargin, true);  %if you want to do it with spectrogram method
[varargin, doPSpectrum] = util.argkeyval('doPSpectrum',varargin, false);  %if you want to do it with spectrogram method from pspectrum with matlab 
[varargin, multiTaperWindow] = util.argkeyval('multiTaperWindow',varargin, .200);  %the multitaper window in seconds

[varargin, BandPassed] = util.argkeyval('Bandpassed', varargin, false); %alternate to spectrogram to run filters and build them on top of each other at 2 hz bands
[varargin, DoBandFilterBroad] = util.argkeyval('DoBandFilterBroad', varargin, true);  %if you want to also run canonical basic band filters (different than the 2 hz filter method below) in classic frequencies (delta 1-4 theta 4-8 alpha 8-13 beta 13-30 gamma 30-50 high gamma 50 to 200)
[varargin, IIR] = util.argkeyval('IIR',varargin, true);  % IIR vs FIR, UCSF uses FIR for phase stuff

[varargin, Freq_BandWidth] = util.argkeyval('Freq_BandWidth',varargin, 2);  %width of the bands you are filtering (DOESN'T SEEM TO WORK RIGHT NOW)
[varargin, MinFreq] = util.argkeyval('MinFreq',varargin, 1);  % minimium frequency to run
[varargin, MaxFreq] = util.argkeyval('MaxFreq',varargin, 150);  % maximum  frequency to run

[varargin, bandfilter] = util.argkeyval('bandfilter',varargin, []);  % check if filters already made so you don't have to keep making them each run
[varargin, filterClassBand] = util.argkeyval('dataClassBand',varargin, []);  % check if classic broad filters already made so you don't have to keep making them each run
[varargin, classicBandRange]= util.argkeyval('classicBandRange', varargin, [1 4; 4 8; 8 13; 13 30; 30 50; 50 150]); %filtered data classic
%flip data if suspect it's in channels x data
if size(data,1)<=size(data,2)
    %warning('data in channels x voltage, not voltage x channels, converted to voltage x channels for analysis');
    data=data';
end

[varargin, Epoch] = util.argkeyval('Epoch',varargin, 1:size(data,1)); % option to take only a designated epoch


%%
%for spectrogram
params = struct;
params.Fs = fs;   % in Hz
params.fpass = [MinFreq MaxFreq];     % [minFreqz maxFreq] in Hz
params.tapers = [5 9]; %second number is 2x the first -1, and the tapers is how many ffts you do.
params.pad = 1;
%params.err = [1 0.05];
params.err=0;
params.trialave = 0; % average across trials
params.win = [multiTaperWindow 0.005];   % size and step size for windowing continuous data
params.bipolar=false;
params.dbPower=dBPower;
params.zScore=zScore;
params.Spectrogram=Spectrogram;
params.Freq_BandWidth=Freq_BandWidth;
params.MinFreq=MinFreq;
params.MaxFreq=MaxFreq;
params.OverlapPercentage=95; %this is for pspectrum
%%

filtData=struct;

data=data(Epoch, :);

%make sure data is columns=channels and rows are time
if size(data, 1)<size(data,2)
    data=data';
end


%set up the frequency band categories
freqBand = [MinFreq:Freq_BandWidth:MaxFreq];

%% common average to subtract the dc offset
if commonAverage
    data = data - repmat(nanmean(data,1), size(data,1), 1);
end

%% add a ramp up mirrored end (really mirrored start)
%NOTE: this mirrored end is set to 1s, if you change this, must change the
%tplot below, subtracting the same time you mirrored.
ramp=fs*mirroredEnd;
if ramp>0
    dataM = vertcat(flipud(data(1:ramp-1,:)), data, flipud(data(end-ramp+1:end,:)));
end


%%
%if needs a notch filter
if needsCombfilter 
    if IIR
    % Filter for 60 Hz noise and 120 Hz and 180 Hz
    notchFilt60 = designfilt('bandstopiir','FilterOrder',2, ...
        'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
        'SampleRate',fs,'DesignMethod','butter');
    
    notchFilt120 = designfilt('bandstopiir','FilterOrder',2, ...
        'HalfPowerFrequency1',119,'HalfPowerFrequency2',121, ...
        'SampleRate',fs,'DesignMethod','butter');
    
    notchFilt180 = designfilt('bandstopiir','FilterOrder',2, ...
        'HalfPowerFrequency1',179,'HalfPowerFrequency2',181, ...
        'SampleRate',fs,'DesignMethod','butter');
    
    dataM = filtfilt(notchFilt60,dataM);
    dataM = filtfilt(notchFilt120,dataM);
    dataM = filtfilt(notchFilt180,dataM);
    else %for fir
        for ii = 1:size(dataM,2)  % loops through the signals
            noise=60;               % remove 60 Hz
            for jj = 1:6             % filter out 60Hz and harmonics up to 360 (6*60Hz)
                [n1_b, n1_a]=butter(3,2*[(noise*jj)-2 (noise*jj)+2]/fs,'stop');
                dataM(:,ii)=filtfilt(n1_b, n1_a, dataM(:,ii));
            end
        end
    end
end

%the notch filtered and CAR with mirrored end removed
filtData.dataBasicFilter=dataM(ramp:end-ramp,:); 

%design a lowpass filter for smoothing after power
if BandPassed || DoBandFilterBroad
lpFilt = designfilt('lowpassiir','FilterOrder',8, ...
         'PassbandFrequency',15,'PassbandRipple',0.2, ...
         'SampleRate',fs);
end

%% Run either spectrogram or band filters

%% Spectrograms
if Spectrogram
        %run the spectrogram, does it in 3d so get freq x time x channels
        %(verified)
        [dataTempM, tplotTemp, ff]=chronux.ct.mtspecgramc(dataM, params.win, params); %time by freq, need to ' to plot with imagesc
        
        %remove the mirrored ends
        
        %set up plotting with time and frequency bands (this works)
        tplotTempT=tplotTemp-mirroredEnd; 
        zr=find(tplotTempT>0 & tplotTempT<tplotTempT(end)-mirroredEnd); %find the row for time=0        
        tplot=tplotTempT(zr(1):zr(end)); %cut off the mirrored end
        dataTemp=dataTempM(zr(1):zr(end), :, :); %cut off the mirrored end
        
        
        dataTemp=permute(dataTemp, [2,1,3]); %flip to make it freq x time x channel
        %set up plotting
        filtData.dataSpec.tplot=tplot;
        filtData.dataSpec.f=ff;
        filtData.params=params;
        bandfilter=[]; %have an empty return of bandfilter

        if doPSpectrum %can also do it with pspectrum to compare, f does 1024 at nyquist, so just cut it off.
            [sPspectrum, f, t] = pspectrum(dataM, fs, "spectrogram", TimeResolution=  params.win(1), OverlapPercent = params.OverlapPercentage); %will need to do normalize
            tplotTempT=t-mirroredEnd;
            zr=find(tplotTempT>0 & tplotTempT<tplotTempT(end)-mirroredEnd); %find the row for time=0
            tplotpSpec=tplotTempT(zr(1):zr(end)); %cut off the mirrored end
            dataTempPS=sPspectrum(:, zr(1):zr(end), :); %cut off the mirrored end
            maxF=find(f >= MaxFreq);
            dataTempPSmaxF=dataTempPS(1:maxF(1),:,:); 

            filtData.dataSpec.pSpectrum.tplot=tplotpSpec;
            filtData.dataSpec.pSpectrum.f=f(1:maxF(1));        
            filtData.dataSpec.pSpectrum.data=dataTempPSmaxF;        

        end
        
elseif BandPassed
        %% Bandpassed
        %bandpass filters
        if isempty(bandfilter)
            %create the filters if not done previously
            [bandfilter]=Analysis.PAC.bandfiltersAP(Freq_BandWidth, fs, 'MinAmpFreq', MinFreq, 'MaxAmpFreq', MaxFreq); %create the band filters
        end
        
        %% set up the filtering
        lblA=fieldnames(bandfilter);  
        
        
        %% run the filters
        tt=tic;
        for ii=1:length(freqBand)
            %run the filters and make power
            tempMD=filtfilt(bandfilter.(lblA{ii}), dataM).^2;
            %lowpass to smooth the data.  This can be a variable pass, based on what "window" you want to smooth over
            tempMDFF=filtfilt(lpFilt, tempMD);
            MDnegTemp=find(tempMDFF<0);
            tempMDFF(MDnegTemp)=tempMDFF(MDnegTemp)*-1;
            tempMDC(ii,:,:)=tempMDFF; %build the filtered data into 3d matrix and make 3rd dimmension channels, so now freq x time x channels
        end
        
        %remove the mirrored end
        dataTemp=tempMDC(:,ramp:end-ramp,:);
        %dataTemp=permute(dataTemp, [2,1,3]);
        
        toc(tt)
        %set up plotting with time and frequency bands
        %get the time for plotting
        tplot = 0:1/fs:size(dataTemp,1)/fs;
        filtData.dataSpec.tplot=tplot;
        filtData.dataSpec.f=freqBand;
else %if you don't want to do the spectrogram because it's taking forever
    %NOT CHECKED
    
    %just turn the basic filtered data to power
    tempMD=dataM.^2;
    %lowpass to smooth the data.  This can be a variable pass, based on what "window" you want to smooth over
    tempMDFF=filtfilt(lpFilt, tempMD);
    MDnegTemp=find(tempMDFF<0);
    tempMDFF(MDnegTemp)=tempMDFF(MDnegTemp)*-1;
    tempMDC=tempMDFF; %build the filtered data into 3d matrix and make 3rd dimmension channels, so now freq x time x channels
    clear tempMDFF;
    
    %remove the mirrored end
    dataTemp=tempMDC(:,ramp:end-ramp,:);
    %dataTemp=permute(dataTemp, [2,1,3]);
    

    %set up plotting with time and frequency bands
    %get the time for plotting
    tplot = 0:1/fs:size(dataTemp,1)/fs;
    filtData.dataSpec.tplot=tplot;
    filtData.dataSpec.f=freqBand;
end


        
        
        
if DoBandFilterBroad
    if  IIR
        if isempty(filterClassBand)
        %create the filters if not done previously, for the classic bands,
        %the Freq_BandWidth is actually not used here, but just runs it
        %smoothly
        [~, ~, ~, ~, filterClassBand]=Analysis.PAC.bandfiltersAP(fs, 'AmpFreqVectorRun', false, 'nerdcoPACFilternerdcoPACFilter', false, 'doClassicBand', true, 'classicBandRange', classicBandRange); %create the band filters
        end
        %% set up the filtering
        lblB=fieldnames(filterClassBand);
        
        %% run the filters
        tt=tic;
        for ii=1:length(lblB)
            %run the filters and make power
            tempClassicBand=filtfilt(filterClassBand.(lblB{ii}), dataM).^2;
            %lowpass to smooth the data.  This can be a variable pass, based on what "window" you want to smooth over
            tempClassicBandFF=filtfilt(lpFilt, tempClassicBand);
            negTemp=find(tempClassicBandFF<0);
            tempClassicBandFF(negTemp)=tempClassicBandFF(negTemp)*-1;
            tempCBC(:,ii,:)=tempClassicBandFF; %data x band x channel
            %dataTempClassicBandAngle(:,ii)=[];
        end
        
    else %do an FIR with the ucsf code    
        bandSt=3;
        for ii=bandSt:length(classicBandRange) %skipping delta and theta due to constraints on the filter epochs.
            lblB{ii-bandSt+1}=strcat(num2str('FIR', classicBandRange(ii, 1)), 'to', num2str(classicBandRange(ii, 2)));
            tCB=eegfilt_FIR(dataM', fs, classicBandRange(ii, 1), classicBandRange(ii, 2));
            tempClassicBand(:, ii-bandSt+1, :)=tCB';
            tempCBC(:,ii-bandSt+1,:)=abs(hilbert(tempClassicBand(:,ii-bandSt+1,:))); %a power function essentially
            tempCBAngle(:,ii-bandSt+1,:)=angle(hilbert(tempClassicBand(:,ii-bandSt+1,:)));
        end
    end
    
    
    %remove the mirrored end
    dataClassicBandfilt=tempClassicBand(ramp:end-ramp,:,:);
    dataTempClassicBandPow=tempCBC(ramp:end-ramp,:,:);
    if ~IIR
        dataTempClassicBandAngle=tempCBAngle(ramp:end-ramp,:,:);
    end
    %set up plotting with time and frequency bands
    %get the time for plotting
    tplotCB = 0:1/fs:(size(data,1)-1)/fs;
    filtData.ClassicBand.tplotCB=tplotCB;
    filtData.ClassicBand.f=[1 4; 4 8; 8 13; 13 30; 30 50; 50 200];
end




%% dB plus a convolve smoothing function to mitigate large fluctuations from dB (dripping appearance)
if BandPassed || Spectrogram || DoBandFilterBroad
    if dBPower
        dataTemp=10*log10(dataTemp);     
        
        if BandPassed
            for ii=1:size(dataTemp,3)
                [dataTemp(:,:,ii), tplotC]=Analysis.BasicDataProc.convSmooth(dataTemp(:,:,ii), 30, fs);
            end
        end
        if DoBandFilterBroad && IIR
            dataTempClassicBandT=10*log10(dataTempClassicBandPow);
            for ii=1:size(dataTempClassicBandT,3)
                [dataTempClassicBandT(:,:,ii), tplotC]=Analysis.BasicDataProc.convSmooth(dataTempClassicBandT(:,:,ii), convWin, fs);
            end
        elseif DoBandFilterBroad && ~IIR
            for ii=1:size(dataTempClassicBandPow,3)
                [dataTempClassicBandT(:,:,ii)]=Analysis.BasicDataProc.convSmooth(dataTempClassicBandPow(:,:,ii), convWin, fs);
            end
            totaltime=size(data,1)/fs; %find the total time in secondsl;
            %create a time vector to plot the data
            tplotC=linspace(1/fs, totaltime, size(dataTempClassicBandT,1));
        end
    else
        dataTempClassicBandT=dataTempClassicBandPow;
    end
    
    %% z score
    if zScore && ~itiProc %do not run z score if an iti repmat
        for ii=1:size(dataTemp,3)
            baseTemp=dataTemp(:,:,ii);
            [a, b]=proc.basic.zScore(baseTemp, 'z-score', 2); %get the z score mean and std
            dataFinalZ(:,:,ii)=(baseTemp-a)./b;
            if doPSpectrum
                sPspectrumZ(:,:,ii) = normalize(sPspectrum(:,:,ii),2); %auto normalizes
            end

        end
        if DoBandFilterBroad 
            for ii=1:size(dataTempClassicBandT,3)
                baseTempCB=dataTempClassicBandT(:,:,ii);
                [a, b]=proc.basic.zScore(baseTempCB, 'z-score', 2); %get the z score mean and std
                dataFinalCBZ(:,:,ii)=(baseTempCB-a)./b;
            end
        end
    else
        dataFinalZ=[]; %store blank if no zScore or it's itiProc
        dataFinalCBZ=[];
    end
    
    %save a non z scored version
    if itiProc
        dataMean=mean(dataTemp,2);
        dataFinal=repmat(dataMean, 1, size(dataTemp,2), 1);
    else
        dataFinal=dataTemp;
    end
    if DoBandFilterBroad
        dataFinalCB=dataTempClassicBandT;
    else
        dataFinalCB=[];
    end
    
    filtData.dataSpec.data=dataFinal;
    clear dataFinal
    filtData.dataSpec.dataZ=dataFinalZ;
    clear dataFinal
    if doPSpectrum
        filtData.dataSpec.pSpectrum.data=sPspectrum;
        clear sPspectrum
        filtData.dataSpec.pSpectrum.data=sPspectrumZ;
    end

    
    if DoBandFilterBroad
        for ii=1:length(lblB)
            filtData.ClassicBand.Power.(lblB{ii})=dataFinalCB(:, ii, :);
            if ~isempty(dataFinalCBZ)
                filtData.ClassicBand.PowerZ.(lblB{ii})=dataFinalCBZ(:, ii, :);
            end
            filtData.ClassicBand.t=tplotC;
            if ~IIR
                filtData.ClassicBand.Angle.(lblB{ii})=dataTempClassicBandAngle(:, ii, :);
            end            
        end
        %filtData.ClassicBand.FiltOnly.(lblB{ii})=dataClassicBandfilt;         
    end
    
end


filtData.ClassicBand.zScore=zScore;
filtData.ClassicBand.dBPower=dBPower;
filtData.ClassicBand.IIR=IIR;
filtData.ClassicBand.convWin=convWin;
filtData.ClassicBand.itiProc=itiProc;


end



