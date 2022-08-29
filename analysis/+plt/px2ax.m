function pos = px2ax(ax,px,xlims,ylims)
% PX2AX Convert pixels into axes position
%
%   PX = PX2AX(AX,POS)
%   Convert the [x,y] value POS from axes units into pixels.  The values in
%   POS must have the same units as the axes AX (i.e. get(AX,'Units')
%   value).
%
%   PX = AX2PX(AX,POS,XLIMS,YLIMS)
%   Use the specified x and y limits instead of the current axes settings.
%
%   See also PX2AX.

% validate inputs
if size(px)~=2,px=px';end
assert(size(px,2)==2,'Must provide positions as a Nx2 set of [x,y] coordinates in pixel space');
npos = size(px,1);

% get axes position, xlim, and ylim
axpos = getpixelposition(ax);
if nargin<3,xlims = get(ax,'XLim');end
if nargin<4,ylims = get(ax,'YLim');end

% convert: axes coordinates are xlim(1) + proportionate distance across
pos = nan(npos,2);
for kk=1:npos
    pos(kk,1) = xlims(1) + diff(xlims)*(px(kk,1)-axpos(1))/axpos(3);
    pos(kk,2) = ylims(1) + diff(ylims)*(px(kk,2)-axpos(2))/axpos(4);
end