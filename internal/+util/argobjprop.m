function [args,values,keys,found] = argobjprop(obj,args)
% extract values from key-value pairs in a cell array where keys are any of
% the properties of a (user-provided) object
% key should be char, args input should be cell, default is the default
% value if key-value pair not found, if n is provided it will be a strncmpi
% instead of strcmpi on n characters
% args output is cell array minus the key-value pair if found; value output
% is the cell following the key if found

% property names
mco = metaclass(obj);
keys = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};

% look for keys
idx = cellfun(@(x)strcmpi(x,args),keys,'UniformOutput',false);
found = find(cellfun(@any,idx));

% if found, extract
values = cell(1,length(found));
idx_or = false(size(args));
for kk=1:length(found)
    assert(nnz(idx{found(kk)})<=1,'argobjprop does not support multiple matches');
    assert(~idx{found(kk)}(end),'Key match cannot occur at the end of args (expecting a key-value pair)');
    idx_or = idx_or | idx{found(kk)} | circshift(idx{found(kk)},1,2);
    
    % get the following cell
    values{kk} = args{circshift(idx{found(kk)},1,2)};
    obj.(keys{found(kk)}) = values{kk};
end

% remove all keys and values from args
args(idx_or) = [];

% update found to logical
keys = keys(found);
found = any(found);