function [phtimes,phnames,num_trials] = getPhaseInfo(task,blc,debug)

% get phase names/times
phnames = task.phaseNames;
phtimes = [task.phaseTimes sum(task.trialTimes,2)];
num_trials = find(phtimes(:,end)<=seconds(blc.DataInfo.Duration),1,'last');
if num_trials<task.numTrials
    debug.log(sprintf('Neural recordings only have enough data for first %d out of %d trials',num_trials,task.numTrials),'warn');
end
phtimes = phtimes(1:num_trials,:);