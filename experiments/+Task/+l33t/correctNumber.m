function success = correctNumber(word,l33t,letters,numbers,response)

% correct response
success = sum(numbers);

% if response provided, check whether correct
if nargin==5
    
    % make sure it's a number
    if ischar(response),response=str2double(response);end
    
    % add numbers in the word
    success = response==success;
end