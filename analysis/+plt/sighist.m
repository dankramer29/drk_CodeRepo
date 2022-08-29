function [fig,ax] = sighist(varargin)
% SIGHIST plot signal horizontally plus a rotated histogram of the signal
%
%  AX = SIGHIST(Y)
%  Plot the data in Y vs the index of each value in Y in a lefthand plot
%  and plot a bar histogram of the data in a righthand plot, rotated 90
%  degrees clockwise. The handles to the axes are returned in AX. If Y is a
%  matrix, columns of Y will be interpreted as separate variables. 
%
%  AX = SIGHIST(X,Y)
%  Plot the data in Y vs the values in X. If Y is a matrix, X should either
%  be a single vector of the same length as size(Y,1), or a matrix with the
%  same size as Y.
%
%  SIGHIST(...,FIG,...)
%  Provide the figure handle FIG in which to create the axes for the signal
%  and histogram plots.
%
%  SIGHIST(...,'box',[LEFT BOTTOM WIDTH HEIGHT],...)
%  Specify the area within the area available in the figure in which to
%  generate the plots. Values for LEFT, BOTTOM, WIDTH, and HEIGHT range
%  from 0 to 1 and represent normalized area. This is useful when plotting
%  multiple instances of signal/histogram in a single figure. Note the
%  specification of "available area" above - when things such as the title
%  reduce the available area of the figure, the box area provided here
%  still represents normalized percentages.
% 
%  Example with two sets of signal/histogram, each occupying 50% of the
%  vertical height (100% of the horizontal width):
%
%    % first instance
%    >> fig = sighist(x1,y1,'box',[0 0.5 1 0.5])
%    
%    % second instance
%    >> sighist(fig,x2,y2,'box',[0 0 1 0.5])
%
%  SIGHIST(...,'legend',{'LABEL1','LABEL2',...})
%  Specify a legend when plotting multiple signals and their histograms.
%
%  SIGHIST(...,'title',TITLESTR,...)
%  Specify a string to display as a title for the entire figure. If a title
%  is provided, additional space will be reserved at the top of the figure
%  in which to print the title.
%
%  SIGHIST(...,'sigxlabel',XLBLSTR,...)
%  SIGHIST(...,'sigylabel',YLBLSTR,...)
%  Specify a string for the x-axis label and/or y-axis label, respectively,
%  of the signal plot.
%
%  SIGHIST(...,'hstxlabel',XLBLSTR,...)
%  SIGHIST(...,'hstylabel',YLBLSTR,...)
%  Specify a string for the x-axis label and/or y-axis label, respectively,
%  of the histogram.
%
%  SIGHIST(...,'sigxlim',XLIMS,...)
%  SIGHIST(...,'hstxlim',XLIMS,...)
%  Specify values for the x-axis limits of the signal plot and/or
%  histogram, respectively. XLIMS should be in the form [MIN MAX].
%
%  SIGHIST(...,'ylim',YLIMS,...)
%  Specify values for the y-axis limits of both the signal plot and
%  histogram. The y-axis on both plots are linked (see LINKAXES) and
%  therefore must have the same limits.
%
%  SIGHIST(...,'sigstyle',STYLE,...)
%  Specify the style of the signal portion of the plot. If STYLE is 'stem',
%  the signal will be plotted using the MATLAB builtin function STEM.
%  Otherwise, STYLE may be any value accepted by the MATLAB builtin
%  function PLOT to specify the line style and marker.
%
%  SIGHIST(...,'hststyle',STYLE,...)
%  Specify the style of the histogram plot. If STYLE is 'bar', the
%  histogram will be plotted as a bar plot. If STYLE is 'line', the
%  histogram will be plotted as a continuous line. Finally, if STYLE is
%  STEM, the histogram will be plotted as stems.
%
%  SIGHIST(...,'signorm',METHOD,...)
%  Normalize the signal values. Valid values of METHOD include 'unity'
%  (range [0 1]) or 'zscore'.
%
%  SIGHIST(...,'hstnorm',METHOD,...)
%  Normalize the histogram. Valid values of METHOD include any accepted by
%  the MATLAB builtin function HISTCOUNTS for the 'NORMALIZATION'
%  name-value pair argument: count, probability, countdensity, pdf,
%  cumcount, or cdf (see documentation for additional information).
%  
%  EXAMPLE:
%
%    >> fig = plot.sighist('box',[0 0.5 1 0.5],[x1(:) x2(:)],...
%         'title','Title String for X1 and X2',...
%         'legend',{'X1 Label','X2 Label'},...
%         'ylabel','Y-axis Label');
%    >> plot.sighist(fig,'box',[0 0 1 0.5],x1(:)-x2(:),...
%         'legend',{'Difference Label'},...
%         'ylabel','Y-axis Label',...
%         'xlabel','X-axis Label');
assert(~isempty(varargin),'Must provide some inputs');

