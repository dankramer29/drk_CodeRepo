function print(varargin)
% ENV.PRINT print BLX environment variables to the screen
%
%   ENV.PRINT prints the value of all BLX environment variables to the
%   screen.
%
%   ENV.PRINT(NAME) prints the value of the BLX environment variable NAME 
%   to the screen.
%
%   See also ENV.CLEAR, ENV.DEFAULT, ENV.DEP, ENV.EV, ENV.GET,
%   ENV.LOCATION, ENV.SET, ENV.STR2NAME.

% make sure no outputs
assert(nargout==0,'Outputs not supported.');

% form the list of variables to print
if nargin>0
    
    % process only the input names
    varnames = cell(1,length(varargin));
    for kk=1:length(varargin)
        varnames{kk} = varargin{kk};
    end
else
    
    % process all registered BLX environment variables
    blxVars = getenv(env.str2name('blxvars'));
    if isempty(blxVars)
        varnames = {};
    else
        varnames = strsplit(blxVars,',');
        varnames(cellfun(@isempty,varnames)) = [];
    end
end

% alert if no BLX env vars; otherwise, list them
if isempty(varnames)
    fprintf('No registered BLX environment variables.\n');
else
    str = sprintf('%%%ds: %%s\n',max(cellfun(@length,varnames)));
    for kk=1:length(varnames)
        fprintf(str,varnames{kk},getenv(env.str2name(varnames{kk})));
    end
end