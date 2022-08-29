function success = correctWord(word,l33t,letters,numbers,response)

% correct response
success = 'y';

% if response provided, check whether correct
if nargin==5
    
    % make sure one character
    if ~ischar(response),response=char(response);end
    response=response(1);
    
    % enter 'y' if subject reported a word, 'n' if could not
    success = response==success;
end