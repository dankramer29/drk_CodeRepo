function val = isValidKeyName(varargin)
% ISVALIDKEYNAME Check whether a string is a valid key name
%
%   VAL = ISVALIDKEYNAME(NAME1,NAME2,...)
%   In a vector with one entry for each of the input strings NAME1, NAME2, 
%   etc., VAL will indicate via TRUE or FALSE whether the corresponding 
%   string is a valid key name.

% get the list of valid key names
list = KbName('KeyNames');

% remove empty elements so ismember doesn't complain
list( cellfun(@isempty,list) ) = [];

% check for a match
val = ismember(varargin,list);