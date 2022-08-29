function message(str,lvl,opt,src)
% MESSAGE Print a message to the screen based on priority and verbosity
%
%   MESSAGE
%   With no inputs, print double newline characters.
%
%   MESSAGE(STR,LVL,OPT)
%   Print the message in STR to the screen if the priority LVL is less than
%   or equal to the verbosity defined by the field or property "verbosity"
%   in the object or struct OPT.  The message priority LVL may be any
%   numerical value, including +/- Inf, but may not be NaN.  It may also be
%   provided as a string representation:
%
%     STRING    NUMBER  PRIORITY
%     critical  0       The message must always be printed.
%     error     1       The message represents an error.
%     warning   2       The message is a warning.
%     info      3       The message contains information.
%     hint      4       The message is useful but not that important.
%     debug     5       The message is for debug purposes.
%     insanity  6       The message is superfluous and probably not useful.
%
%  MESSAGE(STR,LVL,OPT,SRC)
%  Additionally provide a string label indicating the source of the
%  message.  For example, simply add the MATLAB command MFILENAME as the
%  last argument when calling. If no source is provided, the third entry
%  in the DBSTACK will be used.
if isempty(opt)
    opt = struct('verbosity',Debug.PriorityLevel.WARNING);
elseif isnumeric(opt) || isenum(opt) || isa(opt,'Debug.PriorityLevel')
    opt = struct('verbosity',opt);
end

% if message level is within verbosity level, print the message
if nargin==0
    
    % no input, just print newlines
    fprintf('\n\n');
else
    
    % handle char priority level input
    if ischar(lvl)
        switch lower(lvl)
            case {'crit','critical','essential'}
                lvl=0;
            case 'error'
                lvl=1;
            case {'warn','warning'}
                lvl=2;
            case {'info','information'}
                lvl=3;
            case 'hint'
                lvl=4;
            case 'debug'
                lvl=5;
            case {'insanity','ludicrous'}
                lvl=6;
            otherwise
                error('Unknown priority level ''%s''',lvl);
        end
    end
    
    % validate priority level
    assert(isnumeric(lvl),'Invalid message priority');
    
    % check priority against verbosity level
    if lvl<=opt.verbosity
        if nargin<4 || isempty(src)
            stack = dbstack;
            src = stack(3).name;
        end
            
        % print the message
        fprintf('%s: %s\n',src,str);
    end
end