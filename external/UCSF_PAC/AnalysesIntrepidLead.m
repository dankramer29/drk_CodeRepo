


%%% intrepid lead%%%

% loop through each file
files = dir('*ecog_filt.mat');  % loads all the patients by file name into 'files'
for k=1:length(files)           % counts the number of patients in 'files' and loops
    load(files(k).name)         % loads each patient from 'files'
    
    %% 1. Reference/filter data
    % rereference data
    for i = 1:length(lfp.contact)-1     % counts the number of contacts and loops
        signals(i,:)=lfp.contact(i).signal-lfp.contact(i+1).signal; % subtracts reference from signal        i
    end
    
    % notch filter noise
    for i = 1: size(signals,1)  % loops through the signals
        noise=60;               % remove 60 Hz
        Fs=lfp.Fs(i);           % identify the sampling frequency for each contact
        for j = 1:6             % filter out 60Hz and harmonics up to 360 (6*60Hz)
            [n1_b, n1_a]=butter(3,2*[(noise*j)-2 (noise*j)+2]/Fs,'stop');
            signals(i,:)=filtfilt(n1_b, n1_a, signals(i,:));
        end
    end
    
    % select 1min of data wihtout noise
    if size(signals,2)>=60000 % 60s*freq sampling (1000Hz)
        signals=signals(:,1:60000);
    end
    
    %% compute psd
    
    for i = 1: size(signals,1)
        %compute psd for each lfp channel
        [psd,F] = pwelch(signals(i,:),2^(nextpow2(lfp.Fs(i))),2^(nextpow2(lfp.Fs(i)/2)),2^(nextpow2(lfp.Fs(i))),lfp.Fs(i));
        %put raw psd in a matrix and average psd in different freq band (alpha, theta, beta...)
        psd_all(:,i)=psd;
        t = find(F>=1 & F<=4); % theta
        psd_delta(i) = nanmean(log10(psd(t)));
        t = find(F>=5 & F<=7);   % delta
        psd_theta(i) = nanmean(log10(psd(t)));
        t = find(F>=8 & F<=12); % alpha
        psd_alpha(i) = nanmean(log10(psd(t)));
        t = find(F>=13 & F<=30); % beta
        psd_beta(i) = nanmean(log10(psd(t)));
        t = find(F>=13 & F<=20); % low beta
        psd_Lbeta(i) = nanmean(log10(psd(t)));
        t = find(F>=20 & F<=30); % high beta
        psd_Hbeta(i) = nanmean(log10(psd(t)));
        t = find(F>=50 & F<=150); % gamma
        psd_gamma(i) = nanmean(log10(psd(t)));
        
        % normalize psd (using 5-100Hz as baseline) and average norm psd accross different freq bands
        norm_idx=find(F>=5 & F<=100);
        psd_norm=psd/mean(psd(norm_idx(1):norm_idx(end)));
        psd_norm_all(:,i)=psd_norm;
        t = find(F>=1 & F<=4);
        psd_norm_delta(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=5 & F<=7);
        psd_norm_theta(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=8 & F<=12);
        psd_norm_alpha(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=13 & F<=30);
        psd_norm_beta(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=13 & F<=20);
        psd_norm_Lbeta(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=20 & F<=30);
        psd_norm_Hbeta(i) = nanmean(log10(psd_norm(t)));
        t = find(F>=30 & F<=50);
        psd_norm_gamma(i) = nanmean(log10(psd_norm(t)));
    end
    % save psd matrices and averaged psd
    save([name '_psd'],'psd_theta', 'psd_delta','psd_alpha','psd_beta','psd_Lbeta','psd_Hbeta','psd_gamma','psd_all','F'...
        ,'psd_norm_theta', 'psd_norm_delta','psd_norm_alpha','psd_norm_beta','psd_norm_Lbeta','psd_norm_Hbeta','psd_norm_gamma','psd_norm_all');
    % plot data
    figure
    subplot(2,2,1)
    plot(F,log10(psd_all))
    xlim([0 200])
    ylim([-3 3])
    legend('lfp  1','lfp  2','lfp  3','lfp  4','lfp  5','lfp  6','lfp  7')
    subplot(2,2,2)
    plot(F,log10(psd_norm_all))
    xlim([0 200])
    ylim([-1.5 1.5])
    subplot(2,2,3)
    plot(F,log10(psd_all))
    xlim([0 50])
    ylim([-3 3])
    subplot(2,2,4)
    plot(F,log10(psd_norm_all))
    xlim([0 50])
    ylim([-1.5 1.5])
    saveas(gcf,[name '_PSD_filt'],'fig');
    
    %% beta source
    %filter low and High beta and extract amplitude
    Fs=1000;
    for i= 1:size(signals,1)
        LB=eegfilt_FIR(signals(i,:),Fs,15,17); % just filtering
        LBlfps(i, :) = LB;
        HB=eegfilt_FIR(signals(i,:),Fs,24,26); % just filtering
        HBlfps(i, :) = HB;
    end
    % plot 1s of data
    figure
    subplot(1,2,1)
    hold on
    for i = 1:7
        plot(LBlfps(i,1:1000)+i*10);
    end
    title('LB 15Hz 17Hz')
    subplot(1,2,2)
    hold on
    for i = 1:7
        plot(HBlfps(i,1:1000)+i*10);
    end
    title('LB 24Hz 26Hz')
    saveas(gcf,[name '_betasource_filt'],'fig');
    % save
    save([name '_source'],'LBlfps','HBlfps');
    
    
    %% compute PAC
    % define variables
    PhaseFreqVector=[4:2:50];
    AmpFreqVector=[10:4:400];
    
    PhaseFreq_BandWidth=2;
    AmpFreq_BandWidth=4;
    
    srate=Fs;
    
    nbin = 18;
    position=zeros(1,nbin); % this variable will get the beginning (not the center) of each phase bin (in rads)
    winsize = 2*pi/nbin;
    for j=1:nbin
        position(j) = -pi+(j-1)*winsize;
    end
    
    % filter data and extract phase/amplitude
    for i =1:size(signals,1)
        lfp = signals(i,:);
        AmpFreqTransformed = zeros(length(AmpFreqVector), size(signals,2));
        PhaseFreqTransformed = zeros(length(PhaseFreqVector), size(signals,2));
        
        for ii=1:length(AmpFreqVector)
            Af1 = AmpFreqVector(ii)-AmpFreq_BandWidth/2;
            Af2=AmpFreqVector(ii)+AmpFreq_BandWidth/2;
            AmpFreq=eegfilt_FIR(lfp,srate,Af1,Af2); % just filtering
            AmpFreqTransformed(ii, :) = abs(hilbert(AmpFreq)); % getting the amplitude envelope
        end
        
        for jj=1:length(PhaseFreqVector)
            Pf1 = PhaseFreqVector(jj) - PhaseFreq_BandWidth/2;
            Pf2 = PhaseFreqVector(jj) + PhaseFreq_BandWidth/2;
            PhaseFreq=eegfilt_FIR(lfp,srate,Pf1,Pf2); % this is just filtering
            PhaseFreqTransformed(jj, :) = angle(hilbert(PhaseFreq)); % this is getting the phase time series
        end
        
        % calculate PAC
        
        counter1=0;
        for ii=1:length(PhaseFreqVector)
            counter1=counter1+1;
            counter2=0;
            for jj=1:length(AmpFreqVector)
                counter2=counter2+1;
                [MI,MeanAmp]=ModIndex_v2(PhaseFreqTransformed(ii, :), AmpFreqTransformed(jj, :), position);
                Comodulogram(counter1,counter2,i)=MI;
                x = 10:20:360;
                [val,pos]=max(MeanAmp);
                Comodulogram_phase(counter1,counter2,i) = x(pos);
            end
        end
    end
    % save data
    save([name '_Com_chan_filt'],'Comodulogram','Comodulogram_phase','PhaseFreqVector','PhaseFreq_BandWidth','AmpFreqVector','AmpFreq_BandWidth');
    
    
    %plot data
    figure
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
    saveas(gcf,[name '_Com_filt'],'fig');
    
    
    clear  psd_all psd_norm_all signals HBlfps LBlfps
    
end



