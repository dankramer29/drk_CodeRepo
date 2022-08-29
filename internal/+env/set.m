function set(name,val)
% ENV.SET set an BLX enviornment variable
%
%   ENV.SET(NAME,VAL) sets an BLX environment variable NAME to have the
%   value VAL.  VAL must be a char.
%
%   See also ENV.CLEAR, ENV.DEFAULT, ENV.DEP, ENV.EV, ENV.GET,
%   ENV.LOCATION, ENV.PRINT, ENV.STR2NAME.

% handle location differently
if strcmpi(name,'location')
    env.location(val);
    return;
end

% make sure location is set
if isempty(getenv(env.str2name('location')))
    env.location;
end

% run char conversion function
v2e = env.ev(name);
val = v2e(val);

% make sure correct value type coming in
assert(isa(val,'char'),'environment variables must be of type ''char''');

% get the list of registered BLX environment variables
blxvars = getenv(env.str2name('blxvars'));

% clear dependent BLX environment variables
deps = env.dep(name);
regvars = util.str2cell(blxvars,',');
deps = deps(ismember(deps,regvars));
if ~isempty(deps), env.clear(deps{:}); end

% register NAME if it is not already registered
idx = strfind(blxvars,name);
if isempty(idx)
    
    % add to list of registered BLX environment variables
    if isempty(blxvars)
        blxvars = name;
    else
        blxvars = sprintf('%s,%s',blxvars,name);
    end
    
    % set blxvars, a list of registered BLX environment variables
    setenv(env.str2name('blxvars'),blxvars);
end

% set the BLX environment variable
setenv(env.str2name(name),val);