function [idx,iprange,inner_fence,percentiles]=outliers(data,tile,thresh,sides,varargin)
% [idx,iprange,inner_fence]=outliers(data,tile,thresh)
% 
% Find outliers in a vector.
% skellis 12/6/2010
%
% method: http://www.itl.nist.gov/div898/handbook/prc/section1/prc16.htm
%
% Inputs:
%   data   - vector of observations from a single variable
%   tile   - percentiles used (optional; default [25 75])
%   thresh - multiplied by the inter-percentile range to get the inner 
%            fence (optional; default 1.5)
%   sides  - two-sided ('both'), or one-sided ('left' or 'right')
%
% Outputs:
%   idx         - index of outliers in the input data vector
%   iprange     - the inner-percentile range (see "help iqr")
%   inner_fence - the thresholds calculated for outlying values
%   percentiles - percentiles used to calculate fences
%
% TO DO:
% finish adaptive percentiles code
% test for gaussian-ness, and apply transformations (sqrt, log) if not
% gaussian?

% process inputs/defaults
if nargin<4||isempty(sides)
    sides = 'both';
end
if nargin<3||isempty(thresh)
    thresh = 1.5;
end
if nargin<2||isempty(tile)
    tile = [25 75];
end

% default values (no outliers, nan stats)
idx = [];
iprange = NaN;
inner_fence = [NaN NaN];
percentiles = [NaN NaN];
if ~any(isfinite(data(:))),return;end
if numel(data)<=1,return;end

% make sure data is a column array
if size(data,1)==1
    [~,which] = max(size(data));
    data = permute(data,[which setdiff(1:length(size(data)),which)]);
end
assert(size(data,1)>1,'Must provide a column vector or matrix');
sz = size(data);

% select uniform output
uniformOutput = length(sz)==2&&sz(2)==1;
idx = strcmpi(varargin,'UniformOutput');
if any(idx)
    uniformOutput = varargin{circshift(idx,1,2)};
end

% select adaptive or fixed percentile mode
adaptivePercentile = false;
idx = strcmpi(varargin,'adaptivePercentile');
if any(idx)
    adaptivePercentile = varargin{circshift(idx,1,2)};
end

% rearrange data for easier processing
data=data(:,:);

% find the the percentiles specified by "tile" and inter-percentile range
if adaptivePercentile
    for kk=1:size(data,2)
        
        % motivation: if there are outliers, then at some point the value
        % of the percentile will jump, so looking for the max difference
        % between adjoining percentile values could correspond to a
        % boundary between "normal" and "outlier" values. we'll use the
        % percentile just before that boundary as the basis for the
        % threshold test.
        p = prctile(data(:,kk),90:0.5:100);
        dp = diff(p);
        [~,idx] = max(dp);
        percentiles(2,kk) = p(idx);
        
        % now do the same for the minimum value (note coming at it from the
        % opposite side, so looking for min, taking one after the min, etc)
        p = prctile(data(:,kk),0:0.5:10);
        dp = diff(p);
        [~,idx] = min(dp);
        percentiles(1,kk) = p(idx+1);
    end
else
    percentiles=prctile(data,tile);
    if size(percentiles,1)==1,percentiles=percentiles(:);end
end
iprange=squeeze(diff(percentiles,1));

% calculate inner fences (quartile +/- thresh*iqr)
inner_fence=[percentiles(1,:)-thresh*iprange; percentiles(2,:)+thresh*iprange];

% identify outliers
if strcmpi(sides,'both')
    idx=arrayfun(@(x)find(data(:,x)<inner_fence(1,x)|data(:,x)>inner_fence(2,x)),1:size(data,2),'UniformOutput',false);
elseif strcmpi(sides,'left')
    idx=arrayfun(@(x)find(data(:,x)<inner_fence(1,x)),1:size(data,2),'UniformOutput',false);
elseif strcmpi(sides,'right')
    idx=arrayfun(@(x)find(data(:,x)>inner_fence(2,x)),1:size(data,2),'UniformOutput',false);
end

% reshape outliers to match input data size
if length(sz)>2,idx=reshape(idx,sz(2:end));end

% take out of cell if uniform output flag set
if uniformOutput
    assert(length(idx)==1,'Uniform output only possible with single column vector input');
    idx = idx{1};
end