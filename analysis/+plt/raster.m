function [fig,ax] = raster(varargin)
% RASTER Make a raster plot with PSTH overlay
%
%   [FIG,AX] = RASTER(SPIKES)
%   For the spike data input SPIKES, create a raster and/or PSTH plot.
%   Return handles to the figure and the axes within the figure in FIG and
%   AX respectively. SPIKES may take the form of a (possibly sparse)
%   logical array, where a logical TRUE indicates that a spike occurred at
%   that timestamp, or a cell array with lists of timestamps per channel
%   (or feature or trial, depending on what the rows of the raster plot
%   should look like). If logical, rows represent samples and columns
%   represent channels/features/trials.
%
%   The SPIKES input may also be provided as cell arrays of either sparse
%   logical matrices or cells of numerical timestamp lists (so, in the
%   latter case, two-level-deep cell arrays). Here, the top-level cells
%   represent channel/feature/trial grouping (see 'GROUPS' input below).
%
%   [...] = RASTER(T,SPIKES)
%   Provide timing information for the spike data. The units of T may be in
%   samples or seconds, but the length of T must match the number of
%   timestamps in the SPIKES input. By default, the timing vector will be
%   constructed as consecutive integers with units of samples, starting at
%   0 and matching the length of the spike timestamp data.
%
%   [...] = RASTER(...,'RASTER',TRUE|FALSE)
%   [...] = RASTER(...,'PSTH',TRUE|FALSE)
%   Enable or disable the raster and PSTH subplots (at least one of these
%   must be enabled or the function will generate an error). By default,
%   both are enabled.
%
%   [...] = RASTER(...,'FS',FS)
%   Provide the sampling rate. This input is only useful when the input T
%   is either missing or provided with units of samples instead of
%   seconds).
%
%   [...] = RASTER(...,'XLABEL',XLBL)
%   [...] = RASTER(...,'XLIM',XLM)
%   Provide the label for the x-axis (XLBL) and the limits for the x-axis
%   (XLM). By default, the x-axis will be labeled in seconds if T is
%   provided and the median diff between consecutive values of T is <1; the
%   xlim will be set to the first/last entry of the timing vector.
%
%   [...] = RASTER(...,'SORT','NONE'|'FR_ASC'|'FR_DESC')
%   Choose how to sort the rows of the raster plot. The default option,
%   'NONE', does not reorder the rows. The other two options sort the rows
%   based on ascending ('FR_ASC') or descending ('FR_DESC') firing rate.
%   Sorted indices start at the bottom of the plot and run toward the top
%   of the plot (so, 'FR_ASC' puts the lowest-firing-rate rows at the
%   bottom). If the data are grouped (see 'GROUPS' input below), sorting
%   applies within groups.
%
%   [...] = RASTER(...,'GROUPS',GRP)
%   Provide indices for one or more groups selected from the channels/
%   features/trials of the SPIKES input. The input GRP should be a cell
%   array where each cell contains the numerical indices of the channels
%   /features/trials (i.e., the columns of a sparse logical input or the
%   cell indices of a cell array of numerical timestamps).
%
%   [...] = RASTER(...,'GROUPLABELSS',LBL)
%   Provide text labels for each of the groups in the input LBL, which must
%   be a cell array of char with one cell per grouping (see 'GROUPS'
%   above). If group labels are provided, a legend will also be displayed
%   (with 'AutoUpdate' set to 'off' so that additions will not appear in
%   the legend).
%
%   [...] = RASTER(...,'INVISIBLE')
%   Keep the generated figure invisible, which may provide some performance
%   improvements when plotting over may iterations in a loop. By default,
%   the figure will be visible.
%
%   [...] = RASTER(...,'TITLE',TSTR)
%   Provide a title for the figure in TSTR. By default, there is no title.
%
%   [...] = RASTER(...,'MARKERSIZE',SZ)
%   Set the size of the marker used to represent a single spike event. By
%   default, this parameter is set to 3.
%
%   [...] = RASTER(...,HFIG)
%   Provide a handle to an existing figure instead of creating a new one.
%
%   [...] = RASTER(...,DBG)
%   Provide a DEBUG.DEBUGGER object DBG to be used for logging debug
%   messages. By default, a new DEBUG.DEBUGGER object will be created.

