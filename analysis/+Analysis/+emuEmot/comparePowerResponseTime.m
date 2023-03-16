function [RTDEsec,RTDIsec, summaryStats] = comparePowerResponseTime(nback, ResponseTimesDiffIdentity, ResponseTimesDiffEmotion, identityTaskLFP, emotionTaskLFP, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[varargin, plt]=util.argkeyval('plt', varargin, 1); %toggle on or off if you want to plot


summaryStats = struct;

%grab fields
chNum = fieldnames(nback);

conditionName = fieldnames(nback.(chNum{1}));

resultName = fieldnames(nback.(chNum{1}).(conditionName{1}));

resultNameAll = fieldnames(nback.(chNum{1}).(conditionName{4}));

%convert to seconds (was in micro seconds to adjust with neural clock)
RTDEsec = ResponseTimesDiffEmotion/1e6;
RTDIsec = ResponseTimesDiffIdentity/1e6;
%remove the nan from first trial
RTDEsec(1) = [];
RTDIsec(1) = [];

[pos, summaryStats.ReactionTimesEmotTaskvIdTask, ci, stats] = ttest(RTDEsec, RTDIsec);

%look at high gamma for areas that were 
for cc = 1:length(chNum)
    for nn = 1:length(conditionName)
        if nback.(chNum{1}).(conditionName{nn}).



if plt
    figure
    boxplot([RTDEsec, RTDIsec])
    xticklabels({'Emotion Task', 'Identity Task'});
    ylabel('Seconds')
    title('Response Times')
    set(gca, 'fontsize', 13)
end


end