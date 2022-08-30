function eq = checkEqual(thing1,thing2,tol)
% CHECKEQUAL check whether two things are equal
%
%   EQ = CHECKEQUAL(THING1,THING2)
%   Checks whether two things, THING1 and THING2, are equal.
%   Supports numeric, char, logical, cache.Cacheable, struct,
%   and cell data types.
%
%   EQ = CHECKEQUAL(THING1,THING2,TOL)
%   Provide a tolerance for equality in terms of the order-of-magnitude of
%   the largest allowable difference between THING1 and THING2. Default
%   value of TOL is 4. For example, if THING1 is 0.05 and THING2 is
%   0.050001, then ABS(THING1-THING2)=1e-6. The threshold would be
%   calculated as MIN(THING1,THING2)/10^TOL=5e-6. Since the 1e-6<5e-6, EQ
%   would be set to TRUE.
if nargin<3||isempty(tol),tol=4;end

eq = true;
if isnumeric(thing1)
    if ~isnumeric(thing2)
        eq = false;
        return;
    end
    if ~all(size(thing1)==size(thing2))
        eq = false;
        return;
    end
    if isempty(thing1)
        eq = isempty(thing2);
        return;
    end
    idx_nan = isnan(thing1(:));
    if any(idx_nan)
        eq = all(isnan(thing2(idx_nan))) && all(isequal(thing1(~idx_nan),thing2(~idx_nan)));
        return;
    end
    idx_compare = ~idx_nan;
    tmp1 = thing1(idx_compare);
    tmp2 = thing2(idx_compare);
    if ~strcmpi(class(tmp1),class(tmp2))
        try
            tmp2 = cast(tmp2,'like',tmp1);
        catch ME
            eq = false;
            return;
        end
    end
    threshold = min(tmp1,tmp2)/10^tol;
    eq = all(abs(tmp1-tmp2)<=threshold);
elseif ischar(thing1)
    if isa(thing2,'function_handle')
        thing2 = func2str(thing2);
    end
    if ~ischar(thing2),eq=false;return;end
    if ~strcmpi(thing1,thing2),eq=false;return;end
elseif islogical(thing1)
    if isnumeric(thing2)
        eq = isequal(thing1,logical(thing2));
    elseif ~islogical(thing2)
        eq = false;
        return;
    end
    if thing2~=thing1,eq=false;return;end
elseif isa(thing1,'cache.Cacheable')
    if ~isa(thing2,'cache.Cacheable'),eq=false;return;end
    eq = isEqual(thing1,thing2);
    if ~eq,return;end
elseif isstruct(thing1)
    if ~isstruct(thing2),eq=false;return;end
    eq = cache.isEqualStruct(thing1,thing2);
    if ~eq,return;end
elseif iscell(thing1)
    if ~iscell(thing2),eq=false;return;end
    eq = cache.isEqualCell(thing1,thing2);
    if ~eq,return;end
elseif isa(thing1,'function_handle')
    if ~isa(thing2,'function_handle')
        eq = strcmpi(func2str(thing1),thing2);
    else
        eq = isequal(thing1,thing2);
    end
else
    try
        eq = isequal(thing1,thing2);
    catch ME
        util.errorMessage(ME);
        eq=-1; % indicate failure as opposed to inequality
    end
    if ~eq,return;end
end