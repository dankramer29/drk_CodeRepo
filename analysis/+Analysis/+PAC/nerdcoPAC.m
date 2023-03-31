function [outputArg1,outputArg2] = nerdcoPAC(dataLow,dataHigh,varargin)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

[varargin, fs] = util.argkeyval('fs',varargin, 2000); %sampling rate, default is 500
[varargin, epochLength] = util.argkeyval('epochLength',varargin, 1:size(dataLow,2)); %length of the input signal
[varargin, bandFilter] = util.argkeyval('bandFilter',varargin, []); %input the frequency bands if you have made them before
%%
[varargin, AmpFreq_BandWidth] = util.argkeyval('AmpFreq_BandWidth',varargin, 2);  % amplitude frequency band width
[varargin, MaxAmpFreq] = util.argkeyval('MaxAmpFreq',varargin, 100);  % maximum Amplitude frequency for your bands, amplitude being the higher frequency bands
[varargin, MinAmpFreq] = util.argkeyval('MinAmpFreq',varargin, 10);  % minimium Amplitude frequency for your bands
%%
[varargin, PhaseFreq] = util.argkeyval('PhaseFreq',varargin, true);  % run separate phase filtering for the phases, if the filters are used for both phase and amp, don't need it.
[varargin, PhaseFreq_BandWidth] = util.argkeyval('PhaseFreq_BandWidth',varargin, 10);  % phase frequency band width
[varargin, MaxPhaseFreq] = util.argkeyval('MaxPhaseFreq',varargin, 30);  % maximum phase frequency to run PAC to
[varargin, MinPhaseFreq] = util.argkeyval('MinPhaseFreq',varargin, 10);  % maximum phase frequency to run PAC to



t = 0:1/fs:epochLength; % Time vector (10 seconds)
% Step 2: Define frequency ranges
phase_freq_range = MinPhaseFreq:1:MaxPhaseFreq; % Phase frequencies (Hz)
amp_freq_range = MinAmpFreq:1:MaxAmpFreq; % Amplitude frequencies (Hz)

% Step 3: Calculate the modulation indices
modulation_indices = zeros(length(phase_freq_range), length(amp_freq_range));

if isempty(bandFilter)
    [bandFilter.bandfilterAmp, bandFilter.bandfilterPhase] = Analysis.PAC.bandfiltersAP(fs);
end
filterNameAmp = fieldnames(bandFilter.bandfilterAmp);
filterNamePhase = fieldnames(bandFilter.bandfilterPhase);

for p = 1:length(filterNamePhase)
    % Filter phase data   
    phase_data = filtfilt(bandFilter.bandfilterPhase.(filterNamePhase{p}), dataLow);
    phase_angles = angle(hilbert(phase_data));

    for a = 1:length(filterNameAmp)
        % Filter amplitude data       
        amp_data = filtfilt(bandFilter.bandfilterAmp.(filterNameAmp{a}), dataHigh);
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

end