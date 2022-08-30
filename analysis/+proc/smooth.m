function xsmooth = smooth(x,method,params,debugger)
% SMOOTH Wrapper function to apply different smoothing methods
%
%   XSMOOTH = SMOOTH(X)
%   Passes X to the built-in SMOOTH method to apply the default smoothing
%   method (moving average with 5-sample span).  Data in X will be smoothed
%   along columns.
%
%   XSMOOTH = SMOOTH(X,METHOD,PARAMS)
%   Specify a smoothing method and parameters for that method.  In addition
%   to any of the methods available from the built-in SMOOTH method, METHOD
%   may also be 'mj' for min-jerk kernel smoothing.  See PROC.SMOOTHMJ for
%   additional information about min-jerk smoothing.
%
%   PARAMS must be a struct with fields as name-value pairs.  See the
%   builtin SMOOTH method for a description of parameters applicable for
%   each of the builtin methods.
%
%   When METHOD is 'mj', the following parameters are available:
%
%     kernelwidth   Width of the min-jerk kernel in arbitrary units (units
%                   must match units of the period) (REQUIRED).
%
%     period        Sampling period of the data (time per sample)
%                   (REQUIRED).
%
%     halfkernel    Whether to use the full or half kernel (OPTIONAL;
%                   default FALSE).
%
%     causal        Whether to apply the filter causally or include
%                   information from future samples (OPTIONAL; default
%                   FALSE).
%
%   See also SMOOTH, PROC.SMOOTHMJ.

% process inputs/set defaults
if nargin<2||isempty(method),method='moving';end % method
if nargin<3||isempty(params),params=struct;end % parameters

% smooth operations
switch lower(method)
    case 'mj' % minjerk smoothing
        
        % require kernelwidth and period
        assert(isfield(params,'kernelwidth'),'Smoothing method ''mj'' requires parameter ''kernelwidth'' defining the kernel width in unit time');
        assert(isfield(params,'period'),'Smoothing method ''mj'' requires parameter ''period'' defining the unit time per sample');
        args = {};
        if isfield(params,'halfkernel') && ~isempty(params.halfkernel)
            
            % whether to use full or half kernel
            args = [args {params.halfkernel}];
        else
            args = [args {false}];
        end
        if isfield(params,'causal') && ~isempty(params.causal)
            
            % causal - whether samples may contain info about future
            args = [args {params.causal}];
        else
            args = [args {false}];
        end
        xsmooth = proc.smoothmj(x,params.kernelwidth,params.period,args{:});
    case {'moving','lowess','loess','sgolay','rlowess','rloess'} % built-in smoothing options
        
        % some require odd span; smooth function wouldn't cause an error
        % but would silently subtract one so make that change explicit with
        % a warning
        args = {};
        if isfield(params,'span') && ~isempty(params.span)
            if any(strcmpi(method,{'sgolay','moving'}))
                if rem(params.span,2)==1
                    warning('Smoothing method ''%s'' requires span to be odd, so subtracting 1 to give span=%d',method,span-1);
                    params.span = params.span-1;
                end
            end
            if strcmpi(method,'sgolay') && isfield(params,'degree') && ~isempty(params.degree)
                assert(params.span>params.degree,'Smoothing method ''sgolay'' requires span (%.2f) to be larger than degree (%.2f)',params.span,params.degree);
            end
            args = [args {params.span}];
        end
        args = [args {lower(method)}];
        
        % sgolay accepts a degree parameter
        if strcmpi(method,'sgolay') && isfield(params,'degree') && ~isempty(params.degree)
            args = [args {params.degree}];
        end
        
        % run smoothing
        xsmooth = smooth(x,args{:});
    otherwise
        
        % unrecognized option
        error('Unknown smoothing method ''%s''',method);
end