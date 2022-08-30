%% 
% testing use of Chronux's spectrogram functions to return results as
% desired and see if we can utilize parrallelization

% [S,t,f,Serr]=mtspecgramc(data,movingwin,params)

% Initialize Chronux Parameters and combine into Chr struct

MovingWin = [0.1 0.05]; %[WindowSize StepSize]

Tapers = [5 9]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad = 1; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass = [0 200]; %frequency range
TrialAve = 0; %we want it all
Chr = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve); 
Chr.Fs = ns.Fs;

%% generate spectrograms using GPU
% data (in form samples x channels/trials) -- required

Channels = size(NeuralData,2);
Trials = size(NeuralData, 3);

tic

% generate one spectrum out of the loop to get sizes of time bins and
% frequencies (although there must be a way to calculate this based on
% input parameters) to pre-allocate for the rest of the generated spectrums

[Specgram, TimeBins, Frequencies] = chronux_gpu.ct.mtspecgramc(NeuralData(:,:,1),MovingWin,Chr);

toc

% pre-allocate
Specs = zeros(size(TimeBins, 2), size(Frequencies, 2), Channels, Trials);
% include first entry generated above
Specs(:,:,:,1) = Spectgram(:,:,:);

% loop through all trials and store spectrograms
for T = 2:Trials
    Specs(:,:,:,T) = chronux_gpu.ct.mtspecgramc(NeuralData(:,:,T),MovingWin,Chr);
end
% S = TimeBins X FreqBins X Channels X Trials
toc

%%
% Variable Clean Up
clear MovingWin Tapers Pad FPass TrialAve Chr Channels Trials...
    Spectrum T