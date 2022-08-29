function [pos,sz,clr] = getImagePositionSizeColor(user,type,number,varargin)
% GETIMAGEPOSITIONSIZECOLOR Get positions size and color for images
srcdir = fullfile(env.get('media'),'img');
info = Task.NumberLanguage.getCueData(type{1},type{2});

% determine size, color, position for each trial of this type
pos = cell(1,length(number));
sz = cell(1,length(number));
clr = cell(1,length(number));
for kk=1:length(number)
    
    img = fullfile(srcdir,info{number(kk)+1});
    assert(exist(img,'file')==2,'Cannot find image ''%s''',img);
    im = imfinfo(img);
    dims = [im.Width im.Height];
    
    % default color
    thisColor = nan;
    
    % default image size (maximum dimension)
    switch lower(user.imageSizeSrc)
        case 'params'
            if dims(1)>dims(2) % width>height
                thisSize = [user.imageSize user.imageSize*dims(2)/dims(1)];
            else
                thisSize = [user.imageSize*dims(1)/dims(2) user.imageSize];
            end
        case 'file'
            thisSize = dims;
    end
    thisPosition = []; % empty will default to center of screen
    
    % custom values provided in type cell array
    for nn=1:length(varargin)
        if isscalar(varargin{nn})
            thisSize = varargin{nn};
        end
    end
    
    % assign size, color, position
    sz{kk} = thisSize;
    clr{kk} = thisColor;
    pos{kk} = thisPosition;
end