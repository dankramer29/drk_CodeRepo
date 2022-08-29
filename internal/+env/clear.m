function clear(varargin)
% ENV.CLEAR clear the contents of BLX environment variables
%
%   ENV.CLEAR clears the contents of all registered BLX environment 
%   variables (it explicitly sets their values to be '').
%
%   ENV.CLEAR(NAME) clears the value of the BLX environment variable NAME.
%
%   See also ENV.DEFAULT, ENV.DEP, ENV.EV, ENV.GET, ENV.LOCATION,
%   ENV.PRINT, ENV.SET, ENV.STR2NAME.

% get list of all registered BLX environment variables
blxvars = env.get;

% select which BLX environment variables to clear
if nargin==0
    
    % get list of all registered BLX environment variables
    varnames = blxvars;
else
    
    % just the input names
    varnames = varargin;
end

% check validity before clearing
for kk=1:length(varnames)
    assert(nnz(strcmpi(blxvars,varnames{kk}))>0,'Cannot find ''%s'' in the list of registered BLX environment variables.',varnames{kk});
end

% set them all to empty
for kk=1:length(varnames)
    setenv(env.str2name(varnames{kk}),'');
    blxvars(strcmpi(blxvars,varnames{kk})) = [];
end

% update the list of registered BLX environment variables
str = util.cell2str(blxvars);
setenv(env.str2name('blxvars'),str);
