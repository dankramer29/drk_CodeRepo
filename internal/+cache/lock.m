function lock(str)
% LOCK lock a cache file for access
%
%   LOCK(STR)
%   Lock the resource identified by STR. Generally, provide the cache file
%   name as STR.

% check current cache locks
cachelock = env.get('cachelock');
if isempty(cachelock)
    
    % nothing locked, so set to current string
    cachelock = {str};
else
    
    % one or more thing(s) are locked, so check whether our string is
    cachelock = util.str2cell(cachelock);
    idx = strcmpi(cachelock,str);
    assert(~any(idx),'Cache is locked for ''%s''',cachelock{idx});
    cachelock = [cachelock {str}];
end

% save the updated lock
env.set('cachelock',util.cell2str(cachelock));