function [bandspectrum, betaband, Comodulogram_phase, bandfilterA, bandfilterP, bandfilterS] = PAC_ucsf(data,varargin)
%this is an edited copy of the main function they use at UCSF
%


% Inputs:
%     data=  data as signal by channels
% 
% Outputs:
%     bandspectrum= struct with all of the mtpsectrumc total and at each band, from window below, but usually 200ms with 5ms overlap
%     betaband= struct with just the filtered data over narrow ranges of beta
%     Comudulogram_phase= the comodulogram after running the PAC analysis
%     bandfiltersA= bandfilters for Amplitude, to be put back into this for future runs
%     bandfiltersP= bandfilters for Phase, to be put back into this for future runs
%     bandfiltersS= bandfilters for the narrow beta bands, to be put back into this for future runs


[varargin, bipolar] = util.argkeyval('bipolar',varargin,false); %NOT READY YET, BUT WILL MAKE OPTION FOR BIPOLAR
[varargin, params] = util.argkeyval('params',varargin,[]); %can update params if desired
[varargin, fs] = util.argkeyval('fs',varargin,2000); %sampling rate
%dont think i need this in this [varargin, high_freq] = util.argkeyval('high_freq',varargin,[65 150]); %high frequency amplitude component
% same [varargin, low_freq] = util.argkeyval('low_freq',varargin,[15 30]); %low frequency phase component
[varargin, spect_freq] = util.argkeyval('spect_freq',varargin,[0 200]); % range for your spectrogram frequency
[varargin, pad]=util.argkeyval('pad',varargin,1); %control the pad in the spectrogram
[varargin, window] = util.argkeyval('window',varargin,[0.2, 0.005]); % window for spectrogram
[varargin, ch] = util.argkeyval('channels',varargin,(1:size(data,2))); % if you want to specify only certain channels, can also do (4,5,8)
%% how long an epoch to look at
[varargin, epochLength] = util.argkeyval('epochLength',varargin,[1, size(data, 1)]); % how long of an epoch do you want to pass into the PAC function

%% basic running parameters
[varargin, needsfilter] = util.argkeyval('needsfilter',varargin, false); % option to comb filter/bandpass filter the data
[varargin, normBaseline] = util.argkeyval('normBaseline',varargin,[5 100]);  % the baseline normalization to be done
[varargin, nbinRad] = util.argkeyval('nbinRad',varargin, 18);  % number of bins f
%% Filters
[varargin, PhaseFreq_BandWidth] = util.argkeyval('PhaseFreq_BandWidth',varargin, 2);  % phase frequency band width
[varargin, AmpFreq_BandWidth] = util.argkeyval('AmpFreq_BandWidth',varargin, 4);  % amplitude frequency band width
[varargin, MaxPhaseFreq] = util.argkeyval('MaxPhaseFreq',varargin, 50);  % maximum phase frequency to run PAC to
[varargin, MinPhaseFreq] = util.argkeyval('MinPhaseFreq',varargin, 4);  % maximum phase frequency to run PAC to

[varargin, MaxAmpFreq] = util.argkeyval('MaxAmpFreq',varargin, 200);  % maximum Amplitude frequency to run PAC to
[varargin, MinAmpFreq] = util.argkeyval('MaxAmpFreq',varargin, 10);  % minimium Amplitude frequency for your bands

[varargin, BetaRange] = util.argkeyval('BetaRange',varargin, [15 17 24 26]);  % the narrow beta range changes plotted
[varargin, bandfilterA] = util.argkeyval('bandfiltersA',varargin, []);  % check if filters already made so you don't have to keep making them each run
[varargin, bandfilterP] = util.argkeyval('bandfiltersP',varargin, []);  % check if filters already made so you don't have to keep making them each run
[varargin, bandfilterS] = util.argkeyval('bandfiltersS',varargin, []);  % check if filters already made so you don't have to keep making them each run

%%
util.argempty(varargin); % check all additional inputs have been processed


% check if params structure was provided
if nargin == 1 || isempty (params)
    params = struct;
    params.Fs = fs;   % in Hz
    params.fpass = spect_freq;     % [minFreqz maxFreq] in Hz
    params.tapers = [5 9]; %second number is 2x the first -1, and the tapers is how many ffts you do.
    params.pad = pad;
    %params.err = [1 0.05];
    params.err=0;
    params.trialave = 1; % average across trials
    params.win = window;   % size and step size for windowing continuous data
end



