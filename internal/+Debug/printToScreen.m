function fid = printToScreen(msg,fid)
if nargin<2||isempty(fid),fid=1;end

% make sure string input for message
if isnumeric(msg)
    return; % init/cleanup
else
    assert(ischar(msg),'Input should be char, not ''%s''',class(msg));
end

% write message to screen
fprintf(fid,'%s\n',msg);