function wait(cachefile,res,maxiter)
% WAIT Pause execution until a cache file is available (unlocked)
%
%   WAIT(CACHEFILE)
%   While the cache entry CACHEFILE is locked, continue to check the lock
%   every 0.1 sec up to 100 times (10 sec wait total).
%
%   WAIT(CACHEFILE,RES)
%   Specify the time resolution RES in milliseconds.
%
%   WAIT(CACHEFILE,RES,MAXITER)
%   Specify the maximum number of iterations.
%
% NOTE: There is a potential race condition where multiple processes are
% waiting on a single locked resource since the process of checking the
% lock then acquiring the lock is not atomic (i.e., process 1 could check,
% assume resource available, and try to acquire the lock but fail since
% process 2 could have acquired the lock in the time since process 1
% checked it. One thought on a solution for this issue is to have a queue,
% likely stored as a series of unique IDs in an environment variable, that
% controls the order of access to the queue (first in, first access).
if nargin<2||isempty(res),res=100;end
if nargin<3||isempty(maxiter),maxiter=100;end

% start checking the cache lock at regular intervals
iter=0;
while iter<=maxiter && cache.locked(cachefile)
    
    % sleep
    java.lang.Thread.sleep(res);
    
    % increment iteration counter
    iter=iter+1;
end

% throw an error if the cache file is still locked
assert(~cache.locked(cachefile),'After %d iterations (%.2f sec time steps) cache file ''%s'' is still locked',iter,res/1e3,cachefile);