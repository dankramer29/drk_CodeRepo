%%
chans = [1:10];
trials = 1;
ND = NeuralData(:,chans,trials);
K = @(nw)(2*nw)-1;
%%
MovingWin     = [0.5 0.05]; %[WindowSize StepSize]
nw            = 5;
Tapers        = [nw K(nw)]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass         = [0 200]; %frequency range of the output data
TrialAve      = 0; %Average later
Fs            = nsT2.Fs;
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
gpuflag       = true;

% [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(NeuralData,1), MovingWin, DtClass);
[PA1, FB1, TB1] = Analysis.DelayedReach.LFP.multiSpec(ND,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
    'gpuflag', gpuflag);

ftitle = sprintf('PA1 - mw %.3f %.3f - tap %d %d', MovingWin(1), MovingWin(2),...
    Tapers(1), Tapers(2));
figure('Name', ftitle, 'units', 'normalized', 'outerposition', [0 0.1 1 0.65])
imagesc(TB1, FB1, 10*log10(PA1(:,:,chans(1))')); axis xy;
ts = sprintf('Ch %d Tr %d', chans(1), trials(1));
title(ts)
colorbar

%%
MovingWin     = [0.5 0.05]; %[WindowSize StepSize]
nw            = 3;
Tapers        = [nw K(nw)]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass         = [0 200]; %frequency range of the output data
TrialAve      = 0; %Average later
Fs            = nsT2.Fs;
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
gpuflag       = true;

% [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(NeuralData,1), MovingWin, DtClass);
[PA2, FB2, TB2] = Analysis.DelayedReach.LFP.multiSpec(ND,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
    'gpuflag', gpuflag);

ftitle = sprintf('PA2 - mw %.3f %.3f - tap %d %d', MovingWin(1), MovingWin(2),...
    Tapers(1), Tapers(2));
figure('Name', ftitle, 'units', 'normalized', 'outerposition', [0 0.1 1 0.65])
imagesc(TB2, FB2, 10*log10(PA2(:,:,chans(1))')); axis xy;
ts = sprintf('Ch %d Tr %d', chans(1), trials(1));
title(ts)
colorbar

fprintf("nw: %d k: % d TBins: %d FBins: %d\n", Tapers(1), Tapers(2), length(TB2), length(FB2))

%%
MovingWin     = [0.5 0.05]; %[WindowSize StepSize]
nw            = 15;
Tapers        = [nw K(nw)]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass         = [0 200]; %frequency range of the output data
TrialAve      = 0; %Average later
Fs            = nsT2.Fs;
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
gpuflag       = true;

% [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(NeuralData,1), MovingWin, DtClass);
[PA2, FB2, TB2] = Analysis.DelayedReach.LFP.multiSpec(ND,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
    'gpuflag', gpuflag);

ftitle = sprintf('PA2 - mw %.3f %.3f - tap %d %d', MovingWin(1), MovingWin(2),...
    Tapers(1), Tapers(2));
figure('Name', ftitle, 'units', 'normalized', 'outerposition', [0 0.1 1 0.65])
imagesc(TB2, FB2, 10*log10(PA2(:,:,chans(1))')); axis xy;
ts = sprintf('Ch %d Tr %d', chans(1), trials(1));
title(ts)
colorbar

fprintf("nw: %d k: %d TBins: %d FBins: %d\n", Tapers(1), Tapers(2), length(TB2), length(FB2))

%%
MovingWin     = [0.5 0.05]; %[WindowSize StepSize]
nw            = 2;
Tapers        = [nw K(nw)]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass         = [0 200]; %frequency range of the output data
TrialAve      = 0; %Average later
Fs            = nsT2.Fs;
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
gpuflag       = true;

% [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(NeuralData,1), MovingWin, DtClass);
[PA2, FB2, TB2] = Analysis.DelayedReach.LFP.multiSpec(ND,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
    'gpuflag', gpuflag);

ftitle = sprintf('PA2 - mw %.3f %.3f - tap %d %d', MovingWin(1), MovingWin(2),...
    Tapers(1), Tapers(2));
figure('Name', ftitle, 'units', 'normalized', 'outerposition', [0 0.1 1 0.65])
imagesc(TB2, FB2, 10*log10(PA2(:,:,chans(1))')); axis xy;
ts = sprintf('Ch %d Tr %d', chans(1), trials(1));
title(ts)
colorbar

fprintf("nw: %d k: %d TBins: %d FBins: %d\n", Tapers(1), Tapers(2), length(TB2), length(FB2))

%%
MovingWin     = [0.3 0.05]; %[WindowSize StepSize]
nw            = 3;
Tapers        = [nw K(nw)]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass         = [0 200]; %frequency range of the output data
TrialAve      = 0; %Average later
Fs            = nsT2.Fs;
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
gpuflag       = true;

% [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(NeuralData,1), MovingWin, DtClass);
[PA4, FB4, TB4] = Analysis.DelayedReach.LFP.multiSpec(ND,...
    'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass,...
    'gpuflag', gpuflag);

ftitle = sprintf('PA2 - mw %.3f %.3f - tap %d %d', MovingWin(1), MovingWin(2),...
    Tapers(1), Tapers(2));
figure('Name', ftitle, 'units', 'normalized', 'outerposition', [0 0.1 1 0.65])
imagesc(TB4, FB4, 10*log10(PA4(:,:,chans(1))')); axis xy;
ts = sprintf('Ch %d Tr %d', chans(1), trials(1));
title(ts)
colorbar

fprintf("***\nnw : %d k  : %d TBins: %d FBins: %d\n", Tapers(1), Tapers(2), length(TB4), length(FB4))
fprintf("MW1: %.3f MW2: %.3f \n***", MovingWin(1), MovingWin(2))
