function [PAC_ch, bandfilterA, bandfilterP, bandfilterS] = trialPAC_ucsf(data, ptname, varargin)
%this is an edited copy of the main function they use at UCSF
%This is built for trial averaged data

% The PAC portion (see part 3) works like this: 
% 			i. Break the amplitude (envelope) vector into 10:4:100 and the
% 			phase (angle) 4:2:50 
%           ii. Filter just the frequency in those
% 			bands then take the abs(hilbert) for amplitude and
% 			angle(hilbert) for the phase to give the instantaneous phase
% 			iii. In modindex_v2 you are going through the phase in that
% 			frequency band by binning all frequencies (18 bins of 20degrees
% 			each)  and finding each instantaneous phase at a given time
% 			point in phasefreq, then finding what the mean amplitude is for
% 			the same time points in ampfreq
% 				1) This means you are looking at say 0-20 degrees and
% 				looking through phasefreq from 12:14Hz for time points that
% 				are in 0-20 degrees, then finding out the mean amplitude at
% 				those time points from ampfreq for each filtered frequency
% 				so for say 61:64Hz.  Then you do 20-40deg and do the same
% 				thing from -360 to 360.  Next you do 13:14H for 65:68hz
% 				until 200, then you do it again for 15:16Hz.
% 
% 
% 
% Inputs:
%     data=  data as signal x trials x channels
% 
% Outputs:
%     bandspectrum= struct with all of the mtpsectrumc total and at each band, from window below, but usually 200ms with 5ms overlap
%     betaband= struct with just the filtered data over narrow ranges of beta
%     Comudulogram_phase= the comodulogram after running the PAC analysis
%     bandfiltersA= bandfilters for Amplitude, to be put back into this for future runs
%     bandfiltersP= bandfilters for Phase, to be put back into this for future runs
%     bandfiltersS= bandfilters for the narrow beta bands, to be put back into this for future runs

%example use without filters made already
%
%     [PAC_ch, bandfiltersA, bandfiltersP, bandfiltersS] = Analysis.PAC.trialPAC_ucsf(dt, 'p024');
%
%example use with filters made already
%     [PAC_ch] = Analysis.PAC.trialPAC_ucsf(dt, 'p024', 'bandfilterA', bandfiltersA, 'bandfilterP', bandfiltersP, 'bandfilterS', bandfiltersS);


%[varargin, blc] = util.argkeyval('blc',varargin, blc); %blc file if have it

[varargin, bipolar] = util.argkeyval('bipolar',varargin,true); %Choose bipolar or not, if not it does a common average rereference 
[varargin, params] = util.argkeyval('params',varargin,[]); %can update params if desired
[varargin, fs] = util.argkeyval('fs',varargin,2000); %sampling rate

[varargin, spect_freq] = util.argkeyval('spect_freq',varargin,[0 200]); % range for your spectrogram frequency
[varargin, pad]=util.argkeyval('pad',varargin,1); %control the pad in the spectrogram
[varargin, window] = util.argkeyval('window',varargin,[0.2, 0.005]); % window for spectrogram
[varargin, ch] = util.argkeyval('channels',varargin,(1:size(data,3))); % if you want to specify only certain channels, can also do (4,5,8)

%% how long an epoch to look at
[varargin, epochLength] = util.argkeyval('epochLength',varargin,[1, size(data, 1)]); % how long of an epoch do you want to pass into the PAC function

%% basic running parameters
[varargin, needsfilter] = util.argkeyval('needsfilter',varargin, true); % option to comb filter/bandpass filter the data
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
[varargin, bandfilterA] = util.argkeyval('bandfilterA',varargin, []);  % check if filters already made so you don't have to keep making them each run
[varargin, bandfilterP] = util.argkeyval('bandfilterP',varargin, []);  % check if filters already made so you don't have to keep making them each run
[varargin, bandfilterS] = util.argkeyval('bandfilterS',varargin, []);  % check if filters already made so you don't have to keep making them each run

%%
util.argempty(varargin); % check all additional inputs have been processed



%figtitle=['PAC ', blc.ChannelInfo(ch(rr)).Label, ' Heatmap ', blc.SourceBasename, ' ', ecog.evtNames{ff}];

%% TO DO
%THE BIPOLAR REALLY ONLY WORKS IF YOU KNOW THE CHANNELS ARE ALREADY NEXT TO
%EACH OTHER, PROBABLY WILL RUN IT LIKE THIS SEVERAL TIMES FOR A GRID RATHER
%THAN BUILD IT INTO HERE, JUST TO KEEP IT STREAMLINED


