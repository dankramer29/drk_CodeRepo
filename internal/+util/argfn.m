function [args,value,found] = argfn(fn,args,default)
% extract value giving logical true from user-provided function
% fn should be function handle, args input should be cell, default
% is the default value if nothing gives logical true
% args output is cell array minus matching cells; value output
% is the matching values if found
value = default;

% look for key
idx = cellfun(@(x)feval(fn,x),args);

% if found, extract
found = false;
if any(idx)
    assert(nnz(idx)<=1,'argfcn does not support multiple matches (see argfcns)');
    found = true;
    
    % get the keys
    value = args{idx};
    
    % remove both key and value from cell array
    args(idx) = [];
end