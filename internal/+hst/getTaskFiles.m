function list = getTaskFiles(taskname,varargin)
% GETTASKFILES Get a list of files associated with one run of a task
%
%   LIST = GETTASKFILES(TASKNAME,SESSION)
%   Get a cell array of strings listing the full path to all files
%   associated with the the task TASKNAME for the session ID SESSION.
%
%   NOTE: INCOMPLETE DOCUMENTATION.

% fast or thorough operation
[varargin,flag_fast] = util.argkeyword({'fast','thorough'},varargin,'fast');
flag_fast = strcmpi(flag_fast,'fast');
[varargin,pid] = util.argfn(@(x)ischar(x)&&hst.isValidPatient(x),varargin,'');
pid = lower(pid);
assert(~isempty(pid),'Must provide a valid patient ID');

% get session
session = hst.getSessionDates(pid,varargin{:});
assert(~isempty(session),'No session found (subject ''%s'')',pid);
assert(~iscell(session)||length(session)==1,'Must process one session at a time, not %d',length(session));
if iscell(session),session=session{1};end
assert(ischar(session),'Must provide a valid session string, not a ''%s''',class(session));

% get the path to the session
sessionPath = hst.getSessionPath(session,pid);
assert(~isempty(sessionPath),'Could not find session ''%s'' for subject ''%s''',session,pid);

% get list of all mat files in the task directory
flist = dir(fullfile(sessionPath,'Task','*.mat'));

% not the . or .. entries
dotname = arrayfun(@(x)strncmpi(x.name,'.',1),flist);
flist( dotname ) = [];

% must not be directory
flist( [flist.isdir] ) = [];

% search for tasks in the task files
list = {};
for kk=1:length(flist)
    
    % try to pull the task name from the file name first, then by loading
    % in the MAT file and searching the struct
    
    % match decoder
    tokens_decoder = regexp(flist(kk).name,'(decoder)','tokens');
    
    % filename assumption: YYYYMMDD-HHMMSS-HHMMSS_(taskname)_...
    tokens_fw1 = regexp(flist(kk).name,'^\d{8}-\d{6}-\d{6}[-_]([^.]+)','tokens');
    
    % filename assumption: YYYYMMDD-HHMMSS_(taskname)_...
    tokens_fw2 = regexp(flist(kk).name,'^\d{8}-\d{6}[-_]([^.]+)','tokens');
    
    % check for matches
    if ~isempty(tokens_decoder)
        continue;
    elseif ~isempty(tokens_fw1)
        if ~strcmpi(tokens_fw1{1},'framework')
            if strcmpi(tokens_fw1{1}{1},taskname)
                list{end+1} = fullfile(sessionPath,'Task',flist(kk).name);
            end
        elseif strcmpi(tokens_fw1{1},'decoder')
            continue;
        end
    elseif ~isempty(tokens_fw2) && ~strcmpi(tokens_fw2{1},'framework')
        if strcmpi(tokens_fw2{1}{1},taskname)
            list{end+1} = fullfile(sessionPath,'Task',flist(kk).name);
        end
    else
        
        % create full path to file
        taskFile = fullfile(sessionPath,'Task',flist(kk).name);
        assert(exist(taskFile,'file')==2,'Could not locate task file ''%s''',taskFile);
        
        % get list of variables in the file
        try
            vars = Utilities.matwho( taskFile );
        catch ME
            Utilities.errorMessage(ME);
            continue;
        end
        
        % handle file differently if +Science, +Framework
        if any(strcmpi(vars,'saveData'))
            try
                task = load(taskFile);
                if isfield(task.saveData,'experimentInfo')
                    % saveData.experimentInfo.params.ExperimentName
                    name = task.saveData.experimentInfo.params.ExperimentName;
                elseif isfield(task.saveData,'ExperimentDescription')
                    % saveData.ExperimentDescription
                    name = task.saveData.ExperimentDescription;
                end
            catch ME
                Utilities.errorMessage(ME);
                keyboard
                continue;
            end
            if strcmpi(name,taskname)
                list{end+1} = fullfile(sessionPath,'Task',flist(kk).name);
            end
        elseif any(strcmpi(vars,'Block')) || (any(strcmpi(vars,'Data')) && any(strcmpi(vars,'Options')) && any(strcmpi(vars,'Task')))
            if any(strcmpi(vars,'Block'))
                task = load(taskFile);
            else
                task.Block = load(taskFile);
            end
            for bb=1:length(task.Block)
                try
                    if isfield(task.Block(1),'Options')
                        
                        % use Framework.Options.taskConstructor field
                        name = task.Block(1).Options.taskConstructor;
                        name = strsplit(name,'.');
                    elseif isfield(task.Block(1),'OPTIONS')
                        
                        % use Framework.Options.taskConstructor field
                        name = task.Block(1).OPTIONS.taskConstructor;
                        if isa(name,'function_handle')
                            name = func2str(name);
                        end
                        name = strsplit(name,'.');
                    else
                        keyboard
                    end
                    if strcmpi(name{1},'Experiment')
                        if length(name)==3
                            
                            % Experiment.Task.(taskname)
                            name = name{3};
                        elseif length(name)==2
                            
                            % Experiment.(taskname)
                            name = name{2};
                        else
                            keyboard
                        end
                    elseif strcmpi(name{1},'Experiment2')
                        % Experiment2.(taskname).Task
                        name = name{2};
                    elseif strcmpi(name{1},'Task')
                        % Task.(taskname).Task
                        name = name{2};
                    end
                catch ME
                    Utilities.errorMessage(ME);
                    continue;
                end
                if strcmpi(name,taskname)
                    list{end+1} = fullfile(sessionPath,'Task',flist(kk).name);
                end
            end
        else
            if ~flag_fast
                task = load(taskFile);
                if isfield(task,'saveStruct')
                    continue;
                end
            end
            if flag_fast
                fprintf('Could not identify the task for "%s"',taskFile);
            else
                fprintf('Could not identify the task for "%s": please figure it out and hit F5 to continue',taskFile);
                keyboard
            end
        end
    end
end

% only return a single instance of each task name
list = unique(list);