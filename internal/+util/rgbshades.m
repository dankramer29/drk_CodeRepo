function colors = rgbshades(color,num,range,dim,style)
% RGBSHADES Get shades of a specific color
%
%   COLORS = RGBSHADES(COLOR)
%   Get back 5 (default) shades of the color specified by RGB triplet in
%   COLOR, ranging over -30% to +10% luminance from the provided color.
%
%   COLORS = RGBSHADES(COLOR,NUM)
%   Specify the number of colors to return. DEFAULT: 5.
%
%   COLORS = RGBSHADES(COLOR,NUM,RANGE)
%   Specify the range of luminance to cover in the returned colors.
%   DEFAULT: [-0.3 0.1].
%
%   COLORS = RGBSHADES(COLOR,NUM,RANGE,DIM)
%   Specify the aspect the color to vary. Can provide string representation
%   (hue, [sat]uration, or [lum]inance) or number (1=hue, 2=saturation,
%   3=luminance). DEFAULT: luminance.
%
%   COLORS = RGBSHADES(COLOR,NUM,RANGE,DIM,STYLE)
%   Specify the style of operation: "absolute" or "relative". In the case
%   of absolute, the range becomes the actual range of values. In the case
%   of relative, the range is added to the existing value. DEFAULT:
%   relative.
%
% See also PLOT.RGB2HSL, PLOT.HSL2RGB.
if nargin<2||isempty(num),num=5;end
if nargin<3||isempty(range),range=[-0.3 0.1];end
if nargin<4||isempty(dim),dim=3;end
if nargin<5||isempty(style),style='relative';end
if ischar(dim)
    if strncmpi(dim,'hue',3)
        dim = 1;
    elseif strncmpi(dim,'saturation',3)
        dim = 2;
    elseif strncmpi(dim,'luminance',3)
        dim = 3;
    else
        error('Unknown dim value ''%s''',dim);
    end
end
if isscalar(range),range=[range range];end
assert(range(2)>=range(1),'Range must be nondecreasing, i.e., [LOWER UPPER]');

% create new color by varying one of the aspects (hue/sat/lum)
hsl = util.rgb2hsl(color);
switch lower(style)
    case 'absolute'
        range(1) = max(range(1),0);
        range(2) = max(range(2),0);
        range(1) = min(range(1),1);
        range(2) = min(range(2),1);
        newdim = linspace(range(1),range(2),num);
    case 'relative'
        if hsl(dim)+range(1)<0
            range = [-hsl(dim) range(2)];
        end
        if hsl(dim)+range(2)<0
            range = [range(1) -hsl(dim)];
        end
        if hsl(dim)+range(1)>1
            range = [1-hsl(dim) range(2)];
        end
        if hsl(dim)+range(2)>1
            range = [range(1) 1-hsl(dim)];
        end
        offset = linspace(range(1),range(2),num);
        newdim = hsl(dim) + offset;
    otherwise
        error('Unknown style ''%s''',style);
end
switch dim
    case 1, newhsl = [newdim(:) repmat(hsl(2:3),length(newdim),1)];
    case 2, newhsl = [repmat(hsl(1),length(newdim),1) newdim(:) repmat(hsl(3),length(newdim),1)];
    case 3, newhsl = [repmat(hsl(1:2),length(newdim),1) newdim(:)];
    otherwise, error('Unknown dim');
end

% convert HSL colors back to RGB
colors = util.hsl2rgb(newhsl);