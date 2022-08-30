function islocked = locked(str)
% LOCKED check whether cache file is locked for access
%
%   LOCKED(STR)
%   Check whether resource identified by STR is locked for access.
%   Generally, provide the cache file name as STR.
islocked = false;

% check current cache locks
cachelock = env.get('cachelock');
if ~isempty(cachelock)
    
    % one or more thing(s) are locked, so check whether our string is
    cachelock = util.str2cell(cachelock);
    idx = strcmpi(cachelock,str);
    islocked = any(idx);
end