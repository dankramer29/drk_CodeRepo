function varargout = load(tag,varargin)
% LOAD Load data from the cache
%
%   VARARGOUT = LOAD(TAG)
%   Load data identified by cache tag TAG.  The same number of outputs will
%   be (must be) returned as were originally cached. Note that this
%   function assumes the data are cached and valid.
%
%   See also CACHE.CACHEABLE, CACHE.QUERY, CACHE.SAVE.
varargout = cell(1,nargout); % default empty
local_tmr = tic;

% validate tag input
if isobject(tag)
    assert(isa(tag,'util.Structable'),'If it is an object, tag input must be Structable');
    assert(isa(tag,'cache.Taggable'),'If it is an object, tag input must be Taggable');
    cachebasename = tag.hash;
else
    cachebasename = tag;
end
assert(ischar(cachebasename)&&isempty(regexpi(cachebasename,'[^a-f0-9]+')),'Cache basename must be char made up of alphanumeric characters in the hexadecimal character set');

% debugger
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,nan);
if ~found_debug,debug=Debug.Debugger('cache');end

% process consolidate input
idx = strcmpi(varargin,'consolidate');
flagConsolidate = false;
if any(idx)
    flagConsolidate = true;
    varargin(idx|circshift(idx,1,2)) = [];
end
assert(isempty(varargin),'Unexpected inputs');

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

% return immediately if not cached
assert(any(cached),'No cache entry exists for ''%s''',cachebasename);

% select the first of the cache locations
idx = find(cached);
if flagConsolidate && ~ismember(1,idx)
    debug.log(sprintf('Consolidating cache file from ''%s'' to ''%s''',cachefile{idx(1)},cachefile{1}),'debug');
    copyfile(cachefile{idx(1)},cachefile{1});
    idx = 1;
end
cachefile = cachefile{idx(1)};

% if the cache file is locked, wait for it to become available again
if cache.locked(cachefile)
    %id = cache.hash(now);
    %cache.request(cachefile,id);
    cache.wait(cachefile);%,id);
end

% lock the cache file
cache.lock(cachefile);

% load the cached data and assign outputs
try
    tmp = load(cachefile);
catch ME
    
    % release the cache lock before erroring out
    cache.release(cachefile);
    rethrow(ME);
end

% add a timestamp to the cached data file
try
    lastaccess = now;
    save(cachefile,'lastaccess','-append');
catch ME
    
    % release the cache lock before erroring out
    cache.release(cachefile);
    rethrow(ME);
end

% release the cache lock
cache.release(cachefile);

% validate outputs
for kk=1:nargout
    assert(isfield(tmp,sprintf('arg%02d',kk)),'Missing argument %d in the cached data',kk);
    varargout{kk} = tmp.(sprintf('arg%02d',kk));
end

% report the time it took to load the cached data
tmr = toc(local_tmr);
debug.log(sprintf('Took %.2f seconds to load cache entry ''%s''',tmr,cachebasename),'debug');