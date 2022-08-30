function varargout = validKeyNames
% VALIDKEYNAMES List all valid key names
%
%   VALIDKEYNAMES
%   Print a list of all valid key names to the screen.
%
%   LIST = VALIDKEYNAMES
%   Return a cell array of strings containing all valid key
%   names.  The list is not printed to the screen.

% get a list of all valid key names
list = KbName('KeyNames');

% get rid of empty elements
list( cellfun(@isempty,list) ) = [];

% return cell array if no output args
if nargout>0, varargout{1} = list; return; end

% otherwise, print the list to the command window
fprintf('Valid Key Names:\n');
for kk=1:length(list)
    fprintf('%3d. %s\n',kk,list{kk});
end