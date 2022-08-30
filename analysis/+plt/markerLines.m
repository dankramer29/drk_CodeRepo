function [hl,ht] = markerLines(ax,x,varargin)
% MARKERLINES Add marker lines to a plot
%
%   [HL,HT] = MARKERLINES(AX,X)
%   Add marker lines to the plot in the axes AX at the x-positions in X.
%
%   MARKERLINES(...,'MarkerLabels',LBLS)
%   Provide a cell array of strings LBLS, with one entry ver value of X,
%   indicating the label of each marker line.
%
%   MARKERLINES(...,'LineWidth',WID)
%   Set the width of the marker lines to WID (default 2).
%
%   MARKERLINES(...,'Style',ST)
%   Set the line style of the marker lines to ST (default '-').
%
%   MARKERLINES(...,'VerticalAnchor',VA)
%   Set the vertical anchor (i.e., the zero-point along the y-axis) for the
%   marker labels (default 'TOP').
%
%   MARKERLINES(...,'VerticalOffset',VO)
%   Set the vertical offset between the vertical anchor and the closest
%   edge of the marker label, in pixels (default 4).
%
%   MARKERLINES(...,'HorizontalOffset',HO)
%   Set the horizontal offset between the marker line and marker label
%   (default 8).
%
%   MARKERLINES(...,'FontSize',FS)
%   Set the font size of the marker labels (default 8).
%
%   MARKERLINES(...,'FontWeight',FW)
%   Set the font weight of the marker labels (default 'bold').

% process inputs
[varargin,mlabels] = util.argkeyval('MarkerLabels',varargin,{});
[varargin,linewidth] = util.argkeyval('LineWidth',varargin,2);
[varargin,style] = util.argkeyval('LineStyle',varargin,'-');
[varargin,vanchor] = util.argkeyval('VerticalAnchor',varargin,'top');
[varargin,voffset] = util.argkeyval('VerticalOffset',varargin,4);
[varargin,hoffset] = util.argkeyval('HorizontalOffset',varargin,8);
[varargin,fontsize] = util.argkeyval('FontSize',varargin,8);
[varargin,fontweight] = util.argkeyval('FontWeight',varargin,'bold');
util.argempty(varargin);

xl = get(ax,'xlim');
yl = get(ax,'ylim');
idx = find(x>xl(1)&x<=xl(2));

% add markers if provided
xx = repmat(x(:)',2,1);
yy = repmat(yl(:),1,length(x));
hl = line(xx(:,idx),yy(:,idx),'Color',[0 0 0],'LineStyle',style,'LineWidth',linewidth,'Parent',ax);

% add labels if provided
if iscell(mlabels) && ~isempty(mlabels)
    assert(length(x)==length(mlabels),'Must provide one label per marker');
    axpos = getpixelposition(ax);
    ht = nan(1,length(idx));
    for nn=idx(:)'
        
        % convert x position into pixels
        pxval = plot.ax2px(ax,[x(nn) yl(2)],xl,yl);
        
        % convert y position from pixels back into axes coordinates
        switch vanchor
            case 'top'
                axval = plot.px2ax(ax,[pxval(1)-hoffset axpos(2)+axpos(4)-voffset],xl,yl);
                horiz = 'right';
            case 'bottom'
                axval = plot.px2ax(ax,[pxval(1)-hoffset axpos(2)+voffset],xl,yl);
                horiz = 'left';
            otherwise
                error('Unknown vertical orientation style ''%s''',vanchor);
        end
           
        % draw the text
        ht(nn) = text(axval(1),axval(2),mlabels{nn},'Rotation',90,'FontSize',fontsize,...
            'HorizontalAlignment',horiz,'FontWeight',fontweight,'Parent',ax);
    end
end

% make sure the axes limits didn't change from adding the lines
set(ax,'YLim',yl,'XLim',xl);