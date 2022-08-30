%% GENERATE RAW DATA
% taskObj = FrameworkTask('C:\Users\mbarb\Documents\Data\P010\20170830\Task\20170830-133354-133456-DelayedReach.mat');% taskObj = FrameworkTask('D:\1_Year\Neuro_SP\Task Recording\Data\P010\20170830\Task\20170830-133354-133456-DelayedReach.mat');
taskObj = FrameworkTask('\\Striatum\Data\neural\incoming\unsorted\keck\Ruiz Miguel psych task\20170830\Task\20170830-133354-133456-DelayedReach.mat');

ns = taskObj.getNeuralDataObject('allgrids', 'ns3');
ns = ns{1};
%GridMap = GridMap('C:\Users\Mike\Documents\Data\P010\20170830\AllGrids\P010_map.csv');
TaskString = string(regexp(taskObj.taskString, '\d*-(.*)', 'tokens'));

%Recorded channel #s (1-128). GridMap has channel #s relative to all active
%channels (1-76)
TotalChanArray = [1:10 17:26 33:42 49:58 65:74 81:90 97:104 113:120]; % all channels recording neural data
MicroChanArray = [1:10 17:26 33:42 49:58 65:74 81:90]; % all micro channels
MacroChanArray = [97:104 113:120]; % all macro channels


Locations = 1:8;
SuccessDist = 104;

successfuls = arrayfun(@(x) le(x.response_hypot, SuccessDist), taskObj.trialdata);
trials = 1:length([taskObj.trialdata.tr_prm]);
targets = arrayfun(@(x)x.tr_prm.targetID,taskObj.trialdata);
targetTrue = ismember(targets, Locations); %if only certain target locations are desired
LogArray = and(targetTrue, successfuls)'; %returns 1 if the target matches location specified and was deemed successful

%-------------------------------------------------------------------------------
%Trial Removal
LogArray(19) = 0; %Target Location 7 disrupts all channels
%-------------------------------------------------------------------------------

TrialNums = trials(LogArray)'; %find LogArray

TrialStarts = [taskObj.trialTimes(:,1)];
TrialStartTimes = TrialStarts(LogArray);
TrialEnds = [taskObj.trialTimes(:,2)];
TrialEndTimes = TrialEnds(LogArray);
SampleTime = ceil(mean(TrialEndTimes)); %take average and round up = duration of sample

NeuralSampleRanges = [TrialStartTimes SampleTime*ones(size(TrialEndTimes,1),1)]; %need m x 2 array with start time and duration to sample in every row

Targets = targets(LogArray)'; %to be used by specStats 'Mode' 'PValues'

% NeuralData = Samples(Time) x Channels x Trials
DtClass = 'single';

[NeuralData, RelativeTimes, FeatureDef] = proc.blackrock.broadband(...
    ns, 'PROCWIN', NeuralSampleRanges, DtClass, 'CHANNELS',...
    TotalChanArray, 'Uniformoutput', true);



%% PLOT RAW DATA ALL CHANNELS ALL TRIALS SELECTED

for ch = 1:size(NeuralData, 2)
    FString = sprintf('%s-Channel-%d All-Targets All-Trials', TaskString, ch);
    f = figure('Name', FString, 'NumberTitle', 'off', 'Units', 'normalized',...
        'OuterPosition', [0 0.025 0.5 0.97]); %just about half a screen
    for t = 1:8
        TargetLogical = Targets == t;
        TargetND = squeeze(NeuralData(:,ch,TargetLogical));
        NumTrials = size(TargetND, 2);
        TargetMean = mean(TargetND,2);
        subplot_tight(8,1,t, [0.035 0.045]);
        hold on
        for tr = 1:NumTrials
            plot(RelativeTimes,TargetND(:,tr), 'Color', [0.7 0.87 0.54],...
            'LineWidth', 0.2)
        end
        set(gca, 'YLim', [-500 500], 'xticklabels', '')
        ylabel('\muV', 'Interpreter','tex')
        TString = sprintf('Target Location %d, %d Trials', t, NumTrials);
        title(TString)
        plot([2 2],[-500 500], 'k', 'LineWidth', 0.2) %to plot horizontal line at fixation
        plot([4 4],[-500 500], 'k', 'LineWidth', 0.2) %cue
        plot([5 5],[-500 500], 'k', 'LineWidth', 0.2) %delay
        plot([6 6],[-500 500], 'k', 'LineWidth', 0.2) %action stage
        
        plot(RelativeTimes,TargetMean, 'Color', [0.2 0.63 0.17],...
        'LineWidth', 0.5)
        
        if t == 8
            xlabel('Time (s)')
            set(gca, 'xticklabelmode', 'auto')
        end
        hold off
        
    end
