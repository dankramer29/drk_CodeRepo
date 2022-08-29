function [trgroup,grouplbl,shortname,longname] = groupTrialsByTarget(task,params)
shortname = 'tgt';
longname = 'Target';

% compatibility
assert(isa(task,'FrameworkTask'),'Must provide a FrameworkTask object, not ''%s''',class(task));
Parameters.validate(params,mfilename('fullpath'));

% identify target number
if isfield(task.trialdata(1).tr_prm,'targetID')
    tgt = arrayfun(@(x)x.tr_prm.targetID,task.trialdata);
else
    keyboard;
end

% create trial groups for each of the possible overlaps (require success)
grouplbl = unique(tgt);
trgroup = cell(1,length(grouplbl));
for kk=1:length(grouplbl)
    trgroup{kk} = find(ismember(tgt,grouplbl(kk)));
end

% remove groups without enough trials
numtrials = cellfun(@length,trgroup);
trgroup(numtrials<params.dt.mintrialspercat)=[];
grouplbl(numtrials<params.dt.mintrialspercat)=[];
assert(numel(trgroup)>1,'Too few trial groups');