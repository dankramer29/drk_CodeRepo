taskObj = FrameworkTask('C:\Users\Mike\Documents\Data\P010\20170830\Task\20170830-133354-133456-DelayedReach.mat');
ns = taskObj.getNeuralDataObject('allgrids', 'ns3');
ns = ns{1};


SuccessDist = 104; %px from center of target (og target radius = 52px)
StartPhase = 1; % 1 = ITI 4 = delay phase
EndPhase = 0; % code doesn't use end phase yet

ChanArray = [1:10 17:26 33:42 49:58 65:74 81:90 97:104 113:120]; % all channels used

DtClass = 'single'; %more efficient for GPU during spectrogram processing

%%
% Left Location
TargetLoc = 7;

[LTrialNums, LTrialStarts, LTrialEnds, ~] = Analysis.DelayedReach.LFP.pullTrials(taskObj, TargetLoc, SuccessDist, StartPhase, EndPhase);
[LNeuralStarts, LNeuralEnds, LMaxTrialLength] = Analysis.DelayedReach.LFP.pullNeural(taskObj, LTrialStarts, LTrialEnds);
LNeuralDuration = ceil(LMaxTrialLength)*ones(size(LNeuralStarts,1),1); %better to get too much than not enough

LProcWin = [LNeuralStarts LNeuralDuration]; %column vec of start times and sampling windows
% manually removing the 3rd L location trial due to huge V spike mid trial
% LProcWin([3],:) = []; %keeping [] to show how to remove multiple rows at once

[LNeuralDataCells, LRelTimes, LFeatDef] = proc.blackrock.broadband(ns, 'PROCWIN', LProcWin, DtClass, 'CHANNELS', ChanArray, 'Uniformoutput', true); %Univorm output 'true'

% pre-allocation keeps the MATLAB lords happy
LTrialsAvg = zeros(size(LNeuralDataCells(1)), 'single');
% LTrialsAvg = Time x #Channels

LChanAvg = zeros(size(LNeuralDataCells,1),size(LNeuralDataCells,3),'single'); %make named variable for trial #s
% LChanAvg = Time X Trials

% add the channel data for each trial to make the channel average
% mean of all channels in a trial for the trial average
for c = 1:size(LNeuralDataCells, 3)
    LTrialsAvg = LTrialsAvg + LNeuralDataCells(:,:,c);
    LChanAvg(:,c) = mean(LNeuralDataCells(:,:,c),2,'native'); %keeps output same DtClass as input
end
% divide by number of trials selected to get channel averages for trials
LTrialsAvg = LTrialsAvg / size(LNeuralDataCells,2); % time samples X #channels : 

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
    cell 

%%
% Right Location

TargetLoc = 3;

[RTrialNums, RTrialStarts, RTrialEnds, ~] = Analysis.DelayedReach.LFP.pullTrials(taskObj, TargetLoc, SuccessDist, StartPhase, EndPhase);
[RNeuralStarts, RNeuralEnds, RMaxTrialLength] = Analysis.DelayedReach.LFP.pullNeural(taskObj, RTrialStarts, RTrialEnds);
RNeuralDuration = ceil(RMaxTrialLength)*ones(size(RNeuralStarts,1),1); %better to get too much than not enough

RProcWin = [RNeuralStarts RNeuralDuration]; %column vec of start times and sampling windows

[RNeuralDataCells, RRelTimes, RFeatDef] = proc.blackrock.broadband(ns, 'PROCWIN', RProcWin, DtClass, 'CHANNELS', ChanArray, 'Uniformoutput', true);

% pre-allocation keeps the MATLAB lords happy
RTrialsAvg = zeros(size(RNeuralDataCells(1)), 'single');
% i'm sure there's a better way to index cells
RChanAvg = zeros(size(RNeuralDataCells,1),size(RNeuralDataCells,3), 'single');

% add the channel data for each trial to make the channel average
% mean of all channels in a trial for the trial average
for c = 1:size(RNeuralDataCells, 3)
    RTrialsAvg = RTrialsAvg + RNeuralDataCells(:,:,c);
    RChanAvg(:,c) = mean(RNeuralDataCells(:,:,c),2,'native'); %keeps output same DtClass as input
end
% divide by number of trials selected to get channel averages for trials
RTrialsAvg = RTrialsAvg / size(RNeuralDataCells,2);

% to get the average for all channel data for all trials specified
RMasterAvg = mean(RTrialsAvg,2);

%Rrange = [(1/ns.Fs):(1/ns.Fs): RNeuralDuration];
% use RRelTimes

RTableOfDataUsed = table(RTrialNums, RTrialStarts, RTrialEnds,...
    RNeuralStarts, RNeuralEnds,...
    RNeuralDuration);


clear SuccessDist StartPhase EndPhase ChanArray TargetLoc RTrialNums RTrialStarts...
    RTrialEnds RLogArray RNeuralStarts RNeuralEnds RMaxTrialLength RNeuralDuration...
    cell c DtClass

