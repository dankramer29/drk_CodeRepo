function name = str2name(str)
% ENV.STR2NAME create valid BLX environment variable name from string
%
%   NAME = ENV.STR2NAME(STR) returns the BLX environment variable name
%   corresponding to STR in NAME.
%
%   See also ENV.CLEAR, ENV.DEFAULT, ENV.DEP, ENV.EV, ENV.GET,
%   ENV.LOCATION, ENV.PRINT, ENV.SET.

name = sprintf('blx__%s',upper(str));