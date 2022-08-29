function [args,value,key,found] = argfnvals(fn,args,default)
% extract key-value pair where key results in logical true from
% user-provided function
% fn should be function handle, args input should be cell, default
% is the default value if nothing gives logical true
% args output is cell array minus matching cells; value output
% is the matching values if found
value = {default};
found = false;
key = {};
if isempty(args),return;end

% look for key
idx = cellfun(@(x)feval(fn,x),args);
assert(isempty(idx)||~idx(end),'Key match cannot occur at the end of args (expecting a key-value pair)');

% if found, extract
if any(idx)
    found = nnz(idx);
    
    % account for potential multiple matches
    key = cell(1,nnz(idx));
    value = cell(1,nnz(idx));
    
    % get the following cell
    [key{:}] = args{idx};
    [value{:}] = args{circshift(idx,1,2)};
    
    % remove both key and value from cell array
    args(idx|circshift(idx,1,2)) = [];
end