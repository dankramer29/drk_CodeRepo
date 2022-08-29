function cl = str2cell(str,varargin)
% STR2CELL split string into a cell array
%
%   CL = STR2CELL(STR)
%   Split the string STR into a cell array CL.  By default, the 
%   separating character is a comma ",".
%
%   CL = STR2CELL(STR,SEP)
%   Replaces the separating character with the value in SEP.
%
%   See also CELL2STR.

% handle empty corner case
if isempty(str)
    cl = {};
    return;
end

% separating character
sep = {',','|','#'}; % support 3 levels of cell-string hierarchy (deepest level first)
if nargin>1, sep = varargin{1}; end
sep = util.ascell(sep);

% validate input
assert(ischar(str),'Input must be char');
assert(iscell(sep),'Separating character(s) must be char or cell array of char');

% split the string
cl = splitstring(str,sep);
cl = util.ascell(cl);

% remove empty cells
cl(cellfun(@isempty,cl)) = [];



function cl = splitstring(str,sep)

cl = strsplit(str,sep{end});
if iscell(cl)&&length(cl)==1,cl=cl{1};end
if length(sep)==1,return;end
if ischar(cl)
    cl = splitstring(cl,sep(1:end-1));
else
    for kk=1:length(cl)
        cl{kk} = splitstring(cl{kk},sep(1:end-1));
    end
end