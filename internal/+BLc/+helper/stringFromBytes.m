function s = stringFromBytes(b)
lt = find(b==0,1,'first');
assert(~isempty(lt),'String must be NULL terminated.');
b = b(:)';
s = char(b(1:lt-1));