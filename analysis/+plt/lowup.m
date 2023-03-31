function [strout] = lowup(str)
%converts all lower case words to upper case words including after space
%   Detailed explanation goes here

str=lower(str);
str = lower( str );
expression = '(^|[\. ])\s*.';
replace = '${upper($0)}';
strout = regexprep(str,expression,replace);


end