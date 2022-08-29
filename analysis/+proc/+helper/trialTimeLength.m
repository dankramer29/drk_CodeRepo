function [tm,len,trialdef] = trialTimeLength(window,task,params,debugger)
% TRIALTIMELENGTH Get start times and lengths of processing windows
%
%   [TM,LEN] = TRIALTIMELENGTH(WINDOW,TASK,PARAMS,DEBUGGER)
%   Get the start times TM and the lengths LEN of trials for the task
%   represented by FRAMEWORKTASK object TASK, based on window information
%   in WINDOW, parameters in PARAMETERS.DYNAMIC object PARAMS, and using
%   the debugging resources in DEBUG.DEBUGGER object DEBUGGER.
%
%   WINDOW can be any of the following:
%
%     EMPTY   - TM and LEN will be the start times and lengths of each
%               trial in TASK (see FRAMEWORKTASK/GETTRIALTIME).
%     CELL    - For now, only a single cell is supported and it should
%               contain a valid phase indicator (see
%               FRAMEWORKTASK/GETPHASETIME).
%     CHAR    - The string should be a valid phase name (see
%               FRAMEWORKTASK/GETPHASETIME).
%     NUMERIC - Should be a two-element vector where the first element is
%               interpreted as an additive offset to the trial times
%               returned by FRAMEWORKTASK/GETTRIALTIME, and the length LEN
%               is the difference between the first and second elements.
%
%   Typically, WINDOW would be taken from the parameters TM.BASELINE and/or
%   TM.ANALYSIS (see PARAMETERS.TOPIC.TIME).
%
%   PARAMETERS
%   This function depends upon the following parameters.
%
%     TM.LENFCN - function to determine trial lengths (e.g., to unify)
%     TM.MIN - the minimum length allowed
%
%   See also FRAMEWORKTASK, PARAMETERS.DYNAMIC, DEBUG.DEBUGGER.

% extract times and lengths
if isempty(window)
    [tm,len] = task.getTrialTime([],'seconds');
else
    if iscell(window)
        debugger.log('Using only the first cell of WINDOW, and assuming it is a valid phase indicator','warn');
        [tm,len] = task.getPhaseTime([],window{1});
    elseif isnumeric(window)
        tm = task.getTrialTime;
        tm = tm + window(1);
        len = repmat(diff(window),[length(tm) 1]);
    end
end

% apply trial length function
lenfcn = params.tm.lenfcn;
if ischar(lenfcn),lenfcn=func2str(lenfcn);end
debugger.log(sprintf('Applying the length function %s to the trial lengths',func2str(lenfcn)),'debug');
len = feval(lenfcn,len);
if isscalar(len),len=repmat(len,size(tm));end
len = len(:);
assert(all(size(len)==size(tm)),'Trial length LEN (%d x %d) must be the same size as start time TM (%d x %d)',size(len,1),size(len,2),size(tm,1),size(tm,2));

% look for NaN trials
idxKeep = find(~isnan(tm)&~isnan(len));
if isempty(idxKeep),warning('No trials kept');end
tm = tm(idxKeep);
len = len(idxKeep);
bhv = task.trialdata(idxKeep);

% create trialdef
trialdef = arrayfun(@(w,x,y,z){w,x,y,z},idxKeep(:),tm(:),len(:),bhv(:),'UniformOutput',false);
trialdef = cat(1,trialdef{:});
trialdef = [trialdef(:,1:3) repmat({task.taskString},size(trialdef,1),1) trialdef(:,4)];
trialdef = cell2table(trialdef,'VariableNames',{'trial','trial_start','trial_length','task_id','behavioral'});

% add in buffer pre/post
tm = tm(:)-params.tm.bufferpre;
len = len(:)+params.tm.bufferpre+params.tm.bufferpost;