%% P015 Left vs Right Analysis
% 
%%
% Controls for re-running this script
loadData     = false;
generateData = true;
plotData     = false;
fullScript   = false;

%% Import Contents and Task Info
% initial data import method: 
%

if generateData || fullScript
   %env.set('Data', '\\striatum\Data\neural\incoming\unsorted\keck'); %consider setting the default for this PC to this location
   taskObj = FrameworkTask('C:\Users\Mike\Documents\Data\P015\20180130\Task\20180130-142930-143333-DelayedReach.mat');
   ns = taskObj.getNeuralDataObject('NSP1', 'ns3');
   ns = ns{1};

   TaskString = string(regexp(taskObj.taskString, '\d*-(.*)', 'tokens'));


   gridMapObj = GridMap('\\striatum\Data\neural\incoming\unsorted\keck\angulo\P015\gridmap.map');
   % gridMapObj.GridInfo: Location names and hemispheres, channel list out of
   % total channels (x/90). gridMapObj.GridChannelIndex: each column has column
   % vector of channel #s out of recorded channels (x/60).

   TotalChanArray = cell2mat(gridMapObj.GridInfo.Channels)';
   % TotalChanArray = [1:10 17:26 33:42 49:58 65:74 81:90]; % all channels recording neural data

   Targets = arrayfun(@(x)x.tr_prm.targetID,taskObj.trialdata)';
   DtClass = 'single';
   
   %Just return relative times not neural data
   [~, RelTCheck, ~] = proc.blackrock.broadband(...
       ns, DtClass, 'CHANNELS', TotalChanArray, 'Uniformoutput', true);
end
%%
if loadData
   localPath = '\\striatum\Data\user home\Mike\P015\DelayedReach';

   savedData = {'02062018-P015-GridMap.mat', '02062018-P015-NeuralData.mat',...
       '02062018-P015-SpecsOutput.mat', '02062018-P015-Targs.mat', ...
       '02072018-P015-Averages.mat', '02072018-P015-ZScores.mat', ...
       '02132018-P015-ns.mat', '02132018-P015-taskObj.mat'};
   
   for d = 1:length(savedData)
       fp = fullfile(localPath, savedData{d});
       load(fp)
   end
   gridMapObj = GridMap('\\striatum\Data\neural\incoming\unsorted\keck\angulo\P015\gridmap.map');
   GInfo = gridMapObj.GridInfo;
   ChanIdx = cell2mat(gridMapObj.GridChannelIndex);
   fprintf('Done Loading Previous Data\n')
   clear localPath savedData d fp
end
if generateData || fullScript   

   DtClass = 'single';
   TotalChanArray = [1:10 17:26 33:42 49:58 65:74 81:90];
end
%% Inspect Trial Data
% This task went for 64 trials, but need to know how long the recording
% lasted because the recording stopped prematurely. 
if fullScript
    RecordingLength = max(RelTCheck)
    [trialIdx, ~] = find(taskObj.trialTimes(:,1) < 180.00);
    LastTrial = max(trialIdx);

    taskObj.trialTimes(14,:) %171.6473 10.2200

end
%%
% so we won't be able to use the whole 14th trial.
% *2 Options*:
% * Slice all trials to 8s and use 14th trial (makes #L == #R)
% * Don't use trial 14, but use 10s for each trial

%% Using 14 Trials 8s in Length
% Pt was very quick to reach and touch target location. Action phase starts
% 6 seconds after trial starts, but lasts 4 seconds, which is much longer
% than the pt needed. 8 second trial lengths should keep patient movement
% data.
if generateData || fullScript
    StartTimes    = taskObj.trialTimes(1:14, 1);
    TrialDuration = 8;
    ProcessWindow = [StartTimes TrialDuration*ones(14,1)];
    TargetShort = Targets(1:14);

    % Now get neural data and relative times
    [NeuralData, RelativeTimes, FeatureDef] = proc.blackrock.broadband(...
        ns, 'PROCWIN', ProcessWindow, DtClass, 'CHANNELS', TotalChanArray,...
        'Uniformoutput', true);
end
%%
% Plot all channels' trial data with averages in bold. These have already
% been made and saved.
%
%   Analysis.DelayedReach.LFP.plotNeuralDataTrials(NeuralData, TargetShort, RelativeTimes, TaskString)
%   Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)

