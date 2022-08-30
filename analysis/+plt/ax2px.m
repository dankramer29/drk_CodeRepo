function px = ax2px(ax,pos,xlims,ylims)
% AX2PX Convert axes position to pixels
%
%   PX = AX2PX(AX,POS)
%   For each row of the Nx2 matrix POS, convert the [x,y] value from axes
%   units into pixels.  The values in POS must have the same units as the
%   axes AX (i.e. get(AX,'Units') value).
%
%   PX = AX2PX(AX,POS,XLIMS,YLIMS)
%   Use the specified x and y limits instead of the current axes settings.
%
%   See also PX2AX.

% validate inputs
if size(pos)~=2,pos=pos';end
assert(size(pos,2)==2,'Must provide positions as a Nx2 set of [x,y] coordinates in axes position space');
npos = size(pos,1);

% get axes position, xlim, and ylim
axpos = getpixelposition(ax);
if nargin<3,xlims = get(ax,'XLim');end
if nargin<4,ylims = get(ax,'YLim');end

% convert: pixels are left position + proportionate distance across axes
px = nan(npos,2);
for kk=1:npos
    px(kk,1) = axpos(1) + axpos(3)*(pos(kk,1)-xlims(1))/diff(xlims);
    px(kk,2) = axpos(2) + axpos(4)*(pos(kk,2)-ylims(1))/diff(ylims);
end