%store information about how it was run
ParamsUsed = struct;
ParamsUsed.fs = fs;
ParamsUsed.bipolar = bipolar;
ParamsUsed.spect_freq = spect_freq;
ParamsUsed.pad = pad;
ParamsUsed.window = window;
ParamsUsed.normBaseline = normBaseline;
ParamsUsed.nbinRad = nbinRad;
ParamsUsed.ptname = ptname;



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


PAC_ch=struct;

%% make filters once
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

%bandpass filters
if isempty(bandfilterA)
    %create the filters if not done previously
    [bandfilterA, bandfilterP, bandfilterS] = Analysis.PAC.bandfiltersAP(AmpFreq_BandWidth, fs, 'PhaseFreq_BandWidth', PhaseFreq_BandWidth,...
        'MaxPhaseFreq', MaxPhaseFreq, 'MinPhaseFreq', MinPhaseFreq, 'MaxAmpFreq', MaxAmpFreq, 'MinAmpFreq', MinAmpFreq, 'SubBandRange', BetaRange);
end

%% begin for each channel
if ~bipolar
    for rr = 1:length(ch) %channels
        
        %option if the data is raw       
        if needsfilter
            %remove dc offset
            data = data-repmat(nanmean(data,1),size(data,1),1);
            %filter 60hz harmonics noise
            data = filtfilt(bsFilt1,data);
            data = filtfilt(bsFilt2,data);
            data = filtfilt(bsFilt3,data);
        end
        %common average
        %take the average at every sample across channels and subtract from the same sample
        datasig = data - repmat(nanmean(data,3),[1,1,size(data,3)]);
    end
elseif bipolar
    for rr = 1:(length(ch)-1)
        signals1 = data(:,:,rr);
        signals2 = data(:,:,rr+1);
        signalsbip = signals2 - signals1; %bipolar
        if needsfilter
            %remove dc offset
            signalsbip = signalsbip-repmat(nanmean(signalsbip,1),size(signalsbip,1),1);
            %filter 60hz harmonics noise
            signalsbip = filtfilt(bsFilt1,signalsbip); 
            signalsbip = filtfilt(bsFilt2,signalsbip);
            signalsbip = filtfilt(bsFilt3,signalsbip);
            
        end
        datasig(:,:,rr) = signalsbip;
    end
    ch(end)=[]; %subtract the last channel number for the rest of the code if bipolar
end
            
    
    
