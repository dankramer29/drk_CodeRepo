function tag = getCacheTag(task,fname,varargin)
% GETCACHETAG Get the hash string and base string for a dataset
%
%   TAG = GETCACHETAG(TASK,FNAME)
%   For the FRAMEWORKTASK object TASK and file identifier FNAME, produce a
%   CACHE.TAGGABLE object TAG which represents the identifying tag for the
%   relevant data in the cache. The tagging information will include:
%
%     taskname
%     subject
%     session
%     taskstring
%     mfilename
tag = cache.Taggable(...
    'taskname',task.taskName,...
    'subject',task.subject,...
    'session',task.session,...
    'taskstring',task.taskString,...
    'mfilename',fname,...
    varargin{:});