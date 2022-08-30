function [cached,valid,prop,cachefile] = query(tag,params,varargin)
% QUERY Check whether something is cached and whether it is valid.
%
%   [CACHED,VALID,FILE,PROP] = QUERY(TAG,PARAMOBJ)
%   For the parameters defined in PARAMOBJ and the cache tag in TAG, check
%   whether the data are cached (logical output CACHED) and if so, whether
%   they are valid (logical output VALID). PARAMOBJ should be either a
%   struct or an object of class CACHEABLE. TAG should be a char used to
%   create the cached data originally, or a CACHE.TAGGABLE object. The full
%   path to the cached file is returned in FILE. If VALID is false, PROP
%   will contain the name of the offending property.
%
%   ... = QUERY(TAG,PARAMOBJ,PROP1,PROP2,...)
%   ... = QUERY(TAG,PARAMOBJ,'IGNORE',PROP1,PROP2,...)
%   Specify properties of PARAMOBJ to ignore when determining validity.
%
%   ... = QUERY(TAG,PARAMOBJ,'REQUIRE',PROP1,PROP2,...)
%   Specify properties of PARAMOBJ to require when determining validity.
%
%   See also CACHE.CACHEABLE, CACHE.QUERY, CACHE.SAVE, CACHE.WAIT.

% defaults false
valid = false;
prop = [];

% log function
[varargin,debug,found] = util.argisa('Debug.Debugger',varargin,nan);
if ~found,debug=Debug.Debugger('cache');end

% validate tag input
if isobject(tag)
    assert(isa(tag,'util.Structable'),'If it is an object, tag input must be Structable');
    assert(isa(tag,'cache.Taggable'),'If it is an object, tag input must be Taggable');
    cachebasename = tag.hash;
else
    cachebasename = tag;
end
assert(ischar(cachebasename)&&isempty(regexpi(cachebasename,'[^a-f0-9]+')),'Cache basename must be char made up of alphanumeric characters in the hexadecimal character set');

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
if ~any(cached)
    cached = false;
    debug.log(sprintf('No cache entry for ''%s''',cachebasename),'debug');
    return;
end

% warn if multiple matches
if ~cached(1) && nnz(cached)>0
    debug.log(sprintf('Cache entry ''%s'' resides in secondary location(s): %s',cachebasename,strjoin(cachedir(cached))),'debug');
end

% select the first of the cache locations
idx = find(cached,1,'first');
cachefile = cachefile{idx};
cached = cached(idx(1));

% if the cache file is locked, wait for it to become available again
if cache.locked(cachefile)
    %id = cache.hash(now);
    %cache.request(cachefile,id);
    cache.wait(cachefile);%,id);
end

% lock the cache file
cache.lock(cachefile);

% load cached parameters
try
    tmp = load(cachefile,'params');
    assert(isfield(tmp,'params'),'Could not find params struct in cache entry %s',cachebasename);
catch ME
    
    % release the cache lock before exiting
    cache.release(cachefile);
    rethrow(ME);
end

% release the cache lock
cache.release(cachefile);

% compare new parameters
if isstruct(params)
    [valid,prop] = cache.isEqualStruct(params,tmp.params,varargin{:});
elseif isobject(params) && isa(params,'cache.Cacheable')
    [valid,prop] = isEqual(params,tmp.params,varargin{:});
else
    error('Unknown format for parameters input');
end

% print out info if cached but not valid
if cached && ~valid
    debug.log(sprintf('Cache entry %s invalid due to property ''%s''',cachebasename,prop),'info');
end