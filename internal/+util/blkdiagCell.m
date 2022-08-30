function y = blkdiagCell(ABC)

% same as blockdiag but now taks a cell of matrices.  The main reason for
% making this is to allow a single matrix could be coppied an arbitrary
% number of times:
%   A=util.blkdiagCell(repmat({A},1,5));

p2 = zeros(length(ABC)+1,1);
m2 = zeros(1, length(ABC)+1);
for k=1:length(ABC)
    x = ABC{k};
    [p2(k+1),m2(k+1)] = size(x); %Precompute matrix sizes
    
end
%Precompute cumulative matrix sizes
p1 = cumsum(p2);
m1 = cumsum(m2);

y = zeros(p1(end),m1(end)); %Preallocate for full doubles only
for k=1:length(ABC)
    y(p1(k)+1:p1(k+1),m1(k)+1:m1(k+1)) = ABC{k};
end
