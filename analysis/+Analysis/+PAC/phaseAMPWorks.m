
%%

% Step 1: Generate the simulated data
fs = 500; % Sampling frequency (Hz)
t = 0:1/fs:3; % Time vector (10 seconds)
%sim_data = randn(1, numel(t)); % Generate random noise as an example
%sim_data = signal(:,1,1);
sim_data = signal;
% Step 2: Define frequency ranges
phase_freq_range = 2:1:30; % Phase frequencies (Hz)
amp_freq_range = 10:1:100; % Amplitude frequencies (Hz)

% Step 3: Calculate the modulation indices
modulation_indices = zeros(length(phase_freq_range), length(amp_freq_range));

for p = 1:length(phase_freq_range)
    % Filter phase data
    bpFilt_phase = designfilt('bandpassfir','FilterOrder',100,'CutoffFrequency1',phase_freq_range(p)-1,'CutoffFrequency2',phase_freq_range(p)+1, 'SampleRate',fs);
    phase_data = filtfilt(bpFilt_phase, sim_data);
    phase_angles = angle(hilbert(phase_data));

    for a = 1:length(amp_freq_range)
        % Filter amplitude data
        bpFilt_amp = designfilt('bandpassfir','FilterOrder',100,'CutoffFrequency1',amp_freq_range(a)-5,'CutoffFrequency2',amp_freq_range(a)+5, 'SampleRate',fs);
        amp_data = filtfilt(bpFilt_amp, sim_data);
        amp_envelope = abs(hilbert(amp_data));

        % Compute the modulation index
        n_bins = 18; % Number of phase bins
        bin_centers = linspace(-pi, pi, n_bins+1);
        bin_centers = bin_centers(1:end-1) + (bin_centers(2)-bin_centers(1))/2;

        mean_amplitude = zeros(1, n_bins);

        for i = 1:n_bins
            idx = phase_angles >= bin_centers(i) - pi/n_bins & phase_angles < bin_centers(i) + pi/n_bins;
            mean_amplitude(i) = mean(amp_envelope(idx));
        end

        modulation_indices(p, a) = (max(mean_amplitude) - min(mean_amplitude)) / sum(mean_amplitude);
    end
end

% Step 4: Plot the heatmap
figure;
imagesc(phase_freq_range, amp_freq_range, modulation_indices');
set(gca,'YDir','normal');
xlabel('Phase Frequency (Hz)');
ylabel('Amplitude Frequency (Hz)');
title('Modulation Indices Heatmap');
colorbar;
