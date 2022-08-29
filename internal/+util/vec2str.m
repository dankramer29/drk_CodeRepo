function str = vec2str(vec,varargin)
% VEC2STR convert a vector or matrix of numbers into a formatted string
%
%   STR = VEC2STR(VEC)
%   Print the values in VEC in a string with square-bracket enclosures,
%   spaces separating values, semicolons separating rows if there are
%   multiple rows, and values printed with %g (compact floating point).
%   The default output can be evaluated back into the original input (under
%   the constraint of the number of decimal places printed).
%
%   STR = VEC2STR(...,FORMAT_STRING)
%   Modify the number output format.  The input FORMAT_STRING must begin
%   with a percent sign, and supports the full range of formats available
%   to MATLAB sprintf function.
%
%   STR = VEC2STR(...,ENCLOSURE_STRING)
%   Modify the characters printed at the beginning and end of STR.  The
%   input ENCLOSURE_STRING may not contain any '\' characters (e.g., \n),
%   and must be two characters long.
%
%   STR = VEC2STR(...,ENCL_FORMAT_STRING)
%   Compact method of customizing the format and enclosure strings.
%   The input FORMAT_ENCL_STRING should have a single ENCLOSURE_STRING
%   character, followed by a percent-sign-leading FORMAT_STRING, and end
%   with the second ENCLOSURE_STRING character.
%
%   STR = VEC2STR(...,DELIMITER_STRING)
%   If an input does not match the FORMAT_STRING, ENCLOSURE_STRING, or
%   ENCL_FORMAT_STRING, it will be interpreted as the string to place
%   between each value in VEC.
%
%   If both the enclosure and delimiter characters are specified, are both
%   two characters long, and neither has any '\' characters, then the
%   enclosure must occur before the delimiter in the input list.
%
%   Example: default behavior
%
%     >> vec = [1 2 3];
%     >> str = vec2str(vec);
%     str = [1 2 3]
%
%   Example: Customized enclosure + format
%
%     >> vec = [1.39 2.75 3.52];
%     >> str = vec2str(vec,'{%.1f}');
%     str = {1.4 2.8 3.5}
%
%   Example: newline delimiter strings
%
%     >> vec = [1 2 3];
%     >> str = vec2str(vec,'\n');
%     str = [1
%     2
%     3]
%
%   Example: array with customized enclosure + format
%
%     >> vec = rand(2,3);
%     >> str = vec2str(vec,'{%.2f}');
%     str = {0.06 0.93 0.12; 0.74 0.77 0.37;}
%
%   SEE ALSO SPRINTF.

% default parameters
format_string = '%g'; % print compact floating point (no insignificant zeros)
delimiter_string = ' '; % spaces between numbers
enclosure_strings = '[]'; % enclose the string in square brackets

% user input: format, enclosure+format
idx = find(cellfun(@(x)~isempty(strfind(x,'%')),varargin),1,'first');
if any(idx)
    mult_string = varargin{idx};
    varargin(idx) = [];
    perc_idx = strfind(mult_string,'%');
    if perc_idx==1
        format_string = mult_string;
    elseif perc_idx==2
        enclosure_strings = mult_string([1 end]);
        format_string = mult_string(2:end-1);
    else
        error('Only single enclosure characters are allowed (percent sign must be in first or second index');
    end
else
    
    % user input: enclosure string
    idx = find(cellfun(@(x)length(x)==2&isempty(strfind(x,'\')),varargin)==1,1,'first');
    if any(idx)
        enclosure_strings = varargin{idx};
        varargin(idx) = [];
    end
end

% user input: delimiter string
if ~isempty(varargin)
    delimiter_string = sprintf(varargin{1});
    varargin(1) = [];
end

% validate settings
assert(length(enclosure_strings)==2,'Enclosure strings must have two characters (one character for beginning, one for end), not %d',length(enclosure_strings));
assert(length(size(vec))<=2,'Input must have two or fewer dimensions');
assert(isempty(varargin),'There are %d unknown inputs',length(varargin));

% if a column vector, convert to row vector
if min(size(vec))==1 && size(vec,1)>1
    vec=vec';
end

% construct output string internals (values + delimiters)
if size(vec,1)==1
    
    % row vector
    str = sprintf([format_string delimiter_string],vec);
else
    
    % matrix, with semicolon+space between rows
    str = cell(1,size(vec,1));
    for kk=1:size(vec,1)
        str{kk} = sprintf([format_string delimiter_string],vec(kk,:));
        str{kk} = sprintf(['%s;' delimiter_string],str{kk}(1:end-length(delimiter_string)));
    end
    str = cat(2,str{:});
end

% add enclosure characters
str = sprintf([enclosure_strings(1) '%s' enclosure_strings(2)],str(1:end-length(delimiter_string)));