function [task,blc,map] = getAnalysisObjects(task,debug,varargin)
[varargin,poison_strings] = util.argkeyval('poison_strings',varargin,{'test run','do not use'});
if ~iscell(poison_strings),poison_strings={poison_strings};end
[varargin,neural_data_type] = util.argkeyval('neural_data_type',varargin,'blc');
[varargin,neural_data_fs] = util.argkeyval('neural_data_fs',varargin,'fs2k');
[varargin,neural_data_lmtype] = util.argkeyval('neural_data_lmtype',varargin,'none'); % 'lmresid','lmfit','none'
[varargin,neural_data_lmcontext] = util.argkeyval('neural_data_lmcontext',varargin,'grid'); % 'grid','file'
if strcmpi(neural_data_lmtype,'none')
    neural_data_lm = {};
else
    neural_data_lm = {neural_data_lmtype,'lmcontext',neural_data_lmcontext};
end
util.argempty(varargin);

% load task and data objects
if ischar(task)
    task = FrameworkTask(task,debug);
else
    assert(isa(task,'FrameworkTask'),'must provide path to task file or FrameworkTask object');
end
poison_match = nan(1,length(poison_strings));
for kk=1:length(poison_strings)
    poison_match(kk) = ~isempty(regexpi(task.userEndComment,poison_strings{kk}));
end
assert(~any(poison_match),'User end comment contains poison string "%s"',poison_strings{find(poison_match,1,'first')});
blc = task.getNeuralDataObject(neural_data_type,neural_data_fs,neural_data_lm{:});
blc = blc{1};
map = task.getGridMapObject(neural_data_fs); map=map{1};