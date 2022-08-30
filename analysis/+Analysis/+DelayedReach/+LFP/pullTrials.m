function [TrialNums, TrialStarts, Targets, LogArray, TrialEnds] = pullTrials(taskObj, Locations, SuccessDist, StartPhase, EndPhase)
    % compare SuccessDist to distance between pt response location and
    % target location
    successfuls = arrayfun(@(x) le(x.response_hypot, SuccessDist), taskObj.trialdata); %can index like TrialEnds line 10
    trials = 1:length([taskObj.trialdata.tr_prm]);
    targets = arrayfun(@(x)x.tr_prm.targetID,taskObj.trialdata);
    targetTrue = ismember(targets, Locations);
    LogArray = and(targetTrue, successfuls)';
    TrialNums = trials(LogArray)'; %find LogArray
    
    if StartPhase == 1
        TrialStarts = [taskObj.trialTimes(:,1)];
    else
        TrialStarts = arrayfun(@(x) x.et_phase(StartPhase), taskObj.trialdata);
    end
    
    TrialStarts = TrialStarts(LogArray)';
    TrialEnds = [taskObj.trialdata.et_trialCompleted];
    TrialEnds = TrialEnds(LogArray)';
    Targets = targets(LogArray)';
end