function t = getTimer(name,varargin)
%t = getTimer(name,varargin)
%passes name-value pairs directly from varargin to timer

% retrieve or create timer
tt = timerfind('Name',name);
if ~isempty(tt), delete(tt); end
t = timer('Name',name); % create new

idx=1;
while idx < length(varargin)
    t.(varargin{idx}) = varargin{idx+1};
    idx = idx+2;
end