% process inputs
[varargin,fs] = util.argkeyval('fs',varargin,nan);
[varargin,flagShowPSTH] = util.argkeyval('psth',varargin,true);
[varargin,flagShowRaster] = util.argkeyval('raster',varargin,true);
assert(flagShowPSTH||flagShowRaster,'Must enable at least one of the PSTH or raster subplots');
[varargin,rasterXLabel,~,found_rasterXLabel] = util.argkeyval('xlabel',varargin,nan);
[varargin,rasterXLim,~,found_rasterXLim] = util.argkeyval('xlim',varargin,nan);
[varargin,sorting] = util.argkeyval('sort',varargin,'none'); % 'none','fr_asc','fr_desc'
[varargin,groups,~,found_groups] = util.argkeyval('groups',varargin,nan);
[varargin,glabels] = util.argkeyval('grouplabels',varargin,nan);
[varargin,flagVisible] = util.argflag('invisible',varargin,true);
[varargin,titlestr] = util.argkeyval('title',varargin,'');
flagShowTitle = ~isempty(titlestr);
[varargin,markersize] = util.argkeyval('markersize',varargin,3);
[varargin,fig] = util.argisa('matlab.ui.Figure',varargin,[]);
[varargin,debug,found] = util.argisa('Debug.Debugger',varargin,nan);
if ~found,debug=Debug.Debugger('raster');end

% leftovers are either {t,spikes} or {spikes}
if length(varargin)==1
    spikes = varargin{1};
    t = nan;
    varargin(1) = [];
else
    t = varargin{1};
    spikes = varargin{2};
    varargin(1:2) = [];
end
util.argempty(varargin);

