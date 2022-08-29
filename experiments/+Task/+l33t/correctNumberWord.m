function success = correctNumberWord(word,l33t,letters,numbers,response)

% read in number words
srcdir = fileparts(mfilename('fullpath'));
srcfile = fullfile(srcdir,'wordlist_numbers.txt');
assert(exist(srcfile,'file')==2,'Cannot locate source file ''%s''','wordlist_numbers.txt');
fid = fopen(srcfile);
assert(fid>=0);
try
    numberwords = textscan(fid,'%s','Delimiter','\n');
    numberwords = numberwords{1}(:)';
catch ME
    util.errorMessage(ME);
    fclose(fid);
end
fclose(fid);

% identify index
idx = find(strcmpi(numberwords,word));

% correct response
success = idx-1;

% if response provided, check whether correct
if nargin==5
    
    % make sure one character
    if ~ischar(response),response=str2double(response);end
    response=response(1);
    
    % enter 'y' if subject reported a word, 'n' if could not
    success = response==success;
end