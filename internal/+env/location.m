function loc = location(varargin)
% ENV.LOCATION get or set the BLX location environment variable
%
%   LOC = ENV.LOCATION uses the local computer name to automatically set 
%   the location and returns the current location in LOC.
%
%   LOC = ENV.LOCATION(LOC) sets the location to the value in LOC.
%
%   See also ENV.CLEAR, ENV.DEFAULT, ENV.DEP, ENV.EV, ENV.GET, ENV.PRINT,
%   ENV.SET, ENV.STR2NAME.

% get the list of registered BLX environment variables
blxvars = getenv(env.str2name('blxvars'));

% clear all dependent environment variables
indeps = env.dep('location',1); % get list of independent variables
vars2clear = util.str2cell(blxvars,',');
vars2clear(ismember(vars2clear,indeps)) = []; % remove independent variables
if ~isempty(vars2clear), env.clear(vars2clear{:}); end

% use default location unless otherwise specified by input
loc = env.default('location');
if nargin>0
    loc = varargin{1};
end

% make sure value is a char
assert(ischar(loc),'Location must be char');

% set the environment variable to established value
setenv(env.str2name('blxvars'),'location');
setenv(env.str2name('location'),loc);