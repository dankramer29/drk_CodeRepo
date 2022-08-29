%% GENERATE RAW DATA
% taskObj = FrameworkTask('C:\Users\mbarb\Documents\Data\P010\20170830\Task\20170830-133354-133456-DelayedReach.mat');
taskObj = FrameworkTask('C:\Users\Mike\Documents\Data\P010\20170830\Task\20170830-140236-140327-DirectReach.mat');
% taskObj = FrameworkTask('D:\1_Year\Neuro_SP\Task Recording\Data\P010\20170830\Task\20170830-133354-133456-DelayedReach.mat');

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

%********************************
% Change for Direct Reach Timings
%********************************

for ch = 1:size(NeuralData, 2)
    FString = sprintf('%s-Channel-%d All-Targets All-Trials', TaskString, ch);
    f = figure('Name', FString, 'NumberTitle', 'off', 'Units', 'normalized',...
        'OuterPosition', [0 0.025 0.5 0.97]); %just about half a screen
    for t = 1:8
        TargetLogical = Targets == t;
        TargetND = squeeze(NeuralData(:,ch,TargetLogical));
        NumTrials = size(TargetND, 2); % number of trials for that target
        TargetMean = mean(TargetND,2); % average values for that target
        subplot_tight(8,1,t, [0.035 0.045]);
        hold on
        for tr = 1:NumTrials
            plot(RelativeTimes,TargetND(:,tr), 'Color', [0.7 0.87 0.54],...
            'LineWidth', 0.2) %thin light green line for each trial of target
        end
        set(gca, 'YLim', [-500 500], 'xticklabels', '')
        ylabel('\muV', 'Interpreter','tex')
        TString = sprintf('Target Location %d, %d Trials', t, NumTrials);
        title(TString)
        plot([2 2],[-500 500], 'k', 'LineWidth', 0.2) %to plot horizontal line at fixation start
        plot([3 3],[-500 500], 'k', 'LineWidth', 0.2) %action stage
        
        plot(RelativeTimes,TargetMean, 'Color', [0.2 0.63 0.17],...
        'LineWidth', 0.5) %thick green line for target average
        
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
% FixLogical = TimeBins > 2.0 & TimeBins < 3.0;
% ActLogical = TimeBins > 3.0 & TimeBins < 5.0;
% 
% FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
% PhaseLog = [ITILogical FixLogical ActLogical];
% 
% PA = zeros(size(PowerArray,3), size(PhaseLog, 2), size(FreqLog, 1), 8); % Ch x FreqBins x Phases x TargetLocation
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

%%
% about 12.8s per loop (25.5863 min for 120 loops)
% 11.2s per loop on crunch (37.39 min for 200 loops)
ThetaLogical  = FreqBins > 4  & FreqBins < 8;
AlphaLogical  = FreqBins > 8  & FreqBins < 12;
BetaLogical   = FreqBins > 12 & FreqBins < 30;
LGammaLogical = FreqBins > 30 & FreqBins < 80;
HGammaLogical = FreqBins > 80 & FreqBins < 200;

ITILogical = TimeBins > 0   & TimeBins < 2.0;
FixLogical = TimeBins > 2.0 & TimeBins < 3.0;
ActLogical = TimeBins > 3.0 & TimeBins < 5.0;

FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
PhaseLog = [ITILogical FixLogical ActLogical];

Chs = size(PowerArray, 3);
Fs = size(FreqLog, 1);
Phs = size(PhaseLog, 2);
Ts = 8;

MeanArray = zeros(76, Phs, Fs, Ts);
CIArray = zeros(76, 2, Phs, Fs, Ts);

parfor ph = 1:size(PhaseLog, 2)
    PermedPArray = permute(PowerArray, [3 1 2 4]);
    MA = zeros(76, Fs, Ts);
    CIA = zeros(76, 2, Fs, Ts);
    for fr = 1:size(FreqLog, 1)
        for ta = 1:8
            TargLog = Targets == ta;
            SubPowerArray = PermedPArray(:, PhaseLog(:,ph), FreqLog(fr,:), TargLog);
