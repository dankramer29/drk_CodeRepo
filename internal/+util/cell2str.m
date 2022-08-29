function str = cell2str(cl,varargin)
% CELL2STR concatenate cell elements into a single string
%
%   STR = CELL2STR(CL)
%   Concatenates the cell elements in CL into the string STR.  CL must have
%   a singleton dimensions, and all elements of CL must be char.  By
%   default, the concatenating character is a comma ",".
%
%   STR = CELL2STR(CL,SEP)
%   Replaces the separating character with the value in SEP.
%
%   See also STR2CELL.

% handle empty corner case
if isempty(cl)
    str = '';
    return;
end

% handle string case
if ischar(cl)
    str = cl;
    return;
end

% separating character
sep = {',','|','#'}; % support 3 levels of cell-string hierarchy (deepest level first)
if nargin>1,sep=varargin{1}; end
sep = util.ascell(sep);
depth = 1;
if nargin>2,depth=varargin{2}; end

% validate input
assert(iscell(cl),'Input must be a cell array');
assert(min(size(cl))==1,'Cell input must have a singleton dimension');
assert(nnz(size(cl))==2,'Cell input must be 1xN or Nx1');
assert(all(cellfun(@iscell,cl)|cellfun(@ischar,cl)),'Each element in the cell input must be a char');
assert(iscell(sep)&all(cellfun(@ischar,sep)),'Separating character(s) must be char or cell array of char');

% first pass: identify the depth of the cell-string hierarchy and place
% markers at each depth/separation point
for kk=1:length(cl)
    if iscell(cl{kk})
        cl{kk} = util.cell2str(cl{kk},sep,depth+1);
    end
    sepsymbol = sprintf('#DEPTH-%03d#',depth);
    len = length(sepsymbol);
    cl{kk} = sprintf('%s%s',cl{kk},sepsymbol);
end

% concatenate cell elements into single string
str = cat(2,cl{:});

% remove the final separating character(s)
str( (end-len+1):end ) = [];

% if at original depth, replace depth markers with separation symbols
if depth==1
    tk = regexpi(str,'#DEPTH-(?<depth>\d{3})#','names');
    depths = unique(cellfun(@str2double,{tk.depth}));
    assert(length(sep)>=length(depths),'Need at least %d separation symbols, but have only %d',length(depths),length(sep));
    sepid = max(depths) - depths + 1;
    for kk=1:length(depths)
        str = strrep(str,sprintf('#DEPTH-%03d#',kk),sep{sepid(kk)});
    end
end