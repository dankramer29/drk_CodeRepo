function success = correctTrial_yesno(numbers,number,response)
% CORRECTTRIAL_YESNO Identify correct response when response is yes/no
%
%   SUCCESS = CORRECTTRIAL_YESNO(NUMBERS,NUMBER)
%   Return the expected response SUCCESS based on the list of numbers being
%   tested NUMBERS and the current number NUMBER.
%
%   SUCCESS = CORRECTTRIAL_YESNO(NUMBERS,NUMBER,RESPONSE)
%   Return logical SUCCESS indicating whether the response in RESPONSE was
%   correct given the list of numbers being tested NUMBERS and the current
%   number NUMBER.

% correct response
success = 'y';

% check whether response provided
if nargin==3
    if strcmpi(response,'x')
        
        % "i don't know" response
        success = nan;
    else
        
        % check whether provided response is correct
        success = strcmpi(response,'y');
    end
end