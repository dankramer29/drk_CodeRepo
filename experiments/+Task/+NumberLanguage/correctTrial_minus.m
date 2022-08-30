function success = correctTrial_minus(numbers,number,response)
% CORRECTTRIAL_MINUS Identify correct response when subject has to subtract
%
%   SUCCESS = CORRECTTRIAL_MINUS(NUMBERS,NUMBER)
%   Return the expected response SUCCESS based on the list of numbers being
%   tested NUMBERS and the current number NUMBER.
%
%   SUCCESS = CORRECTTRIAL_MINUS(NUMBERS,NUMBER,RESPONSE)
%   Return logical SUCCESS indicating whether the response in RESPONSE was
%   correct given the list of numbers being tested NUMBERS and the current
%   number NUMBER.

% make sure number is char
number = util.aschar(number);

% max number
maxnum = max(numbers);

% correct response
success = util.aschar(maxnum-str2double(number)+1);

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