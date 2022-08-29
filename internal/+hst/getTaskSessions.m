function list = getTaskSessions(task,varargin)
% GETTASKSESSIONS Identify sessions in which a particular task was run
%
%   This function operates by looping over each available session (see
%   HST.GETSESSIONLIST), getting a list of all tasks for that session (see
%   HST.GETSESSIONTASKS), and then checking to see whether TASK matches any
%   of those. Because these actions require reading data from disk over
%   many directories (and often over a network connection), it can be very
%   slow to look for something over all sessions.
%
%   LIST = GETTASKSESSIONS(TASK,PATIENT)
%   At a minimum, provide a task name TASK and a patient ID PATIENT, and
%   the sessions in which TASK was run with PATIENT will be returned in
%   LIST (a cell array of strings).
%
%   LIST = GETTASKSESSIONS(...,SESSION)
%   LIST = GETTASKSESSIONS(...,SESSION1,SESSION2)
%   Search for a session folder matching the name SESSION, or search for
%   all session folders between SESSION1 and SESSION2 (inclusive).  Assumes
%   session folders are named according to date, i.e. YYYYMMDD.
%
%   LIST = GETTASKSESSIONS(...,DBG)
%   Provide a DEBUG.DEBUGGER object DBG.
%
%   LIST = GETTASKSESSIONS(...,'CACHE')
%   LIST = GETTASKSESSIONS(...,'NOCACHE')
%   By default, this function will use a CACHE package if available to
%   cache results and speed up operation. If the cache is requested but is
%   not available, an error will be generated. If the cache is not
%   available and the user does not request it, it will not be enabled. If
%   the cache is available but the user specifies NOCACHE, it will not be
%   used.
list = {};

% inputs
cacheavail = util.existp('cache','package')==9;
[varargin,cacheread] = util.argkeyval('cacheread',varargin,cacheavail);
[varargin,cachewrite] = util.argkeyval('cachewrite',varargin,cacheavail);
if (cacheread||cachewrite)&&~cacheavail
    warn('Caching was requested, but could not find caching API; disabling cache capabilities');
    cacheread = false;
    cachewrite = false;
end
[varargin,debug,found] = util.argisa('Debug.Debugger',varargin,{});
if ~found,debug=Debug.Debugger('getTaskSessions');end
[varargin,dates] = util.argfns(@(x)ischar(x)&&~isempty(regexpi(x,'^\d{8}$')),varargin,{});
dates = util.ascell(dates);
[varargin,patient,found] = util.argfn(@(x)ischar(x)&&hst.isValidPatient(x),varargin,'');
assert(found,'Must provide a patient ID');
assert(hst.isValidPatient(patient),'Must provide a valid patient ID');
util.argempty(varargin);

% get a list of the requested sessions and all sessions for the patient
[requestedSessionList,~,~,fullSessionList_actual] = hst.getSessionList(patient,dates{:},'UniformOutput',false);
if isempty(requestedSessionList),return;end

% create the cache tag
if cacheread || cachewrite
    prm.fullSessionList = fullSessionList_actual;
    tag = cache.Taggable('mfilename',mfilename,'taskname',lower(task),'patient',lower(patient));
end

% check the cache; "cached" means that the data are available in the cache;
% "update" means that we need to process one or more new sessions and add
% them to the cache
[cached,update] = checkcache(tag,prm,cacheread,debug);

% load from the cache, or initialize to empty
fullSessionList_cached = {};
list = {};
if cached
    
    % load from cache
    list = cache.load(tag,debug);
    prm = cache.params(tag,debug);
    fullSessionList_cached = prm.fullSessionList;
end

% update the list if needed
if update
    
    % loop over sessions
    found = false(1,length(fullSessionList_actual));
    for ss=1:length(fullSessionList_actual)
        
        % if this session is already listed as containing the task of
        % interest, mark it as found; otherwise, if the task is not in the
        % complete set of cached sessions, process it.
        if ismember(fullSessionList_actual{ss},fullSessionList_cached)
            found(ss) = ismember(fullSessionList_actual{ss},list);
        elseif ~ismember(fullSessionList_actual{ss},fullSessionList_cached)
            msg = sprintf('Processing session %s',fullSessionList_actual{ss});
            debug.log(msg,'info');
            
            % get list of tasks from this session
            try
                taskList = hst.getSessionTasks(patient,fullSessionList_actual{ss},'logfcn',debug);
            catch ME
                util.errorMessage(ME);
            end
            
            % check for requested task
            found(ss) = any(strcmpi(taskList,task));
        end
    end
    
    % return the task list
    list = fullSessionList_actual(found);
    
    % save the result to the cache
    if cachewrite
        prm.fullSessionList = fullSessionList_actual;
        cache.save(tag,prm,'logfcn',debug,list);
    end
end

% subselect to requested sessions
list = list(ismember(list,requestedSessionList));


function [cached,update] = checkcache(tag,prm,cacheread,debug)
% cached - whether the data are cached
% update - whether we need to process new sessions and update cached data
if cacheread
    update = false;
    
    % cache package exists
    [cached,valid] = cache.query(tag,prm,debug);
    if ~cached || ~valid
        update = true;
    end
else
    
    % no caching
    cached = false;
    update = true;
end