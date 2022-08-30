function [eq,prop] = isEqualStruct(st1,st2,varargin)
% ISEQUALSTRUCT comparison of structs
%
%   EQ = ISEQUALSTRUCT(ST1,ST2)
%   Compares ST2 to the reference struct ST1 and returns a
%   logical result indicating whether they're equivalent.
%
%   EQ = ISEQUAL(ST1,ST2,FIELD1,FIELD2,...)
%   EQ = ISEQUAL(ST1,ST2,{FIELD1,FIELD2,...})
%   EQ = ISEQUAL(ST1,ST2,'IGNORE',{FIELD1,FIELD2,...})
%   Specify fieldnames to ignore.
%
%   EQ = ISEQUAL(THIS,OBJ,'REQUIRE',{FIELD1,FIELD2,...})
%   Specify fieldnames to require.
%
%   EQ = ISEQUAL(...,'EXCEPT',{FIELD1,FIELD2,...})
%   In accordance with previous arguments to either IGNORE or REQUIRE
%   certain parameters, list any exceptions using the EXCEPT argument. For
%   example, to require some fields that may have been listed for IGNORE,
%   or to ignore some fields that may have been listed for REQUIRE.
%
%   [EQ,PROP] = ISEQUAL(...)
%   If EQ is false, PROP will contain the name of the offending property.
%   Otherwise, PROP will be empty.

% convert multidimensional arrays of structs to vectors
st1=st1(:);
st2=st2(:);
prop='';

% specify ignore/require property lists
[varargin,ignore] = util.argkeyval('ignore',varargin,{});
[varargin,require] = util.argkeyval('require',varargin,{});
[varargin,except] = util.argkeyval('except',varargin,{});
if ~isempty(varargin)
    if iscell(varargin{1})
        ignore = varargin{1};
        varargin(1) = [];
    else
        ignore = varargin;
        varargin = {};
    end
end
ignore = util.ascell(ignore);
require = util.ascell(require);
util.argempty(varargin);

% make sure structs of equal length
eq = length(st1)==length(st2);
if ~eq,return;end

% make sure equal number of fields
fieldlist = fieldnames(st1);
eq = length(fieldlist)==length(fieldnames(st2));
if ~eq,return;end

% reduce based on user ignore/require lists
idx_discard = [];
if ~isempty(require)
    assert(isempty(ignore),'Cannot specify both required and ignored properties');
    idx_except = ismember(cellfun(@lower,require,'UniformOutput',false),cellfun(@lower,except,'UniformOutput',false));
    require(idx_except) = [];
    idx_require = ismember(cellfun(@lower,fieldlist,'UniformOutput',false),cellfun(@lower,require,'UniformOutput',false));
    idx_discard = ~idx_require;
elseif ~isempty(ignore)
    assert(isempty(require),'Cannot specify both required and ignored properties');
    idx_except = ismember(cellfun(@lower,ignore,'UniformOutput',false),cellfun(@lower,except,'UniformOutput',false));
    ignore(idx_except) = [];
    idx_ignore = ismember(cellfun(@lower,fieldlist,'UniformOutput',false),cellfun(@lower,ignore,'UniformOutput',false));
    idx_discard = idx_ignore;
end
fieldlist(idx_discard) = [];

% loop over all fields
prop = [];
for kk=1:length(fieldlist)
    
    % make sure this field exists in second struct
    if ~isfield(st2,fieldlist{kk}),eq=false;break;end
    
    % loop over all array elements and compare values
    for nn=1:length(st1)
        eq = cache.checkEqual(st1(nn).(fieldlist{kk}),st2(nn).(fieldlist{kk}));
        if eq<0,warning('Could not process property ''%s'' of class ''%s''',fieldlist{kk},class(fieldlist{kk}));end
        if ~eq
            prop = fieldlist{kk};
            break;
        end
    end
    if ~eq
        prop = fieldlist{kk};
        return;
    end
end