function [args,value,key,found] = argkeyvals(key,args,default,n,allowed)
% extract values from a key-value pair in a cell array, where multiple
% pair matches could exist
% key should be char, args input should be cell, default is the default
% value if key-value pair not found, if n is provided it will be a strncmpi
% instead of strcmpi on n characters
% args output is cell array minus the key-value pair if found; value output
% is a cell array of values taken from the cells following each key match
value = {default};
found = false;
if isempty(args),return;end
if nargin<4||isempty(n),n=length(key);end
if nargin<5||isempty(allowed),allowed={};end
allowed = util.ascell(allowed);

% look for key
if nargin>=3 && ~isempty(n) && isnumeric(n)
    idx = cellfun(@(x)ischar(x)&&isempty(regexpi(x,'\s+'))&&strncmpi(regexprep(x,'^([^\s]*)\s+.*$','$1'),key,n),args);
else
    idx = strcmpi(args,key);
end
assert(~idx(end),'Key match cannot occur at the end of args (expecting a key-value pair)');

% if found, extract
if any(idx)
    found = nnz(idx);
    
    % account for potential multiple matches
    key = cell(1,nnz(idx));
    value = cell(1,nnz(idx));
    
    % get the following cell
    [key{:}] = args{idx};
    [value{:}] = args{circshift(idx,1,2)};
    if ~isempty(allowed)
        idx_allowed = cellfun(@(x)any(cellfun(@(y)isequal(x,y),allowed)),value);
        if nnz(~idx_allowed)<=1
            assert(all(idx_allowed),'Value %s does not match the allowed options',util.vec2str(find(~idx_allowed))); %#ok<FNDSB>
        else
            assert(all(idx_allowed),'Values %s do not match the allowed options',util.vec2str(find(~idx_allowed))); %#ok<FNDSB>
        end
    end
    
    % remove both key and value from cell array
    args(idx|circshift(idx,1,2)) = [];
end