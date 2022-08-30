function DefaultSettings_Common(obj)

% verify ptbopacity, ptbhid settings
[o,h] = env.get('ptbopacity','ptbhid');
if o<1.0,warning('Environment variable "ptbopacity" should be 1.0, but currently set to %.1f',o);end
if h~=1,warning('Environment variable "ptbhid" should be 1, but currently set to %d',h);end

obj.user.targetScale = 0.07;
obj.user.targetLayoutStyle = 'radial'; % 'radial' or 'grid'
obj.user.targetcolornames = {'gray'}';
obj.user.targetcolors = [1 1 1];
obj.user.targetbrightness = 255;
obj.user.fixationScale = 0.04;

switch obj.user.targetLayoutStyle
    case 'radial'
        obj.user.targetlocations = 1.15*[...
            0.0000    0.2000
            0.1414    0.1414
            0.2000    0.0000
            0.1414   -0.1414
            0.0000   -0.2000
            -0.1414   -0.1414
            -0.2000    0.0000
            -0.1414    0.1414];
        obj.user.homeLocation = [0 0];
        obj.user.targetlocationnames = arrayfun(@(x)sprintf('target%d',x),(1:size(obj.user.targetlocations,1))','UniformOutput',false);
    case 'grid'
        z = 3;
        grid_end  = z^2;
        %incr = 1/(z+1);
        %incr_array = incr:incr:1-incr;
        incr_array = [0.2 0.5 0.8];
        
        pos_grid = ones(z,z,2);
        pos_grid(:,:,1) = pos_grid(:,:,1) .* incr_array;
        pos_grid(:,:,2) = pos_grid(:,:,2) .* incr_array;
        if rem(z,2) ~= 0
            middle = round(grid_end/2);
        else
            middle = 0;
        end
        pos_grid(middle) = [];
        
        obj.user.gridLocations = pos_grid;
    otherwise
        error('unknown style');
end

% control number of trials (one entry for each balance-condition option)
obj.user.balance = {'targetlocationnames'}';
obj.user.numTrialsPerBalanceCondition = 8; % number of trials for each balance condition

% font
obj.user.fontFamily = 'Courier New';
obj.user.fontSize = 80;
obj.user.fontColor = 255*[0.8 0.8 0.8];