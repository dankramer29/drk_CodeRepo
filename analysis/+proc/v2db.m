function x = v2db(x,r)
% convert voltage (i.e. raw signals) to decibels

% default reference is 1
if nargin<2||isempty(r),r=1;end

% check scalar ref
if isscalar(r),r=repmat(r,size(x));end

% check for negative or zero values
if any(x<=0)
    warning('Negative or zero power will produce imaginary or infinite decibel values.  Sign will be ignored.');
    x = abs(x);
end

% convert to db
x = 20*log10(x./r);