%% Make Spectrograms
%Initialize Chronux Parameters
if generateData || fullScript
    MovingWin     = [0.5 0.05]; %[WindowSize StepSize]
    Tapers        = [5 9]; % [TW #Tapers] TW = Duration*BandwidthDesired
    Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
    FPass         = [0 200]; %frequency range of the output data
    TrialAve      = 0; %Average later
    Fs            = ns.Fs;
    ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
    gpuflag       = true;

    % [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(NeuralData,1), MovingWin, DtClass);
    [PowerArray, FreqBins, TimeBins] = Analysis.DelayedReach.LFP.multiSpec(NeuralData, 'spectrogram', 'Parameters', ChrParams, 'DtClass', DtClass, 'gpuflag', gpuflag);
end
%%  Sub-Select Spectrogram Data and Establish Phase Timing
if generateData || fullScript
    % Update: show entire trial time, still making a logical index.
    TimeIDX = TimeBins == TimeBins; %> 3.999; % Action phase starts at 6s, Delay at 5s and Cue at 4 s
    SubTimeBins = TimeBins(TimeIDX);
    SubFreqBins = FreqBins; % Not sub-selecting frequencies yet
    SubSpecs = PowerArray(TimeIDX, :, :, :);

    % Need time stamps of the phases to overlay in spectrograms later
    % Phase lines don't need to line up with spect time bins, or any time
    % bins for that matter. They just need to show when the phases changed,
    % and the bins can be interpreted from there.
%     FixStartT = SubTimeBins(SubTimeBins == (SubTimeBins(1) + 2)); %2 sec after trial start
%     CueStartT = SubTimeBins(SubTimeBins == (SubTimeBins(1) + 4)); %4 sec " "
%     DelStartT = SubTimeBins(SubTimeBins == (SubTimeBins(1) + 5)); %5 sec " " 
%     ActStartT = SubTimeBins(SubTimeBins == (SubTimeBins(1) + 6)); %6 sec " "
%     
    % plot function takes row of X coords and will plot vertical lines at each
    ItiStartT = double(TimeBins(1)); %bc text() is a very specific fucntion
    FixStartT = 2;
    CueStartT = 4;
    DelStartT = 5;
    ActStartT = 6;
    PhaseCoords = [ItiStartT FixStartT CueStartT DelStartT ActStartT]; %updated to show all phases
    PhaseNames  = {'ITI', 'Fixation', 'Cue', 'Delay', 'Action'}; % for labelling plots later
end
if fullScript
    whos SubSpecs
end
%% Make Left and Right Target Indices

if generateData || fullScript
    %  Left Targets = 8, 7, 6
    LTTrialsIdx = TargetShort == 6 | TargetShort == 7 | TargetShort == 8;
    fprintf('# L Target Trials: %d\n', sum(LTTrialsIdx))

    %  Right Targets = 2, 3, 4
    RTTrialsIdx = TargetShort == 2 | TargetShort == 3 | TargetShort == 4;
    fprintf('# R Target Trials: %d\n', sum(RTTrialsIdx))
end
%% Index and Average

if generateData || fullScript
    % *Take trials for L targets and average*
    LTSpecs = SubSpecs(:, :, :, LTTrialsIdx);
    LTAvgSpecs = mean(LTSpecs, 4);

    % *Take trials for R targets and average*
    RTSpecs = SubSpecs(:, :, :, RTTrialsIdx);
    RTAvgSpecs = mean(RTSpecs, 4);
end
%% Make ITI Mean and Standard Deviation
% *Make indices*
if generateData || fullScript
    TrialsIdx = LTTrialsIdx | RTTrialsIdx;
    fprintf('# L + R Target Trials: %d\n', sum(TrialsIdx))

    ITIidx = TimeBins < 2.001; % ITI from 0 - 2s of each trial
    ITISpecs = PowerArray(ITIidx, :, :, TrialsIdx);
    ITITimes = TimeBins(ITIidx);
end
if fullScript
    whos ITISpecs
end
%%
% Average across time, then get standard deviation and the average across
% all the trials we're using for L and R targets
if generateData || fullScript
    ITITimeAvg = mean(ITISpecs, 1); % Time average
    ITITrialAvg = mean(ITITimeAvg,4);
    ITIStd = std(ITITimeAvg, [], 4);
end
%%
% We now have a row vector for each channel, containing each frequency
% bin's average value for all 10 trials' ITI phase. We'll expand this row
% so that each value is repeated for each time bin. By making this array
% equal in size to our left and right trial averages, we can vectorize our
% z-score equation later.
if generateData || fullScript
    time = size(SubTimeBins, 1); % To match time length of averages -> vectorized z-score later
    ITIMeans = repmat(ITITrialAvg, [time, 1, 1]);
    % take a 1 x 410 x 60 matrix and expand it to fill time x 1 x 1
    % gives a time x 410 x 60 matrix of 
    ITIStDevs = repmat(ITIStd, [time, 1, 1]); 
end

%%
% Plot channel 1's averaged spectogram for all frequencies in the ITI phase
% as an example:
if plotData || fullScript
    Ch1ITIAvg = ITIMeans(:, :, 1);
    figure
    imagesc(ITITimes, FreqBins, 10*log10(Ch1ITIAvg)'); axis xy;
end
%% Differences of Z-Scored Left and Right Trials
% 2 Different methods for calculating z-scores have very different
% computation time
%
%   count1 = 0;
%   totime1 = 0;
%   for i = 1:1000
%       tic
%       LeftZScores = (LTAvgSpecs - ITIMeans) ./ ITIStDevs;
%       t = toc;
%       totime1 = totime1 + t;
%       count1 = count1 + 1;
%   end
%   avg1 = totime1/count1
%   avg1 = 8.3833e-04
%   
%   count2 = 0;
%   totime2 = 0;
%   for i = 1:1000
%       tic
%       LeftZScores2 = arrayfun(@(a,b,c) (a-b)/c, LTAvgSpecs, ITIMeans, ITIStDevs);
%       t = toc;
%       totime2 = totime2 + t;
%       count2 = count2 + 1;
%   end
%   avg2 = totime2/count2
%   avg2 = 1.7959
if generateData || fullScript
    LeftZScores = (LTAvgSpecs - ITIMeans) ./ ITIStDevs;
    RightZScores = (RTAvgSpecs - ITIMeans) ./ ITIStDevs;
    LvRZScores = LeftZScores - RightZScores;
end
%% Get Channels from GridMap
%
if generateData || fullScript
    GInfo = gridMapObj.GridInfo;
    ChanIdx = cell2mat(gridMapObj.GridChannelIndex);
end
if fullScript
    GInfo
    ChanIdx
end
%%
% *Red dashed lines at start of Fixation, Cue, Delay, and Action phase (left to
% right)*

%% Left Head Hippocampus
% *1st Location* averages and z-score differences normalized
if plotData || fullScript
loc = 1;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', 'Row',...
    'PlotColorBar', false, 'VertLineCoords', PhaseCoords)
end
%% Left Tail Hippocampus
% *2nd Location* averages and z-score differences
if plotData || fullScript
loc = 2;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', 'Row',...
    'PlotColorBar', false, 'VertLineCoords', PhaseCoords)