end

%% MAKE SPECTROGRAMS
%Initialize Chronux Parameters
MovingWin     = [0.5 0.05]; %[WindowSize StepSize]
Tapers        = [5 9]; % [TW #Tapers] TW = Duration*BandwidthDesired
Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
FPass         = [0 200]; %frequency range of the output data
TrialAve      = 0; %we want it all
Fs            = ns.Fs;
ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
gpuflag       = true;

[FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(NeuralData,1), MovingWin, DtClass);
[PowerArray, FreqBins, TimeBins] = Analysis.DelayedReach.LFP.multiSpec(NeuralData, 'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass, 'gpuflag', gpuflag);

%% SUBSELECT BY FREQUENCY BIN AND PHASE #
% 4 < IndTheta < 8 , 8 < IndAlpha < 12, 12 < IndBeta < 30, 30 < IndLGamma <
% 80, 80 < IndHGamma < 200
% ThetaLogical  = FreqBins > 4  & FreqBins < 8;
% AlphaLogical  = FreqBins > 8  & FreqBins < 12;
% BetaLogical   = FreqBins > 12 & FreqBins < 30;
% LGammaLogical = FreqBins > 30 & FreqBins < 80;
% HGammaLogical = FreqBins > 80 & FreqBins < 200;
% 
% ITILogical = TimeBins > 0   & TimeBins < 2.0;
% FixLogical = TimeBins > 2.0 & TimeBins < 4.0;
% CueLogical = TimeBins > 4.0 & TimeBins < 5.0;
% DelLogical = TimeBins > 5.0 & TimeBins < 6.0;
% ActLogical = TimeBins > 6.0;
% 
% FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
% PhaseLog = [ITILogical FixLogical CueLogical DelLogical ActLogical];
% 
% PA = zeros(size(PowerArray,3),5,5,8); % Ch x FreqBins x Phases x TargetLocation
% PowerRanges = zeros(size(PA,1),size(PA,2),2); % Ch x FreqBin x Min or Max
% 
% for ch = 1:size(PowerArray,3)
%     for fr = 1:5
%         for ph = 1:5
%             for ta = 1:8
%                 TargLog = Targets == ta;
%                 A = squeeze(PowerArray(PhaseLog(:,ph), FreqLog(fr,:), ch, TargLog)); 
%                 mA = mean(A,3);
%                 mmA = mean(mA,2);
%                 mmmA = mean(mmA);
%                 PA(ch,fr,ph,ta) = mmmA;
%                 %PA(ch,fr,ph,ta) = 10*log10(mmmA);
%             end
%         end
%         MinVal = floor(min(min(PA(ch,fr,:,:),[],4)));
%         PowerRanges(ch,fr,1) = 10*log10(MinVal);
%         %PowerRanges(ch,fr,1) = floor(min(min(PA(ch,fr,:,:),[],4))); 
%         MaxVal = ceil(max(max(PA(ch,fr,:,:),[],4)));
%         PowerRanges(ch,fr,2) = 10*log10(MaxVal);
%         %PowerRanges(ch,fr,2) = ceil(max(max(PA(ch,fr,:,:),[],4)));
%     end
% end
%% Generate Means, Confidence Intervals, and Max and Mins for spectrogram data
% about 12.8s per loop (25.5863 min for 120 loops)
% 11.2s per loop on crunch (37.39 min for 200 loops)

ThetaLogical  = FreqBins > 4  & FreqBins < 8;
AlphaLogical  = FreqBins > 8  & FreqBins < 12;
BetaLogical   = FreqBins > 12 & FreqBins < 30;
LGammaLogical = FreqBins > 30 & FreqBins < 80;
HGammaLogical = FreqBins > 80 & FreqBins < 200;
% Have a logical array = in length to the # of FREQUENCY bins output by the
% spectrogram function above, specifying which frequency bins are in the
% frequency range. Arrays are row vectors.

ITILogical = TimeBins > 0   & TimeBins < 2.0;
FixLogical = TimeBins > 2.0 & TimeBins < 4.0;
CueLogical = TimeBins > 4.0 & TimeBins < 5.0;
DelLogical = TimeBins > 5.0 & TimeBins < 6.0;
ActLogical = TimeBins > 6.0;
% Have a logical array = in length to the # of TIME bins output by the
% spectrogram function above, specifying which time bins are in the
% trial phase of interest. Arrays are column vectors.



FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
PhaseLog = [ITILogical FixLogical CueLogical DelLogical ActLogical];
% Concatenate the arrays from above. Freqs were in rows so now have 5 rows,
% and Phases were in columns so now have 5 columns. 


Chs = size(PowerArray, 3);
Fs = size(FreqLog, 1);
Phs = size(PhaseLog, 2);
Ts = 8;

% Pre-allocate
MeanArray = zeros(Chs, Phs, Fs, Ts);
CIArray = zeros(Chs, 2, Phs, Fs, Ts);

% Mean and CI loop, output explained below
parfor ph = 1:size(PhaseLog, 2)
    %Permute the array to speed up indexing
    PermedPArray = permute(PowerArray, [3 1 2 4]);
    %MA = MeanArray
    MA = zeros(76, Fs, Ts);
    CIA = zeros(76, 2, Fs, Ts);
    for fr = 1:size(FreqLog, 1)
        for ta = 1:8
            TargLog = Targets == ta;
            SubPowerArray = PermedPArray(:, PhaseLog(:,ph), FreqLog(fr,:), TargLog);
            % All channels, times for this phase, freqs in range, trials
            % for the target 
            SubPA = SubPowerArray(:,:); %'unroll'
            SubPA = SubPA'; %transpose
            % now have some big number X channels: all specgram powers for
            % the times, freqs, and trials of the current index
            [OutputMean, OutputCI] = Analysis.DelayedReach.LFP.bootMeanCI(SubPA, 1000);
            % bootstrapped a sample, took a mean, x1000. Took a mean of
            % those means = OutputMean. Sorted the 1000 means and took the
            % value at 5% and 95% of those means for CI. This is for each
            % column, in this case, channels.
            MA(:,fr,ta) = OutputMean'; % every channel has a mean for this
            % freq range and target
            CIA(:,:,fr,ta) = OutputCI'; % every channel has a low and high
            % (5%, 95%) confidence interval for freq range and target
        end
    end
    MeanArray(:,ph,:,:) = MA; % Gather each channels mean for all freq
    % ranges and targets and put into array for this phase
    CIArray(:,:,ph,:,:) = CIA; % same as above but 5,95 CI
end

% MEANARRAY = Channels X PhaseBins X FreqBins X Targets and can now plot a
% scatter of the 8 targets for a given phase and freq bin, for a specified
% channel. Ex: MeanArray(1,2,5,:) = Channel 1, Fixation presentation phase,
% High gamma frequency range, all targets average specgram power
% CIARRAY = Channels X Low/High CI X PhaseBins X FreqBins X Targets same as
% above but the second dimension has low and high confidence interval
% values. Ex: CIArray(1,:,2,5,:) Channel 1's low and high confidence
% interval of the mean for the fixation phase in high gamma frequency range
% for all targets.

% The old way:
% % PowerRanges = zeros(Chs, Fs, 2);
% % for ch = 1:Chs
% %     for fr = 1:Fs
% %         MinVal = min(min(MeanArray(ch,:,fr,:),[],4)); 
% %         PowerRanges(ch,fr,1) = floor(10*log10(MinVal));
% %         MaxVal = max(max(MeanArray(ch,:,fr,:),[],4));
% %         PowerRanges(ch,fr,2) = ceil(10*log10(MaxVal));
% %     end
% % end

%Need the min and max values for each frequency band for each channel, as 
%this is the vertical axis in our subplot for each channel below. This way
%we can compare the mean and CI values across trial phases.
PowerRanges = zeros(Chs, Fs, 2);
for ch = 1:Chs
    for fr = 1:Fs
        MinVal = min(min(CIArray(ch, 1, :, fr, :), [], 5)); 
        PowerRanges(ch,fr,1) = floor(10*log10(MinVal));
        MaxVal = max(max(CIArray(ch, 2, :, fr, :), [], 5));
        PowerRanges(ch,fr,2) = ceil(10*log10(MaxVal));
    end
end
%% Load Previously Generated Data
localPath = '\\striatum\Data\user home\Mike\Crunch_Output';
% localPath = 'D:\1_Year\Neuro_SP\Task Recording\Data\P010\20170830\Results\LFP\DelayedReach\Crunch_Output';

savedData = {'P010DelR_CIArray.mat', 'P010DelR_FreqBins.mat',...
    'P010DelR_MeanArray.mat', 'P010DelR_PowerArray.mat', ...
    'P010DelR_PowerRanges.mat', 'P010DelR_Targets.mat', ...
    'P010DelR_TimeBins.mat', 'NoLogGauss.mat', 'OGGauss.mat'};

for d = 1:length(savedData)
    fp = fullfile(localPath, savedData{d});
    load(fp)
end
fprintf('Done Loading Previous Data\n')
clear localPath savedData d fp

%% Gaussian Fits

t = (1:8)'; %to match shape of y, and prevent warnings from prepareCurveData
ft = fittype( 'gauss1' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [-500 -100 0];
 %assume data is centered on max value at 4
% specifying starting point helps ensure same output from fit()


fitresult = cell(size(MeanArray, 1), size(MeanArray, 2), size(MeanArray, 3));
gof = struct( 'sse', cell(size(MeanArray, 1), size(MeanArray, 2), size(MeanArray, 3)), ...
        'rsquare', [], 'dfe', [], 'adjrsquare', [], 'rmse', [] );
shifts = struct( 'ShiftedPower', cell(size(MeanArray, 1), size(MeanArray, 2), size(MeanArray, 3)), ...
    'ShiftedTargets', [], 'ShiftAmt', [], 'TunedTarg', []);
for ch = 1:76
    for ph = 1:5
        for fr = 1:5
            y = 10*log10(squeeze(MeanArray(ch, ph, fr, :)));
            [s, col] = max(y);
            opts.StartPoint = [s 4 2.4495];
            shiftamt = 4 - col;
            shiftedy = circshift(y, shiftamt); % get the max value at 4
            shiftedx = circshift(t, shiftamt); % shift target values same amt for later retrieval
            [xData, yData] = prepareCurveData(t, shiftedy);
            [Oidx,~,~,~] = util.outliers(y);
            excludedPoints = excludedata(xData, yData, 'Indices', Oidx);
            opts.Exclude = excludedPoints; % fitoptions(fitresult{}).Exclude
            [fitr, goodf] = fit(xData, yData, ft, opts);
            fitresult{ch, ph, fr} = fitr;
            gof(ch, ph, fr) = goodf;
            shifts(ch, ph, fr).ShiftedPower = shiftedy;
            shifts(ch, ph, fr).ShiftedTargets = shiftedx;
            shifts(ch, ph, fr).ShiftAmt = shiftamt;
            shifts(ch, ph, fr).TunedTarg = fitr.b1 - shiftamt;
        end
    end
end

%% PLOT EACH CHANNEL'S 5X5 GRID
% TString = sprintf('%s-TestSpectrum-Chan%d', TaskString, ChannelArray(Ch));
TargetLocs = 1:size(MeanArray,4);
ConTL      = [TargetLocs; TargetLocs]; %need 2x8 for plotting CI as lines
Phases = {'ITI' 'Fixation' 'Cue' 'Delay' 'Action'};
Frequencies = {'Theta 4-8' 'Alpha 8-12' 'Beta 12-30' 'Low Gamma 30-80'...
    'High Gamma 80-200'};

MarkerSize  = 20; %pixels?
MarkerColor = [0.9047, 0.1918, 0.1988;
               0.2941, 0.5447, 0.7494;
               0.3718, 0.7176, 0.3612;
               1.0000, 0.5482, 0.1000;
               0.8650, 0.8110, 0.4330;
               0.6859, 0.4035, 0.2412;
               0.9718, 0.5553, 0.7741;
               0.6400, 0.6400, 0.6400]; %RGB colors


for ch = 1%:size(MeanArray,1)
    FString = sprintf('%s-Channel-%d Target-Averaged', TaskString, ch);
    figure('Name', FString, 'NumberTitle', 'off', 'units', 'normalized',...
        'outerposition', [0 0 1 1]);
    in = 0;
    for fr = Fs:-1:1 %Index in reverse so frequencies decrease as plots descend
        for ph = 1:Phs %Index normally so phases progress sequentially
            in = in +1; %keep track of subplot
            SmallMeanArray = 10*log10(squeeze(MeanArray(ch, ph, fr, :)))'; % 1x8 powers
            SmallCIArray   = 10*log10(squeeze(CIArray(ch, :, ph, fr, :))); % 2x8 powers
            %UpBound        = SmallCIArray(2, :) - SmallMeanArray; % distance from upper CI to mean
            %LoBound        = SmallMeanArray - SmallCIArray(1, :);  % distance from lower CI to mean
            subplot(Fs, Phs, in)
            scatter(TargetLocs, SmallMeanArray, MarkerSize, MarkerColor, 'filled')
            hold on
            plot(ConTL, SmallCIArray, 'k', 'LineWidth', 0.2)
            ylim([PowerRanges(ch, fr, 1) PowerRanges(ch, fr, 2)])
            xlim([0.5 8.5])
            hold off
        end
    end
    subplot(5, 5, 1)
    title('ITI')
    ylabel('High Gamma 80 - 200', 'FontWeight', 'bold')
    subplot(5, 5, 2)
    title('Fixation')
    subplot(5, 5, 3)
    title('Cue')
    subplot(5, 5, 4)
    title('Delay')
    subplot(5, 5, 5)
    title('Action')
    subplot(5, 5, 6)
    ylabel('Low Gamma 30 - 80', 'FontWeight', 'bold')
    subplot(5, 5, 11)
    ylabel('Beta 12 - 30', 'FontWeight', 'bold')
    subplot(5, 5, 16)
    ylabel('Alpha 8 - 12', 'FontWeight', 'bold')
    subplot(5, 5, 21)
    ylabel('Theta 4 - 8', 'FontWeight', 'bold')

end
%%
% Original plotting section
% TargetLocs = 1:size(PA,4);
% Phases = {'ITI' 'Fixation' 'Action'};
% PL = size(MeanArray,2);
% Frequencies = {'Theta 4-8' 'Alpha 8-12' 'Beta 12-30' 'Low Gamma 30-80'...
%     'High Gamma 80-200'};
% FL = size(MeanArray,3);
% 
% MarkerSize  = 50; %pixels?
% MarkerColor = [0.9047, 0.1918, 0.1988;
%                0.2941, 0.5447, 0.7494;
%                0.3718, 0.7176, 0.3612;
%                1.0000, 0.5482, 0.1000;
%                0.8650, 0.8110, 0.4330;
%                0.6859, 0.4035, 0.2412;
%                0.9718, 0.5553, 0.7741;
%                0.6400, 0.6400, 0.6400]; %RGB colors
% 
% 
% for ch = 1%:size(PA,1)
%     FString = sprintf('%s-Channel-%d Target-Averaged', TaskString,ch);
%     figure('Name', FString, 'NumberTitle', 'off', 'units', 'normalized',...
%         'outerposition', [0 0 1 1]);
%     in = 0;
%     for fr = 1:FL
%         for ph = 1:size(PA,3)
%             in = in+1;
%             subplot(5,5,in)
%             scatter(TargetLocs, 10*log10(PA(ch,fr,ph,:)), MarkerSize, MarkerColor, 'filled')
%             %scatter(TargetLocs, PA(ch,fr,ph,:), MarkerSize, MarkerColor, 'filled')
%             ylim([PowerRanges(ch,fr,1) PowerRanges(ch,fr,2)])
%     %         ts = sprintf('%d',in);
%     %         title(ts)
%         end
%     end
%     subplot(FL, PL, 1)
%     title(string(Phases(1)))
%     ylabel('Theta 4 - 8', 'FontWeight', 'bold')
%     subplot(FL, PL, 2)
%     title(string(Phases(2)))
%     subplot(FL, PL, 3)
%     title(string(Phases(3)))
%     subplot(FL, PL, 4) %length(Phases) + 1
%     ylabel('Alpha 8 - 12', 'FontWeight', 'bold')
%     subplot(FL, PL, 7) %length(Phases) + length(Frequencies)
%     ylabel('Beta 12 - 30', 'FontWeight', 'bold')
%     subplot(FL, PL, 10) % length(Phases) + 2*length(Frequencies)
%     ylabel('Low Gamma 30 - 80', 'FontWeight', 'bold')
%     subplot(FL, PL, 13) % length(Phases) + 3*length(Frequencies)
%     ylabel('High Gamma 80 - 200', 'FontWeight', 'bold')
% 
% end
%% FINDING AND REMOVING BAD TRIAL
% changes made to above script based on below code to remove trial
% Targ7Log = Targets == 7;
% Targ7NeuralData = NeuralData(:,:,Targ7Log);
% Targ7Nums = find(Targets == 7);
% m = max(squeeze(Targ7NeuralData(:,1,:)),[],1) %shows which target 7 trial has
% % largest value (only 1 channel needed to find it)
% plot(RelativeTimes, Targ7NeuralData(:,1,3)) %plot it to make sure it's right
% BadTrialNum = TrialNums(Targ7TrialNums(3)); % 17/55 trials used in this case, 
% % #19 trial out of 64 total

