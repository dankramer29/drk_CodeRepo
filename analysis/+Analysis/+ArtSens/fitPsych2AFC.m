function [fitresults,gof] = fitPsych2AFC(xdata,ydata,varargin)


% make sure they are column vectors
xdata = xdata(:);
ydata = ydata(:);

fcnstr = '1 - 0.5*exp(-(((-log(0.5))^(1/beta))*x/alpha).^beta)';
coeffs = {'alpha','beta'};
low_range = [1 -Inf];
up_range = [100 Inf];
startpts = [0 0.1];
%fcnstr = '( 1.0 + 0.5*exp( - (x./alpha).^beta ) )';
[varargin,fcnstr] = util.argkeyval('function',varargin,fcnstr);
[varargin,coeffs] = util.argkeyval('coefficients',varargin,coeffs);
[varargin,low_range] = util.argkeyval('lower',varargin,low_range);
[varargin,up_range] = util.argkeyval('upper',varargin,up_range);
[varargin,robstr] = util.argkeyval('robust',varargin,'LAR');
[~,startpts] = util.argkeyval('start',varargin,startpts);

ft = fittype(fcnstr,'independent',{'x'},'dependent',{'y'},'coefficients',coeffs);
opts = fitoptions(ft);
opts.Display = 'Off';
opts.Lower = low_range;
opts.StartPoint = startpts;
opts.Upper = up_range;
opts.Robust = robstr;
opts.MaxFunEvals = 1000;
opts.MaxIter = 500;
opts.DiffMaxChange = 0.15;

[fitresults, gof] = fit(xdata,ydata,ft,opts);

end