for rr = 1:size(datasig, 3)
    
    %flip signals for use in this program
    signals = datasig(:,:,rr)';
    
    %% 1) compute psd
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
        
        [psd, F] = chronux.ct.mtspectrumc(signals(i,:), params); %run a
        %spectrum instead
        %[psd,F] = pwelch(signals(i,:),2^(nextpow2(fs)),2^(nextpow2(fs/2)),2^(nextpow2(fs)),fs);
        %put raw psd in a matrix and average psd in different freq band (alpha, theta, beta...)
        PAC_ch(rr).bandspectrum.psd_all(:,i)=psd;
        t = find(F>=1 & F<=4); % theta
        PAC_ch(rr).bandspectrum.psd_delta(i) = nanmean(log10(psd(t)));
        t = find(F>=5 & F<=7);   % delta
        PAC_ch(rr).bandspectrum.psd_theta(i) = nanmean(log10(psd(t)));
        t = find(F>=8 & F<=12); % alpha
        PAC_ch(rr).bandspectrum.psd_alpha(i) = nanmean(log10(psd(t)));
        t = find(F>=13 & F<=30); % beta
        PAC_ch(rr).bandspectrum.psd_beta(i) = nanmean(log10(psd(t)));
        t = find(F>=13 & F<=20); % low beta
        PAC_ch(rr).bandspectrum.psd_Lbeta(i) = nanmean(log10(psd(t)));
        t = find(F>=20 & F<=30); % high beta
        PAC_ch(rr).bandspectrum.psd_Hbeta(i) = nanmean(log10(psd(t)));
        t = find(F>=30 & F<=50); % gamma
        PAC_ch(rr).bandspectrum.psd_gamma(i) = nanmean(log10(psd(t)));
        t = find(F>=50 & F<=150); % high gamma
        PAC_ch(rr).bandspectrum.psd_Hgamma(i) = nanmean(log10(psd(t)));
        
        % normalize psd (using 5-100Hz as baseline, normBaseline) and average norm psd accross different freq bands
        %WHY THIS NORMALIZATION METHOD, WHY 5 TO 100HZ
        norm_idx=find(F>=normBaseline(1) & F<=normBaseline(2));
        psd_norm=psd/mean(psd(norm_idx(1):norm_idx(end)));
        PAC_ch(rr).bandspectrum.psd_norm_all(:,i)=psd_norm;
        t = find(F>=1 & F<=4);
        PAC_ch(rr).bandspectrum.psd_norm_delta(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=5 & F<=7);
        PAC_ch(rr).bandspectrum.psd_norm_theta(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=8 & F<=12);
        PAC_ch(rr).bandspectrum.psd_norm_alpha(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=13 & F<=30);
        PAC_ch(rr).bandspectrum.psd_norm_beta(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=13 & F<=20);
        PAC_ch(rr).bandspectrum.psd_norm_Lbeta(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=20 & F<=30);
        PAC_ch(rr).bandspectrum.psd_norm_Hbeta(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=30 & F<=50);
        PAC_ch(rr).bandspectrum.psd_norm_gamma(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=50 & F<=150);
        PAC_ch(rr).bandspectrum.psd_norm_Hgamma(i) = nanmean(log10(psd_norm(t)));
    end
    % save psd matrices and averaged psd
    %save([name '_psd'],'psd_theta', 'psd_delta','psd_alpha','psd_beta','psd_Lbeta','psd_Hbeta','psd_gamma','psd_all','F'...
    %    ,'psd_norm_theta', 'psd_norm_delta','psd_norm_alpha','psd_norm_beta','psd_norm_Lbeta','psd_norm_Hbeta','psd_norm_gamma','psd_norm_all');

    
    
    
    
    %% 2) beta source
    %filter low and High beta and extract amplitude
    %DO YOU HAPPEN TO KNOW IF YOU WERE RECORDING IN MV OR UV? ALSO WHAT WOULD
    %BE AN EXAMPLE OF WHAT YOU'D SEE IN THE BETA OSCILLATIONS FOR THIS?
    
    betaband = struct;
   
    
    lbl = fieldnames(bandfilterS);
    for i= 1:size(signals,1)
        LB = filtfilt(bandfilterS.(lbl{1}), signals(i,:)); % filtering
        LBlfps(i, :) = LB;
        HB = filtfilt(bandfilterS.(lbl{1}), signals(i,:)); % filtering
        HBlfps(i, :) = HB;
    end
    PAC_ch(rr).betaband.LB = LBlfps;
    PAC_ch(rr).betaband.HB = HBlfps;
    
    
    
    
    
    %% 3) compute PAC
    % define variables
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
            %FIR? WAS RUNNING INTO PROBLEMS WITH IT SO SWITCHED TO FILTFILT
            AmpFreq = filtfilt(bandfilterA.(lblA{ii}), lfp); % just filtering at each specific frequency band
            AmpFreqTransformed(ii, :) = abs(hilbert(AmpFreq)); % getting the amplitude envelope at just that frequency band
        end
        
        for jj=1:length(PhaseFreqVector)
            PhaseFreq = filtfilt(bandfilterP.(lblP{jj}), lfp); % just filtering at each specific frequency band
            PhaseFreqTransformed(jj, :) = angle(hilbert(PhaseFreq)); % this is getting the phase time series at just that frequency band
        end
        
        % calculate PAC
        
        counter1=0;
        for ii=1:length(PhaseFreqVector)
            counter1=counter1+1;
            counter2=0;
            %go through first each phase vector (the x) and then each amp
            %freq (the y) and measure the modulation index and return the
            %mean amplitude
            for jj=1:length(AmpFreqVector)
                counter2=counter2+1;
                %load each specific frequency band's phase angle (x) at each
                %time point, and get the mod index for each frequency
                %band's amplitude (y) at those time points by finding the mean amplitude of the ampfreq that occurred at each phase bin 
                [MI,MeanAmp]=Analysis.PAC.PAC_ModIndex_v2(PhaseFreqTransformed(ii, :), AmpFreqTransformed(jj, :), position);
                Comodulogram(counter1,counter2,i)=MI;
                x = 10:20:360;
                [val,pos]=max(MeanAmp); %now find the max amplitude in the bins and which bin it is (pos)
                %figure out which radian bin that one is (so the max pos is
                %say 180 degrees for this Phase/Amp combo), so
                %comodulogram_phase
                %has stored which phase is most important at each pixel of
                %phase (x axis) and amplitude (y axis)
                Comodulogram_phase(counter1,counter2,i) = x(pos); 
            end
        end
    end
    %average across trials
    ComodulogramAve = nanmean(Comodulogram, 3);
    %store the values
    PAC_ch(rr).Comodulogram = Comodulogram;
    PAC_ch(rr).ComodulogramAve = ComodulogramAve;
    PAC_ch(rr).Comodulogram_phase = Comodulogram_phase;

    %save the amp and phase freq vectors
    ParamsUsed.AmpFreqVector = AmpFreqVector;
    ParamsUsed.PhaseFreqVector = PhaseFreqVector;
    PAC_ch(rr).ParamsUsed = ParamsUsed;

