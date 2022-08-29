function cleanup(varargin)
% CLEANUP Remove unused cache files
%
%   CLEANUP
%   Remove all cache files that have not been accessed in the last 30 days.
%
%   CLEANUP(...,'DAYS',N)
%   Specify the number of past days N in which a cache file must have been
%   accessed to avoid being invalidated. Default is 30.
%
%   CLEANUP(...,'CACHEDIR','/PATH/TO/CACHE')
%   Specify the cache directory to process as a char. Specify multiple
%   cache directories as a cell array of chars. The strings must represent
%   a full path to an existing directory. Default is the value of the HST
%   Environment Variable CACHE.

% number of past days in which file must have been accessed
days = 30;
idx = strcmpi(varargin,'days');
if any(idx)
    days = varargin{circshift(idx,1,2)};
    varargin(idx|circshift(idx,1,2)) = [];
end
assert(isempty(varargin),'Unexpected inputs');

% log function
[varargin,logfcn] = cache.helper.getLogFcn(varargin);

% specify the cache directory to process
cachedir = env.get('cache');
idx = strcmpi(varargin,'cachedir');
if any(idx)
    cachedir = varargin{circshift(idx,1,2)};
    varargin(idx|circshift(idx,1,2)) = [];
end
cachedir = util.ascell(cachedir);
assert(all(cellfun(@(x)exist(x,'dir')==7,cachedir)),'Must provide full path to existing directory');
assert(isempty(varargin),'Unexpected or unused inputs');

% set a common current date
t_now = now;

% process the cache directories
num_keep = nan(1,length(cachedir));
num_delete = nan(1,length(cachedir));
for dd=1:length(cachedir)
    [num_keep(dd),num_delete(dd)] = process_dir(cachedir{dd},t_now,days,logfcn);
    msg = sprintf('%s: removed %d/%d (%d remaining)',cachedir{dd},num_delete(dd),num_keep(dd)+num_delete(dd),num_keep(dd));
    cache.log(logfcn,msg,'info');
end



function [num_keep,num_delete] = process_dir(cdir,t_now,days,logfcn)
num_keep = 0;
num_delete = 0;

% get a list of files/directories in the cache directory
info = dir(cdir);

% remove '.' and '..'
info(~cellfun(@isempty,regexpi({info.name},'^\.+$'))) = [];

% loop over the remaining entries
for ff=1:length(info)
    
    % process directories or files
    if info(ff).isdir
        
        % process the directory
        [local_keep,local_delete] = process_dir(fullfile(cdir,info(ff).name),t_now,days,logfcn);
        num_keep = num_keep + local_keep;
        num_delete = num_delete + local_delete;
        msg = sprintf('%s: removed %d/%d (%d remaining)',fullfile(cdir,info(ff).name),local_delete,local_keep+local_delete,local_keep);
        cache.log(logfcn,msg,'debug');
    else
        
        % construct the full path to the cache file
        cachefile = fullfile(cdir,info(ff).name);
        
        % if the cache file is locked, wait for it to become available again
        if cache.locked(cachefile)
            cache.wait(cachefile);
        end
        
        % lock the cache file
        cache.lock(cachefile);
        
        % process file in try-catch in case of problems
        try
            local_keep = process_file(cachefile,t_now,days,logfcn);
        catch ME
            
            % release the cache lock before erroring out
            cache.release(cachefile);
            rethrow(ME);
        end
        
        % remove the file if indicated
        if ~local_keep
            
            % wrap in try-catch in case of problems
            try
                delete(cachefile);
            catch ME
                
                % release the cache lock before erroring out
                cache.release(cachefile);
                rethrow(ME);
            end
        end
        
        % release the cache lock
        cache.release(cachefile);
        
        % update counters
        num_keep = num_keep + local_keep;
        num_delete = num_delete + ~local_keep;
    end
end



function keep = process_file(cfile,t_now,days,logfcn)
keep = true;

% validate the input file
[~,~,cext] = fileparts(cfile);
assert(exist(cfile,'file')==2,'Must provide full path to existing file');
assert(strcmpi(cext,'.mat'),'Files must be *.mat, not ''%s''',cext);

% check for existence of 'lastaccess' field
vars = util.matwho(cfile);

% remove cache file if no lastaccess var
if ~any(strcmpi(vars,'lastaccess'))
    keep = false;
    msg = sprintf('%s: delete (no ''lastaccess'' entry)',cfile);
    cache.log(logfcn,msg,'debug');
    return;
end

% load the 'lastaccess' field
val = load(cfile,'lastaccess');
t_access = datenum(val.lastaccess);
num_days = t_now-t_access;
assert(num_days>0,'Access time for %s is in the future',cfile);
if num_days>days
    keep = false;
    msg = sprintf('%s: delete (last access %.1f days ago but threshold was %d days)',cfile,num_days,days);
    cache.log(logfcn,msg,'debug');
    return;
end