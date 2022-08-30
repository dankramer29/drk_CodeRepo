function plotsave(name,formats,handle)
%       COMMON.PLOTSAVE(NAME,FORMATS,HANDLE)
% Helper function to save figures in multiple formats, defaults is to save
% current figure in *.fig and *.png format.
%

if nargin == 1 || isempty(formats); formats = {'fig','png'}; end;
if nargin < 3 || isempty(handle); handle = gcf; end

% check is cell
if ~iscell(formats); formats = cellstr(formats); end

% check if single string/cell or cell array
if ischar(name)
    name = repmat(cellstr(name),size(formats));
elseif iscell(name) && length(name) == 1
    name = repmat(name,size(formats));
end

for kk = 1:length(formats)
    saveas(handle,name{kk},formats{kk});
end

end % END of PLOTSAVE function