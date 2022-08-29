function list = dep(name,independent)
% ENV.DEP Identify dependent variables for an HST environment variable.
%
%   LIST = ENV.DEP(NAME)
%   Retrieve a list of HST environment variables dependent on the HST 
%   environment variable NAME.
%
%   LIST = ENV.DEP(NAME,INDEPENDENT)
%   If INDEPENDENT is TRUE, return a list of HST environment variables that
%   are independent of the HST environment variable NAME.
%
%   See also ENV.CLEAR, ENV.DEFAULT, ENV.EV, ENV.GET, ENV.LOCATION,
%   ENV.PRINT, ENV.SET, ENV.STR2HSTNAME.

% dependent list returned by default
if nargin<2, independent=false; end

% empty list by default
list_dep = {};
list_ind = {};

% identify dependencies
switch lower(name)
    case 'subject'
        list_dep = {'arrays'};
end

% identify independencies
switch lower(name)
    case 'location'
        list_ind = {'subject'};
end

% assign requested list
if independent
    list = list_ind;
else
    list = list_dep;
end