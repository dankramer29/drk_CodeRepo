%%
% LFP Analysis

taskObj = FrameworkTask('C:\Users\Mike\Documents\Data\P010\20170830\Task\20170830-133354-133456-DelayedReach.mat');
ns = taskObj.getNeuralDataObject('allgrids', 'ns3');
ns = ns{1};
GridMap = GridMap('\\striatum\Data\neural\source\P010\20170830-PH2\data\mapfile.csv');

% Ch_Map = containers.Map( {'L Amygdala'}, {'1:10'});
% Ch_Map('L Head Hippocampus') = '11:20'; %17:26
% Ch_Map('L Tail Hippocampus') = '21:30'; %33:42
% Ch_Map('R Amygdala') = '31:40'; %49:58
% Ch_Map('R Head Hippocampus') = '41:50'; %65:74
% Ch_Map('R Tail Hippocampus') = '51:60'; %81:90
% Ch_Map('L Parietal') = '61:68'; %97:104
% Ch_Map('R Parietal') = '69:76'; %113:120

%%
% 
% 	• Data would be [Time x Channel x Trial]

% initial variables

StartPhase = 1;
Locations = 1:8;
SuccessDist = 104;
EndPhase = 0;
PreZero = 0; %2 seconds before our zero reference
PostZero = 6; %6 seconds of neural data after zero reference
DtClass = 'single'; %more efficient for GPU during spectrogram processing
TotalChanArray = [1:10 17:26 33:42 49:58 65:74 81:90 97:104 113:120]; % all channels recording neural data
MicroChanArray = [1:10 17:26 33:42 49:58 65:74 81:90]; % all micro channels
MacroChanArray = [97:104 113:120]; % all macro channels
%%
% generate time windows to sample, slice neural data using those times,
% include trial numbers

% returns frameIDs (column vec) corresponding to trial numbers and target numbers.
% TrialLogArray is a logical array Mx1 M = total # trials, with 1 = trial
% with a response within the SuccessDist and not an I Don't Know response
[TrialNums, TrialZeroFrame, Targets, TrialLogArray, TrialEnds] = Analysis.DelayedReach.LFP.pullTrials(...
    taskObj, Locations, SuccessDist, StartPhase, EndPhase);

%Make changes for VarArgIn and VarArgOut!
% Using the frameID from above, get the corresponding neural times (column
% vec)
[NeuralSampleRanges, NeuralStartTimes, NeuralEndTimes] = Analysis.DelayedReach.LFP.pullNeural(taskObj, TrialZeroFrame, TrialEnds, PreZero, PostZero);

% % using the neural times from above, corresponding to the cue presentation,
% % generate the neural sample start and end times for each trial
% NeuralStartTimes = NeuralZeroTimes - PreZero;
% NeuralEndTimes = NeuralZeroTimes + PostZero;
% %column vec of start times and total sample time. This matches the format
% %the following function requires
% NeuralSampleRanges = [NeuralStartTimes (NeuralEndTimes - NeuralStartTimes)]; 

% NeuralData = Samples(Time) x Channels x Trials
[NeuralData, RelativeTimes, FeatureDef] = proc.blackrock.broadband(...
    ns, 'PROCWIN', NeuralSampleRanges, DtClass, 'CHANNELS',...
    TotalChanArray, 'Uniformoutput', true);

TableOfDataUsed = table(TrialNums, Targets, NeuralStartTimes, NeuralSampleRanges,...
    NeuralEndTimes);

% Variable Clean Up
clear Locations SuccessDist EndPhase PreZero PostZero DtClass TotalChanArray...
    MicroChanArray MacroChanArray TrialNums NeuralStartTimes NeuralZeroTimes...
    NeuralEndTimes NeuralSampleRanges TrialZeroFrame TrialEnds StartPhase

%%
% 	• Spectrograms (not trial or channel averaged)
% 	• 100 msec time bin, 50 msec step size (movingwin [0.1 0.05], tapers [5 9], pad 1
% 	• S is going to be [Time x Frequency x Channel x Trial]

%%
% Channel Average = average over the channel dimension = Time x #Trials
%ChanAvgData = squeeze(mean(NeuralData,2));

%%
% Trial Average = average over the trial dimension = Time x #Channels
%TrialAvgData = squeeze(mean(NeuralData,3));

%%
% Plot each channel individually, with all loc 7 trials in blue and all loc
% 3 trials in red. All channels grouped?

Target3Logical = ismember(Targets, 3); %logical array where 1 = target 0 = others
Target7Logical = ismember(Targets, 7);
Target7Logical(17,1) = 0;

LogicColumns = [Target3Logical Target7Logical];

MapLocations = Ch_Map.keys;
MapChannelRanges = Ch_Map.values;

time = 1:size(NeuralData,1);

for Loc = 1:length(MapLocations)
    LeadLoc = MapLocations{Loc};
    figure('Name', LeadLoc, 'Position', [1280 0 1280 1440])
    Channels = str2num(MapChannelRanges{Loc});
    ChLen = length(Channels);
    for i = 1:ChLen
        Targ3Data = squeeze(NeuralData(:,Channels(i), Target3Logical));
        Targ7Data = squeeze(NeuralData(:,Channels(i), Target7Logical));
        ax = subplot(ChLen, 1, i);
        
        plot(time, Targ3Data, 'g')
        hold on
        plot(time, Targ7Data, 'b')
        ax.YLim = [-500 500];
        tStr = ['Channel ' num2str(Channels(i))];
        title(tStr);
        hold off
        
    end
    

end

% Variable Clean Up
clear Loc LeadLoc Channels ChLen i ax tStr LogicColumns
 
%%