end
%% Right Head Hippocampus
% *3rd Location* averages and z-score differences
if plotData || fullScript
loc = 3;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', 'Row',...
    'PlotColorBar', false, 'VertLineCoords', PhaseCoords)
end
%% Right Tail Hippocampus
% *4th Location* averages and z-score differences
if plotData || fullScript
loc = 4;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', 'Row',...
    'PlotColorBar', false, 'VertLineCoords', PhaseCoords)
end
%% Left Amygdala
% *5th Location* averages and z-score differences
if plotData || fullScript
loc = 5;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', 'Row',...
    'PlotColorBar', false, 'VertLineCoords', PhaseCoords)
end
%% Right Amygdala
% *6th Location* averages and z-score differences
if plotData || fullScript
loc = 6;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', 'Row',...
    'PlotColorBar', false, 'VertLineCoords', PhaseCoords)
end
%% Example plot arguments Spectrograms and Z-Scores
% No normalization, plotting color bar
%   loc = 2;
%   Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
%       string(GInfo.Location(loc)));
%   Channels = ChanIdx(:,loc)';
%   
%   Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
%       LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
%       'PlotColorBar', true, 'VertLineCoords', PhaseCoords)

%% Example plot arguments All Z-Scores
%  With colorbars plotted, channel based color range fixing
%   loc = 2;
%   Location = sprintf("%s-%s-ZScores", string(GInfo.Hemisphere(loc)),...
%       string(GInfo.Location(loc)));
%   Channels = ChanIdx(:,loc)';
%   
%   Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LeftZScores, RightZScores,...
%       LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', 'Channel',...
%       'PlotColorBar', true, 'AllZs', true, 'VertLineCoords', PhaseCoords)
%% Quantify Spectrogram Differences with Percent Difference
% specPercentDiff code:
%     function [PercDifferences, TimeStamps] = specPercentDiff(RightSpectrograms, LeftSpectrograms, TimeBins, FreqBins, timebinwindow)
% 
%         ThetaLogical  = FreqBins > 4  & FreqBins < 8;
%         AlphaLogical  = FreqBins > 8  & FreqBins < 12;
%         BetaLogical   = FreqBins > 12 & FreqBins < 30;
%         LGammaLogical = FreqBins > 30 & FreqBins < 80;
%         HGammaLogical = FreqBins > 80 & FreqBins < 200;
%         FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
%     %     Frequencies = {'Theta 4-8' 'Alpha 8-12' 'Beta 12-30' 'Low Gamma 30-80'...
%     %         'High Gamma 80-200'};
% 
%         NumTS = (length(TimeBins) - rem(length(TimeBins),timebinwindow))/ timebinwindow;
%         timewindow = TimeBins(timebinwindow) - TimeBins(1); %to get precise time window
% 
%         PercDifferences = zeros(5,NumTS,60);
%         RTracker = zeros(5,NumTS,60);
%         LTracker = zeros(5, NumTS, 60);
% 
%         for ch = 1:60
%             for fr = 1:size(FreqLog,1)
%                 TimeStamps = zeros(NumTS, 1);
%                 startIdx = 1;
%                 endIdx = timebinwindow;
%                 for tw = 1:NumTS
%                     startTime = TimeBins(startIdx);
%                     endTime = TimeBins(endIdx);
%                     TimeStamps(tw) = mean([startTime endTime]);
%                     LWin = 10*log10(LeftSpectrograms(startIdx:endIdx, FreqLog(fr,:), ch));
%                     LWinAvg = mean(mean(LWin));
%                     LTracker(fr,tw,ch) = LWinAvg;
%                     RWin = 10*log10(RightSpectrograms(startIdx:endIdx, FreqLog(fr,:), ch));
%                     RWinAvg = mean(mean(RWin));
%                     RTracker(fr,tw,ch) = RWinAvg;
%                     PDiff = (RWinAvg-LWinAvg)./abs(RWinAvg + LWinAvg);
%                     PercDifferences(fr,tw,ch) = PDiff;
%                     startIdx = endIdx + 1;
%                     endIdx = endIdx + timebinwindow;
%                 end %endwhileTime
%                 %fprintf('Ch %d, %s, val1 = %d\n', ch, string(Frequencies{fr}), PercDiff(1))
%             end %endforFBins
%         end %endforChannels
%     end

