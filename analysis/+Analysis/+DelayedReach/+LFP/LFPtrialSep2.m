task = FrameworkTask('C:\Users\Mike\Documents\Data\P010\20170830\Task\20170830-133354-133456-DelayedReach.mat');
ns = task.getNeuralDataObject('allgrids','ns6');
ns = ns{1};
debug = Debug.Debugger('debug09142017')

leftIDs = [8 7 6];
rightIDs = [2 3 4];
upperIDs = [8 1 2];
lowerIDs = [6 5 4];
left = [7];
right = [3];
startPhase = 5;
% ITI = 1, Fixate = 2, Cue = 3, Delay = 4, Respond = 5

numTrials = length(task.trialdata);
%locations = upperIDs;

leftCount = 0;
rightCount = 0;
upperRow = 0;
lowerRow = 0;
%%
% sort left and right trials
leftTrialnum = [];
rightTrialnum = [];

for trialNumber = 1:numTrials
    targetLocation = task.trialdata(trialNumber).tr_prm.targetID;
    
    %if task.trialdata(trialNumber).ex_success == 1
        
    if any( targetLocation == left)
        leftCount = leftCount+1;
        leftTrialnum = [leftTrialnum trialNumber];
    
    elseif any( targetLocation == right)
        rightCount = rightCount+1;
        rightTrialnum = [rightTrialnum trialNumber];
    end %region sorting for successful trials

end %end location count

%%
% build matrix of trial info (for easier indexing than structs)

assert((leftCount) == rightCount, 'Different number of trials for conditions specified')

lResultmatrix = zeros(leftCount,1,7);
rResultmatrix = zeros(rightCount,1,7);


for i = 1:rightCount
    trialNum = rightTrialnum(i);
    rResultmatrix(i,1,1) = trialNum; %trial number
    rResultmatrix(i,1,2) = task.trialdata(trialNum).tr_prm.targetID; %target location 
    rResultmatrix(i,1,3) = task.trialdata(trialNum).et_phase(startPhase); %start frame ID
    rResultmatrix(i,1,4) = task.trialdata(trialNum).et_trialCompleted; %end frame ID
    rResultmatrix(i,1,5) = task.data.neuralTime(rResultmatrix(i,1,3)); %neural time start
    rResultmatrix(i,1,6) = task.data.neuralTime(rResultmatrix(i,1,4)); %neural time stop
    rResultmatrix(i,1,7) = rResultmatrix(i,1,6) - rResultmatrix(i,1,5); %total time to reference
end % end build right results matrix


for i = 1:leftCount
    trialNum = leftTrialnum(i);
    lResultmatrix(i,1,1) = trialNum; %trial number
    lResultmatrix(i,1,2) = task.trialdata(trialNum).tr_prm.targetID; %target location 
    lResultmatrix(i,1,3) = task.trialdata(trialNum).et_phase(startPhase); %start frame ID
    lResultmatrix(i,1,4) = task.trialdata(trialNum).et_trialCompleted; %end frame ID
    lResultmatrix(i,1,5) = task.data.neuralTime(lResultmatrix(i,1,3)); %neural time start
    lResultmatrix(i,1,6) = task.data.neuralTime(lResultmatrix(i,1,4)); %neural time stop
    lResultmatrix(i,1,7) = lResultmatrix(i,1,6) - lResultmatrix(i,1,5); %total time to reference
end % end build left results matrix


%% plot windows of L data

% Normalize data times
Window = max(max(rResultmatrix(:,:,7)),max(lResultmatrix(:,:,7)));

% channel list
channelList = [17:26; 65:74];

% pre-allocate neural data matrix
range = [(1/ns.Fs):(1/ns.Fs): Window];
Ldata = zeros(leftCount,size(range,2));
Rdata = zeros(leftCount,size(range,2));
LdataAvg = zeros(2,size(range,2));
RdataAvg = zeros(2,size(range,2));

% add data from each Ltrial, averaged over channels specified in L
for ch = 1:size(channelList,1)
    channels = channelList(ch,:);
    for i = 1:leftCount
        startTimeL = lResultmatrix(i,1,6) - Window;
        startTimeR = rResultmatrix(i,1,6) - Window;
        endTimeL = lResultmatrix(i,1,6);
        endTimeR = rResultmatrix(i,1,6);
        dL = ns.read('times', [startTimeL endTimeL], 'channels', channels);
        dR = ns.read('times', [startTimeR endTimeR], 'channels', channels);
        Ldata(i,:) = mean(dL);
        Rdata(i,:) = mean(dR);
    end
    LdataAvg(ch,:) = mean(Ldata);
    RdataAvg(ch,:) = mean(Rdata);
end



%% plot windows of R data

% Normalize data times
Window = max(max(rResultmatrix(:,:,7)),max(lResultmatrix(:,:,7)));

% channel list
R = [17:26];

% pre-allocate neural data matrix
range = [(1/ns.Fs):(1/ns.Fs): Window];
Rdata = zeros(rightCount,size(range,2));

% add data from each R trial, averaged over channels specified in R
% for i = 1:rightCount
%     startTimeR = rResultmatrix(i,1,6) - Window;
%     endTimeR = rResultmatrix(i,1,6);
%     dR = ns.read('times', [startTimeR endTimeR], 'channels', R);
%     Rdata(i,:) = mean(dR);
% end

%RdataAvg = mean(Rdata);

ax(1) = subplot(2,2,1);
plot(LdataAvg(1,:))
title('DelR Left trials Ch 17-26')

ax(2) = subplot(2,2,3);
plot(RdataAvg(1,:))
title('DelR Right trials Ch 17-26')

ax(3) = subplot(2,2,2);
plot(LdataAvg(2,:))
title('DelR Left trials Ch 65:74')

ax(4) = subplot(2,2,4);
plot(RdataAvg(2,:))
title('DelR Right trials Ch 65:74')


