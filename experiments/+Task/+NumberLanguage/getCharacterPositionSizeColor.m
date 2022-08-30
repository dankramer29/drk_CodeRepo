function [pos,sz,clr] = getCharacterPositionSizeColor(user,type,number,varargin)
% GETCHARACTERPOSITIONSIZECOLOR Get positions size and color for characters

% determine size, color, position for each trial of this type
sz = cell(1,length(number));
clr = cell(1,length(number));
pos = cell(1,length(number));
for kk=1:length(number)
    
    % default values
    thisColor = user.fontColor;
    thisSize = user.fontSize;
    thisPosition = {'center','center'};
    
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