%% Test different timebin windows for averaging
% use a plot of the same channels for reference
% Timebins are 50ms each for these spectrograms. 
% BaseTitle = "RvL - %Diff"; % trying to keep the plotting function general
% % so user inputs must be more specific. Need to use this base title with
% % slight changes for next bunch of figures.
% 
% Window = [1 1]; %compare right trials to left trials for every time bin
% % not really averaging
% [PercDifferences1, TimeStamps1] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
%     LTAvgSpecs, SubTimeBins, FreqBins, 'Window', Window);
% 
% Channels = [2 3 4 7];
% loc = 1;
% Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
%     string(GInfo.Location(loc)));
% TitleMod = sprintf('%s - Win=[%d %d]', BaseTitle, Window(1), Window(2));
% 
% Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDifferences1, TimeStamps1,...
%     'VertLineCoords', PhaseCoords, 'TitleMod', TitleMod)
% 
% %%
% % 
% Window = [2 2]; %100ms of time
% [PercDifferences2, TimeStamps2] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
%     LTAvgSpecs, SubTimeBins, FreqBins, 'Window', Window);
% 
% Channels = [2 3 4 7];
% loc = 1;
% Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
%     string(GInfo.Location(loc)));
% TitleMod = sprintf('%s - Win=[%d %d]', BaseTitle, Window(1), Window(2));
% 
% Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDifferences2, TimeStamps2,...
%     'VertLineCoords', PhaseCoords, 'TitleMod', TitleMod)
% 
% %%
% % 
% Window = [5 5];%250ms of time
% [PercDifferences5, TimeStamps5] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
%     LTAvgSpecs, SubTimeBins, FreqBins, 'Window', Window);
% 
% Channels = [2 3 4 7];
% loc = 1;
% Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
%     string(GInfo.Location(loc)));
% TitleMod = sprintf('%s - Win=[%d %d]', BaseTitle, Window(1), Window(2));
% 
% Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDifferences5, TimeStamps5,...
%     'VertLineCoords', PhaseCoords, 'TitleMod', TitleMod)
% %%
% % 
% Window = [10 10];
% [PercDifferences10, TimeStamps10] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
%     LTAvgSpecs, SubTimeBins, FreqBins, 'Window', Window);
% 
% Channels = [2 3 4 7];
% loc = 1;
% Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
%     string(GInfo.Location(loc)));
% TitleMod = sprintf('%s - Win=[%d %d]', BaseTitle, Window(1), Window(2));
% 
% Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDifferences10, TimeStamps10,...
%     'VertLineCoords', PhaseCoords, 'TitleMod', TitleMod)