% look for figure handle
idx = cellfun(@(x)isa(x,'matlab.ui.Figure'),varargin);
if any(idx)
    fig = varargin{idx};
    varargin(idx) = [];
else
    fig = figure('Position',[100 100 1600 800]);
end

% test the inputParser for processing inputs
[varargin,x,y,box,lgndstr,titlestr,sigxlbl,sigylbl,hstxlbl,hstylbl,...
    sigxl,hstxl,yl,sigstyle,hststyle,signorm,hstnorm] = parseInputs(varargin{:});
assert(isempty(varargin),'%d unexpected inputs',length(varargin));

% validate inputs
if min(size(y))==1
    y = y(:);
    x = x(:);
else
    if min(size(x))==1
        x = x(:);
    end
    assert(size(x,1)==size(y,1),'X must have the same number of rows as Y');
    assert(size(x,2)==1||size(x,2)==size(y,2),'X must have either one column or the same number of columns as Y');
end

% identify common edges for the histogram
[edges,binwidth] = util.optedges(y(:));
t = (edges(1:end-1)+edges(2:end))/2;

% determine normalization argument for histcounts function
args = {};
if ~isempty(hstnorm)
    args = {'Normalization',hstnorm};
end

% generate histogram
n = nan(length(edges)-1,size(y,2));
for kk=1:size(y,2)
    n(:,kk) = histcounts(y(:,kk),edges,args{:});
end

% normalize the data if requested
if ~isempty(signorm)
    switch signorm
        case 'unity'
            x = x - min(x);
            x = x ./max(x);
        case 'zscore'
            x = zscore(x);
        case 'none'
        otherwise
            error('Unknown value for signorm ''%s''',signorm);
    end
end

% generate figure and plot the data
marginFigLeft = 0.04*box(3);
if ~isempty(sigylbl)
    marginFigLeft = 0.08*box(3);
elseif ~isempty(hstylbl)
    marginFigLeft = 0.08*box(3);
elseif ~isempty(sigylbl) && ~isempty(hstylbl)
    marginFigLeft = 0.12*box(3);
end
marginFigBottom = 0.12*box(4);
if ~isempty(sigxlbl) || ~isempty(hstxlbl)
    marginFigBottom = 0.12*box(4);
end
marginFigRight = 0.04*box(3);
marginFigTop = 0.04*box(4);
if ~isempty(titlestr)
    marginFigTop = 0.12*box(4);
end
currLeft = box(1)+marginFigLeft;
currBottom = box(2)+marginFigBottom;
currWidth = 0.8*(box(3)-marginFigLeft-marginFigRight);
currHeight = box(4)-marginFigBottom-marginFigTop;
ax(1) = axes('Parent',fig,'Position',[currLeft currBottom currWidth currHeight]);
currLeft = currLeft + currWidth + 0.01;
currWidth = 0.2*(box(3)-marginFigLeft-marginFigRight);
ax(2) = axes('Parent',fig,'Position',[currLeft currBottom currWidth currHeight]);
if strcmpi(sigstyle,'stem')
    hl = stem(ax(1),x,y);
else
    assert(all(ismember(sigstyle,{'-',':','.','o','+','*','.','x','s','d','^','v','>','<','p','h'})),'Please see MATLAB documentation for line properties to identify valid values for the line style input (''%s'' is not acceptable)',sigstyle);
    hl = plot(ax(1),x,y,sigstyle);
end
xlim(ax(1),x([1 end]));
switch hststyle
    case 'stem'
        hb = stem(ax(2),n,t); % force plot sideways
    case 'bar'
        hb = barh(ax(2),t,n);
    case 'line'
        hb = plot(ax(2),n,t); % force plot sideways
    otherwise
        error('Unknown hststyle value ''%s''',hststyle);
end
if ~isempty(sigxlbl)
    xlabel(ax(1),sigxlbl);
end
if ~isempty(sigylbl)
    ylabel(ax(1),sigylbl);
end
if ~isempty(hstxlbl)
    xlabel(ax(2),hstxlbl);
end
if ~isempty(hstylbl)
    ylabel(ax(2),hstylbl);
end

% make sure equivalent ylims and remove ticks from histogram
if ~isempty(sigxl)
    set(ax(1),'xlim',sigxl);
end
if ~isempty(hstxl)
    set(ax(2),'xlim',hstxl);
end
if isempty(yl)
    yl = get(ax(1),'ylim');
end
yl(1) = min(yl(1),edges(1)-binwidth/2); % leave room to show full histogram bar
yl(2) = max(yl(2),edges(end)+binwidth/2);
linkaxes(ax,'y');
set(ax(1),'ylim',yl);
set(ax(2),'ytick',[]);
%set(ax(2),'xtick',[]);

% add label
if ~isempty(lgndstr)
    legend(ax(1),lgndstr);
end

% make sure same colors
for kk=1:size(y,2)
    cl = get(hl(kk),'Color');
    switch hststyle
        case {'stem','line'}
            set(hb(kk),'Color',cl);
        case 'bar'
            set(hb(kk),'FaceColor',cl);
            set(hb(kk),'EdgeAlpha',0);
    end
