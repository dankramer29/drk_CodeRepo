%% P015 LvR Working Script

%%
% Load P015 Data with 14 trials
%   load('D:\1_Year\Neuro_SP\Task Recording\Data\P015\DelayedReach_Results\02062018-P015-GridMap.mat')
%   load('D:\1_Year\Neuro_SP\Task Recording\Data\P015\DelayedReach_Results\02062018-P015-NeuralData.mat')
%   load('D:\1_Year\Neuro_SP\Task Recording\Data\P015\DelayedReach_Results\02062018-P015-SpecsOutput.mat')
%   load('D:\1_Year\Neuro_SP\Task Recording\Data\P015\DelayedReach_Results\02062018-P015-Targs.mat')

%% 
ActionIDX = TimeBins > 4.0; % Action phase starts at 6s, get delay phase
SubTimeBins = TimeBins(ActionIDX);
SubFreqBins = FreqBins; % Not sub-selecting frequencies yet
SubSpecs = PowerArray(ActionIDX, :, :, :);

whos SubSpecs

%% Make Left and Right Target Indices
% Left Targets = 8, 7, 6
LTTrialsIdx = TargetShort == 6 | TargetShort == 7 | TargetShort == 8;
fprintf('# L Target Trials: %d\n', sum(LTTrialsIdx))
%%
% Right Targets = 2, 3, 4
RTTrialsIdx = TargetShort == 2 | TargetShort == 3 | TargetShort == 4;
fprintf('# R Target Trials: %d\n', sum(RTTrialsIdx))
%% Index and Average
% *Take trials for L targets and average*
LTSpecs = SubSpecs(:, :, :, LTTrialsIdx);
LTAvgSpecs = mean(LTSpecs, 4);
%%
% *Take trials for R targets and average*
RTSpecs = SubSpecs(:, :, :, RTTrialsIdx);
RTAvgSpecs = mean(RTSpecs, 4);

%% Make ITI Mean and Standard Deviation
% *Make indices*
TrialsIdx = LTTrialsIdx | RTTrialsIdx;
fprintf('# L + R Target Trials: %d\n', sum(TrialsIdx))

ITIidx = TimeBins < 2.001; % ITI from 0 - 2s of each trial
ITISpecs = PowerArray(ITIidx, :, :, TrialsIdx);
ITITimes = TimeBins(ITIidx);
whos ITISpecs

%%
% Average across time, then get standard deviation and the average across
% all the trials we're using for L and R targets
ITITimeAvg = mean(ITISpecs, 1); % Time average
ITITrialAvg = mean(ITITimeAvg,4);
ITIStd = std(ITITimeAvg, [], 4);

%%
% We now have a row vector for each channel, containing each frequency
% bin's average value for all 10 trials' ITI phase. We'll expand this row
% so that each value is repeated for each time bin. By making this array
% equal in size to our left and right trial averages, we can vectorize our
% z-score equation later.
ITIMeans = zeros(36, 410, 60);
ITIStDevs = zeros(36, 410, 60);
for i = 1:36
    ITIMeans(i, :, :) = ITITrialAvg(1,:,:);
    ITIStDevs(i, :, :) = ITIStd(1,:,:);
end

%%
% Plot channel 1's averaged spectogram for all frequencies in the ITI phase
% as an example:
Ch1ITIAvg = ITIMeans(:, :, 1);
figure
imagesc(ITITimes, FreqBins, 10*log10(Ch1ITIAvg)'); axis xy;

%% Differences of Z-Scored Left and Right Trials
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

LeftZScores = (LTAvgSpecs - ITIMeans) ./ ITIStDevs;
RightZScores = (RTAvgSpecs - ITIMeans) ./ ITIStDevs;
LvRZScores = LeftZScores - RightZScores;
[S, L] = bounds(LvRZScores);

%% Get Channels from GridMap
%
GInfo = gridMapObj.GridInfo;
ChanIdx = cell2mat(gridMapObj.GridChannelIndex);
GInfo
ChanIdx

%% Left Head Hippocampus
% *1st Location* averages and z-score differences
loc = 1;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true)

%%
% same location but *all z-scored* specctrograms
Location = sprintf("%s-%s-ZScores", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LeftZScores, RightZScores,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true, 'AllZs', true)

%%
% 
Location = 'Left-HeadHippocampus sub';
Channels = 5;
Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', true, 'PlotColorBar',...
    true, 'AllZs', false)

%% Left Tail Hippocampus
% *2nd Location* averages and z-score differences
loc = 2;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true)
%%
% same location but *all z-scored* spectrograms
Location = sprintf("%s-%s-ZScores", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LeftZScores, RightZScores,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true, 'AllZs', true)
%% Right Head Hippocampus
% *3rd Location* averages and z-score differences
loc = 3;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true)
%%
% same location but *all z-score* spectrograms
Location = sprintf("%s-%s-ZScores", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LeftZScores, RightZScores,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true, 'AllZs', true)

%% Right Tail Hippocampus
% *4th Location* averages and z-score differences
loc = 4;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true)
%%
% same location but *all z-score* spectrograms
Location = sprintf("%s-%s-ZScores", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LeftZScores, RightZScores,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true, 'AllZs', true)

%% Left Amygdala
% *5th Location* averages and z-score differences
loc = 5;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true)
%%
% same location but *all z-score* spectrograms
Location = sprintf("%s-%s-ZScores", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LeftZScores, RightZScores,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true, 'AllZs', true)

%% Right Amygdala
% *6th Location* averages and z-score differences
loc = 6;
Location = sprintf("%s-%s", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LTAvgSpecs, RTAvgSpecs,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true)
%%
% same location but *all z-score* spectrograms
Location = sprintf("%s-%s-ZScores", string(GInfo.Hemisphere(loc)),...
    string(GInfo.Location(loc)));
Channels = ChanIdx(:,loc)';

Analysis.DelayedReach.LFP.plotLvRLocations(Location, Channels, LeftZScores, RightZScores,...
    LvRZScores, SubTimeBins, SubFreqBins, 'Normalize', false,...
    'PlotColorBar', true, 'AllZs', true)
