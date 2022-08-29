function y = vonmises(beta,x)

%  y=vonmises(beta,x) defined for (0:2*pi)
%
%  Von Mises (circular normal distribution) model for nonlinear fit:
%  y = y0 + exp(k * cos(x - theta)) / (2 * pi * besselj(0,k)) * A
%
%  input:
%       beta: matrix of parameters
%           beta(1): k - parameter of concetration, width
%           beta(2): theta - mean angle (preferred direction)
%           beta(3): A - amplitude
%           beta(4): y0 - offset
%       x: independent variable (phi = angles)
%
%  output:
%       y = y0 + exp(k * cos(x - theta)) / (2 * pi * besselj(0,k)) * A
%
%  needs:
%
if ((length(beta) ~= 4) || nargin ~= 2)
   error('usage  y = vonmises(beta,x)')
end 

% y =  beta(4) + (exp(beta(1) * cos(x - beta(2))) / (2 * pi * besseli(0,beta(1)))) * beta(3);
y =  (exp(beta(1) * cos(x - beta(2))) / (2 * pi * besseli(0,beta(1)))) * beta(3);
end