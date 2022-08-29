function release(str)
% RELEASE Release a cache file from the locked state
%
%   RELEASE
%   Release all currently locked resources.
%
%   RELEASE(STR)
%   Release the resource identified by STR. Generally, provide the cache
%   file name as STR.

% check current cache locks
cachelock = env.get('cachelock');
cachelock = util.str2cell(cachelock);

% unlock everything if no inputs, otherwise unlock specified only
if nargin==0 || isempty(str)
    
    % remove all locks
    cachelock = {};
else
    
    % identify user specified resources
    idx = strcmpi(cachelock,str);
    assert(any(idx),'There is no cache lock for ''%s''',str);
    assert(nnz(idx)==1,'There can only be one cache lock for the resource ''%s''! Check caching logic',str);
    
    % remove the lock for STR
    cachelock(idx) = [];
end

% release the cache lock
env.set('cachelock',util.cell2str(cachelock));