%% 1. Reference/filter data
% rereference data
% for i = 1:length(lfp.contact)-1     % counts the number of contacts and loops
%     signals(i,:)=lfp.contact(i).signal-lfp.contact(i+1).signal; % subtracts reference from signal        i
% end

% % notch filter noise
% for i = 1: size(signals,1)  % loops through the signals
%     noise=60;               % remove 60 Hz
%     Fs=lfp.Fs(i);           % identify the sampling frequency for each contact
%     for j = 1:6             % filter out 60Hz and harmonics up to 360 (6*60Hz)
%         [n1_b, n1_a]=butter(3,2*[(noise*j)-2 (noise*j)+2]/Fs,'stop');
%         signals(i,:)=filtfilt(n1_b, n1_a, signals(i,:));
%     end
% end

% select 1min of data wihtout noise
%IS THIS CONTINUOUS DATA AND CAN WE DO IT TRIAL BASED? LOOKS LIKE YES BASED
%ON PRIOR STUDIES YOUVE DONE.  DOES IT NEED 1 MINUTE OF DATA
% if size(signals,2)>=60000 % 60s*freq sampling (1000Hz)
%     signals=signals(:,1:60000);
% end

if length(ch)==2
    ch=ch(1):ch(2);
    disp('channels should be entered as individual channels, or as the first and the last, e.g. ch=[1,2,3,4,9,10,11,14]; or ch=[1 20] which will be represented as ch=[1:20];')
end

bandspectrum=struct;

%select only the channles you care about

signals = data(:, ch);

%option if the data is raw
%CONSIDER BIPOLAR
if needsfilter
    %remove dc offset
    signals = signals-repmat(nanmean(signals,1),size(signals,1),1);
    
    %notch filter
    % Filter for 60 Hz noise and 120 Hz and 180 Hz
    bsFilt1 = designfilt('bandstopiir','FilterOrder',2, ...
        'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
        'SampleRate',fs,'DesignMethod','butter');
    
    bsFilt2 = designfilt('bandstopiir','FilterOrder',2, ...
        'HalfPowerFrequency1',119,'HalfPowerFrequency2',121, ...
        'SampleRate',fs,'DesignMethod','butter');
    
    bsFilt3 = designfilt('bandstopiir','FilterOrder',2, ...
        'HalfPowerFrequency1',179,'HalfPowerFrequency2',181, ...
        'SampleRate',fs,'DesignMethod','butter');
    
    signals = filtfilt(bsFilt1,signals); % filter raw data
    signals = filtfilt(bsFilt2,signals);
    signals = filtfilt(bsFilt3,signals);  
end

%flip signals for use in this program
signals = signals';

%% compute psd
%run through channels
%I think this is taking power spectral density (power along
%frequencies for an epoch of time, being fed in as the time you want to
%evaluate), then turn to db and store the mean for each band (so all the signals 4 to 8),
%then normalize by dividing by the mean of the signal between 5 and 100
%(normBaseline)
for i = 1: size(signals,1)
    %compute psd for each lfp channel
    %change pwelch to mtspectrumc with each channel as a trial to do this
    %with trials.  
    %WHY PWELCH, IS IT BECAUSE CONTINUOUS DATA? PWELCH IS JUST TAKING A
    %BUNCH OF EPOCHS OF DATA (2048) IN ORDER TO
    [psd, F] = chronux.ct.mtspectrumc(signals(i,:), params); %run a
    %spectrum instead
    %[psd,F] = pwelch(signals(i,:),2^(nextpow2(fs)),2^(nextpow2(fs/2)),2^(nextpow2(fs)),fs);
    %put raw psd in a matrix and average psd in different freq band (alpha, theta, beta...)
    bandspectrum.psd_all(:,i)=psd;
    t = find(F>=1 & F<=4); % theta
    bandspectrum.psd_delta(i) = nanmean(log10(psd(t)));
    t = find(F>=5 & F<=7);   % delta
    bandspectrum.psd_theta(i) = nanmean(log10(psd(t)));
    t = find(F>=8 & F<=12); % alpha
    bandspectrum.psd_alpha(i) = nanmean(log10(psd(t)));
    t = find(F>=13 & F<=30); % beta
    bandspectrum.psd_beta(i) = nanmean(log10(psd(t)));
    t = find(F>=13 & F<=20); % low beta
    bandspectrum.psd_Lbeta(i) = nanmean(log10(psd(t)));
    t = find(F>=20 & F<=30); % high beta
    bandspectrum.psd_Hbeta(i) = nanmean(log10(psd(t)));
    t = find(F>=30 & F<=50); % gamma
    bandspectrum.psd_gamma(i) = nanmean(log10(psd(t)));
    t = find(F>=50 & F<=150); % high gamma
    bandspectrum.psd_Hgamma(i) = nanmean(log10(psd(t)));
    
    % normalize psd (using 5-100Hz as baseline, normBaseline) and average norm psd accross different freq bands
   %WHY THIS NORMALIZATION METHOD, WHY 5 TO 100HZ
    norm_idx=find(F>=normBaseline(1) & F<=normBaseline(2));
    psd_norm=psd/mean(psd(norm_idx(1):norm_idx(end)));
    bandspectrum.psd_norm_all(:,i)=psd_norm;
    t = find(F>=1 & F<=4);
    bandspectrum.psd_norm_delta(i) = nanmean(log10(psd_norm(t)));
    t = find(F>=5 & F<=7);
    bandspectrum.psd_norm_theta(i) = nanmean(log10(psd_norm(t)));
    t = find(F>=8 & F<=12);
    bandspectrum.psd_norm_alpha(i) = nanmean(log10(psd_norm(t)));
    t = find(F>=13 & F<=30);
    bandspectrum.psd_norm_beta(i) = nanmean(log10(psd_norm(t)));
    t = find(F>=13 & F<=20);
    bandspectrum.psd_norm_Lbeta(i) = nanmean(log10(psd_norm(t)));
    t = find(F>=20 & F<=30);
    bandspectrum.psd_norm_Hbeta(i) = nanmean(log10(psd_norm(t)));
    t = find(F>=30 & F<=50);
    bandspectrum.psd_norm_gamma(i) = nanmean(log10(psd_norm(t)));
    t = find(F>=50 & F<=150);
    bandspectrum.psd_norm_Hgamma(i) = nanmean(log10(psd_norm(t)));
