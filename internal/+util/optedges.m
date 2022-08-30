function [edges,binwidth] = optedges(data,binwidth,nshuf,nsamp)
% OPTEDGES calculate appropriate binwidth and edges for histogram count
%
%   [EDGES,BINWIDTH] = OPTEDGES(DATA)
%   Determine an appropriate binning of the data in DATA, and return the
%   corresponding edges of the bins and the binwidth. Algorithm shamelessly
%   borrowed from Mathworks' HISTCOUNTS function. By default, the edges
%   are constructed such that the first bin is centered around the minimum
%   value of DATA.
%
%   [EDGES,BINWIDTH] = OPTEDGES(DATA,BINWIDTH)
%   Specify the binwidth to use as a scalar, numerical value, or set to
%   'auto' to infer from the data (default behavior).
%
%   [EDGES,BINWIDTH] = OPTEDGES(DATA,BINWIDTH,NSHUF,NSAMP)
%   Instead of calculating the bin width and edge start points directly
%   from the data, take NSAMP samples from the data (with replacement)
%   NSHUF times and calculate the min, max, and standard deviation. The
%   average of these values will be used to determine the appropriate bins.

% validate data input
assert(min(size(data))==1&&length(size(data))==2,'Data input must be a vector');
minNumBins = 9;

% handle the case of all same value (including all zeros)
if numel(unique(data))==1
    binwidth = 1;
    edges = mean(data) + (binwidth/2) + (-round(minNumBins/2):(round(minNumBins/2)-1));
    return;
end

% formula for calculating binwidth
fn_binwidth = @(x,y)3.5*x/(y^(1/3)); % x - std dev, y - numel data

% determine edges and binwidth
if nargin>2 % shuffle
    assert(nargin==4,'Must provide both NSHUF and NSAMP inputs');
    
    % only if requested, sample the data to bootstrap the std dev
    if nargin==1 || isempty(binwidth) || (ischar(binwidth) && strcmpi(binwidth,'auto'))
        stds = util.shufflefun(nshuf,nsamp,data,@nanstd);
        binwidth = mean(fn_binwidth(stds,length(data)));
    end
    
    % adjust the percentiles used in determining minimum and maximum bins
    factor = 1;
    while diff(prctile(data,[0+factor 100-factor]))/binwidth <= minNumBins
        
        % require that the difference between the min and max allows for at
        % least 10 bins
        factor = factor/10;
        if factor<=1e-5
            
            % once we get too small, just use the min and max because we
            % catch the corner case of all identical values above
            factor = 0;
        end
    end
    
    % determine the binwidth and edge start/stop
    edge1 = prctile(data,factor) - binwidth/2;
    edge2 = prctile(data,100-factor) + binwidth/2;
else
    
    % borrowed from Mathworks' HISTCOUNTS
    if nargin==1 || isempty(binwidth) || (ischar(binwidth) && strcmpi(binwidth,'auto'))
        binwidth = feval(fn_binwidth,nanstd(data),numel(data));
    end
    
    % determine the edge start/stop
    edge1 = nanmin(data) - binwidth/2;
    edge2 = nanmax(data) + binwidth/2;
end

% calculate bin edges
edges = edge1:binwidth:edge2;

% make sure there are enough bins
while length(edges)<(minNumBins+1) % make sure enough bins
    edges = [edges(1)-binwidth edges edges(end)+binwidth];
end