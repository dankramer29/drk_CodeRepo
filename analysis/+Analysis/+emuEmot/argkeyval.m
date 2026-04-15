function [args,value,key,found] = argkeyval(key,args,default,n,allowed)
% extract value from a key-value pair in a cell array
% key should be char, args input should be cell, default is the default
% value if key-value pair not found, if n is provided it will be a strncmpi
% instead of strcmpi on n characters
% args output is cell array minus the key-value pair if found; value output
% is the cell following the key if found
value = default;
if nargin<4||isempty(n),n=length(key);end
if nargin<5||isempty(allowed),allowed={};end
allowed = util.ascell(allowed);

% look for key
if nargin>=3 && ~isempty(n) && isnumeric(n)
    idx = cellfun(@(x)ischar(x)&&isempty(regexpi(x,'\s+'))&&strncmpi(regexprep(x,'^([^\s]*)\s+.*$','$1'),key,n),args);
else
    idx = strcmpi(args,key);
end
assert(isempty(idx)||~idx(end),'Key match cannot occur at the end of args (expecting a key-value pair)');

% if found, extract
found = false;
if any(idx)
    assert(nnz(idx)<=1,'argkeyval does not support multiple matches (see argkeyvals)');
    found = true;
    
    % get the keys
    key = args{idx};
    
    % get the following cell
    value = args{circshift(idx,1,2)};
    if ~isempty(allowed)
        idx_allowed = cellfun(@(x)isequal(value,x),allowed);
        assert(any(idx_allowed),'Value does not match any of the allowed options');
    end
    
    % remove both key and value from cell array
    args(idx|circshift(idx,1,2)) = [];
end