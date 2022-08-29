function t = makeColumnLabels(tspec,labels,varargin)
%{
            T = MAKECOLUMNLABELS(TSPEC,VARARGIN)

        Creates cell array with "sparse" labels in specified time/frequency
        points through optional input LABELS, or in default time marks
        of 0, 200, 400,...,tspec(end) ms. Default labels are made for time
        vector, but optional input can specify for frequency labels
%}

% Set defaults
if nargin == 1; labels = 0:200:ceil(tspec(end)*1000); end
mult = 1000; % multiplier, to get time in milliseconds

% check if time or frequency labels
idx = find(strcmpi(varargin,'frequency'),1);
if ~isempty(idx); mult = 1; end

t = linspace(floor(tspec(1)),round(tspec(end)),length(tspec))*mult; % plot in milliseconds (if time vector)
if mult == 1000
    t(~ismember(round(t),labels)) = NaN;
else
    t(~any((repmat(t,length(labels),1)-repmat(labels',1,length(t))) >= 0 & (repmat(t,length(labels),1)-repmat(labels',1,length(t))) <= 2)) = NaN;
    t = floor(t/10)*10; % truncate to closest multiple of 10.
end
% check for repeated values
t(~isnan(diff([NaN t]))) = NaN;

t = num2cell(t,1);
t = cellfun(@num2str,t,'UniformOutput',false); % convert to cell array
t(cellfun(@(x)strcmp(x,'NaN'),t)) = {' '}; % make NaN values blank spaces
end % END of makeColumnLabels function