% process spike input: user could input sparse matrices, cells of either
% sparse matrices or cells of numeric timestamp lists, etc. the format we
% eventually need is a single sparse matrix (no cell)
if iscell(spikes)
    num_timestamps = nan;
    user_group_input_ok = false;
    
    % check for cell of cell arrays: first-level cells are groups;
    % second-level cells are numerical lists of timestamps (one cell per
    % feature/trial etc.)
    if all(cellfun(@iscell,spikes))
        
        % get max timestamp over all groups and all features/trials
        if ~isnan(t)
            num_timestamps = length(t);
        else
            num_timestamps = nan(1,length(spikes));
            for kk=1:length(spikes)
                num_timestamps(kk) = max(cellfun(@nanmax,spikes{kk}));
            end
            num_timestamps = nanmax(num_timestamps);
        end
        
        % convert to sparse: now we'll have a cell array of sparse matrices
        % (one per group)
        spikes = cellfun(@(x)proc.helper.ts2sparse(x,'numsamples',num_timestamps),spikes,'UniformOutput',false);
        user_group_input_ok = false;
    end
    
    % check for cells of numeric vectors: in this case each cell is a list
    % of timestamps for feature/trial/etc. and we need to convert to sparse
    if ~all(cellfun(@issparse,spikes))
        
        % get the max timestamp over all features/trials
        if isnan(t)
            num_timestamps = max(cellfun(@max,spikes));
        else
            num_timestamps = length(t);
        end
        
        % convert to sparse: now we'll have a cell array with one cell
        % containing a sparse matrix (one group)
        spikes = proc.helper.ts2sparse(spikes,'numsamples',num_timestamps);
        spikes = util.ascell(spikes);
        user_group_input_ok = true;
    end
    
    % compute the final max_timestamp if needed: the larger of the number
    % of rows or the number of columns (assumption that there will be more
    % samples than channels/trials.
    if isnan(num_timestamps) && isnan(t)
        num_timestamps = nanmax(cellfun(@(x)max(size(x)),spikes));
    end
    
    % now we have one or more cells of sparse matrices; combine them and
    % form the group indices
    assert(user_group_input_ok||~found_groups,'Group indices cannot be specified when the input data are provided in cells');
    if ~found_groups
        groups = cell(1,length(spikes));
        idx = 0;
        for gg=1:length(spikes)
            if size(spikes{gg},1)~=num_timestamps,spikes{gg}=spikes{gg}';end
            assert(size(spikes{gg},1)==num_timestamps,'Cell %d of SPIKES input has %d rows, which is different from the computed length %d',gg,size(spikes{gg},1),num_timestamps);
            groups{gg} = idx + (1:size(spikes{gg},2));
            idx = idx + size(spikes{gg},2);
        end
    end
    spikes = cat(2,spikes{:});
end

% compute timing vector if needed
if isnan(t)
    max_timestamps = size(spikes,1);
    t = (0:max_timestamps-1)';
end

% convert timing from samples to seconds if fs provided
if median(diff(t))>=1
    if ~isnan(fs),t=t/fs;end
end

% default group includes all channels/trials/etc.
if ~iscell(groups) && isnan(groups)
    groups = {1:size(spikes,2)};
end

% default X label based on whether T is in samples or seconds
t_in_seconds = median(diff(t))<1;
if ~found_rasterXLabel
    if t_in_seconds
        rasterXLabel = 'Time (sec)';
    else
        rasterXLabel = 'Samples';
    end
end
if ~found_rasterXLim
    rasterXLim = t([1 end]);
end

% rearrange by group
groups = util.ascell(groups);
numGroups = length(groups);
origspikes = spikes;
featidx = 0;
for gg=1:numGroups
    dt = origspikes(:,groups{gg});
    if ~strcmpi(sorting,'none')
        fr = sum(dt,1);
        switch lower(sorting)
            case {'fr_asc','fr_ascend'}
                [~,idx] = sort(fr,'ascend');
            case {'fr_desc','fr_descend'}
                [~,idx] = sort(fr,'descend');
            otherwise
                error('Unknown sort method "%s" (must be "none", "fr_asc", or "fr_desc")',sorting);
        end
        dt = dt(:,idx);
    end
    spikes(:,featidx + (1:length(groups{gg}))) = dt;
    groups{gg} = featidx + (1:length(groups{gg}));
    featidx = featidx + length(groups{gg});
end
spikes(:,(featidx+1):size(spikes,2)) = [];
clear origspikes;
numFeats = size(spikes,2);

% extract timestamp indices from spikes input
ts = cell(1,numGroups);
feat = cell(1,numGroups);
r = cell(1,numGroups);
tau = cell(1,numGroups);
e = cell(1,numGroups);
for gg=1:numGroups
    
    % pull out timestamps
    [ts{gg},feat{gg}] = find(spikes(:,groups{gg}));
    feat{gg} = feat{gg} + (min(groups{gg})-1);
    if isempty(ts{gg}), ts{gg}=nan; feat{gg}=nan; end
    
    % calculate psth
    kernel_sd = ceil(length(t)/200);
    kernel_sd = max(kernel_sd,100);
    kernel_sd = min(kernel_sd,10000);
    [r{gg},tau{gg},e{gg}] = proc.basic.psth(spikes(:,groups{gg}),t,debug,'alpha',0.05,'kernel_width',diff(t([1 kernel_sd+1])));
    e{gg}(1,:) = r{gg} - e{gg}(1,:);
    e{gg}(2,:) = e{gg}(2,:) - r{gg};
end

% create figure if needed
if isempty(fig)
    screenMargin = [100 100];
    figWidth = 1500;
    if flagShowPSTH
        figHeight = 450+25+flagShowTitle*40+round(0.75*numFeats);
    else
        figHeight = 150+flagShowTitle*40+round(0.75*numFeats);
    end
    figpos = [screenMargin(1) screenMargin(2) figWidth figHeight];
    set(0,'units','pixels');
    rootProps = get(0);
    if isfield(rootProps,'ScreenSize')
        figLeft = max(rootProps.ScreenSize(1)+screenMargin(1)-1,(rootProps.ScreenSize(3)-figWidth-screenMargin(1))/2);
        figBottom = max(rootProps.ScreenSize(2)+screenMargin(2)-1,(rootProps.ScreenSize(4)-figHeight-screenMargin(2))/2);
        figpos = [figLeft figBottom figWidth figHeight];
    end
    fig = figure('Position',figpos,'PaperPositionMode','auto');
end
if ~flagVisible, set(fig,'Visible','off'); end

% create axes
if flagShowPSTH && flagShowRaster
    if flagShowTitle
        hAxesRaster = axes('Position',[0.04 0.08 0.94 0.40]); % raster
        hAxesPSTH = axes('Position',[0.04 0.50 0.94 0.43]); % psth
        hTextTitle = uicontrol(... % title
            'Parent',fig,...
            'HorizontalAlignment','center',...
            'Units','normalized',...
            'Position',[0.04 0.93 0.94 0.04],...
            'String','',...
            'FontSize',12,...
            'FontWeight','bold',...
            'Tag','textTitle',...
            'Style','text');
        ax = [hAxesRaster; hAxesPSTH; hTextTitle];
    else
        hAxesRaster = axes('Position',[0.04 0.08 0.94 0.40]); % raster
        hAxesPSTH = axes('Position',[0.04 0.50 0.94 0.46]); % psth
        ax = [hAxesRaster; hAxesPSTH;];
    end
elseif ~flagShowPSTH && flagShowRaster
    if flagShowTitle
        hAxesRaster = axes('Position',[0.04 0.15 0.94 0.73]); % raster
        hTextTitle = uicontrol(... % title
            'Parent',fig,...
            'HorizontalAlignment','center',...
            'Units','normalized',...
            'Position',[0.04 0.88 0.94 0.09],...
            'String','',...
            'FontSize',12,...
            'FontWeight','bold',...
            'Tag','textTitle',...
            'Style','text');
        ax = [hAxesRaster; hTextTitle];
    else
        hAxesRaster = axes('Position',[0.04 0.16 0.94 0.80]); % raster
        ax = hAxesRaster;
    end
elseif flagShowPSTH && ~flagShowRaster
    if flagShowTitle
        hAxesPSTH = axes('Position',[0.04 0.12 0.94 0.78]); % raster
        hTextTitle = uicontrol(... % title
            'Parent',fig,...
            'HorizontalAlignment','center',...
            'Units','normalized',...
            'Position',[0.04 0.9 0.94 0.07],...
            'String','',...
            'FontSize',12,...
            'FontWeight','bold',...
            'Tag','textTitle',...
            'Style','text');
        ax = [hAxesPSTH; hTextTitle];
    else
        hAxesPSTH = axes('Position',[0.04 0.12 0.94 0.84]); % raster
        ax = hAxesPSTH;
    end
end
colors = get(ax(1),'ColorOrder');
if size(colors,1)<numGroups
    colors = proc.distinguishable_colors(numGroups);
end
assert(size(colors,1)>=numGroups,'Not enough colors - need to update code');

% create the raster plot
if flagShowRaster
    hold(hAxesRaster,'on');
    for gg=1:numGroups
        plot(hAxesRaster,t(ts{gg}),feat{gg},'marker','.','markersize',markersize,'linestyle','none','color',colors(gg,:));
    end
    hold(hAxesRaster,'off');
    ylim(hAxesRaster,[0 numFeats+1]);
    xlim(hAxesRaster,rasterXLim);
    xlabel(hAxesRaster,rasterXLabel);
    ylabel(hAxesRaster,'Observations');
    box(hAxesRaster,'on');
    if iscell(glabels) && ~flagShowPSTH
        
        % legend would default to showing the small markers which are hard
        % to see, so we'll temporarily plot to lines and delete them.
        handles = cell(1,numGroups);
        hold(hAxesRaster,'on');
        for gg=1:numGroups
            handles{gg} = plot(hAxesRaster,[0 1],[-1 -1],'color',colors(gg,:),'linewidth',2);
        end
        hold(hAxesRaster,'off');
        numObsPerGroup = cellfun(@length,groups,'UniformOutput',false);
        glabels = cellfun(@(x,y)sprintf('%s (%d)',x,y),glabels,numObsPerGroup,'UniformOutput',false);
        legend(hAxesRaster,cat(1,handles{:}),glabels,'Interpreter','none','AutoUpdate','off');
        cellfun(@delete,handles);
    end
end

% create the psth plot
if flagShowPSTH
    xx = zeros(length(tau{1}),numGroups);
    yy = zeros(length(r{1}),numGroups);
    zz = zeros(length(e{1}),2,numGroups);
    for gg=1:numGroups
        xx(:,gg) = tau{gg}(:);
        yy(:,gg) = r{gg}(:);
        zz(:,1:2,gg) = e{gg}';
    end
    [hl,hp] = util.boundedline(xx,yy,zz,'alpha','cmap',colors(1:numGroups,:),'transparency',0.5,hAxesPSTH);
    set(hl,'LineWidth',2);
    
    % axes properties
    xlim(hAxesPSTH,rasterXLim);
    currYLim = get(hAxesPSTH,'ylim');
    ylim(hAxesPSTH,[0 currYLim(2)]);
    if flagShowRaster
        set(hAxesPSTH,'XTick',[]);
    end
    if ~flagShowRaster
        xlabel(hAxesPSTH,rasterXLabel);
    end
    ylabel(hAxesPSTH,'Rate (spk/sec)');
    box(hAxesPSTH,'on');
    if iscell(glabels)
        numObsPerGroup = cellfun(@length,groups,'UniformOutput',false);
        glabels = cellfun(@(x,y)sprintf('%s (%d) (mn ± 95%% ci)',x,y),glabels,numObsPerGroup,'UniformOutput',false);
        handles = hp(:);
        legend(hAxesPSTH,handles,glabels,'Interpreter','none','AutoUpdate','off');
    end
end

% add title
if flagShowTitle
    set(hTextTitle,'String',titlestr);
end