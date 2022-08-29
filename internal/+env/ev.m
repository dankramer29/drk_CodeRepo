function [v2e,e2v] = ev(name)
% ENV.EV store functions for converting between var and env var.
%
%   Recall that environment variables must be of type char.  These
%   functions make it possible to store other variable types; v2e must
%   convert a value into a char, and e2v converts from char back to the
%   original type.
%
%   The default values are the anonymous function @(X)X.
%
%   [V2E,E2V] = ENV.EV(NAME) returns function handles for converting from
%   variable to environment variable (V2E) and from environment variable to
%   variable (E2V) for the HST environment variable NAME.
%
%   Example functions for converting between logical and string:
%
%     str = {'false','true'};
%     v2e = @(x)str{x+1};
%     e2v = @(x)eval(x);
%
%   Example functions for converting between integer and string:
%
%     v2e = @(x)int2str(x);
%     e2v = @(x)str2double(x);
%
%   See also ENV.CLEAR, ENV.DEFAULT, ENV.DEP, ENV.GET, ENV.LOCATION,
%   ENV.PRINT, ENV.SET, ENV.STR2HSTNAME.

% switch on env var name
switch lower(name)
    case {'numproc','screenid','ptbhid'}
        v2e = @(x)sprintf('%d',x);
        e2v = @(x)str2double(x);
    case 'ptbopacity'
        v2e = @(x)sprintf('%.1f',x);
        e2v = @(x)str2double(x);
    case {'verbosity','verbosityscreen','verbositylogfile'}
        v2e = @(x)char(Debug.PriorityLevel.fromAny(x));
        e2v = @(x)Debug.PriorityLevel.fromAny(x);
    case {'data','cache','nsps'} % cell, convert to/from string
        v2e = @util.cell2str;
        e2v = @util.str2cell;
    case 'debug' % integers, values 0-2
        v2e = @(x)char(Debug.Mode.fromAny(x));
        e2v = @(x)Debug.Mode.fromAny(x);
    case {'displayresolution','monitorsize'} % numeric, convert to/from string
        v2e = @num2str;
        e2v = @str2num;
    case {'hasgpu'} % logical
        v2e = @(x)sprintf('%d',x);
        e2v = @(x)logical(x);
    otherwise
        v2e = @(x)x;
        e2v = @(x)x;
end