function [args,value,key,found] = argfnval(fn,args,default)
% extract key-value pair where key results in logical true from
% user-provided function
% fn should be function handle, args input should be cell, default
% is the default value if nothing gives logical true
% args output is cell array minus matching cells; value output
% is the matching values if found
value = default;
key = '';

% look for key
idx = cellfun(@(x)feval(fn,x),args);
assert(isempty(idx)||~idx(end),'Key match cannot occur at the end of args (expecting a key-value pair)');

% if found, extract
found = false;
if any(idx)
    assert(nnz(idx)<=1,'argfcn does not support multiple matches (see argfcns)');
    found = true;
    
    % get the keys
    key = args{idx};
    
    % get the following cell
    value = args{circshift(idx,1,2)};
    
    % remove both key and value from cell array
    args(idx|circshift(idx,1,2)) = [];
end