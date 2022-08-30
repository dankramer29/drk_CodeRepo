function s = pwr2db(x,r)
% convert power (i.e. spectrum output) to decibels
% 
%   S = PWR2DB(X)
%   Convert the values in X to decibels using a reference of 1.
%
%   S = PWR2DB(X,R)
%   Use the reference in R when converting to decibels.  R may be scalar or
%   the same size as X.

% default reference is 1
if nargin<2||isempty(r),r=1;end

% check for negative or zero values
if any(x<=0)
    warning('Negative or zero power will produce imaginary or infinite decibel values.  Sign will be ignored.');
    x = abs(x);
end

% convert to db
if isscalar(r)
    s = 10*log10(x/r);
else
    s = 10*log10(x./repmat(r,size(x)));
end