end
% save psd matrices and averaged psd
%save([name '_psd'],'psd_theta', 'psd_delta','psd_alpha','psd_beta','psd_Lbeta','psd_Hbeta','psd_gamma','psd_all','F'...
%    ,'psd_norm_theta', 'psd_norm_delta','psd_norm_alpha','psd_norm_beta','psd_norm_Lbeta','psd_norm_Hbeta','psd_norm_gamma','psd_norm_all');
% plot data
%THESE YLIMS, THROW MY DATA OFF SCREEEN, I'M ASSUMING THIS HAS TO DO WITH
%THE DIFFERENCE IN YOUR RECORDINGS VS MINE BUT WAS THERE A REASON YOU DID
%IT THAT WAY?

%things to do:
% going to want to get a mean and sd for these, then plot it with the other
% trials, so likely take this out of here or make it optional

figure
set(gca, 'FontSize', 22);
subplot(2,2,1)
plot(F,log10(bandspectrum.psd_all))
xlim([0 200])
%ylim([-3 3])
xlabel('Frequency');
ylabel('dB Power');
legend('lfp  1','lfp  2','lfp  3','lfp  4','lfp  5','lfp  6','lfp  7','lfp 8')
subplot(2,2,2)
plot(F,log10(bandspectrum.psd_norm_all))
xlim([0 200])
%ylim([-1.5 1.5])
xlabel('Frequency');
ylabel('Normalized (/mean(5 to 100 Hz) dB Power');
subplot(2,2,3)
plot(F,log10(bandspectrum.psd_all))
xlim([0 50])
%ylim([-3 3])
xlabel('Frequency');
ylabel('dB Power');
subplot(2,2,4)
plot(F,log10(bandspectrum.psd_norm_all))
xlim([0 50])
%ylim([-1.5 1.5])
xlabel('Frequency');
ylabel('Normalized (/mean(5 to 100 Hz) dB Power');
%saveas(gcf,[name '_PSD_filt'],'fig');

%% beta source
%filter low and High beta and extract amplitude
%DO YOU HAPPEN TO KNOW IF YOU WERE RECORDING IN MV OR UV? ALSO WHAT WOULD
%BE AN EXAMPLE OF WHAT YOU'D SEE IN THE BETA OSCILLATIONS FOR THIS? 

betaband = struct;
if isempty(bandfilterA)
    %create the filters if not done previously
    [bandfilterA, bandfilterP, bandfilterS] = Analysis.PAC.bandfiltersAP(AmpFreq_BandWidth, fs, 'PhaseFreq_BandWidth', PhaseFreq_BandWidth,...
        'MaxPhaseFreq', MaxPhaseFreq, 'MinPhaseFreq', MinPhaseFreq, 'MaxAmpFreq', MaxAmpFreq, 'MinAmpFreq', MinAmpFreq, 'SubBandRange', BetaRange);
