function [a,b] = getNormValues(baseline,method,dim2,dim3,basedim)
%{
	[A,B] = GETNORMVALUES(BASELINE,METHOD,ROWS,COLS)        
	Get numerator and denominator values for normalization, according to
    specified normalization/standarization method.
    basedim is the dimension you want the mean and std to be done across
%}

% Input error check
narginchk (2,5);

if nargin == 2 || isempty([dim2(:);dim3(:)])
    dim2 = 1; dim3 = 1; basedim = 2;
end

if nargin == 4
    basedim = 2;
end

if size(baseline,3) > 1
    basedim = 3;
end

switch method
    case 'z-score'
        a = nanmean(baseline,basedim);
        b = nanstd(baseline,[],basedim);
    case 'minmax'
        a = nanmin(baseline,[],basedim);
        b = nanmax(baseline,[],basedim);
    case 'robust1'
        a = nanmedian(baseline,basedim);
        b = mad(baseline,0,basedim);
    case 'robust2'
        a = nanmedian(baseline,basedim);
        b = mad(baseline,1,basedim);
end
if size(a,2) == dim2 
    if size(a,1) == size(baseline,1)
        a = repmat(a,1,1,dim3);
        b = repmat(b,1,1,dim3);
    elseif dim3 > 1
        a = repmat(a,size(baseline,1),1,dim3);
        b = repmat(b,size(baseline,1),1,dim3);
    else
        a = repmat(a,size(baseline,1),1);
        b = repmat(b,size(baseline,1),1);
    end
else
    a = repmat(a,1,dim2,dim3);
    b = repmat(b,1,dim2,dim3);
end

end % END of getNormValues function
