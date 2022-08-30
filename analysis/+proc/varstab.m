function x = varstab(x,method,params)
% VARSTAB Apply a variance-stabilizing transformation to the data
%
%   X = VARSTAB(X)
%   Apply a square-root transformation to the data in X.
%
%   X = VARSTAB(X,METHOD)
%   Apply the variance-stabilizing transformation indicated by METHOD to
%   the data in X. METHOD may be 'sqrt', 'log', 'arctanh'/'atanh', or a
%   function handle. If METHOD is a function handle, the function must
%   accept arbitrarily-sized input X and produce X_HAT of the same
%   dimensions.
%
%   A widely-accepted consensus for neural signals is that the square root
%   is the appropriate transformation for Poisson-distributed spike firing
%   data; logarithm is best for spectral power; and arctanh is best for
%   coherence (the magnitude-squared coherency).
%
%   See Pesaran, B. (2008) "Spectral Analysis for Neural Signals" pp. 8-9.
%
% NOTES:
% Would it be appropriate to identify some multiplicative or additive
% factor that would restore the mean value of x after transformation?
% (thinking specifically of min firing rates and thresholds for rejecting
% firing rates that are too small).

if ischar(method)
    switch lower(method)
        case 'sqrt' % most appropriate for Poisson-distributed spike counts
            x = sqrt(x);
        case 'log' % most appropriate for power spectra
            x = log(x);
        case {'arctanh','atanh'} % most appropriate for coherence (magnitude-squared coherency)
            x = atanh(x);
        otherwise
            error('Unknown variance stabilizaing transformation method ''%s''',method);
    end
elseif isa(method,'function_handle')
    sz = size(x);
    x = feval(method,x);
    assert(all(size(x)==sz),'Variance-stabilizing transformation function must return a matrix the same size as the one that was provided to it');
end