end


lbl = fieldnames(bandfilterS);
for i= 1:size(signals,1)
    LB = filtfilt(bandfilterS.(lbl{1}), signals(i,:)); % filtering
    LBlfps(i, :) = LB;
    HB = filtfilt(bandfilterS.(lbl{1}), signals(i,:)); % filtering
    HBlfps(i, :) = HB;
end
betaband.LB = LBlfps;
betaband.HB = HBlfps;
% plot 1s of data
figure
set(gca, 'FontSize', 22);

subplot(1,2,1)
hold on
for i = 1:7
    plot(betaband.LB(i,:)*100+i*10); %*10 to be able to see it and +i*10 is to offset them
end
title('LB 15Hz 17Hz')
xlabel('time');
ylabel('Voltage');
subplot(1,2,2)
hold on
for i = 1:7
    plot(betaband.HB(i,:)*100+i*10);%*10 to be able to see it and +i*10 is to offset them
end
title('LB 24Hz 26Hz')
xlabel('time');
ylabel('Voltage');
%saveas(gcf,[name '_betasource_filt'],'fig');
% save
%save([name '_source'],'LBlfps','HBlfps');




%% compute PAC
% define variables

%nbinRad = 18;
position=zeros(1,nbinRad); % this variable will get the beginning (not the center) of each phase bin (in rads)
winsize = 2*pi/nbinRad;
for j=1:nbinRad
    position(j) = -pi+(j-1)*winsize;
end

% filter data and extract phase/amplitude
tt=tic;
lblA = fieldnames(bandfilterA);
lblP = fieldnames(bandfilterP);

AmpFreqVector = [MinAmpFreq:AmpFreq_BandWidth:MaxAmpFreq];
PhaseFreqVector = [MinPhaseFreq:PhaseFreq_BandWidth:MaxPhaseFreq];

for i =1:size(signals,1)
    lfp = signals(i,epochLength(1):epochLength(2)); %take the signal to 
    AmpFreqTransformed = zeros(length(AmpFreqVector), size(lfp,2));
    PhaseFreqTransformed = zeros(length(PhaseFreqVector), size(lfp,2));
    
    for ii=1:length(AmpFreqVector)
       %WHAT WERE YOU GETTING AT FILTERWISE WITH THE EEGFILT_FIR AND WHY
       %FIR? WAS RUNNING INTO PROBLEMS WITH IT SO WAS GOING TO USE FILTFILT
        AmpFreq = filtfilt(bandfilterA.(lblA{ii}), lfp); % just filtering
        AmpFreqTransformed(ii, :) = abs(hilbert(AmpFreq)); % getting the amplitude envelope
    end
    
    for jj=1:length(PhaseFreqVector)        
        PhaseFreq = filtfilt(bandfilterP.(lblP{jj}), lfp); % just filtering 
        PhaseFreqTransformed(jj, :) = angle(hilbert(PhaseFreq)); % this is getting the phase time series
    end
    
    % calculate PAC
    
    counter1=0;
    for ii=1:length(PhaseFreqVector)
        counter1=counter1+1;
        counter2=0;
        for jj=1:length(AmpFreqVector)
            counter2=counter2+1;
            [MI,MeanAmp]=Analysis.PAC.PAC_ModIndex_v2(PhaseFreqTransformed(ii, :), AmpFreqTransformed(jj, :), position);
            Comodulogram(counter1,counter2,i)=MI;
            x = 10:20:360;
            [val,pos]=max(MeanAmp);
            Comodulogram_phase(counter1,counter2,i) = x(pos);
        end
    end
end
toc(tt)
% save data
%save([name '_Com_chan_filt'],'Comodulogram','Comodulogram_phase','PhaseFreqVector','PhaseFreq_BandWidth','AmpFreqVector','AmpFreq_BandWidth');

%plot data
figure
set(gca, 'FontSize', 22);
Clim2 = max(max(max(Comodulogram(:,:,2))));
Clim1 = min(min(min(Comodulogram(:,:,2))));

for i = 1:7
    subplot(2,4,i)
    C=squeeze(Comodulogram(:,:,i));
    contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,C',30,'lines','none')
    set(gca,'fontsize',14)
    ylabel('Amplitude Frequency (Hz)')
    xlabel('Phase Frequency (Hz)')
    colorbar
    caxis([Clim1 Clim2])
    title(['lfp  ' num2str(i) ]);
    
end
% saveas(gcf,[name '_Com_filt'],'fig');


% clear  psd_all psd_norm_all signals HBlfps LBlfps

end