% %     toc(tt)
    % save data
    %save([name '_Com_chan_filt'],'Comodulogram','Comodulogram_phase','PhaseFreqVector','PhaseFreq_BandWidth','AmpFreqVector','AmpFreq_BandWidth');
    
    
    % saveas(gcf,[name '_Com_filt'],'fig');
    
    
    % clear  psd_all psd_norm_all signals HBlfps LBlfps
end

%plot data
%figtitle=['PAC ', blc.ChannelInfo(ch(rr)).Label, ' Heatmap ', blc.SourceBasename, ' ', ecog.evtNames{ff}];
figtitle=['PAC Heatmap ', ptname];
figure('Name', figtitle, 'Position', [5 150 1200 750])
set(gca, 'FontSize', 22);

for rr = 1:length(ch)    
 %   C = PAC_ch(rr).ComodulogramAve;
     C = PAC_ch(rr).Comodulogram;
    Clim2 = max(max(max(C)));
    Clim1 = min(min(min(C)));
    %need to fix the rr part, it's not doing them along the grid layout
    %lines right now
        subplot(4,4,rr)
        
        contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,C',30,'lines','none')
        set(gca,'fontsize',14)
        ylabel('Amplitude Frequency (Hz)')
        xlabel('Phase Frequency (Hz)')
        colorbar
        caxis([Clim1 0.015])
        colormap(jet);
        title(['Ch  ' num2str(rr) ]); 
end


    
% plot spectrums
%THESE YLIMS, THROW MY DATA OFF SCREEEN, I'M ASSUMING THIS HAS TO DO WITH
%THE DIFFERENCE IN YOUR RECORDINGS VS MINE BUT WAS THERE A REASON YOU DID
%IT THAT WAY?

%things to do:
% going to want to get a mean and sd for these, then plot it with the
% trials, so likely take this out of here or make it optional, and will
% do means per trial. 
% Probably want to compare each epoch together for each channel
% also need to fix the rr thing to match the actual grid
%figtitle=['PAC ', blc.ChannelInfo(ch(rr)).Label, ' Heatmap ', blc.SourceBasename, ' ', ecog.evtNames{ff}];

figtitle=['PAC ', num2str(rr), ' Spectrum ', ptname];
figure('Name', figtitle, 'Position', [5 150 1200 750])
set(gca, 'FontSize', 22);
for rr = 1:length(ch)
    subplot(2,2,1)
    plot(F,log10(PAC_ch(rr).bandspectrum.psd_all))
    xlim([0 200])
    %ylim([-3 3])
    xlabel('Frequency');
    ylabel('dB Power');
    legend('lfp  1','lfp  2','lfp  3','lfp  4','lfp  5','lfp  6','lfp  7','lfp 8')
    subplot(2,2,2)
    plot(F,log10(PAC_ch(rr).bandspectrum.psd_norm_all))
    xlim([0 200])
    %ylim([-1.5 1.5])
    xlabel('Frequency');
    ylabel('Normalized (/mean(5 to 100 Hz) dB Power');
    subplot(2,2,3)
    plot(F,log10(PAC_ch(rr).bandspectrum.psd_all))
    xlim([0 50])
    %ylim([-3 3])
    xlabel('Frequency');
    ylabel('dB Power');
    subplot(2,2,4)
    plot(F,log10(PAC_ch(rr).bandspectrum.psd_norm_all))
    xlim([0 50])
    %ylim([-1.5 1.5])
    xlabel('Frequency');
    ylabel('Normalized (/mean(5 to 100 Hz) dB Power');
    %saveas(gcf,[name '_PSD_filt'],'fig');
end
    
%% plot beta bands to see oscillation
%things to do, need to average for each beta band and get std or ci, then
%plot together, probably want to do each epoch against each other.

%figtitle=['PAC ', blc.ChannelInfo(ch(rr)).Label, ' Heatmap ', blc.SourceBasename, ' ', ecog.evtNames{ff}];
figtitle=['PAC ', num2str(rr), ' Beta bands ', ptname];
figure('Name', figtitle, 'Position', [5 150 1200 750])
set(gca, 'FontSize', 22);
 for rr = 1:length(ch)   
    subplot(4,4,rr)
    hold on
    for i = 1:size(datasig,3)
        plot(PAC_ch(rr).betaband.LB(i,:)*100+i*10); %*10 to be able to see it and +i*10 is to offset them
    end
    title('LB 15Hz 17Hz')
    xlabel('time');
    ylabel('Voltage');
    subplot(1,2,2)
    hold on
    for i = 1:size(datasig,3)
        plot(PAC_ch(rr).betaband.HB(i,:)*100+i*10);%*10 to be able to see it and +i*10 is to offset them
    end
    title('LB 24Hz 26Hz')
    xlabel('time');
    ylabel('Voltage');
    %saveas(gcf,[name '_betasource_filt'],'fig');
    % save
    %save([name '_source'],'LBlfps','HBlfps');

end
%}





end