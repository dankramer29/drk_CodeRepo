function eq = isEqualCell(cl1,cl2)
% ISEQUALCELL comparison of cells
%
%   EQ = ISEQUALCELL(CL1,CL2)
%   Compares CL2 to the reference cell CL1 and returns a
%   logical result indicating whether they're equivalent.

% convert multidimensional cells to vector cells
cl1=cl1(:);
cl2=cl2(:);

% check number of cells
if length(cl1)~=length(cl2)
    eq = false;
    return;
end

% check for empty corner case
if isempty(cl1)
    eq = true;
    return;
end

% loop over cells
eq = false(1,length(cl1));
for kk=1:length(cl1)
    try
        eq(kk) = all(cache.checkEqual(cl1{kk},cl2{kk}));
    catch ME
        util.errorMessage(ME);
    end
end
eq = all(eq);