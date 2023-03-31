% Set random number generator seed for reproducibility
rng(1)

% Define simulation parameters
fs = 1000; % sampling rate (Hz)
t = 0:1/fs:10; % time vector (seconds)
lowfreq = 6; % theta band (Hz)
highfreq = 40; % gamma band (Hz)
lowamp = 1; % theta amplitude
highamp = 0.2; % gamma amplitude
pac_strength = 0.5; % strength of phase-amplitude coupling (0-1)

% Generate low-frequency theta signal
lowsignal = lowamp*sin(2*pi*lowfreq*t);

% Generate high-frequency gamma signal
highsignal = highamp*sin(2*pi*highfreq*t);

% Add phase-amplitude coupling to gamma signal
phase = angle(hilbert(highsignal));
coupling = lowamp*(1+pac_strength*sin(phase));
coupled_signal = highsignal .* coupling;

% Add noise to signals
noise_amp = 0.2;
noisy_lowsignal = lowsignal + noise_amp*randn(size(lowsignal));
noisy_highsignal = coupled_signal + noise_amp*randn(size(coupled_signal));

% Compute PAC as described in previous answer
lowpass = designfilt('lowpassiir','FilterOrder',4, ...
    'PassbandFrequency',lowfreq*2,'PassbandRipple',0.2, ...
    'SampleRate',fs);
highpass = designfilt('highpassiir','FilterOrder',4, ...
    'PassbandFrequency',highfreq/2,'PassbandRipple',0.2, ...
    'SampleRate',fs);
lowsignal_filtered = filtfilt(lowpass,noisy_lowsignal);
highsignal_filtered = filtfilt(highpass,noisy_highsignal);
hilb = hilbert(highsignal_filtered);
phase = angle(hilb);
hilb2 = hilbert(lowsignal_filtered);
amplitude = abs(hilb2);
nbins = 18;
edges = linspace(-pi,pi,nbins+1);
[~,bin] = histc(phase,edges);
bin = bin-1;
bin(bin==0) = 1;
MI = zeros(nbins,1);
for n = 1:nbins
    MI(n) = mean(amplitude(bin==n));
end

% Plot results
figure
subplot(2,2,1)
plot(t,lowsignal,'k')
xlabel('Time (s)')
ylabel('Amplitude')
title('Low-Frequency Signal (Theta)')
subplot(2,2,2)
plot(t,highsignal,'k')
hold on
plot(t,coupled_signal,'r')
xlabel('Time (s)')
ylabel('Amplitude')
title('High-Frequency Signal (Gamma) with PAC')
legend('Original Signal','Coupled Signal')
subplot(2,2,3)
plot(t,noisy_lowsignal,'k')
hold on
plot(t,lowsignal_filtered,'r')
xlabel('Time (s)')
ylabel('Amplitude')
title('Filtered Low-Frequency Signal')
legend('Noisy Signal','Filtered Signal')
subplot(2,2,4)
plot(phase,amplitude,'k.')
hold on
plot(edges(1:end-1)+mean(diff(edges))/2,MI,'r','linewidth',2)
xlabel('Phase (radians)')
ylabel('Amplitude')
title('Phase-Amplitude Coupling')
legend('Data','Modulation Index')
