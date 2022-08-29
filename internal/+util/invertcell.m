function x = invertcell(x)
% INVERTCELL Flip the hierarchy of a cell array
%
%   X = INVERTCELL(X)
%   For cell array X of size 1xB, where each cell of X is a cell array of
%   size 1xA, rearrange X so that Xhat{a}{b} = X{b}{a}.

A = cellfun(@length,x);
assert(numel(unique(A))==1,'cell array must have consistent dimensions');
A = unique(A);
B = length(x);
x = arrayfun(@(a)arrayfun(@(b)x{b}{a},1:B,'UniformOutput',false),1:A,'UniformOutput',false);


% ndim1 = cellfun(@ndims,x);
% assert(numel(unique(ndim1))==1,'cell array must have consistent dimensions');
% ndim1 = unique(ndim1);
% A = cell(1,ndim1);
% [A{:}] = cellfun(@size,x);
% tmpA = cat(1,A{:});
% sse = sum( sum((tmpA - mean(tmpA,2)).^2) );
% assert(sse==0,'cell array must have consistent dimensions');
% A = {A{1}(1),A{2}(1)};
% 
% ndim2 = ndims(x);
% B = cell(1,ndim2);
% [B{:}] = size(x);
% 
% A = cellfun(@(x)1:x,A,'UniformOutput',false);
% B = cellfun(@(x)1:x,B,'UniformOutput',false);
% idx = cell(1,ndim1+ndim2);
% [idx{:}] = ndgrid(A{:},B{:});
% idx = cellfun(@(x)x(:),idx,'UniformOutput',false);
% idx = cat(2,idx{:});
% idxA = idx(:,1:ndim1);
% idxA = arrayfun(@(a){idxA(a,:)},1:size(idxA,1),'UniformOutput',false);
% idxB = idx(:,ndim1+(1:ndim2));
% idxB = arrayfun(@(a){idxB(a,:)},1:size(idxB,1),'UniformOutput',false);
% 
% 
% 
% x = cellfun(@(a,b)x{b{:}}{a{:}},idxA,idxB,'UniformOutput',false);
% 
% 
% x = arrayfun(@(a1,a2)arrayfun(@(b1,b2)x{b1,b2}{a1,a2},1:B1,1:B2,'UniformOutput',false),1:A1,1:A2,'UniformOutput',false);