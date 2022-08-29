function [pos,sz,clr] = getSoundPositionSizeColor(user,type,number,varargin)
% GETSOUNDPOSITIONSIZECOLOR Get positions size and color for images

% determine size, color, position for each trial of this type
pos = cell(1,length(number));
sz = cell(1,length(number));
clr = cell(1,length(number));
for kk=1:length(number)
    sz{kk} = nan;
    clr{kk} = nan;
    pos{kk} = nan;
end