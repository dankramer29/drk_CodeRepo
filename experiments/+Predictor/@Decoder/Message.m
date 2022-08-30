function Message(msg,varargin)
if(isempty(msg))
    fprintf('\n');
else
    fprintf('[DECODER] %s\n',sprintf(msg,varargin{:}));
end