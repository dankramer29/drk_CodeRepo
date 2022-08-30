function [srcfile,srcname,srcline] = getSourceFromStack(st,skip)
% Pull out a source from a call stack or error stack
%
%   SRC = GETSOURCEFROMSTACK(ST,SKIP)
%   Get the source from the stack ST, skipping any preliminary entries
%   matching any of the strings in the cell array SKIP.

% default empty skip
if nargin<2||isempty(skip),skip={};end
skip = util.ascell(skip);

% identify the source
idx = 1;
while idx<length(st) && ~all(cellfun(@isempty,regexpi(st(idx).name,skip)))
    idx = idx+1;
end
srcfile = st(idx).file;
srcname = st(idx).name;
srcline=  st(idx).line;