function [pos,sz,clr] = getCharacterPositionSizeColor(user,number,varargin)
% GETCHARACTERPOSITIONSIZECOLOR Get positions size and color for characters

% determine size, color, position for each trial of this type
sz = cell(1,length(number));
clr = cell(1,length(number));
pos = cell(1,length(number));
for kk=1:length(number)
    
    % default values
    thisColor = user.fontColor;
    thisSize = user.fontSize;
    
    % get positions
    dr = user.displayresolution;
    boundingbox = [dr(1)/4 dr(2)/4 dr(1)/2 dr(2)/2];
    thisPosition = util.getRandomPositionsInArea(number(kk),...
        boundingbox,...
        [10 10],...
        [10 10],...
        pts2pixels(thisSize));
%     thisPosition = util.getRandomPositions(number(kk),...
%         user.displayresolution,... % display resolution
%         [10 10],... % inner spacing in pixels
%         [10 10],... % outer spacing in pixels
%         pts2pixels(thisSize)); % sizing
    thisPosition = thisPosition'; % targets in columns, x/y in rows
    
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
        elseif length(varargin{nn})==2
            thisPosition = varargin{nn};
        end
    end
    
    % assign size, color, position
    sz{kk} = thisSize;
    clr{kk} = thisColor;
    pos{kk} = thisPosition;
end


function px = pts2pixels(pt)
% PTS2PIXELS Convert points to pixels

pt2px = [...
    6 8;
    7 9;
    7.5 10;
    8 11;
    9 12;
    10 13;
    10.5 14;
    11 15;
    12 16;
    13 17;
    13.5 18;
    14 19;
    14.5 20;
    15 21;
    16 22;
    17 23;
    18 24;
    20 26;
    22 29;
    24 32;
    26 35;
    27 36;
    28 37;
    29 38;
    30 40;
    32 42;
    34 45;
    36 48;];
px = interp1(pt2px(:,1),pt2px(:,2),pt,'linear','extrap');