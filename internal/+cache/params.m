function prm = params(tag,varargin)
% PARAMS Get the cached parameters for a given cache tag
%
%   PRM = PARAMS(TAG)
%   For the CACHE.TAGGABLE object TAG (or hash string TAG), load the
%   parameters associated with the cached data.
%
%   See also CACHE.CACHEABLE, CACHE.QUERY, CACHE.SAVE, CACHE.WAIT.

% log function
[varargin,logfcn] = cache.helper.getLogFcn(varargin);
assert(isempty(varargin),'Unknown inputs');

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

% raise an error if not cached
assert(any(cached),'No such data exist in the cache');

% warn if multiple matches
if ~cached(1) && nnz(cached)>0
    msg = sprintf('Cached data ''%s'' resides in secondary location(s): %s',cachebasename,strjoin(cachedir(cached)));
    cache.log(logfcn,msg,'debug');
end

% select the first of the cache locations
idx = find(cached,1,'first');
cachefile = cachefile{idx};

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
    assert(isfield(tmp,'params'),'Could not find params struct in cached file');
catch ME
    
    % release the cache lock before exiting
    cache.release(cachefile);
    rethrow(ME);
end

% release the cache lock
cache.release(cachefile);

% set the output
prm = tmp.params;