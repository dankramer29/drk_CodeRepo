function argempty(args)

% get a list of unused inputs
chargs = '';
for kk=1:length(args)
    if ischar(args{kk})
        chargs = sprintf('%s, %s',chargs,char(args{kk}));
    elseif isnumeric(args{kk})
        chargs = sprintf('%s, %s',chargs,util.vec2str(args{kk}));
    else
        chargs = sprintf('%s, [%s]',chargs,class(args{kk}));
    end
end

% if any exist, append to the message about unexpected inputs
msg = sprintf('There are %d unexpected inputs',length(args));
if ~isempty(chargs)
    fmt = '%s: %s.';
    arg = {msg,chargs(3:end)};
else
    fmt = '%s.';
    arg = {msg};
end

% make the assertion
if ~isempty(args)
    ME = MException('argempty:notempty',fmt,arg{:});
    throwAsCaller(ME);
end