function rgb = hsl2rgb(hsl)
% HSL2RGB Convert HSL value to RGB value
%
%   RGB = hsl2rgb(HSL)
%   Convert HSL, a M X 3 color matrix with values between 0 and 1 into RGB,
%   a M X 3 color matrix with values between 0 and 1.
%
%   See also RGB2HSL, RGB2HSV, HSV2RGB
%
%   Suresh E Joel, April 26,2003

% validate inputs
assert(nargin==1,'Wrong number of arguments');
assert(max(hsl(:))<=1 && min(hsl(:))>=0,'HSL values have to be between 0 and 1');
if size(hsl,2)~=3,hsl=hsl';end
assert(size(hsl,2)==3,'Must provide Nx3 input');

% loop over each color (rows of HSL)
rgb = nan(size(hsl));
for kk=1:size(hsl,1)
    
    % corner case: 0 saturation
    if hsl(kk,2)==0
        
        % all values are same as luminance
        rgb(kk,1:3)=hsl(kk,3);
    end
    
    % calculate red, green, blue
    if hsl(kk,3)<0.5,
        temp2 = hsl(kk,3)*(1+hsl(kk,2));
    else
        temp2 = hsl(kk,3)+hsl(kk,2)-hsl(kk,3)*hsl(kk,2);
    end
    temp1 = 2*hsl(kk,3)-temp2;
    temp3(1) = hsl(kk,1)+1/3;
    temp3(2) = hsl(kk,1);
    temp3(3) = hsl(kk,1)-1/3;
    for jj=1:3
        if temp3(jj)>1
            temp3(jj) = temp3(jj)-1; 
        elseif temp3(jj)<0
            temp3(jj) = temp3(jj)+1; 
        end
        if 6*temp3(jj)<1
            rgb(kk,jj) = temp1+(temp2-temp1)*6*temp3(jj);
        elseif 2*temp3(jj)<1
            rgb(kk,jj) = temp2;
        elseif 3*temp3(jj)<2
            rgb(kk,jj) = temp1+(temp2-temp1)*(2/3-temp3(jj))*6;
        else
            rgb(kk,jj) = temp1;
        end
    end
end

% Sometimes the result is 1+eps instead of 1 or 0-eps instead of 0 ... so
% to get rid of this I am rounding to 5 decimal places)
rgb = round(rgb.*100000)./100000;