%%
% peaks get lower and more broad (looking at low gamma (purple)), so I
% think the integral would stay the same, or similar. But the number of
% peaks decreases. Looking at channel 2's low gamma between 6s and 7s, from
% tbWin 1 - 10 I count 4 , 3ish(4?), 2, and 1 peak respectively.
% Subjectively, the figures of tbWin=2 look the smoothest.
% Also, we are currently losing timebins at the end of the data depending
% on the timebinwindow size.

%% Test Different Time-Bin Window Overlaps
% Figuring out the number of TimeStamps given the window size and step size
% was kind of fun. 
% Window = [2 1]; %100ms of time
% [PercDifferences2_1, TimeStamps2_1] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
%     LTAvgSpecs, SubTimeBins, FreqBins, 'Window', Window);
% 
% Channels = [2 3 4 7];
% loc = 1;
% Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
%     string(GInfo.Location(loc)));
% TitleMod = sprintf('%s - Win=[%d %d]', BaseTitle, Window(1), Window(2));
% 
% Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDifferences2, TimeStamps2_1,...
%     'VertLineCoords', PhaseCoords, 'TitleMod', TitleMod)
% %%
% % [2 1] is a nice intermediate between [1 1] and [2 2], so it seems to be
% % working as expected. 
% % Now to test gradations of window = 5
% 
% Window = [5 2];%250ms of time
% [PercDifferences5, TimeStamps5] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
%     LTAvgSpecs, SubTimeBins, FreqBins, 'Window', Window);
% 
% Channels = [2 3 4 7];
% loc = 1;
% Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
%     string(GInfo.Location(loc)));
% TitleMod = sprintf('%s - Win=[%d %d]', BaseTitle, Window(1), Window(2));
% 
% Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDifferences5, TimeStamps5,...
%     'VertLineCoords', PhaseCoords, 'TitleMod', TitleMod)
% %%
% 
% Window = [5 3];%250ms of time
% [PercDifferences5, TimeStamps5] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
%     LTAvgSpecs, SubTimeBins, FreqBins, 'Window', Window);
% 
% Channels = [2 3 4 7];
% loc = 1;
% Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
%     string(GInfo.Location(loc)));
% TitleMod = sprintf('%s - Win=[%d %d]', BaseTitle, Window(1), Window(2));
% 
% Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDifferences5, TimeStamps5,...
%     'VertLineCoords', PhaseCoords, 'TitleMod', TitleMod)
% %%
% 
% Window = [5 4];%250ms of time
% [PercDifferences5, TimeStamps5] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
%     LTAvgSpecs, SubTimeBins, FreqBins, 'Window', Window);
% 
% Channels = [2 3 4 7];
% loc = 1;
% Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
%     string(GInfo.Location(loc)));
% TitleMod = sprintf('%s - Win=[%d %d]', BaseTitle, Window(1), Window(2));
% 
% Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDifferences5, TimeStamps5,...
%     'VertLineCoords', PhaseCoords, 'TitleMod', TitleMod)
% 
% %%
% 
% Window = [5 1];%250ms of time
% [PercDifferences5, TimeStamps5] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
%     LTAvgSpecs, SubTimeBins, FreqBins, 'Window', Window);
% 
% Channels = [2 3 4 7];
% loc = 1;
% Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
%     string(GInfo.Location(loc)));
% TitleMod = sprintf('%s - Win=[%d %d]', BaseTitle, Window(1), Window(2));
% 
% Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDifferences5, TimeStamps5,...
%     'VertLineCoords', PhaseCoords, 'TitleMod', TitleMod, 'FixYRange', true)
% 
% %%
% % 
% loc = 1;
% Window = [10 1];
% [PercDifferences, TimeStamps] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
%     LTAvgSpecs, SubTimeBins, FreqBins, 'Window', Window);
% Channels = ChanIdx(:,loc)';
% Channels(6) = []; %channel 6 has huge R spike at start of Delay, 
% PhaseCoords(1) = TimeStamps(1);
% 
% 
% Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
%     string(GInfo.Location(loc)));
% TitleMod = sprintf('%s - Win=[%d %d]', BaseTitle, Window(1), Window(2));
% 
% Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDifferences, TimeStamps,...
%     'VertLineCoords', PhaseCoords, 'VertLineLabels', PhaseNames,...
%     'TitleMod', TitleMod, 'FixYRange', true)

