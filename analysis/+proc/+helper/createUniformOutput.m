function [x,varargout] = createUniformOutput(x,varargin)
% CREATEUNIFORMOUTPUT Combine cell array data into a single matrix
%
%   Xu = CREATEUNIFORMOUTPUT(X)
%   Collapse data in cell array X into uniform, numeric matrix output Xhat.
%   All cells of X must have the same size in all dimensions. The unified
%   output Xu will consist of the cells of X concatenated along a new
%   dimension NDIMS(X)+1. This usage of CREATEUNIFORMOUTPUT is equivalent
%   to and slower than calling CAT(NDIMS(X)+1,X{:}) and exists purely for
%   consistency.
%
%   [Xu,Tu] = CREATEUNIFORMOUTPUT(X,T)
%   Additionally provide an indexing variable T that will be used to pare
%   down data in cells of X to the same size prior to concatenation. T must
%   be a cell array with the same number of cells as X, and the kth cell of
%   T must have the same length as SIZE(X{k},1). (For example, T{k} could
%   be a time vector where each element of T{k} is the timestamp associated
%   with the same row of X{k}.) A new, unified indexing vector Tu will be
%   formed with the range [MAX(CELLFUN(@MIN,T)) MIN(CELLFUN(@MAX,T))]. This
%   same range will be applied to the data in cells of X such that
%   SIZE(X{k},1)==LENGTH(Tu) for all k in 1:K. Then, Xu will be constructed
%   by concatenating the cells of X along a new dimension
%   LENGTH(SIZE(X{1}))+1.
%
%   [Xu,T1u,T2u,...,Tnu] = CREATEUNIFORMOUTPUT(X,T1,T2,...,Tn)
%   Provide additional indexing variables Tn, where Tn{k} corresponds to
%   the nth dimension of X{k}. These variables will be processed in the
%   same way as described above. All dimensions of X{k} for which there is
%   no corresponding T provided must have the same size across all K cells.
%
%   [Xu,T1u,T2u,...,Tnu,IDX] = CREATEUNIFORMOUTPUT(...)
%   Also return the indices IDX used to subsample each dimension.
%
%   [...] = CREATEUNIFORMOUTPUT(...,'precision',P)
%   Round Tn to a maximum precision of P(n). The input P must be a vector
%   of the same length as there are Tn provided, and P(n) should be of the
%   form 10^R(n), where R(n) is the decimal place corresponding to the
%   sampling period (i.e., the minimum desired spacing between elements of
%   Tn) of the nth dimension of X{k}. For example:
%
%     * T1{k} is a time vector associated with the first dimension of X{k}
%     * The sampling frequency of T1{k} is 2e3 samples/sec, with a sampling
%       period of 5e-4 sec
%     * We want to preserve nonzero values in the fourth (1e-4) decimal
%       place of T1{k}, but squash nonzero values in fifth (1e-5) and lower
%       places
%     * Thus, R(n) = 4 and P(n) = 10^R(n), or 1e4
%
%   A general formula for setting P(n) relative to the sampling rate FSn
%   used to generate the nth dimension of X{k} is the following:
%
%     P(n) = 10^(FLOOR(LOG10(FSn))+N)
%
%   where N is a fudge factor to increase or decrease precision (a good
%   starting point is N=2).
%
%   [...] = CREATEUNIFORMOUTPUT(...,'SQUEEZE')
%   Apply the MATLAB function SQUEEZE to Xu prior to returning (getting rid
%   of singleton dimensions, for example as in the case where data are
%   being single combined from a single feature). The default behavior is
%   not to squeeze the outputs.

% process X input
assert(iscell(x),'X must be a cell array');
N = length(size(x{1})); % number of dimensions in each cell of X
K = length(x); % number of cells in X
assert(all(cellfun(@(a)length(size(a))==N,x)),'All cells of X must have the same number of dimensions (%d)',N);

% look for precision input
p = [];
idx = strcmpi(varargin,'precision');
if any(idx)
    p = varargin{circshift(idx,1,2)};
    varargin(idx|circshift(idx,1,2)) = [];
end
Np = length(p);
flagSqueeze = false;
idx = strcmpi(varargin,'squeeze');
if any(idx)
    flagSqueeze = true;
    varargin(idx) = [];
end

% process incoming indexing vectors
t = varargin;
Nt = length(t); % Nt must be <= N and is the number of indexing variables provided
assert(Nt<=N,'X has %d dimensions, but %d indexing variables provided',N,Nt);
assert(all(cellfun(@(a)length(a)==K,t)),'All T must have the same number of cells as X (%d)',K);

% make sure there aren't too many P's
assert(Np<=Nt,'%d indexing variables provided, but %d precisions were provided (Np must be less than or equal to Nt)',Nt,Np);

% enforce precisions and identify the keep indices
idx_keep = cell(1,Nt);
for nn=1:Nt
    if nn<=Np && p(nn)~=1 % save a bit of computation
        cl = class(t{nn}{1});
        t{nn} = cellfun(@(a)cast(round(double(a)*p(nn))/p(nn),cl),t{nn},'UniformOutput',false); % round to identified precision
    end
    ok_ = ~cellfun(@isempty,t{nn});
    
    % construct uniform t{nn} with common indices across all k in 1:K
    range(1) = nanmax(cellfun(@nanmin,t{nn}(ok_))); % maximum min value of indexing variable
    range(2) = nanmin(cellfun(@nanmax,t{nn}(ok_))); % minimum max value of indexing variable
    idx_keep{nn} = cell(size(t{nn}));
    idx_keep{nn}(ok_) = cellfun(@(x)x>=range(1)&x<=range(2),t{nn}(ok_),'UniformOutput',false); % calculate the keep indices for this dimension
    t{nn} = cellfun(@(a,b)a(b),t{nn}(:),idx_keep{nn}(:),'UniformOutput',false); % reduce t{nn} to the keep indices
    assert(numel(unique(cellfun(@length,t{nn}(ok_))))==1,'At this point all relt should be equal'); % make sure all t{nn} same size
    t{nn} = t{nn}{find(ok_,1,'first')}; % reduce t{nn} to single vector
    
    % create set of ':' for n-dimensional indexing
    idx = arrayfun(@(a)repmat({':'},1,N),1:K,'UniformOutput',false);
    
    % replace the nnth ':' with idx_keep for subselecting common elements
    idx = cellfun(@(a,b)[a(1:(nn-1)) {b} a((nn+1):end)],idx(:),idx_keep{nn}(:),'UniformOutput',false);
    
    % subselect the data
    x = cellfun(@(a,b)a(b{:}),x(:),idx(:),'UniformOutput',false);
end

% create full-rank NaN matrix for not-ok indices
ok_ = ~cellfun(@isempty,x);
for_not_ok = nan(size(x{find(ok_,1,'first')}),class(x{find(ok_,1,'first')}));
x(~ok_) = arrayfun(@(x)for_not_ok,find(~ok_),'UniformOutput',false);

% make sure all dimensions of x are equal
sz = size(x{1});
assert(all(cellfun(@(a)all(size(a)==sz),x)),'All dimensions of each cell of x must be equal before concatenation');

% construct new uniform x
x = cat(length(sz)+1,x{:});
if flagSqueeze
    x = squeeze(x);
end
varargout = [t idx_keep];