%% Percent Difference Left vs Right
%% Load Previously Generated Data
% Data generated in P010_DelR_Script.m and saved


% localPath = '\\striatum\Data\user home\Mike\Crunch_Output';
% % localPath = 'D:\1_Year\Neuro_SP\Task Recording\Data\P010\20170830\Results\LFP\DelayedReach\Crunch_Output';
% 
% savedData = {'P010DelR_FreqBins.mat', 'P010DelR_PowerArray.mat', ...
%     'P010DelR_Targets.mat', 'P010DelR_TimeBins.mat'};
% 
% for d = 1:length(savedData)
%     fp = fullfile(localPath, savedData{d});
%     load(fp)
% end
% 
% clear localPath savedData d fp
%%
% whos PowerArray
%
%   Name              Size                        Bytes  Class     Attributes
% 
%   PowerArray      171 x 410 x 76 x 54            1150925760  single     
%                   Tim x Fre x Ch x Tr
%% Remove unwanted data
% start by making indices for the action phase, gamma band, and a channel
% logical we will use to subselect channels later.
SelAction = TimeBins > 6.0;
SelGamma  = FreqBins > 30 & FreqBins < 80;
SelChannels = logical(zeros(76, 1)); % Not removing channels yet
SubTimeBins = TimeBins(SelAction);
SubFreqBins = FreqBins(SelGamma);
SubSpecs = PowerArray(SelAction, SelGamma, :, :);


%% Make Left and Right Target Indices
% Left Targets = 8, 7, 6
LTTrials = Targets == 6 | Targets == 7 | Targets == 8;
fprintf('# L Target Trials: %d\n', sum(LTTrials))

%%
% Right Targets = 2, 3, 4
RTTrials = Targets == 2 | Targets == 3 | Targets == 4;
fprintf('# R Target Trials: %d\n', sum(RTTrials))

%% Index and Average
% Take trials for L targets and average
LTSpecs = SubSpecs(:, :, :, LTTrials);
LTAvgSpecs = mean(LTSpecs, 4);
%%
% % Take trials for R targets and average
RTSpecs = SubSpecs(:, :, :, RTTrials);
RTAvgSpecs = mean(RTSpecs, 4);

%% Calculate and Store Difference
% Per channel using the equation: 
%%
% one way: 
% $x = \frac{L-R}{L} * 100
% if x > 0, R is x% smaller than L
% if x < 0, R is |x|% larger than L
% -
% or:
% $x = \frac{L}{R} * 100
% L is x% the size of R

ChLvR = zeros(56, 102, 76);
for ch = 1:76
    LCh = LTAvgSpecs(:, :, ch);
    RCh = RTAvgSpecs(:, :, ch);
    ChLvR(:, :, ch) = (LCh ./ RCh) * 100;
end

%% Plot by Locations
% 'Bank A'
% 1-10    - L Amygdala             (1-10)
% 17-26   - L Head of Hippocampus  (11-20)
% 
% 'Bank B'
% 33-42   - L Tail of Hippocampus  (21-30)
% 49-58   - R Amygdala             (31-40)
% 
% 'Bank C'
% 65-74   - R Head of Hippocampus  (41-50)
% 81-90   - R Tail of HIppocampus  (51-60)
% 
% 'Bank D'
% 97-104  - L Parietal             (61-68)
% 113-120 - R Parietal             (69-76)

%% Left Amygdala LvR

LocName = 'L_Amygdala';
Channels = 1:10;
Analysis.DelayedReach.LFP.plotLvRLocations(LocName, Channels, LTAvgSpecs, RTAvgSpecs,...
    ChLvR, SubTimeBins, SubFreqBins)

%%
% some pretty bad 60 Hz noise, but a few channels look interesting.
% Plot them larger, same location
LocName = 'L_Amygdala_SubGroup';
Channels = [1 2 9];
Analysis.DelayedReach.LFP.plotLvRLocations(LocName, Channels, LTAvgSpecs, RTAvgSpecs,...
    ChLvR, SubTimeBins, SubFreqBins)

%%
% so at these locations, some L targets had increased power around 7.5 sec 
% into the trials compared to R targets

%% Left Head of Hippocampus LvR
 
LocName = 'L_Head_of_Hipp';
Channels = 11:20;
Analysis.DelayedReach.LFP.plotLvRLocations(LocName, Channels, LTAvgSpecs, RTAvgSpecs,...
    ChLvR, SubTimeBins, SubFreqBins)

%%
% Similar to L Amygdala, with more power for L targets than R all around
% 7.5 sec into the trials. 60 Hz noise is evident. 

%%
% Channel 11, in the L Head Hipp
LocName = 'L_Head_of_Hipp_SubGroup';
Channels = 11;
Analysis.DelayedReach.LFP.plotLvRLocations(LocName, Channels, LTAvgSpecs, RTAvgSpecs,...
    ChLvR, SubTimeBins, SubFreqBins)

%%
% The timing is based on when the action phase started. This comparison
% might be biased by variability of movement and touch timing.

%%
% Skipping channels in Bank B due to flat/homogenous signal seen in other
% analysis.

%% Right Head of Hippocampus LvR
% 65-74   - R Head of Hippocampus  (41-50)
LocName = 'R Head of Hippocampus';
Channels = 41:50;
Analysis.DelayedReach.LFP.plotLvRLocations(LocName, Channels, LTAvgSpecs, RTAvgSpecs,...
    ChLvR, SubTimeBins, SubFreqBins)

%%
% Closer look at the first few channels here
LocName = 'R Head of Hippocampus_SubGroup';
Channels = 41:45;
Analysis.DelayedReach.LFP.plotLvRLocations(LocName, Channels, LTAvgSpecs, RTAvgSpecs,...
    ChLvR, SubTimeBins, SubFreqBins)

%% Right Tail of of Hippocampus
% 81-90   - R Tail of HIppocampus  (51-60)
LocName = 'R Tail of Hippocampus';
Channels = 51:60;
Analysis.DelayedReach.LFP.plotLvRLocations(LocName, Channels, LTAvgSpecs, RTAvgSpecs,...
    ChLvR, SubTimeBins, SubFreqBins)

%%
% Some nice 60Hz power spiking
LocName = '60Hz Changes';
Channels = 53:55;
Analysis.DelayedReach.LFP.plotLvRLocations(LocName, Channels, LTAvgSpecs, RTAvgSpecs,...
    ChLvR, SubTimeBins, SubFreqBins)
%% Left Parietal LvR
% 97-104  - L Parietal             (61-68)
LocName = 'L Parietal';
Channels = 61:68;
Analysis.DelayedReach.LFP.plotLvRLocations(LocName, Channels, LTAvgSpecs, RTAvgSpecs,...
    ChLvR, SubTimeBins, SubFreqBins)
%%
% Drowned by 60 Hz?
%% Right Parietal LvR
% 113-120 - R Parietal             (69-76)
LocName = 'R Parietal';
Channels = 69:76;
Analysis.DelayedReach.LFP.plotLvRLocations(LocName, Channels, LTAvgSpecs, RTAvgSpecs,...
    ChLvR, SubTimeBins, SubFreqBins)
%%
% Same as Left Parietal channels. Possibly bank D then.