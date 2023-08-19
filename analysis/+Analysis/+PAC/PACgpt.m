function [modularity_indices] = PACgpt(dataLow,dataHigh, vararagin)
% This does not work. womp womp. could try to sort through it, but useless.
% Parameters
fs = 500;  % Sampling rate
freq_bands_pac = 1:4:30;  % Phase-amplitude coupling frequency bands
freq_bands_mod = 30:2:150;  % Modularity index frequency bands

% Generate sample signals (replace with your actual signals)
t = 0:1/fs:10;  % Time vector
signal1 = sin(2*pi*10*t) + randn(size(t));
signal2 = cos(2*pi*20*t) + randn(size(t));

% Filter signals between 1 and 200 Hz using an IIR filter
[b, a] = butter(4, [1, 200]/(fs/2), 'bandpass');
filtered_signal1 = filtfilt(b, a, signal1);
filtered_signal2 = filtfilt(b, a, signal2);

% Calculate the analytic signals (Hilbert transform)
analytic_signal1 = hilbert(filtered_signal1);
analytic_signal2 = hilbert(filtered_signal2);

% Initialize variable for modularity indices
num_pac_bands = length(freq_bands_pac);
num_mod_bands = length(freq_bands_mod);
modularity_indices = zeros(num_pac_bands, num_mod_bands);

% Calculate modularity indices for each frequency pair
for pac_band_idx = 1:num_pac_bands
    for mod_band_idx = 1:num_mod_bands
        % Extract phase and amplitude for the specified frequency bands
        pac_band = freq_bands_pac(pac_band_idx);
        mod_band = freq_bands_mod(mod_band_idx);
        
        % Calculate indices for the analytic signals
        pac_start_idx = round(pac_band * fs) + 1;
        pac_end_idx = round((pac_band + 3) * fs) + 1;
        mod_start_idx = round(mod_band * fs) + 1;
        mod_end_idx = round((mod_band + 1) * fs) + 1;
        
        % Ensure indices are within the valid range
        pac_start_idx = max(pac_start_idx, 1);
        pac_end_idx = min(pac_end_idx, length(analytic_signal1));
        mod_start_idx = max(mod_start_idx, 1);
        mod_end_idx = min(mod_end_idx, length(analytic_signal2));
        
        % Extract phase and amplitude signals
        phase = angle(analytic_signal1(pac_start_idx:pac_end_idx));
        amplitude = abs(analytic_signal2(mod_start_idx:mod_end_idx));
        
        % Calculate modularity index (replace with your preferred method)
        modularity_indices(pac_band_idx, mod_band_idx) = calculate_modularity_index(phase, amplitude);
    end
end



% Display modularity indices heatmap
figure;
imagesc(freq_bands_mod, freq_bands_pac, modularity_indices);
xlabel('Modulation Frequency (Hz)');
ylabel('Coupling Frequency (Hz)');
colorbar;

% Replace calculate_modularity_index with your actual modularity index calculation function
function index = calculate_modularity_index(phase, amplitude)
    % Your modularity index calculation here
    index = abs(mean(exp(1i*(phase - angle(amplitude)))));
    % Modify this function according to your specific calculation method
end


end