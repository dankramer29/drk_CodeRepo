function S=ApplyFilter(obj,F, Signal)

N=length(F)-1;

if size(Signal,2)<N+1
    S=mean(Signal,2);
else
    S=Signal(:,end:-1:end-N)*F(:);
end