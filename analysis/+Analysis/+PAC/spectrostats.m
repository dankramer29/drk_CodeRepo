% Load example data
load exampledata.mat

% Compute spectrograms for two conditions (e.g., control and experimental)
window = 500; % window size for spectrogram (ms)
overlap = 400; % overlap size for spectrogram (ms)
nfft = 512; % number of points for FFT
spectrogram_control = spectrogram(data_control,window,overlap,nfft,fs);
spectrogram_exp = spectrogram(data_exp,window,overlap,nfft,fs);

% Average spectrograms across trials
spectrogram_control_avg = mean(abs(spectrogram_control),3);
spectrogram_exp_avg = mean(abs(spectrogram_exp),3);

% Compute statistical significance of differences between spectrograms
alpha = 0.05; % significance level
[h,p,ci,stats] = ttest2(spectrogram_control_avg(:),spectrogram_exp_avg(:),'Alpha',alpha);

% Plot results
figure
subplot(1,3,1)
imagesc(t,f,log(abs(spectrogram_control_avg)))
axis xy
xlabel('Time (s)')
ylabel('Frequency (Hz)')
title('Control Spectrogram')
colorbar
subplot(1,3,2)
imagesc(t,f,log(abs(spectrogram_exp_avg)))
axis xy
xlabel('Time (s)')
ylabel('Frequency (Hz)')
title('Experimental Spectrogram')
colorbar
subplot(1,3,3)
imagesc(t,f,p<alpha)
axis xy
xlabel('Time (s)')
ylabel('Frequency (Hz)')
title('Significant Differences')
colormap gray


%%

% Load example data
load exampledata.mat

% Compute spectrograms for two conditions (e.g., control and experimental)
window = 500; % window size for spectrogram (ms)
overlap = 400; % overlap size for spectrogram (ms)
nfft = 512; % number of points for FFT
spectrogram_control = spectrogram(data_control,window,overlap,nfft,fs);
spectrogram_exp = spectrogram(data_exp,window,overlap,nfft,fs);

% Average spectrograms across trials
spectrogram_control_avg = mean(abs(spectrogram_control),3);
spectrogram_exp_avg = mean(abs(spectrogram_exp),3);

% Set up bootstrapping parameters
nboot = 1000; % number of bootstrap samples
alpha = 0.05; % significance level

% Compute bootstrap samples and t-statistics
tvals = zeros(nboot,numel(f),numel(t));
for n = 1:nboot
    % Generate bootstrap samples
    ind1 = randi(size(spectrogram_control,3),[1 size(spectrogram_control,3)]);
    ind2 = randi(size(spectrogram_exp,3),[1 size(spectrogram_exp,3)]);
    spectrogram_control_boot = spectrogram_control(:,:,ind1);
    spectrogram_exp_boot = spectrogram_exp(:,:,ind2);
    % Compute average spectrograms for bootstrap samples
    spectrogram_control_boot_avg = mean(abs(spectrogram_control_boot),3);
    spectrogram_exp_boot_avg = mean(abs(spectrogram_exp_boot),3);
    % Compute t-statistics for each frequency and time point
    [~,~,~,stats] = ttest2(spectrogram_control_boot_avg(:),spectrogram_exp_boot_avg(:),'Alpha',alpha);
    tvals(n,:,:) = reshape(stats.tstat,size(spectrogram_control,1),size(spectrogram_control,2));
end

% Compute p-values from bootstrapped t-statistics
tvals_mean = squeeze(mean(tvals));
tvals_std = squeeze(std(tvals));
pvals = 2*min(cat(3,1-normcdf(abs(tvals_mean./tvals_std)),normcdf(abs(tvals_mean./tvals_std))),[],3); % two-tailed test

% Plot results
figure
subplot(1,3,1)
imagesc(t,f,log(abs(spectrogram_control_avg)))
axis xy
xlabel('Time (s)')
ylabel('Frequency (Hz)')
title('Control Spectrogram')
colorbar
subplot(1,3,2)
imagesc(t,f,log(abs(spectrogram_exp_avg)))
axis xy
xlabel('Time (s)')
ylabel('Frequency (Hz)')
title('Experimental Spectrogram')
colorbar
subplot(1,3,3)
imagesc(t,f,pvals<alpha)
axis xy
xlabel('Time (s)')
ylabel('Frequency (Hz)')
title('Significant Differences')
colormap gray
