function varargout = errorMessage(ME,varargin)
% ERRORMESSAGE print nicely-formatted error information
%
%   ERRORMESSAGE(ME)
%   If ME is an object of class MException, print the error message and
%   debug stack for the error described by ME.  If ME is a char, print ME
%   to STDERR output.
%
%   MSG = ERRORMESSAGE(ME)
%   Return the error message as an output argument instead of printing to
%   screen.
%
%   MSG = ERRORMESSAGE(ME,TRUE)
%   Return the error message as an output argument and print to screen.
%
%   MSG = ERRORMESSAGE(...,'SCREEN')
%   MSG = ERRORMESSAGE(...,'NOSCREEN')
%   Control whether the error message is copied to the screen or not.
%
%   MSG = ERRORMESSAGE(...,'LINK')
%   MSG = ERRORMESSAGE(...,'NOLINK')
%   Control whether the message contains MATLAB-style URLs or not.

% standard error
STDERR=2;

% process inputs
copyToScreen = true; % default print to screen no matter what
hyperlinks = true; % default include hyperlinks
idx_no = strcmpi(varargin,'noscreen');
idx_yes = strcmpi(varargin,'screen');
if any(idx_no)
    copyToScreen = false;
    varargin(idx_no) = [];
end
if any(idx_yes)
    copyToScreen = true;
    varargin(idx_yes) = [];
end
idx_no = strcmpi(varargin,'nolink');
idx_yes = strcmpi(varargin,'link');
if any(idx_no)
    hyperlinks = false;
    varargin(idx_no) = [];
end
if any(idx_yes)
    hyperlinks = true;
    varargin(idx_yes) = [];
end
assert(isempty(varargin),'Unexpected inputs');

% will print to screen as well as return argument if true
if nargin<2||isempty(copyToScreen),copyToScreen=false;end

% construct output string
if isa(ME,'MException')
    
    % define error message
    msg = sprintf('%s',ME.message);
    
    % print out the db stack from the starting location
    stack = cell(1,length(ME.stack));
    for kk=1:length(ME.stack)
        if hyperlinks
            stack{kk} = sprintf('\tIn <a href="matlab:open(''%s'')">%s</a> on <a href="matlab:opentoline(''%s'',%d)">line %d</a>',...
                ME.stack(kk).file,ME.stack(kk).name,ME.stack(kk).file,ME.stack(kk).line,ME.stack(kk).line);
        else
            stack{kk} = sprintf('\tIn %s on line %d',ME.stack(kk).name,ME.stack(kk).line);
        end
    end
elseif ischar(ME)
    msg = ME;
else
    error('Unknown input of class "%s"',class(ME));
end

% check for output arguments
if nargout>0
    
    % return message as argument
    varargout{1} = msg;
    if nargout>1
        varargout{2} = stack;
    end
end

% no outputs or copyToScreen true
if nargout==0 || copyToScreen
    
    % print message to standard error output
    msg = strjoin([{msg} stack],'\n');
    fprintf(STDERR,'[ERROR] %s\n',msg);
end