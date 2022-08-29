function cachefile = save(tag,params,varargin)
% SAVE Save data into the cache
%
%   CACHEFILE = SAVE(CACHEBASENAME,PARAMOBJ,DATA1,DATA2,...)
%   Save data DATA1, DATA2, ... into the cache under the name CACHEBASENAME
%   and with the parameter signature defined by PARAMOBJ.  CACHEBASENAME
%   should be a char that would be a valid file basename.  PARAMOBJ should
%   be a struct or an object of class CACHEABLE.  DATA1, DATA2, ... are
%   individual variables to be saved under this signature.  Returns the
%   full path to the saved cache file in CACHEFILE.
%
%   See also CACHE.CACHEABLE, CACHE.QUERY, CACHE.SAVE.
local_tmr = tic;

% validate params input
if isobject(params)
    assert(isa(params,'util.Structable'),'If it is an object, params input must be Structable');
    assert(isa(params,'cache.Cacheable'),'If it is an object, params input must be Cacheable');
    params = params.toStruct;
end
assert(isstruct(params),'If it is not an object, params input must be a struct');

% validate tag input
if isobject(tag)
    assert(isa(tag,'util.Structable'),'If it is an object, tag input must be Structable');
    assert(isa(tag,'cache.Taggable'),'If it is an object, tag input must be Taggable');
    cachebasename = tag.hash;
    tag = tag.toStruct;
else
    cachebasename = tag;
end
assert(ischar(cachebasename)&&isempty(regexpi(cachebasename,'[^a-f0-9]+')),'Cache basename must be char made up of alphanumeric characters in the hexadecimal character set');

% debugger
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,nan);
if ~found_debug,debug=Debug.Debugger('cache');end

% save version
info = whos('varargin');
ver = {};
if info.bytes>2^31
    ver = {'-v7.3'};
    debug.log('switching to save v7.3 (cached data are larger than 2^31 bytes)','debug');
end

% default cache directory
cachedir = env.get('cache');

% check for overriding directory; kill any existing extension
[userdir,cachebasename,cacheext] = fileparts(cachebasename);
assert(isempty(cacheext)||strcmpi(cacheext,'.mat'),'Cache file must be a *.MAT file');
if ~isempty(userdir),cachedir={userdir};end

% construct full path to cache file
cachesub = cachebasename(1:2); % 16^2 = 256 subdirectories to reduce bloat in root cache directory
cachefile = cellfun(@(x)fullfile(x,cachesub,sprintf('%s.mat',cachebasename)),cachedir,'UniformOutput',false);
cached = cellfun(@(x)exist(x,'file')==2,cachefile);

% determine which cache directory to use
if any(cached)
    
    % select existing location if already cached
    idx = find(cached);
    cachefile = cachefile{idx(1)};
else
    
    % first cache directory takes priority
    cachefile = cachefile{1};
end

% create struct to save the data
assert(~isempty(varargin),'Must provide data to cache');
for kk=1:length(varargin)
    args.(sprintf('arg%02d',kk)) = varargin{kk};
end

% add parameter struct
args.params = params;

% add tag object
args.tag = tag;

% init meta information
args.meta.fileinfo = dir(cachefile);
args.meta.dbstack = dbstack;

% add access time
args.lastaccess = now;

% if the cache file is locked, wait for it to become available again
if cache.locked(cachefile)
    
    % prompt the user to retry, force release, or abort
    prompt = 'Cache file is locked! Retry, force, or cancel?';
    title = 'Locked Resource';
    defaultans = 'Force';
    options = {'Retry', 'Force', 'Cancel'};
    choice = questdlg(prompt,title,options{:},defaultans);
    
    % take user's requested action
    if strcmpi(choice,'Force')
        
        % force the cache file release and continue on
        cache.release(cachefile);
    elseif strcmpi(choice,'Cancel')
        
        % abort and return without further action
        return
    else
        
        % retry until user selects different action
        while strcmpi(choice,'Retry') && cache.locked(cachefile)
            choice = questdlg(prompt,title,options{:},defaultans);
            if strcmpi(choice,'Force')
                cache.release(cachefile);
            elseif strcmpi(choice,'Cancel')
                return
            end
        end
    end
    % id = cache.hash(now);
    % cache.request(cachefile,id);
    % cache.wait(cachefile,id);
end

% lock the cache file
cache.lock(cachefile);

% save the data
try
    cachefiledir = fileparts(cachefile);
    if exist(cachefiledir,'dir')~=7
        [status,errmsg] = mkdir(cachefiledir);
        assert(status>0,'Could not create directory for log file: %s',errmsg);
    end
    save(cachefile,'-struct','args',ver{:});
catch ME
    
    % release the cache lock before erroring out
    cache.release(cachefile);
    rethrow(ME);
end

% release the cache lock
cache.release(cachefile);

% log how long it took
tmr = toc(local_tmr);
debug.log(sprintf('Took %.2f seconds to save cache entry ''%s''',tmr,cachebasename),'debug');