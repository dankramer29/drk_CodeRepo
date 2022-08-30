function hsl = rgb2hsl(rgb)
% RGB2HSL Convert RGB value to HSL value
%
%   HSL = RGB2HSL(RGB)
%   Convert RGB, a M X 3 color matrix with values between 0 and 1 into HSL,
%   a M X 3 color matrix with values between 0 and 1.
%
%   See also HSL2RGB, RGB2HSV, HSV2RGB
%
%   Suresh E Joel, April 26,2003

% validate inputs
assert(nargin==1,'Wrong number of arguments');
assert(max(rgb(:))<=1 && min(rgb(:))>=0,'RGB values have to be between 0 and 1');
if size(rgb,2)~=3,rgb=rgb';end
assert(size(rgb,2)==3,'Must provide Nx3 input');

% loop over each color (rows of RGB)
hsl = nan(size(rgb));
for kk=1:size(rgb,1)
    
    % min/max
    mx = max(rgb(kk,:)); % max of the 3 colors
    mn = min(rgb(kk,:)); % min of the 3 colors
    imx = find(rgb(kk,:)==mx); % which color has the max
    
    % luminance
    hsl(kk,3) = (mx+mn)/2; % half of max value + min value
    
    % corner case: all three colors have same value
    if mx==mn
        hsl(kk,2) = 0; % s=0
        hsl(kk,1) = 0; % h is undefined but for practical reasons 0
        continue;
    end
    
    % saturation
    if hsl(kk,3)<0.5
        hsl(kk,2) = (mx-mn)/(mx+mn);
    else
        hsl(kk,2) = (mx-mn)/(2-(mx+mn));
    end;
    
    % if two colors have same value and be the maximum, use the first color
    switch imx(1)
        case 1
            
            % red is the max color
            hsl(kk,1) = ((rgb(kk,2)-rgb(kk,3))/(mx-mn))/6;
        case 2
            
            % green is the max color
            hsl(kk,1) = (2+(rgb(kk,3)-rgb(kk,1))/(mx-mn))/6;
        case 3
            
            % blue is the max color
            hsl(kk,1) = (4+(rgb(kk,1)-rgb(kk,2))/(mx-mn))/6;
    end
    
    % if hue is negative, add 1 to get it within 0 and 1
    if hsl(kk,1)<0
        hsl(kk,1) = hsl(kk,1)+1;
    end
end

% Sometimes the result is 1+eps instead of 1 or 0-eps instead of 0 ... so
% to get rid of this I am rounding to 5 decimal places)
hsl = round(hsl*100000)/100000;
