function [a,b] = zScore(baseline,method, basedim)
%{
	[A,B] = zScore(BASELINE,METHOD)        
	Get numerator and denominator values for normalization, according to
    specified normalization/standarization method.
    basedim is the dimension you want the mean and std to be done across

It's not built for 3d
%}

% Input error check
narginchk (2,3);

if nargin == 2 
    basedim = 2;
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


a = repmat(a,1,size(baseline,basedim));
b = repmat(b,1,size(baseline,basedim));


end 
