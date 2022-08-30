function [args,value,found] = argisa(type,args,default)
% extract value of a certain class
% type should be char (name of class), args input should be cell, default
% is the default value if nothing matches the class
% args output is cell array minus the "isa" value if found; value output
% is the "isa" value if found
value = default;

% look for key
idx = cellfun(@(x)isa(x,type),args);

% if found, extract
found = false;
if any(idx)
    assert(nnz(idx)<=1,'argisa does not support multiple matches (see argisas)');
    found = true;
    
    % get the keys
    value = args{idx};
    
    % remove both key and value from cell array
    args(idx) = [];
end