function [pos,sz,clr] = getObjectPositionSizeColor(user,type,number,varargin)
% GETOBJECTPOSITIONSIZECOLOR Get positions size and color for objects
srcdir = fullfile(env.get('media'),'img');
info = Task.NumberLanguage.getCueData(type{1},type{2});

img = fullfile(srcdir,info{1});
assert(exist(img,'file')==2,'Cannot find image ''%s''',img);
info = imfinfo(img);
dims = [info.Width info.Height];

% determine size, color, position for each trial of this type
pos = cell(1,length(number));
sz = cell(1,length(number));
clr = cell(1,length(number));
for kk=1:length(number)
    
    % default color
    thisColor = nan;
    
    % default object size (maximum dimension)
    switch lower(user.objectSizeSrc)
        case 'params'
            if dims(1)>dims(2) % width>height
                thisSize = [user.objectSize user.objectSize*dims(2)/dims(1)];
            else
                thisSize = [user.objectSize*dims(1)/dims(2) user.objectSize];
            end
        case 'file'
            thisSize = dims;
    end
    
    % get positions
    thisPosition = util.getRandomPositions(number(kk),...
        user.displayresolution,... % display resolution
        [50 50],... % inner spacing in pixels
        [50 50],... % outer spacing in pixels
        thisSize); % sizing
    thisPosition = thisPosition'; % targets in columns, x/y in rows
    
    % custom values provided in type cell array
    for nn=1:length(varargin)
        if isscalar(varargin{nn})
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