%% Plot R vs L of Frequency Band Averages
% Removing Channel 30 (reference -> 0 avg spectrogram -> -Inf 10*log10() ->
% plotting error)

numLocs = length([GInfo.Location]);

Window = [2 1]; %100ms of time
[PercDiff, TimeStamps] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
    LTAvgSpecs, TimeBins, FreqBins, 'Window', Window);

for l = 1:numLocs
    loc = l;
    Location = sprintf("RvL-%s-%s-PDiff", string(GInfo.Hemisphere(loc)),...
        string(GInfo.Location(loc)));
    Channels = ChanIdx(:,loc)';
    TitleMod = sprintf('DelayedReach - Win=[%d %d]', Window(1), Window(2));
    
    if loc == 3
        Channels(end) = [];
    end

    Analysis.DelayedReach.LFP.plotPercDiff(Location, Channels, PercDiff, TimeStamps,...
        'TitleMod', TitleMod, 'FixYRange', true, 'VertLineCoords', PhaseCoords,...
        'VertLineLabels', PhaseNames)
end

Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)

%%
fprintf('Running PercDiff Window [2 1]\n')
tic
Window = [2 1]; %100ms of time
[PercDiff, TimeStamps] = Analysis.DelayedReach.LFP.specPercentDiff(RTAvgSpecs,...
    LTAvgSpecs, SubTimeBins, SubFreqBins, 'Window', Window);
toc
fprintf('Calculating 95%% bounds\n')
NumSamp = 10000;
tic
[LoCI, HiCI, samplediff] = Analysis.DelayedReach.LFP.shuffleCI(PowerArray, NumSamp, TargetShort, SubTimeBins, SubFreqBins);
toc
%% Sort and get cut off values for every bin
sortsample = sort(samplediff, 4);
sig_Left = sortsample(:, :, :, 250);
sig_Right = sortsample(:, :, :, end-250);
%% Plots of RvL difference for a given band
% if they pass the low or high cut off they are significantly in favor of R
% or L. 
fband_names = {'Theta 4-8' 'Alpha 8-12' 'Beta 12-30' 'Low Gamma 30-80'...
    'High Gamma 80-200'};

for ch = 1:60
    [~, loc] = ind2sub([10 6], ch);
    FigTitle = sprintf('FBand-RLDiff-Channel%d-%s%s', ch, string(GInfo.Hemisphere(loc)),...
        string(GInfo.Location(loc)));
    figure('Name', FigTitle, 'NumberTitle', 'off', 'units', 'normalized',...
        'outerposition', [0.2 0 0.6 1], 'PaperPositionMode', 'auto');
    for s = 1:5
        subplot_tight(5, 1, s, [0.035 0.045])
        plot(TimeStamps, PercDiff(s,:,ch), 'b')
        hold on
        plot(TimeStamps, sig_Left(s,:,ch), 'k:')
        plot(TimeStamps, sig_Right(s,:,ch), 'k:')
        ylim([-1 1])
        xlim([TimeStamps(1) TimeStamps(end)])
        ax = gca;
        ax.XAxisLocation = 'origin';
        ts = sprintf('%s - RLDiff-Ch%d',fband_names{s},ch);
        title(ts);
        hold off
    end
    
