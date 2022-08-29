function [pos,sz,clr] = getShapePositionSizeColor(user,type,number,varargin)
% GETSHAPEPOSITIONSIZECOLOR Get positions size and color for shapes

% determine size, color, position for each trial of this type
sz = cell(1,length(number));
clr = cell(1,length(number));
pos = cell(1,length(number));
for kk=1:length(number)
    
    % default values
    thisColor = user.shapeColor;
    thisSize = user.shapeSize;
    thisPosition = util.getRandomPositions(number(kk),...
        user.displayresolution,... % display resolution
        thisSize/2,... % inner spacing - no overlapping images
        0.1*min(user.displayresolution),... % outer spacing
        thisSize); % sizing
    thisPosition = thisPosition'; % targets in columns, x/y as rows
    
    % custom values provided in type cell array
    for nn=1:length(varargin)
        if any(strcmpi(varargin{nn},{'red','green','blue'}))
            switch lower(varargin{nn})
                case 'red',thisColor=[255 0 0];
                case 'green',thisColor=[0 255 0];
                case 'blue',thisColor=[0 0 255];
            end
        elseif length(varargin{nn})==3
            thisColor = varargin{nn};
        elseif isscalar(varargin{nn})
            thisSize = varargin{nn};
        elseif length(varargin{nn}(:)/2)==number(kk)
            thisPosition = varargin{nn};
        end
    end
    
    % assign size, color, position
    sz{kk} = thisSize;
    clr{kk} = thisColor;
    pos{kk} = thisPosition;
end