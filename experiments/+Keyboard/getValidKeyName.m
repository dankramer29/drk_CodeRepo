function keyName = getValidKeyName(keyName,varargin)
% GETVALIDKEYNAME Uniform representations of key bindings
%
%   GETVALIDKEYNAME(KEYNAME)
%   Find a match in the list of valid key names to the string
%   in KEYNAME.

% whether to return multiple matches
[varargin,FlagAllowMultipleMatches] = util.argkeyval('AllowMultipleMatches',varargin,false);
util.argempty(varargin);

% return immediately if empty input
if isempty(keyName), return; end

% get list of valid key names
KeyNameList = Keyboard.validKeyNames;

% identify the requested key
matchIdx = find(strncmpi(KeyNameList,keyName,length(keyName)));

% process the match
if isempty(matchIdx)
    
    % no match
    keyName = '';
elseif length(matchIdx)==1
    
    % single match: return valid key name
    keyName = KeyNameList{matchIdx};
else
    
    % multiple matches
    if FlagAllowMultipleMatches
        keyName = KeyNameList(matchIdx);
    else
        matchLengths = cellfun(@length,KeyNameList(matchIdx));
        inputLength = length(keyName);
        sameLength = ismember(matchLengths,inputLength);
        if nnz(sameLength)==1 % first, see if one has the same length
            keyName = KeyNameList{matchIdx(sameLength)};
        else
            [~,shortestLength] = min(matchLengths); % otherwise choose first shortest match
            keyName = KeyNameList{matchIdx(shortestLength(1))};
        end
    end
end