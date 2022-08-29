function [args,value,key,found] = argflag(flag,args,default,n)
% look for a single-input flag
% key should be char, args input should be cell, default is the default
% value if flag is not found, if n is provided it will be a strncmpi
% instead of strcmpi on n characters
% args output is cell array minus the flag if found; value output is the
% logical output
% if DEFAULT is TRUE, presence of flag will result in FALSE output
% if DEFAULT is FALSE, presence of flag will result in TRUE output
% i.e., presence of flag flips the default (and the default default value
% is FALSE, so presence of flag would produce TRUE output).
if nargin<3||isempty(default),default=false;end
if nargin<4||isempty(n),n=length(flag);end
assert(islogical(default)||ismember(default,[0 1]),'Default value must be logical or in the set [0,1], not ''%s''',class(default));

% look for flag
if nargin>=3 && ~isempty(n) && isnumeric(n)
    idx = strncmpi(args,flag,n);
else
    idx = strcmpi(args,flag);
end

% if found, flip default
key = flag;
found = false;
value = default;
if any(idx)
    assert(nnz(idx)<=1,'argflag does not support multiple matches');
    found = true;
    
    % get the key
    key = args{idx};
    
    % get the following cell
    value = ~default;
    
    % remove flag from cell array
    args(idx) = [];
end