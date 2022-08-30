classdef MultiPanelFigure < handle
% MULTIPANELFIGURE Manage figure with multiple subplots
%
%   USAGE
%   The following code snippet creates a MultiPanelFigure with 4 rows and 5
%   columns. The data variables are dummy placeholders (i.e. the snippet
%   will not run as is).
%
%   % create the figure and initialize the layout
%   >> h = plot.MultiPanelFigure('position',[50 50 1600 1000],'numrows',4,'numcols',5);
%   >> h.newLayout;
%
%   % plot data into the axes
%   >> h.setGroupHold('on','all');
%   >> for rr=1:R
%   >>   for cc=1:C
%   >>     h.plot(rr,cc,time,data1(:,rr,cc),'LineWidth',2);
%   >>     h.plot(rr,cc,time,data2(:,rr,cc),'LineWidth',2);
%   >>   end
%   >> end
%   >> h.setGroupHold('off','all');
%
%   % modify appearance
%   >> h.setGroupProperties('all','box','on','xgrid','on','ygrid','on');
%   >> h.setGroupXLabel('Time (sec)','bottomrow');
%   >> h.setGroupedXLim('all',time([1 end]));
%   >> h.setGroupedYLim('all','minmax');
%   >> ylabel_strings = arrayfun(@(x)sprintf('Row %d',x),1:R,'UniformOutput',false);
%   >> h.setGroupYLabel(ylabel_strings,'leftcolumn');
%   >> title_strings = arrayfun(@(x)sprintf('Column %d',x),1:C,'UniformOutput',false);
%   >> h.setGroupTitle(title_strings,'toprow','Interpreter','none');
%   >> h.removeGroupXTickLabel('except','bottomrow');
%   >> h.removeGroupYTickLabel('except','leftcolumn');
%   >> h.addMarkerLines('allaxes',marker_times,'MarkerLabels',marker_labels);
%   >> h.addTitle('Example MultiPanelFigure','Interpreter','none')
%
%   save and close the figure
%   >> h.save('outdir',resultdir,'basename','example_multipanelfigure','formats',{'png','fig'},'overwrite');
%   >> h.delete;
    
    properties
        hFigure % handle to the figure
        hAxes % cell array of handles to the primary axes
        hAxesInset % cell array of handles to the inset axes (one per primary axes)
        hAxesTitle % handle to the title axes
        hTextTitle % handle to the title text
        
        TotalAreaBounds % [left bottom width height] of the total allowed area in the figure (w.r.t. figure)
        TotalAreaInnerMargin % margin around the inside edges of the total area
        
        TitleHeight = 0 % height of the title area
        
        AxesSpacing % [horizontal vertical] spacing between axes (with no ticks/labels)
        AxesExtraSpacing % [horizontal vertical] extra spacing to apply for ticks/labels
        
        AxesWidth % width of the axes
        AxesHeight % height of the axes
        NumRows % number of rows in the grid of axes
        NumCols % number of columns in the grid of axes
    end % END properties
    
    methods
        function this = MultiPanelFigure(varargin)
            % MULTIPANELFIGURE Manage figure with multiple subplots
            %
            %   H = MULTIPANELFIGURE;
            %   Construct a figure with (default) 2 rows and 3 columns and
            %   return a handle to the MULTIPANELFIGURE object.
            %
            %   MULTIPANELFIGURE(...,'POSITION',[LEFT BOTTOM WIDTH HEIGHT])
            %   Specify the position (LEFT and BOTTOM corners plus WIDTDH,
            %   HEIGHT) of the figure, in pixels.
            %
            %   MULTIPANELFIGURE(...,'BOUNDS',[LEFT BOTTOM WIDTH HEIGHT])
            %   Specify the total available figure area as the left, bottom
            %   corners plus the width and height, where the area of the
            %   figure has been normalized to the range [0 1]. The total
            %   area bounds the combined axes/title areas.
            %
            %   MULTIPANELFIGURE(...,'MARGIN',[LEFT BOTTOM RIGHT TOP])
            %   Set a margin around the boundaries of the total area, with
            %   each side specified individually.
            %
            %   MULTIPANELFIGURE(...,'AXSPACING',[HORIZ VERT])
            %   MULTIPANELFIGURE(...,'EXTRASPACING',[HORIZ VERT])
            %   Specify the horizontal spacing HORIZ and vertical spacing
            %   VERT between axes (default [0.02 0.02]) when there are no
            %   tickmarks/labels (AXSPACING), and the additional amount of
            %   spacing to add when there are tickmarks/labels (default
            %   [0.02 0.01]).
            %
            %   MULTIPANELFIGURE(...,'NUMROWS',R)
            %   MULTIPANELFIGURE(...,'NUMCOLS',C)
            %   Specify the number of rows and columns in the axes grid
            %   (default R=2, C=3).
            %
            %   MULTIPANELFIGURE(...,'AXWIDTH',W)
            %   MULTIPANELFIGURE(...,'AXHEIGHT',H)
            %   Specify the width and height of the axes. By default, all
            %   of the spacing information otherwise provided (total area
            %   bounds, margins, axes spacing, etc.) will be used to
            %   determine the width and height of the axes.
            [varargin,figure_position] = util.argkeyval('position',varargin,[50 100 1200 800]); % left, bottom, width, height
            
            [varargin,this.TotalAreaBounds] = util.argkeyval('bounds',varargin,[0 0 1 1]);
            [varargin,this.TotalAreaInnerMargin] = util.argkeyval('margin',varargin,[0.06 0.08 0.03 0.06]); % left, bottom, right, top
            
            [varargin,this.AxesSpacing] = util.argkeyval('axspacing',varargin,[0.02 0.02]); % horizontal, vertical
            [varargin,this.AxesExtraSpacing] = util.argkeyval('extraspacing',varargin,[0.02 0.01]); % horizontal, vertical
            
            [varargin,this.NumRows] = util.argkeyval('numrows',varargin,2);
            [varargin,this.NumCols] = util.argkeyval('numcols',varargin,3);
            
            defaultAxesWidth = ((this.TotalAreaBounds(3)-sum(this.TotalAreaInnerMargin([1 3]))) - (this.NumCols-1)*this.AxesSpacing(1))/this.NumCols;
            defaultAxesHeight = ((this.TotalAreaBounds(4)-sum(this.TotalAreaInnerMargin([2 4]))) - (this.NumRows-1)*this.AxesSpacing(2))/this.NumRows;
            [varargin,this.AxesWidth] = util.argkeyval('axwidth',varargin,defaultAxesWidth);
            [varargin,this.AxesHeight] = util.argkeyval('axheight',varargin,defaultAxesHeight);
            util.argempty(varargin);
            
            % create figure
            this.hFigure = figure(...
                'PaperPositionMode','auto',...
                'Position',figure_position);
        end % END function MultiPanelFigure
        
        function newLayout(this,varargin)
            % NEWLAYOUT Initialize the figure layout
            %
            %   NEWLAYOUT(THIS,'INSET',TRUE|FALSE)
            %   Indicate whether or not to add inset axes for each of the
            %   primary axes (default FALSE).
            [varargin,flag_inset] = util.argflag('inset',varargin,false);
            
            % clear the figure
            clearLayout(this);
            
            % create axes
            this.hAxes = cell(this.NumRows,this.NumCols);
            if flag_inset,this.hAxesInset=cell(this.NumRows,this.NumCols);end
            for rr=1:this.NumRows
                for cc=1:this.NumCols
                    this.hAxes{rr,cc} = axes('Parent',this.hFigure);
                    if flag_inset,this.hAxesInset{rr,cc} = axes('Parent',this.hFigure);end
                end
            end
            
            % process title
            if ~isempty(varargin)
                [varargin,title_str] = util.argkeyval('title',varargin,'');
                addTitle(this,title_str,varargin{:});
            end
            
            % refresh the layout
            updateLayout(this);
        end % END function newLayout
        
        function removeAxes(this,rr,cc)
            % REMOVEAXES Remove individual axes
            %
            %   REMOVEAXES(THIS,RR,CC)
            %   Remove the axes at row RR and column CC.
            if ~isempty(this.hAxes{rr,cc})
                try
                    this.hAxes{rr,cc}.delete;
                catch ME
                    util.errorMessage(ME);
                end
                this.hAxes{rr,cc} = [];
            end    
            updateLayout(this);
        end % END function removeAxes
        
        function clearLayout(this)
            % CLEARLAYOUT Clear the layout
            %
            %   CLEARLAYOUT(THIS)
            %   Clear the layout
            clf(this.hFigure);
            this.hAxes = [];
            this.hAxesInset = [];
            this.hAxesTitle = [];
            this.hTextTitle = [];
        end % END function clearLayout
        
        function updateLayout(this)
            % UPDATELAYOUT Refresh the layout
            %
            %   UPDATELAYOUT(THIS)
            %   Refresh the layout accounting for any changes in axes
            %   spacing, margins, bounds, etc.
            
            % helper variables
            axes_spacing = this.AxesSpacing;
            available_width = diff(this.TotalAreaBounds([1 3])) - sum(this.TotalAreaInnerMargin([1 3]));
            available_height = diff(this.TotalAreaBounds([2 4])) - sum(this.TotalAreaInnerMargin([2 4])) - this.TitleHeight;
            axes_width = (available_width - (this.NumCols-1)*axes_spacing(1))/this.NumCols;
            axes_height = (available_height - (this.NumRows-1)*axes_spacing(2))/this.NumRows;
            
            % refresh axes positions
            flag_inset = ~isempty(this.hAxesInset);
            for cc=1:this.NumCols
                for rr=1:this.NumRows
                    
                    % update primary axes
                    left = this.TotalAreaBounds(1) + this.TotalAreaInnerMargin(1) + (cc-1)*(axes_width + axes_spacing(1));
                    bottom = this.TotalAreaBounds(2) + this.TotalAreaInnerMargin(2) + (rr-1)*(axes_height + axes_spacing(2));
                    if isempty(this.hAxes{this.NumRows-rr+1,cc}),continue;end
                    set(this.hAxes{this.NumRows-rr+1,cc},'position',[left bottom axes_width axes_height]);
                    
                    % update inset axes
                    if flag_inset
                        axes_position = get(this.hAxes{this.NumRows-rr+1,cc},'Position');
                        left = axes_position(1)+0.8*axes_position(3);
                        bottom = axes_position(2)+0.75*axes_position(4);
                        inset_width = 0.2*axes_position(3);
                        inset_height = 0.25*axes_position(4);
                        set(this.hAxesInset{this.NumRows-rr+1,cc},'position',[left bottom inset_width inset_height]);
                    end
                end
            end
            
            % transfer information back to object properties
            this.AxesWidth = axes_width;
            this.AxesHeight = axes_height;
            
            % force display update
            drawnow;
        end % END function updateLayout
        
        function addTitle(this,title_str,varargin)
            % ADDTITLE Add a title to the figure
            %
            %   ADDTITLE(THIS,TITLE_STR)
            %   Add the string in TITLE_STR as a title for the figure.
            %   Create a space for the title by adjusting the vertical
            %   height of the axes grid.
            %
            %   ADDTITLE(...,'HEIGHT',H)
            %   Specify the height of the title space.
            %
            %   ADDTITLE(...,'FONTWEIGHT',W)
            %   Specify the font weight W of the title ('normal' or 'bold')
            %   (default W='bold').
            %
            %   ADDTITLE(...,'FONTSIZE',S)
            %   Specify the font size of the title in points (default
            %   S=14).
            [varargin,this.TitleHeight] = util.argkeyval('height',varargin,0.02);
            [varargin,font_weight] = util.argkeyval('fontweight',varargin,'bold');
            [varargin,font_size] = util.argkeyval('fontsize',varargin,14);
            
            % create title axes
            if isempty(this.hAxesTitle)
                left = this.TotalAreaBounds(1);
                bottom = this.TotalAreaBounds(2)+this.TotalAreaBounds(4)-this.TitleHeight;
                width = this.TotalAreaBounds(3);
                height = this.TitleHeight;
                this.hAxesTitle = axes('Parent',this.hFigure,'position',[left bottom width height]);
            end
            
            % create the title text
            this.hTextTitle = text(this.hAxesTitle,0.5,0.0,title_str,...
                'FontWeight',font_weight,...
                'FontSize',font_size,...
                'HorizontalAlignment','center',...
                varargin{:});
            set(this.hAxesTitle,'Visible','off'); % axes is just there so we can use title
            set(findall(this.hAxesTitle,'type','text'),'Visible','on');
            
            % refresh the layout
            updateLayout(this);
        end % END function addTitle
        
        function removeTitle(this)
            % REMOVETITLE Remove an existing title
            %
            %   REMOVETITLE(THIS)
            %   Remove the title and adjust the vertical sizing of the axes
            %   grid to fill the extra space.
            
            % remove title axes
            delete(this.hTextTitle); this.hTextTitle = [];
            delete(this.hAxesTitle); this.hAxesTitle = [];
            
            % update title area bounds
            this.TitleHeight = 0;
            
            % refresh the layout
            updateLayout(this);
        end % END function removeTitle
        
        function lim = setGroupedXLim(this,varargin)
            % SETGROUPEDXLIM Set X-limits for groups of axes
            %
            %   SETGROUPEDXLIM(THIS)
            %   Set x-limits for all axes, making x-limits within columns
            %   consistent.
            %
            %   SETGROUPEDXLIM(...,'BYROW'|'BYCOLUMN'|'ALL')
            %   Make the x-limits consistent for the specified grouping.
            %
            %   SETGROUPEDXLIM(...,[MIN MAX])
            %   Provide user values for the limits.
            %
            %   SETGROUPEDXLIM(...,'MINMAX'|'MEDIAN'|'MEAN'|'USER')
            %   Specify how to compute the common limit. 'MINMAX' finds the
            %   minimum and maximum of the grouping axes limits. 'MEDIAN' 
            %   and 'MEAN' find the median or mean of the grouping axes
            %   limits. 'USER' applies the user-provided limits (see the
            %   numeric input above). The default mode is 'MINMAX' unless
            %   numeric input is provided, in which case the default mode
            %   is 'USER'.
            [varargin,ax] = getGroupedAxes(this,this.hAxes,varargin,'bycolumn');
            [varargin,user_lim,found_user_lim] = util.argfn(@isnumeric,varargin,[nan nan]);
            default_mode = 'minmax';
            if found_user_lim,default_mode='user';end
            [varargin,mode] = util.argkeyword({'minmax','median','mean','user'},varargin,default_mode);
            if strcmpi(mode,'user'),assert(found_user_lim,'Must provide ylim in user mode');end
            util.argempty(varargin);
            lim = setConsistentLim(this,'xlim',ax,mode,user_lim);
        end % END function setGroupedXLim
        
        function lim = setGroupedYLim(this,varargin)
            % SETGROUPEDYLIM Set Y-limits for groups of axes
            %
            %   SETGROUPEDYLIM(THIS)
            %   Set y-limits for all axes, making y-limits within columns
            %   consistent.
            %
            %   SETGROUPEDYLIM(...,'BYROW'|'BYCOLUMN'|'ALL')
            %   Make the y-limits consistent for the specified grouping.
            %
            %   SETGROUPEDYLIM(...,[MIN MAX])
            %   Provide user values for the limits.
            %
            %   SETGROUPEDYLIM(...,'MINMAX'|'MEDIAN'|'MEAN'|'USER')
            %   Specify how to compute the common limit. 'MINMAX' finds the
            %   minimum and maximum of the grouping axes limits. 'MEDIAN' 
            %   and 'MEAN' find the median or mean of the grouping axes
            %   limits. 'USER' applies the user-provided limits (see the
            %   numeric input above). The default mode is 'MINMAX' unless
            %   numeric input is provided, in which case the default mode
            %   is 'USER'.
            [varargin,ax] = getGroupedAxes(this,this.hAxes,varargin,'byrow');
            [varargin,user_lim,found_user_lim] = util.argfn(@isnumeric,varargin,[nan nan]);
            default_mode = 'minmax';
            if found_user_lim,default_mode='user';end
            [varargin,mode] = util.argkeyword({'minmax','median','mean','user'},varargin,default_mode);
            if strcmpi(mode,'user'),assert(found_user_lim,'Must provide ylim in user mode');end
            util.argempty(varargin);
            lim = setConsistentLim(this,'ylim',ax,mode,user_lim);
        end % END function setGroupedYLim
        
        function setGroupXLabel(this,label_strings,varargin)
            % SETGROUPXLABEL Set the X-axis labels for a group of axes
            %
            %   SETGROUPXLABEL(THIS,LABEL_STRINGS)
            %   Set x-axis labels. By default, if LABEL_STRINGS is a single
            %   string (or single cell with string), will set the x label
            %   to the bottom-left axes; if LABEL_STRINGS is a cell array
            %   with THIS.NUMCOLS entries, will set the x labels for the
            %   bottom row.
            %
            %   SETGROUPXLABEL(...,GROUPING_ARGS)
            %   Specify grouping inputs (see GETAXESGROUP).
            %
            %   If there are remaining inputs, they will be passed to the
            %   XLABEL function.
            if ~iscell(label_strings),label_strings={label_strings};end
            if length(label_strings)==this.NumCols
                default_grouping = 'bottomrow';
            elseif length(label_strings)==1
                default_grouping = 'bottomleft';
            else
                default_grouping = 'all';
            end
            [varargin,ax] = getAxesGroup(this,this.hAxes,varargin,default_grouping);
            if length(label_strings)==1 && length(ax)>1
                label_strings = repmat(label_strings,1,length(ax));
            end
            assert(length(label_strings)==length(ax),'Must provide one label string per selected axes');
            cellfun(@(x,y)xlabel(x,y,varargin{:}),ax(:),label_strings(:));
        end % END function setGroupXLabel
        
        function setGroupYLabel(this,label_strings,varargin)
            % SETGROUPYLABEL Set the Y-axis labels for a group of axes
            %
            %   SETGROUPYLABEL(THIS,LABEL_STRINGS)
            %   Set y-axis labels. By default, if LABEL_STRINGS is a single
            %   string (or single cell with string), will set the y label
            %   to the bottom-left axes; if LABEL_STRINGS is a cell array
            %   with THIS.NUMROWS entries, will set the y labels for the
            %   left column.
            %
            %   SETGROUPYLABEL(...,GROUPING_ARGS)
            %   Specify grouping inputs (see GETAXESGROUP).
            %
            %   If there are remaining inputs, they will be passed to the
            %   YLABEL function.
            if ~iscell(label_strings),label_strings={label_strings};end
            if length(label_strings)==this.NumRows
                default_grouping = 'leftcolumn';
            elseif length(label_strings)==1
                default_grouping = 'bottomleft';
            else
                default_grouping = 'all';
            end
            [varargin,ax] = getAxesGroup(this,this.hAxes,varargin,default_grouping);
            if length(label_strings)==1 && length(ax)>1
                label_strings = repmat(label_strings,1,length(ax));
            end
            assert(length(label_strings)==length(ax),'Must provide one label string per selected axes');
            cellfun(@(x,y)ylabel(x,y,varargin{:}),ax(:),label_strings(:));
        end % END function setGroupYLabel
        
        function removeGroupXTickLabel(this,varargin)
            % REMOVEGROUPXTICKLABEL Remove X-tick labels for a set of axes
            %
            %   REMOVEGROUPXTICKLABEL(THIS)
            %   Remove the x-tick labels from all axes in the figure.
            %
            %   REMOVEGROUPXTICKLABEL(...,GROUPING_ARGS)
            %   Specify additional grouping inputs (see GETAXESGROUP).
            [varargin,ax] = getAxesGroup(this,this.hAxes,varargin,'all');
            util.argempty(varargin);
            cellfun(@(x)set(x,'XTickLabel',{' '}),ax);
            
            % tighten up vertical spacing
            this.AxesSpacing = [this.AxesSpacing(1) 0.02];
            updateLayout(this);
        end % END function removeGroupXTickLabel
        
        function removeGroupYTickLabel(this,varargin)
            % REMOVEGROUPYTICKLABEL Remove Y-tick labels for a set of axes
            %
            %   REMOVEGROUPYTICKLABEL(THIS)
            %   Remove the y-tick labels from all axes in the figure.
            %
            %   REMOVEGROUPYTICKLABEL(...,GROUPING_ARGS)
            %   Specify additional grouping inputs (see GETAXESGROUP).
            [varargin,ax] = getAxesGroup(this,this.hAxes,varargin,'all');
            util.argempty(varargin);
            cellfun(@(x)set(x,'YTickLabel',{' '}),ax);
            
            % tighten up horizontal spacing
            this.AxesSpacing = [0.02 this.AxesSpacing(2)];
            updateLayout(this);
        end % END function removeGroupYTickLabel
        
        function setGroupTitle(this,title_strings,varargin)
            % SETGROUPTITLE Set the axes titles for a group of axes
            %
            %   SETGROUPTITLE(THIS,TITLE_STRINGS)
            %   Set axes titles. By default, if TITLE_STRINGS is a single
            %   string (or single cell with string), will set the title
            %   on the top-left axes; if TITLE_STRINGS is a cell array
            %   with THIS.NUMCOLS entries, will set the titles on the
            %   top row.
            %
            %   SETGROUPTITLE(...,GROUPING_ARGS)
            %   Specify grouping inputs (see GETAXESGROUP).
            %
            %   If there are remaining inputs, they will be passed to the
            %   TITLE function.
            if ~iscell(title_strings),title_strings={title_strings};end
            if length(title_strings)==this.NumCols
                default_grouping = 'toprow';
            elseif length(title_strings)==1
                default_grouping = 'topleft';
            else
                default_grouping = 'all';
            end
            [varargin,ax] = getAxesGroup(this,this.hAxes,varargin,default_grouping);
            if length(title_strings)==1 && length(ax)>1
                title_strings = repmat(title_strings,1,length(ax));
            end
            assert(length(title_strings)==length(ax),'Must provide one title string per selected axes');
            cellfun(@(x,y)title(x,y,varargin{:}),ax(:),title_strings(:));
        end % END function setGroupTitle
        
        function setGroupHold(this,which,varargin)
            % SETGROUPHOLD Set hold on or off for a group of axes
            %
            %   SETGROUPHOLD(THIS,'ON'|'OFF')
            %   Specify whether to turn hold "on" or "off" for all axes.
            %
            %   SETGROUPHOLD(...,GROUPING_ARGS)
            %   Specify grouping inputs (see GETAXESGROUP).
            assert(ischar(which)&&any(strcmpi(which,{'on','off'})),'Must specify whether to turn "hold" on or off');
            [varargin,ax] = getAxesGroup(this,this.hAxes,varargin,'all');
            util.argempty(varargin);
            
            % apply hold
            cellfun(@(x)hold(x,which),ax);
        end % END function hold
        
        function setInsetGroupHold(this,which,varargin)
            % SETINSETGROUPHOLD Set hold for a group of inset axes
            %
            %   SETINSETGROUPHOLD(THIS,'ON'|'OFF')
            %   Specify whether to turn hold "on" or "off" for all inset
            %   axes.
            %
            %   SETINSETGROUPHOLD(...,GROUPING_ARGS)
            %   Specify grouping inputs (see GETAXESGROUP).
            assert(ischar(which)&&any(strcmpi(which,{'on','off'})),'Must specify whether to turn "hold" on or off');
            [varargin,ax] = getAxesGroup(this,this.hAxesInset,varargin,'all');
            util.argempty(varargin);
            
            % apply hold
            cellfun(@(x)hold(x,which),ax);
        end % END function hold
        
        function setGroupProperties(this,varargin)
            % SETGROUPPROPERTIES Set properties for a group of axes
            %
            %   SETGROUPPROPERTIES(THIS,PROP1,VAL1,...)
            %   Provide a series of arguments to pass to the SET function
            %   for all axes.
            %
            %   SETGROUPPROPERTIES(...,GROUPING_ARGS)
            %   Specify grouping inputs (see GETAXESGROUP).
            [varargin,ax] = getAxesGroup(this,this.hAxes,varargin,'all');
            cellfun(@(x)set(x,varargin{:}),ax);
        end % END function setGroupProperties
        
        function setInsetGroupProperties(this,varargin)
            % SETINSETGROUPPROPERTIES Set properties for grouped inset axes
            %
            %   SETINSETGROUPPROPERTIES(THIS,PROP1,VAL1,...)
            %   Provide a series of arguments to pass to the SET function
            %   for all inset axes.
            %
            %   SETINSETGROUPPROPERTIES(...,GROUPING_ARGS)
            %   Specify grouping inputs (see GETAXESGROUP).
            [varargin,ax] = getAxesGroup(this,this.hAxesInset,varargin,'all');
            cellfun(@(x)set(x,varargin{:}),ax);
        end % END function setInsetGroupProperties
        
        function val = getGroupProperties(this,varargin)
            % GETGROUPPROPERTIES Get properties for a group of axes
            %
            %   VAL = GETGROUPPROPERTIES(THIS,PROP1,VAL1,...)
            %   Provide a series of arguments to pass to the GET function
            %   for all axes.
            %
            %   GETGROUPPROPERTIES(...,GROUPING_ARGS)
            %   Specify grouping inputs (see GETAXESGROUP).
            [varargin,ax] = getAxesGroup(this,this.hAxes,varargin,'all');
            val = cellfun(@(x)get(x,varargin{:}),ax);
        end % END function getGroupProperties
        
        function val = getInsetGroupProperties(this,varargin)
            % GETINSETGROUPPROPERTIES Get properties for grouped inset axes
            %
            %   VAL = GETINSETGROUPPROPERTIES(THIS,PROP1,VAL1,...)
            %   Provide a series of arguments to pass to the GET function
            %   for all inset axes.
            %
            %   GETINSETGROUPPROPERTIES(...,GROUPING_ARGS)
            %   Specify grouping inputs (see GETAXESGROUP).
            [varargin,ax] = getAxesGroup(this,this.hAxesInset,varargin,'all');
            val = cellfun(@(x)get(x,varargin{:}),ax);
        end % END function getInsetGroupProperties
        
        function h = plot(this,rr,cc,varargin)
            % PLOT Call the plot function for a specific axes
            %
            %   H = PLOT(THIS,ROW,COL,ARG1,ARG2,...)
            %   Pass ARG1, ARG2, etc. to the plot function for the axes
            %   identified by ROW and COL. Return the output of the plot
            %   function in H.
            %
            %   PLOT(...,'TITLE',TITLE_STR)
            %   Additionally add a title to the axes when plotting (more
            %   limited functionality than calling "addTitle", for example,
            %   no ability to provide additional arguments to the TITLE
            %   function).
            [varargin,title_strings,~,found_title] = util.argkeyval('title',varargin,'');
            h = plot(this.hAxes{rr,cc},varargin{:});
            if found_title
                setGroupTitle(this,title_strings,'row',rr,'column',cc);
            end
        end % END function plot
        
        function h = stem(this,rr,cc,varargin)
            % STEM Call the stem function for a specific axes
            %
            %   H = STEM(THIS,ROW,COL,ARG1,ARG2,...)
            %   Pass ARG1, ARG2, etc. to the stem function for the axes
            %   identified by ROW and COL. Return the output of the stem
            %   function in H.
            %
            %   PLOT(...,'TITLE',TITLE_STR)
            %   Additionally add a title to the axes when plotting (more
            %   limited functionality than calling "addTitle", for example,
            %   no ability to provide additional arguments to the TITLE
            %   function).
            [varargin,title_strings,~,found_title] = util.argkeyval('title',varargin,'');
            h = stem(this.hAxes{rr,cc},varargin{:});
            if found_title
                setGroupTitle(this,title_strings,'row',rr,'column',cc);
            end
        end % END function stem
        
        function h = bar(this,rr,cc,varargin)
            % BAR Call the bar function for a specific axes
            %
            %   H = BAR(THIS,ROW,COL,ARG1,ARG2,...)
            %   Pass ARG1, ARG2, etc. to the bar function for the axes
            %   identified by ROW and COL. Return the output of the bar
            %   function in H.
            %
            %   PLOT(...,'TITLE',TITLE_STR)
            %   Additionally add a title to the axes when plotting (more
            %   limited functionality than calling "addTitle", for example,
            %   no ability to provide additional arguments to the TITLE
            %   function).
            [varargin,title_strings,~,found_title] = util.argkeyval('title',varargin,'');
            h = bar(this.hAxes{rr,cc},varargin{:});
            if found_title
                setGroupTitle(this,title_strings,'row',rr,'column',cc);
            end
        end % END function bar
        
        function h = text(this,rr,cc,varargin)
            % TEXT Call the text function for a specific axes
            %
            %   H = TEXT(THIS,ROW,COL,ARG1,ARG2,...)
            %   Pass ARG1, ARG2, etc. to the text function for the axes
            %   identified by ROW and COL. Return the output of the text
            %   function in H.
            h = text(this.hAxes{rr,cc},varargin{:});
        end % END function text
        
        function h = plotInset(this,rr,cc,varargin)
            % PLOT Call the plot function for a specific inset axes
            %
            %   H = PLOT(THIS,ROW,COL,ARG1,ARG2,...)
            %   Pass ARG1, ARG2, etc. to the plot function for the inset
            %   axes identified by ROW and COL. Return the output of the
            %   plot function in H.
            h = plot(this.hAxesInset{rr,cc},varargin{:});
        end % END function plotInset
        
        function addMarkerLines(this,varargin)
            % ADDMARKERLINES Add marker lines to a group of axes
            %
            %   ADDMARKERLINES(THIS,ARG1,ARG2,...)
            %   Pass ARG1, ARG2, etc. to the PLOT.MARKERLINES function for
            %   all axes.
            %
            %   ADDMARKERLINES(...,GROUPING_ARGS)
            %   Specify grouping inputs (see GETAXESGROUP).
            [varargin,ax] = getAxesGroup(this,this.hAxes,varargin,'all');
            cellfun(@(x)plot.markerLines(x,varargin{:}),ax,'UniformOutput',false);
        end % END function addMarkerLines
        
        function save(this,varargin)
            % SAVE Save the figure using PLOT.SAVE
            %
            %   SAVE(THIS,ARG1,ARG2,...)
            %   Pass ARG1, ARG2, etc. to the PLOT.SAVE function for all
            %   axes.
            plt.save(this.hFigure,varargin{:});
        end % END function save
        
        function delete(this)
            % DELETE Close the figure and clean up all resources
            %
            %   DELETE(THIS)
            %   Close the figure and clean up all resources
            if ~isempty(this.hFigure) && ishandle(this.hFigure) && isvalid(this.hFigure)
                try close(this.hFigure); catch ME, util.errorMessage(ME); end
            end
        end % END function delete
    end % END methods
    
    methods(Access=private)
        function lim = setConsistentLim(this,which,ax,mode,user_lim)
            % SETCONSISTENTLIM Set consistent limits for axes groups
            %
            %   SETCONSISTENTLIM(THIS,WHICH,AX,MODE,USER_LIM)
            %   Set limits for the axes in AX. The input WHICH should be
            %   'xlim' or 'ylim'. The input AX should be a cell array of
            %   axes that should end up with the same limits. The input
            %   MODE should be one of 'MINMAX', 'MEDIAN', 'MEAN', or
            %   'USER'. The input USER_LIM is only required if the mode is
            %   set to 'USER'.
            lim = cell(size(ax));
            for aa=1:length(ax)
                if strcmpi(mode,'user')
                    lim{aa} = user_lim;
                else
                    lim{aa} = cellfun(@(x)get(x,which),ax{aa},'UniformOutput',false);
                    lim{aa} = cat(1,lim{aa}{:});
                    switch lower(mode)
                        case 'minmax'
                            lim{aa} = [min(lim{aa}(:,1)) max(lim{aa}(:,2))];
                        case 'median'
                            lim{aa} = median(lim{aa},1);
                        case 'mean'
                            lim{aa} = mean(lim{aa},1);
                        otherwise
                            error('Unknown limit mode "%s"',mode);
                    end
                end
                cellfun(@(x)set(x,which,lim{aa}),ax{aa});
            end
            
            % reduce to non-cell
            if length(lim)==1,lim=lim{1};end
        end % END function setConsistentLim
        
        function [args,ax] = getAxesGroup(this,ax,args,default)
            % GETAXESGROUP Get a group of axes
            %
            %   [ARGS,AX] = GETAXESGROUP(THIS,AX,ARGS,DEFAULT)
            %   Get a cell array of axes from a requested group, for
            %   example, axes from the top row. Provide the VARARGIN as
            %   ARGS input, and specify the default grouping in DEFAULT.
            %
            %   Grouping Instruction
            %   'ALL'               - All axes.
            %   'ROW',R             - All axes from row R.
            %   'COLUMN',C          - All axes from column C.
            %   'ROW',R,'COLUMN',C  - Axes at row RR, column C.
            %   'TOPLEFT'           - Axes in the top-left corner.
            %   'TOPRIGHT'          - Axes in the top-right corner.
            %   'BOTTOMLEFT'        - Axes in the bottom-left corner.
            %   'BOTTOMRIGHT'       - Axes in the bottom-right corner.
            %   'LEFT'              - Axes in the left column.
            %   'RIGHT'             - Axes in the right column.
            %   'MIDDLECOLUMN'      - Axes in the middle column(s).
            %   'TOP'               - Axes in the top row.
            %   'BOTTOM'            - Axes in the bottom row.
            %   'MIDDLEROW'         - Axes in the middle row(s).
            %   'MIDDLE'            - Axes in the middle.
            %
            %   Equivalent names
            %   'TOPLEFT'       - 'LEFTTOP'
            %   'TOPRIGHT'      - 'RIGHTOP'
            %   'LEFT'          - 'LEFTCOLUMN'
            %   'RIGHT'         - 'RIGHTCOLUMN'
            %   'MIDDLECOLUMN'  - 'MIDDLECOLUMNS'
            %   'TOP'           - 'TOPROW'
            %   'BOTTOM'        - 'BOTTOMROW'
            %   'MIDDLEROW'     - 'MIDDLEROWS'
            if isempty(args),args={default};end
            
            % shortcut - request all axes
            [args,all] = util.argflag('all',args,false);
            if all,return;end
            
            % shortcut - request specific combination of row/col
            [args,row,~,found_row] = util.argkeyval('row',args,nan);
            [args,col,~,found_col] = util.argkeyval('column',args,nan);
            if found_row && ~found_col
                ax = ax(row,:);
                return;
            elseif ~found_row && found_col
                ax = ax(:,col);
                return;
            elseif found_row && found_col
                idx = sub2ind(size(ax),row,col);
                ax = ax(idx);
                return;
            end
            
            % allow refinement of selection with "except" logic
            [args,except] = util.argkeyval('except',args,'');
            
            % store which axes requested logically
            idx_axes = false(this.NumRows,this.NumCols);
            idx_avail = cellfun(@(x)isa(x,'matlab.graphics.axis.Axes'),this.hAxes);
            
            % loop over args
            hit = false(1,length(args));
            for kk=1:length(args)
                [hit(kk),idx_axes] = subfcn__process(idx_axes,args{kk},true,idx_avail);
            end
            args(hit) = [];
            
            % if nothing selected, select everything
            if ~any(idx_axes(:))
                idx_axes = true(this.NumRows,this.NumCols);
                idx_axes(~idx_avail) = false;
            end
            
            % loop over except
            if ~isempty(except)
                [~,idx_axes] = subfcn__process(idx_axes,except,false,idx_avail);
            end
            
            % apply selection to axes
            ax = ax(idx_axes);
            
            
            % function to translate terms to indices
            function [hit,idx] = subfcn__process(idx,val,tf,avail)
                if nargin<4
                    avail = true(size(idx));
                end
                hit = false;
                if ischar(val)
                    switch lower(val)
                        case {'topleft','lefttop'}
                            if avail(1,1)
                                idx(1,1) = tf;
                            else
                                r = 1;
                                c = find(avail(r,:),1,'first');
                                while isempty(c) && r<=size(idx,1)
                                    r = r+1;
                                    c = find(avail(r,:),1,'first');
                                end
                                assert(~isempty(c),'Could not find a valid axes');
                                idx(r,c) = tf;
                            end
                            hit = true;
                        case {'topright','righttop'}
                            if avail(1,end)
                                idx(1,end) = tf;
                            else
                                r = 1;
                                c = find(avail(r,:),1,'last');
                                while isempty(c) && r<=size(idx,1)
                                    r = r+1;
                                    c = find(avail(r,:),1,'last');
                                end
                                assert(~isempty(c),'Could not find a valid axes');
                                idx(r,c) = tf;
                            end
                            hit = true;
                        case {'bottomleft','leftbottom'}
                            if avail(end,1)
                                idx(end,1) = tf;
                            else
                                r = size(idx,1);
                                c = find(avail(r,:),1,'first');
                                while isempty(c) && r>0
                                    r = r-1;
                                    c = find(avail(r,:),1,'first');
                                end
                                assert(~isempty(c),'Could not find a valid axes');
                                idx(r,c) = tf;
                            end
                            hit = true;
                        case {'bottomright','rightbottom'}
                            if avail(end,end)
                                idx(end,end) = tf;
                            else
                                r = size(idx,1);
                                c = find(avail(r,:),1,'last');
                                while isempty(c) && r>0
                                    r = r-1;
                                    c = find(avail(r,:),1,'last');
                                end
                                assert(~isempty(c),'Could not find a valid axes');
                                idx(r,c) = tf;
                            end
                            hit = true;
                        case {'left','leftcolumn'}
                            idx(:,1) = tf;
                            for rr=1:size(idx,1)
                                if avail(rr,1),continue;end
                                idx(rr,1) = false;
                                c = find(avail(rr,:),1,'first');
                                if isempty(c),continue;end
                                idx(rr,c) = tf;
                            end
                            hit = true;
                        case {'right','rightcolumn'}
                            idx(:,end) = tf;
                            for rr=1:size(idx,1)
                                if avail(rr,end),continue;end
                                idx(rr,1) = false;
                                c = find(avail(rr,:),1,'last');
                                if isempty(c),continue;end
                                idx(rr,c) = tf;
                            end
                            hit = true;
                        case {'middlecolumn','middlecolumns'}
                            idx(:,2:end-1) = tf;
                            idx(~avail) = false;
                            hit = true;
                        case {'top','toprow'}
                            idx(1,:) = tf;
                            for cc=1:size(idx,2)
                                if avail(1,cc),continue;end
                                idx(1,cc) = false;
                                r = find(avail(:,cc),1,'first');
                                if isempty(r),continue;end
                                idx(r,cc) = tf;
                            end
                            hit = true;
                        case {'bottom','bottomrow'}
                            idx(end,:) = tf;
                            for cc=1:size(idx,2)
                                if avail(end,cc),continue;end
                                idx(end,cc) = false;
                                r = find(avail(:,cc),1,'last');
                                if isempty(r),continue;end
                                idx(r,cc) = tf;
                            end
                            hit = true;
                        case {'middlerow','middlerows'}
                            idx(2:end-1,:) = tf;
                            idx(~avail) = false;
                            hit = true;
                        case {'middle'}
                            idx(2:end-1,2:end-1) = tf;
                            idx(~avail) = false;
                            hit = true;
                    end
                elseif isnumeric(val)
                    if length(val)==2
                        if ~avail(val(1),val(2)),tf=false;end
                        idx(val(1),val(2)) = tf; hit = true;
                    elseif isscalar(val)
                        if ~avail(val),tf=false;end
                        idx(val) = tf; hit = true;
                    end
                end
            end % END function subfcn__process
        end % END function getAxesGroup
        
        function [args,ax] = getGroupedAxes(this,ax,args,default)
            % GETGROUPEDAXES Get axes arranged in groups
            %
            %   [ARGS,AX] = GETGROUPEDAXES(THIS,AX,ARGS,DEFAULT)
            %   Get a cell array of cells containing groups of axes, for
            %   example, axes from the same row. Provide the VARARGIN as
            %   ARGS input, and specify the default grouping in DEFAULT.
            %
            %   Grouping Instruction
            %   'BYROW'     - One cell per row, each cell containing all
            %                 axes in that row.
            %   'BYCOLUMN'  - One cell per column, each cell containing all
            %                 axes in that column.
            %   'ALL'       - one cell, containing a single cell with all
            %                 axes.
            [args,found_byrow] = util.argflag('byrow',args,false);
            [args,found_bycolumn] = util.argflag('bycolumn',args,false);
            [args,found_all] = util.argflag('all',args,false);
            if ~found_byrow && ~found_bycolumn && ~found_all
                if strcmpi(default,'byrow')
                    found_byrow = true;
                elseif strcmpi(default,'bycolumn')
                    found_bycolumn = true;
                elseif strcmpi(default,'all')
                    found_all = true;
                end
            end
            if found_byrow
                ax = arrayfun(@(x)ax(x,:),1:this.NumRows,'UniformOutput',false);
            elseif found_bycolumn
                ax = arrayfun(@(x)ax(:,x),1:this.NumCols,'UniformOutput',false);
            elseif found_all
                ax = {ax(:)};
            end
        end % END function getGrouopedAxes
    end % END methods(Access=private)
end % END classdef MultiPanelFigure