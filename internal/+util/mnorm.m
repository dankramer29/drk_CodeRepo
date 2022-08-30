function out=mnorm(in)

%returns the two-norm across the rows of a matrix;
%ie if in=nxp; out is vec of norms of length 'n'

out=sqrt(sum(in.^2,2));