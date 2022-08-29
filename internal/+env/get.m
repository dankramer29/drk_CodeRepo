function varargout = get(varargin)
% ENV.GET retrieve BLX environment variables.
%
%   ENV.GET prints a list of registered BLX environment variable names to 
%   the screen.
%
%   LIST = ENV.GET returns a cell array of registered BLX environment 
%   variable names in LIST.
%
%   [VAL1,VAL2,...,VALn] = ENV.GET('VAR1','VAR2',...,'VARn') returns the 
%   value of the environment variables VAR1, VAR2, ..., VARn into the
%   outputs VAL1, VAL2, ..., VALn.  The order of the outputs depends upon
%   the order of the inputs:
%
%    [internal,location] = ENV.GET('internal','location');
%    [location,internal] = ENV.GET('location','internal');
%
%   See also ENV.CLEAR, ENV.DEFAULT, ENV.DEP, ENV.EV, ENV.LOCATION,
%   ENV.PRINT, ENV.SET, ENV.STR2NAME.

% if no inputs provided, list or return available BLX env vars
if nargin==0
    
    % if no output args, print to screen; otherwise return cell array of
    % BLX environment variable names
    if nargout==0
        env.print;
    else
        
        % retrieve names of all BLX environment variables
        blxvars = getenv(env.str2name('blxvars'));
        blxvars = util.str2cell(blxvars);
        
        % handle empty case separately
        if isempty(blxvars)
            varargout{1} = {};
        else
            varargout{1} = blxvars;
        end
    end
    
    % exit
    return;
end

% make sure location is set
if isempty(getenv(env.str2name('location')))
    env.location;
end

% process input BLX env var names
varargout = cell(1,length(varargin));
for kk=1:length(varargin)
    varargout{kk} = getvar(varargin{kk});
end


function val = getvar(name)
% GETVAR get environment variable; set to default if empty

% get default value
default = env.default(name);

% get function handles for converting between var / env var
[v2e,e2v] = env.ev(name);

% get current value
val = getenv(env.str2name(name));

% if empty, and default is not empty, set to default
if isempty(val) && ~isempty(default)
    env.set(name,default);
    val = v2e(default);
end

% convert from env var to var
val = e2v(val);