end
%% Plot Frequency Range Averages with Percent Difference
% For a channel of interest and frequency band of interest, average the
% spectrogram of the left target trials in that frequency range. Do the
% same for the right target trials. Plot the 10*log10 of those values over
% time to show the average power over time for right target trials and left
% target trials. Plot the percent difference of those values to judge the
% accuracy of the comparison. 
% DiffArray = PercDifferences;
% TSArray   = TimeStamps;
% Window = [2 1];
% ch = 4;
% FRangeN = 1;
% 
% FRanges = [4 8; 8 12; 12 30; 30 80; 80 200];
% 
% FreqLogical = FreqBins > FRanges(FRangeN, 1) & FreqBins < FRanges(FRangeN, 2);
% chLTFreqAvg = mean(LTAvgSpecs(:,FreqLogical, ch), 2);
% chRTFreqAvg = mean(RTAvgSpecs(:,FreqLogical, ch), 2);
% chPDiff = DiffArray(FRangeN, :, ch);
% 
% FString = sprintf('Channel %d - %d-%dHz Avg - Win %d %d', ch,...
%     FRanges(FRangeN, 1), FRanges(FRangeN, 2), Window(1), Window(2));
% figure('Name', FString, 'NumberTitle', 'off', 'units', 'normalized',...
%     'outerposition', [0.2 0.05 0.6 0.605]);
% %--------------------------------
% subplot_tight(2,1,1, [0.035 0.045])
% plot(SubTimeBins, 10*log10(chLTFreqAvg), 'b')
% hold on
% plot(SubTimeBins, 10*log10(chRTFreqAvg), 'r')
% ax = gca;
% VertLineCoords = PhaseCoords;
% YCoords = ax.YLim;
% Vx = [VertLineCoords; VertLineCoords];
% Vy = YCoords' .* ones(2, length(VertLineCoords));
% plot(Vx, Vy, 'k--')
% legend('Left Trial Avg', 'Right Trial Avg')
% ylabel('10 \cdot log_{10}', 'Interpreter', 'tex')
% ax.XTickLabelMode = 'manual';
% ax.XTickMode = 'manual';
% ts = sprintf('Channel %d - %d-%dHz Avg', ch,...
%     FRanges(FRangeN, 1), FRanges(FRangeN, 2));
% title(ts)
% hold off
% %--------------------------------
% subplot_tight(2,1,2, [0.055 0.045])
% plot(TSArray, chPDiff, 'g') % already 10*log10 scaled
% hold on
% ax = gca;
% YCoords = ax.YLim;
% Vy = YCoords' .* ones(2, length(VertLineCoords));
% plot(Vx, Vy, 'k--')
% plot([0 8], [0 0], 'k')
% legend('% Difference')
% ylabel('$$\frac{(R-L)}{(R+L)}$$', 'Interpreter', 'latex')
% xlabel('Trial Time (s)')
% %ax.XAxisLocation = 'origin';
% ax.YLim = YCoords;
% ts = sprintf('Channel %d - Percent Diff Moving Avg - Win %d %d', ch,...
%     Window(1), Window(2));
% title(ts)
% hold off

%%

% FigTitle = 'Test8 10000 Resamples, 476s';
% figure('Name', FigTitle, 'NumberTitle', 'off', 'units', 'normalized',...
%     'outerposition', [0.2 0 0.6 1], 'PaperPositionMode', 'auto');
% for s = 1:5
%     subplot(5, 1, s)
%     plot(TimeStamps, PercDifferences1(s,:,1), 'b')
%     hold on
%     plot(TimeStamps, LoCI(s,:,1), 'r')
%     plot(TimeStamps, HiCI(s,:,1), 'g')
%     ylim([-1 1])
%     ax = gca;
%     ax.XAxisLocation = 'origin';
%     hold off
% end