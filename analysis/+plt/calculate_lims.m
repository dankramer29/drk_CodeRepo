function varargout = calculate_lims(varargin)
% CALCULATE_LIMS Calculate limits from data to be plotted
%
%   [LIM1,LIM2,...] = CALCULATE_LIMS(DATA1,DATA2,...)
%   Calculate min/max plot limits for each data set.  Limits are calculated
%   as 2 times the interquartile range of the data.

% defaults
[varargin,which] = Utilities.argkeyword({'row','rows','col','cols'},varargin,'cols');
dim = 1; % calculate across first dimension, which means data are in columns
if strncmpi(which,'rows',3),dim=2;end % operate over second dimension, so data are in rows
[varargin,idx,~,found_idx] = Utilities.argkeyval('idx',varargin,nan);
[varargin,tile] = Utilities.argkeyval('tile',varargin,[0.5 99.5]);
[varargin,thresh] = Utilities.argkeyval('thresh',varargin,0.35);
[varargin,margin] = Utilities.argkeyval('margin',varargin,1);
[varargin,method] = Utilities.argkeyword({'minmax','prctile'},varargin,'minmax');

% calculate naive new range and minimum spacing
assert(length(varargin)==1&&isnumeric(varargin{1})&&numel(size(varargin{1}))==2,'Must provide two-dimensional data');
dt = varargin{1};
if dim==2,dt=dt';end % code written for columns, so adjust data if needed
if ~found_idx,idx=1:size(dt,2);end % default all columns
dt = dt(:,idx); % subselect requested columns only
varargout = cell(1,size(dt,2));
for kk=1:size(dt,2)
    switch lower(method)
        case 'minmax'
            
            % take the min/max as the limits
            varargout{kk} = [min(dt(:,kk)) - margin*std(dt(:,kk)) max(dt(:,kk)) + margin*std(dt(:,kk))];
        case 'prctile'
            
            % find the the percentiles specified by "tile" and inter-percentile range
            percentiles = prctile(dt(:,kk),tile);
            iprange = diff(percentiles,1);
            
            % calculate range (quartile +/- thresh*iqr)
            varargout{kk} = [percentiles(1)-thresh*iprange; percentiles(2)+thresh*iprange];
        otherwise
            
            % unknown method
            error('Unknown method ''%s''',method);
    end
    
    % catch a scenario in which max==min, resulting in error on xlim/ylim
    if diff(varargout{kk})==0
        varargout{kk} = [-inf inf];
    end
end