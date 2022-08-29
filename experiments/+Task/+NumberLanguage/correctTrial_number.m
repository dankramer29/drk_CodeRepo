function success = correctTrial_number(numbers,number,response)
% CORRECTTRIAL_NUMBER Identify correct response when reporting the number
%
%   SUCCESS = CORRECTTRIAL_NUMBER(NUMBERS,NUMBER)
%   Return the expected response SUCCESS based on the list of numbers being
%   tested NUMBERS and the current number NUMBER.
%
%   SUCCESS = CORRECTTRIAL_NUMBER(NUMBERS,NUMBER,RESPONSE)
%   Return logical SUCCESS indicating whether the response in RESPONSE was
%   correct given the list of numbers being tested NUMBERS and the current
%   number NUMBER.

% make sure number is char
number = util.aschar(number);

% correct response
success = number;

% check whether response provided
if nargin==3
    response = util.aschar(response);
    if strcmpi(response,'x')
        
        % "i don't know" response
        success = nan;
    else
        
        % check whether provided response is correct
        success = strcmpi(response,success);
    end
end