%             SubPowerArray = permute(SubPowerArray, [3 1 2 4]);
            SubPA = SubPowerArray(:,:);
            SubPA = SubPA';
            [OutputMean, OutputCI] = Analysis.DelayedReach.LFP.bootMeanCI(SubPA, 1000);
            MA(:,fr,ta) = OutputMean';
            CIA(:,:,fr,ta) = OutputCI';
        end
    end
    MeanArray(:,ph,:,:) = MA;
    CIArray(:,:,ph,:,:) = CIA;
end

PowerRanges = zeros(Chs, Fs, 2);
for ch = 1:Chs
    for fr = 1:Fs
        MinVal = floor(min(min(MeanArray(ch,:,fr,:),[],4))); 
        PowerRanges(ch,fr,1) = 10*log10(MinVal);
        MaxVal = ceil(max(max(MeanArray(ch,:,fr,:),[],4)));
        PowerRanges(ch,fr,2) = 10*log10(MaxVal);
    end
end



%% PLOT EACH CHANNEL'S 5X5 GRID
% TString = sprintf('%s-TestSpectrum-Chan%d', TaskString, ChannelArray(Ch));
TargetLocs = 1:size(MeanArray,4);
Phases = {'ITI' 'Fixation' 'Action'};
PL = size(MeanArray,2);
Frequencies = {'Theta 4-8' 'Alpha 8-12' 'Beta 12-30' 'Low Gamma 30-80'...
    'High Gamma 80-200'};
FL = size(MeanArray,3);

MarkerSize  = 50; %pixels?
MarkerColor = [0.9047, 0.1918, 0.1988;
               0.2941, 0.5447, 0.7494;
               0.3718, 0.7176, 0.3612;
               1.0000, 0.5482, 0.1000;
               0.8650, 0.8110, 0.4330;
               0.6859, 0.4035, 0.2412;
               0.9718, 0.5553, 0.7741;
               0.6400, 0.6400, 0.6400]; %RGB colors


for ch = 1%:size(MeanArray,1)
    FString = sprintf('%s-Channel-%d Target-Averaged', TaskString,ch);
    figure('Name', FString, 'NumberTitle', 'off', 'units', 'normalized',...
        'outerposition', [0 0 1 1]);
    in = 0;
    for fr = 1:FL
        for ph = 1:size(PA,3)
            in = in+1;
            subplot(5,5,in)
            scatter(TargetLocs, 10*log10(PA(ch,fr,ph,:)), MarkerSize, MarkerColor, 'filled')
            %scatter(TargetLocs, PA(ch,fr,ph,:), MarkerSize, MarkerColor, 'filled')
            ylim([PowerRanges(ch,fr,1) PowerRanges(ch,fr,2)])
    %         ts = sprintf('%d',in);
    %         title(ts)
        end
    end
    subplot(FL, PL, 1)
    title(string(Phases(1)))
    ylabel('Theta 4 - 8', 'FontWeight', 'bold')
    subplot(FL, PL, 2)
    title(string(Phases(2)))
    subplot(FL, PL, 3)
    title(string(Phases(3)))
    subplot(FL, PL, 4) %length(Phases) + 1
    ylabel('Alpha 8 - 12', 'FontWeight', 'bold')
    subplot(FL, PL, 7) %length(Phases) + length(Frequencies)
    ylabel('Beta 12 - 30', 'FontWeight', 'bold')
    subplot(FL, PL, 10) % length(Phases) + 2*length(Frequencies)
    ylabel('Low Gamma 30 - 80', 'FontWeight', 'bold')
    subplot(FL, PL, 13) % length(Phases) + 3*length(Frequencies)
    ylabel('High Gamma 80 - 200', 'FontWeight', 'bold')

end

%%
