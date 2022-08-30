function chr = aschar(val)
% ASCHAR Convert value to character data type
%
%   CHR = ASCHAR(VAL)
%   For string or numeric value VAL, convert to char and return.

% possible input data types
if ischar(val)
    
    % already a char
    chr = val;
elseif isnumeric(val)
    
    % numeric
    chr = num2str(val);
else
    
    % can't handle anything else
    error('Cannot handle input of type ''%s''',class(val));
end