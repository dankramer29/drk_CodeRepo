function delete(tag)
% DELETE Delete cached data
%
%   DELETE(CACHEBASENAME)
%   Delete cached data identified by basename CACHEBASENAME

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
[userdir,cachebasename,~] = fileparts(cachebasename);
if ~isempty(userdir),cachedir={userdir};end

% construct full path to cache file
cachesub = cachebasename(1:2);
cachefiles = cellfun(@(x)fullfile(x,cachesub,sprintf('%s.mat',cachebasename)),cachedir,'UniformOutput',false);
cached = cellfun(@(x)exist(x,'file')==2,cachefiles);

% return immediately if no matching cached file
if ~any(cached),return;end

% loop over cache directories containing this cached data
cdidx = find(cached);
for dd=cdidx(:)'
    cachefile = cachefiles{dd};
    
    % if the cache file is locked, wait for it to become available again
    if cache.locked(cachefile)
        cache.wait(cachefile);
    end
    
    % lock the cache file
    cache.lock(cachefile);
    
    % delete the cached file
    try
        delete(cachefile);
    catch ME
        
        % release the cache lock before erroring out
        cache.release(cachefile);
        rethrow(ME);
    end
    
    % release the cache lock
    cache.release(cachefile);
end