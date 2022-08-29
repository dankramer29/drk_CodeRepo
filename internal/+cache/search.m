function match_files = search(trm,varargin)
% SEARCH Search for a string in cached files
%
%   MATCH_FILES = SEARCH(TRM)
%   Search for the term TRM in the cache, and return a list of cache files
%   MATCH_FILES. Specifically, SEARCH looks in the FILE and NAME fields of
%   the DBSTACK entry included when the cache entry was originally saved.
%
%   MATCH_FILES = SEARCH(...,'CACHEDIR',/PATH/TO/CACHE')
%   Look in the specified cache directory. Specify multiple locations as a
%   cell array of strings. All provided values must be full paths to
%   existing directories. The default value is the HST Environment Variable
%   CACHE.

% specify the cache directory to process
cachedir = env.get('cache');
idx = strcmpi(varargin,'cachedir');
if any(idx)
    cachedir = varargin{circshift(idx,1,2)};
    varargin(idx|circshift(idx,1,2)) = [];
end
cachedir = util.ascell(cachedir);
assert(all(cellfun(@(x)exist(x,'dir')==7,cachedir)),'Must provide full path to existing directory');

% process the cache directories
match_files = cell(1,length(cachedir));
for dd=1:length(cachedir)
    match_files{dd} = process_dir(cachedir{dd},trm);
end

% concatenate match_files entries and remove empty entries
match_files = cat(2,match_files{:});



function match_files = process_dir(cdir,trm)

% get a list of files/directories in the cache directory
info = dir(cdir);

% remove '.' and '..'
info(~cellfun(@isempty,regexpi({info.name},'^\.+$'))) = [];

% loop over the remaining entries
match_files = cell(1,length(info));
for ff=1:length(info)
    
    % process directories or files
    if info(ff).isdir
        
        % process the directory
        match_files{ff} = process_dir(fullfile(cdir,info(ff).name),trm);
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
            local_match = process_file(cachefile,trm);
        catch ME
            
            % release the cache lock before erroring out
            cache.release(cachefile);
            rethrow(ME);
        end
        
        % release the cache lock
        cache.release(cachefile);
        
        % update entry
        if local_match
            match_files{ff} = {cachefile};
        end
    end
end

% concatenate match_files entries and remove empty entries
match_files = cat(2,match_files{:});



function match = process_file(cfile,trm)
match = false;

% validate the input file
[~,~,cext] = fileparts(cfile);
assert(exist(cfile,'file')==2,'Must provide full path to existing file');
assert(strcmpi(cext,'.mat'),'Files must be *.mat, not ''%s''',cext);

% check for existence of 'lastaccess' field
vars = util.matwho(cfile);

% remove cache file if no lastaccess var
if ~any(strcmpi(vars,'meta'))
    return;
end

% load the 'lastaccess' field
val = load(cfile,'meta');
match = any(~cellfun(@isempty,regexpi({val.meta.dbstack.file},trm)));
if ~match
    match = any(~cellfun(@isempty,regexpi({val.meta.dbstack.name},trm)));
end