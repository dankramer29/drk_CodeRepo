function [q,d,n] = quantvsep(allq,alld,conf,fn)
if nargin<3||isempty(conf),conf=false;end
if nargin<4||isempty(fn),fn={@nanmean,1};end
fn = util.ascell(fn);
assert(isa(fn{1},'function_handle'),'Function input must be a cell array where the first cell is a function handle');

% validate inputs
assert(length(size(allq))==2,'Input quantity must be 2D matrix');
if size(allq,2)~=length(alld),allq=allq';end
assert(size(allq,2)==length(alld),'Input quantities must have same number of columns as entries in d');

% get list of unique separation distances
d = unique(alld(~isnan(alld)));

% compute average value across all instances of the quantity at that
% separation distance
if conf
    q = nan(2,size(allq,1),length(d));
else
    q = nan(size(allq,1),length(d));
end
n = nan(1,length(d));
for kk=1:length(d)
    
    % identify indices of all pairs at this separation distance
    idx_sep = alld==d(kk);
    assert(nnz(idx_sep)>0,'No separations available here');
    n(kk) = nnz(idx_sep);
    
    % shortcut if there is only one pair of channels at this separation
    % distance and user has requested a confidence interval
    if conf && nnz(idx_sep)==1
        q(1,:,kk) = -inf;
        q(2,:,kk) = inf;
        continue;
    end
    
    % get data corresponding to these indices
    allvals = allq(:,idx_sep)';
    
    % compute the desired metric over these values (default nanmean)
    try
        if conf
            q(:,:,kk) = bootci(1e3,[fn(1),{allvals},fn(2:end)],'alpha',0.05);
        else
            q(:,kk) = feval(fn{1},allvals,fn{2:end});
        end
    catch ME
        util.errorMessage(ME);
        keyboard;
    end
end