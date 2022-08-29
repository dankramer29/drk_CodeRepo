function list = getSessionTasks(varargin)
list = {};

% fast or thorough operation
[varargin,flag_fast] = util.argkeyword({'FAST','THOROUGH'},varargin,'FAST');
flag_fast = strcmpi(flag_fast,'FAST');
[varargin,patient,found] = util.argfn(@(x)ischar(x)&&hst.isValidPatient(x),varargin,'');
assert(found,'Must provide a valid patient');
[varargin,flag_ignore_cache] = util.argflag('nocache',varargin,false);
cacheAvailable = util.existp('cache','package')==9;

% log function
logfcn = {{@simplelog},{}};
idx = strcmpi(varargin,'logfcn');
if any(idx)
    logfcn = varargin{circshift(idx,1,2)};
    varargin(idx|circshift(idx,1,2)) = [];
end
idx = cellfun(@(x)isa(x,'Debug.Debugger'),varargin);
if any(idx)
    debugger = varargin{idx};
    varargin(idx) = [];
    logfcn = {{@debugger.log},{}};
end

% get session
session = hst.getSessionList(patient,varargin{:});
assert(~isempty(session),'No session found (subject ''%s'')',patient);

% get the path to the session
sessionPath = hst.getSessionPath(session,patient);
assert(~isempty(sessionPath),'Could not find session ''%s'' for subject ''%s''',session,patient);

% check existence of task directory
taskPath = fullfile(sessionPath,'Task');
if exist(taskPath,'dir')~=7,return;end

% get list of all mat files in the task directory
flist = dir(fullfile(taskPath,'*.mat'));

% not the . or .. entries
dotname = arrayfun(@(x)strncmpi(x.name,'.',1),flist);
flist( dotname ) = [];

% must not be directory
flist( [flist.isdir] ) = [];
if isempty(flist),return;end

% check the cache against the file timestamps
if cacheAvailable && ~flag_ignore_cache
    prm.sessionPath = sessionPath;
    prm.flist = flist;
    prm.timestamp = max([flist.datenum]);
    hashstr = cache.hash([session patient]);
    [cached,valid] = cache.query(hashstr,prm,'logfcn',logfcn);
else
    cached = false;
    valid = false;
end
if cached && valid
    
    % load from cache
    list = cache.load(hashstr,'logfcn',logfcn);
else
    
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
                list{end+1} = tokens_fw1{1}{1};
            elseif strcmpi(tokens_fw1{1},'decoder')
                continue;
            end
        elseif ~isempty(tokens_fw2) && ~strcmpi(tokens_fw2{1},'framework')
            list{end+1} = tokens_fw2{1}{1};
        else
            
            % create full path to file
            taskFile = fullfile(taskPath,flist(kk).name);
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
                list{end+1} = name;
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
                    list{end+1} = name;
                end
            elseif ~isempty(strfind(taskFile,'blackjack')) && any(strcmpi(vars,'Task'))
                list{end+1} = 'Blackjack';
            else
                if ~flag_fast
                    task = load(taskFile);
                    if isfield(task,'saveStruct')
                        continue;
                    end
                end
                msg = sprintf('Could not identify the task for ''%s''',taskFile);
                log(logfcn,msg,'error');
                continue;
            end
        end
    end
    
    % only return a single instance of each task name
    list = unique(list);
    
    % save the data to the cache
    if cacheAvailable && ~flag_ignore_cache
        cache.save(hashstr,prm,'logfcn',logfcn,list);
    end
end


function log(logfcn,msg,priority)
feval(logfcn{1}{:},msg,priority,logfcn{2}{:});

function simplelog(msg,varargin)
fprintf('%s: %s\n',mfilename,msg);