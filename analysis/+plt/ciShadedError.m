function [h] = ciShadedError(mn, ci)
%ciShadedError plots a shaded error bar correctly with a mean and
%confidence interval from bootci
%   to get the mean and ci, perform like this
% mn=nanmean(data);%fullITI collapse across time, so it's one number for each freq bin for the whole time
% ci=bootci(1000, {@mean, data, 'type', 'cper');
%       


N=36;
C=linspecer(N);
clr=randi(34);
cidiff=mn-ci(:,1);
plot( mn, 'LineWidth', 2, 'Color', C(clr,:));
hold on
plot( ci(:,1), 'Color', C(clr+2,:));
plot( ci(:,2), 'Color', C(clr+2,:));




end

