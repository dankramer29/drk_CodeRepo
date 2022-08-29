function [args,value,found] = argkeyword(key,args,default,n)
% look for presence of a keyword out of a set of allowed keywords - just
% the value out of the 'key,value' pair concept, but calling it key here
% key should be char or cell of char, args input should be cell, default is
% the default value if keywords not found, if n is provided it will be a
% strncmpi instead of strcmpi on n characters (ok to provide vector of n,
% one per keyword)
% args output is cell array minus the keyword if found; value output is the
% keyword or default.
value = default;
key = util.ascell(key);
if nargin<4||isempty(n),n=cellfun(@length,key);end
if isnumeric(n)
    if isscalar(n)
        n = arrayfun(@(x)n,1:length(key),'UniformOutput',false);
    else
        n = arrayfun(@(x)x,n,'UniformOutput',false);
    end
end

% look for keywords
idx = cellfun(@(x,y)strncmpi(args,x,y),key,n,'UniformOutput',false);
found = cellfun(@nnz,idx);

% if found, extract
if any(found)
    assert(all(found<=1),'argkeyword does not support multiple matches of any individual keyword');
    assert(nnz(found>0)<=1,'argkeyword does not support multiple keyword matches (see argkeywords)');
    
    % save the keyword
    value = args{idx{found>0}};
    
    % remove keyword from cell array
    args(idx{found>0}) = [];
    found = true;
else
    found = false;
end