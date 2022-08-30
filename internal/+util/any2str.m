function str = any2str(val)
% ANY2STR Convert many different data types into strings
%
%   STR = ANY2STR(VAL)
%   Convert the variable VAL into a string STR. Allowable data types for
%   VAL are listed in the table below.
%
%     Numeric (scalar)      @sprintf
%     Numeric (vector)      @util.vec2str
%     Logical               @sprintf
%     Char                  @(x)x
%     Cell                  @util.cell2str
%     Object                @class
%     Struct                @(x)strjoin(fieldnames(x),', ')
%
%   See also UTIL.VEC2STR, UTIL.CELL2STR.

if isnumeric(val)
    if isscalar(val)
        str = sprintf('%d',val);
    else
        str = util.vec2str(val);
    end
elseif islogical(val)
    str = sprintf('%d',val);
elseif ischar(val)
    str = val;
elseif iscell(val)
    if all(cellfun(@ischar,val))
        str = strjoin(val,',');
    elseif all(cellfun(@isnumeric,val))
        str = strjoin(cellfun(@util.any2str,val,'UniformOutput',false),',');
    else
        str = util.cell2str(val);
    end
elseif isobject(val)
    str = class(val);
elseif isstruct(val)
    str = sprintf('Struct with fields %s',strjoin(fieldnames(val),', '));
elseif isa(val,'function_handle')
    str = func2str(val);
elseif isobject(val) && ismember('char',methods(val))
    str = char(val);
else
    error('Unknown class ''%s''',class(val));
end