end

% create title
if ~isempty(titlestr)
    currLeft = box(1)+marginFigLeft;
    currBottom = box(2)+box(4)-marginFigTop;
    currWidth = 0.8*(box(3)-marginFigLeft-marginFigRight);
    currHeight = 0.08*box(4);
    axtitle = axes('Position',[currLeft currBottom currWidth currHeight],'Parent',fig);
    text(0.5,0.5,titlestr,'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',16,'FontWeight','bold','Parent',axtitle);
    axis(axtitle,'off');
end



function [remaining,x,y,box,lgndstr,titlestr,sigxlbl,sigylbl,hstxlbl,...
    hstylbl,sigxl,hstxl,yl,sigstyle,hststyle,signorm,hstnorm] = parseInputs(varargin)

% look for bounding box
box = [0 0 1 1];
idx = strcmpi(varargin,'box');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'Bounding box input must be provided as a key-value pair');
    box = varargin{idx+1};
    varargin(idx+(0:1)) = [];
end

% look for labels
lgndstr = {};
idx = strcmpi(varargin,'legend');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'Label input must be provided as a key-value pair');
    lgndstr = varargin{idx+1};
    lgndstr = util.ascell(lgndstr);
    varargin(idx+(0:1)) = [];
end

% look for title
titlestr = '';
idx = strcmpi(varargin,'title');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'Title input must be provided as a key-value pair');
    titlestr = varargin{idx+1};
    varargin(idx+(0:1)) = [];
end

% look for xlabel
sigxlbl = '';
idx = strcmpi(varargin,'sigxlabel');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'X-label input must be provided as a key-value pair');
    sigxlbl = varargin{idx+1};
    varargin(idx+(0:1)) = [];
end

% look for ylabel
sigylbl = '';
idx = strcmpi(varargin,'sigylabel');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'Y-label input must be provided as a key-value pair');
    sigylbl = varargin{idx+1};
    varargin(idx+(0:1)) = [];
end

% look for xlabel
hstxlbl = '';
idx = strcmpi(varargin,'hstxlabel');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'X-label input must be provided as a key-value pair');
    hstxlbl = varargin{idx+1};
    varargin(idx+(0:1)) = [];
end

% look for ylabel
hstylbl = '';
idx = strcmpi(varargin,'hstylabel');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'Y-label input must be provided as a key-value pair');
    hstylbl = varargin{idx+1};
    varargin(idx+(0:1)) = [];
end

% look for xlabel
sigxl = '';
idx = strcmpi(varargin,'sigxlim');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'X-lim input must be provided as a key-value pair');
    sigxl = varargin{idx+1};
    varargin(idx+(0:1)) = [];
end

% look for xlabel
hstxl = '';
idx = strcmpi(varargin,'hstxlim');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'X-lim input must be provided as a key-value pair');
    hstxl = varargin{idx+1};
    varargin(idx+(0:1)) = [];
end

% look for ylabel
yl = '';
idx = strcmpi(varargin,'ylim');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'Y-lim input must be provided as a key-value pair');
    yl = varargin{idx+1};
    varargin(idx+(0:1)) = [];
end

% look for style
sigstyle = 'x';
idx = strcmpi(varargin,'sigstyle');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'Style input must be provided as a key-value pair');
    sigstyle = varargin{idx+1};
    varargin(idx+(0:1)) = [];
    assert(ischar(sigstyle),'Must provide plot style as char, not ''%s''',class(sigstyle));
end

% look for style
hststyle = 'bar';
idx = strcmpi(varargin,'hststyle');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'Style input must be provided as a key-value pair');
    hststyle = varargin{idx+1};
    varargin(idx+(0:1)) = [];
    assert(ischar(hststyle),'Must provide plot style as char, not ''%s''',class(hststyle));
end

% look for norm
signorm = '';
idx = strcmpi(varargin,'signorm');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'Signorm input must be provided as a key-value pair');
    signorm = varargin{idx+1};
    varargin(idx+(0:1)) = [];
    assert(ischar(signorm),'Must provide signorm as char, not ''%s''',class(signorm));
end

% look for norm
hstnorm = '';
idx = strcmpi(varargin,'hstnorm');
if any(idx)
    idx = find(idx);
    assert(length(varargin)>idx,'Hstnorm input must be provided as a key-value pair');
    hstnorm = varargin{idx+1};
    varargin(idx+(0:1)) = [];
    assert(ischar(hstnorm),'Must provide hstnorm as char, not ''%s''',class(hstnorm));
end

% interpret inputs
if length(varargin)==1
    x = 1:length(varargin{1});
    y = varargin{1};
    varargin(1) = [];
elseif length(varargin)==2
    x = varargin{1};
    y = varargin{2};
    varargin(1:2) = [];
else
    warning('Unexpected number of leftover inputs');
    keyboard
end

% return whatever's left of varargin
remaining = varargin;