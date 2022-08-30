taskObj = FrameworkTask('C:\Users\Mike\Documents\Data\P010\20170830\Task\20170830-133354-133456-DelayedReach.mat');
ns = taskObj.getNeuralDataObject('allgrids', 'ns3');
ns = ns{1};


SuccessDist = 104; %px from center of target (og target radius = 52px)
StartPhase = 1; % 1 = ITI 4 = delay phase
EndPhase = 0; % code doesn't use end phase yet

ChanArray = [1:10 17:26 33:42 49:58 65:74 81:90 97:104 113:120]; % all channels used

%%
% Left Location
TargetLoc = 7;

[LTrialNums, LTrialStarts, LTrialEnds, ~] = Analysis.DelayedReach.LFP.pullTrials(taskObj, TargetLoc, SuccessDist, StartPhase, EndPhase);
[LNeuralStarts, LNeuralEnds, LMaxTrialLength] = Analysis.DelayedReach.LFP.pullNeural(taskObj, LTrialStarts, LTrialEnds);
LNeuralDuration = ceil(LMaxTrialLength)*ones(size(LNeuralStarts,1),1); %better to get too much than not enough

LProcWin = [LNeuralStarts LNeuralDuration]; %column vec of start times and sampling windows

[LNeuralDataCellsLLoc, LRelTimesLLoc, LFeatDefLLoc] = proc.blackrock.broadband(ns, 'PROCWIN', LProcWin, 'CHANNELS', ChanArray, 'Uniformoutput', true); %Univorm output 'true'

% pre-allocation keeps the MATLAB lords happy
LTrialsAvg = zeros(size(LNeuralDataCellsLLoc(1)));
% i'm sure there's a better way to index cells
LChanAvg = zeros(size(LNeuralDataCellsLLoc,1),size(LNeuralDataCellsLLoc,3)); %make named variable for trial #s

% add the channel data for each trial to make the channel average
% mean of all channels in a trial for the trial average
for c = 1:size(LNeuralDataCellsLLoc, 3)
    LTrialsAvg = LTrialsAvg + LNeuralDataCellsLLoc(:,:,c);
    LChanAvg(:,c) = mean(LNeuralDataCellsLLoc(:,:,c),2);
end
% divide by number of trials selected to get channel averages for trials
LTrialsAvg = LTrialsAvg / size(LNeuralDataCellsLLoc,2); % time samples X #channels : 

% to get the average for all channel data for all trials specified
LMasterAvg = mean(LTrialsAvg,2);

%Lrange = 0:(1/ns.Fs): LNeuralDuration-(1/ns.Fs);
%use LRelTimes

LTableOfDataUsed = table(LTrialNums, LTrialStarts, LTrialEnds,...
    LNeuralStarts, LNeuralEnds,...
    LNeuralDuration);

%clean up some variables
clear TargetLoc LTrialNums LTrialStarts...
    LTrialEnds LLogArray LNeuralStarts LNeuralEnds LMaxTrialLength LNeuralDuration...
    LProcWin cell 
