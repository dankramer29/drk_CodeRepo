function refreshContent(this)
%
% Instead of allowing Grid Electrodes and Channels, let's only allow Grid
% Electrodes complete specification. Then, we can either allow specifying
% number of channels to skip, or the number of the first amplifier channel
% for this grid. Then we can have the "align" checkbox disable and force
% the value, or unchecked allow user-specified.
%
% What does "locked" mean exactly? Can we still move grids up or down? Can
% we still edit them? What are we saying is locked?
%   - the original motivation was that moving other grids would force
%   renumbering with or without alignment, which was messing up overall
%   gridmap. So locking was meant to 



setStatus(this,'Refreshing GUI');
if isempty(this.hGridMap)
    return;
end

% update map file field
set(this.guiHandles.editMapfile,'String',this.Mapfile);

% update text in grid info listbox
if this.hGridMap.NumGrids>0
    gapAfter = false(1,this.hGridMap.NumGrids);
    for gg=1:this.hGridMap.NumGrids-1
        channels_thisGrid = this.hGridMap.ChannelInfo.AmplifierChannel(this.hGridMap.ChannelInfo.GridID==this.hGridMap.GridInfo.GridID(gg));
        channels_nextGrid = this.hGridMap.ChannelInfo.AmplifierChannel(this.hGridMap.ChannelInfo.GridID==this.hGridMap.GridInfo.GridID(gg+1));
        if channels_nextGrid(1) - channels_thisGrid(end) > 1
            gapAfter(gg) = true;
        end
    end
    numEntries = this.hGridMap.NumGrids + nnz(gapAfter);
else
    gapAfter = [];
    numEntries = 0;
end

% create cell array of strings for grid info listbox
listboxGridIdx = nan(numEntries,1);
listboxString = cell(numEntries,1);
listboxIdx = 1;
for gg=1:this.hGridMap.NumGrids
    
    % add current grid
    listboxString{listboxIdx} = sprintf('%2d. %-6s %-16s: %-16s (%2d el.)',...
        gg,...
        this.hGridMap.GridInfo.Hemisphere{gg},...
        this.hGridMap.GridInfo.Location{gg},...
        this.hGridMap.GridInfo.Template{gg},...
        length(this.hGridMap.GridInfo.Electrode{gg}));
    listboxGridIdx(listboxIdx) = gg;
    listboxIdx = listboxIdx + 1;
    
    % check for gap in Central channels
    if gapAfter(gg)
        if gg==this.hGridMap.NumGrids
            error('Cannot have gap at the end');
        else
            firstGapChannel = find(this.hGridMap.ChannelInfo.GridID==this.hGridMap.GridInfo.GridID(gg),1,'last');
            assert(~isempty(firstGapChannel),'Could not find last channel of previous grid');
            firstGapChannel = this.hGridMap.ChannelInfo.AmplifierChannel(firstGapChannel) + 1;
            lastGapChannel = find(this.hGridMap.ChannelInfo.GridID==this.hGridMap.GridInfo.GridID(gg+1),1,'first');
            assert(~isempty(lastGapChannel),'Could not find first channel of next grid');
            lastGapChannel = this.hGridMap.ChannelInfo.AmplifierChannel(lastGapChannel) - 1;
            gapChannels = firstGapChannel:lastGapChannel;
        end
        listboxString{listboxIdx} = sprintf('--. [GAP]                                     (%2d ch.)',length(gapChannels));
        listboxIdx = listboxIdx + 1;
    end
end
if isempty(listboxString)
    set(this.guiHandles.listboxGridInfo,'Min',0,'Max',2,'Value',[]);
elseif get(this.guiHandles.listboxGridInfo,'Value')>length(listboxString)
    set(this.guiHandles.listboxGridInfo,'Value',length(listboxString));
end
set(this.guiHandles.listboxGridInfo,'String',listboxString);
this.listboxGridIndex = listboxGridIdx;
[selectedRow,selectedGrid,selectedGridID] = gui__getSelectedGrid(this);

% update text in channel info listbox
if strcmpi(this.ChannelDisplayMode,'allgrids')
    
    % create cell of strings for channel info
    listboxString = cell(max(this.hGridMap.ChannelInfo.ChannelID),1);
    for cc=1:max(this.hGridMap.ChannelInfo.RecordingChannel)
        idx_channel = find(this.hGridMap.ChannelInfo.RecordingChannel==cc);
        if isempty(idx_channel)
            listboxString{cc} = sprintf('[EMPTY] Central %3d',cc);
        else
            idx_grid = find(this.hGridMap.GridInfo.GridID==this.hGridMap.ChannelInfo.GridID(idx_channel));
            assert(~isempty(idx_grid),'Could not find grid with GridID %d',this.hGridMap.ChannelInfo.GridID(idx_channel));
            listboxString{cc} = sprintf('%-8s: grid %2d, el. %3d, Central %3d, rec. %3d',...
                this.hGridMap.ChannelInfo.Label{idx_channel},...
                idx_grid,...
                this.hGridMap.ChannelInfo.GridElectrode(idx_channel),...
                this.hGridMap.ChannelInfo.RecordingChannel(idx_channel),...
                idx_channel);
        end
    end
elseif strcmpi(this.ChannelDisplayMode,'selectedgrid')
    
    % get list of channels for the selected grid
    if isempty(selectedRow) || this.hGridMap.NumGrids==0
        
        % no grids
        listboxString = {};
    else
        
        % gap selected (nan) or actual grid selected (~nan)
        if isnan(selectedGrid)
            
            % get the channels associated with this gap
            gridChannels = gui__getGapChannels(this,selectedRow);
            listboxString = cell(length(gridChannels),1);
            for cc=1:length(gridChannels)
                listboxString{cc} = sprintf('[EMPTY] Central %3d',gridChannels(cc));
            end
        else
            
            % actual grid selected, get its channels
            numGridChannels = length(this.hGridMap.ChannelInfo.RecordingChannel(this.hGridMap.ChannelInfo.GridID==selectedGridID));
            listboxString = cell(numGridChannels,1);
            offset = find(this.hGridMap.ChannelInfo.GridID==selectedGridID,1,'first');
            for cc=1:numGridChannels
                %idx_channel = this.hGridMap.ChannelInfo.RecordingChannel==cc;
                idx_grid = find(this.hGridMap.GridInfo.GridID==selectedGridID);
                listboxString{cc} = sprintf('%-8s: grid %2d, el. %3d, Central %3d, rec. %3d',...
                    this.hGridMap.ChannelInfo.Label{cc+offset-1},...
                    idx_grid,...
                    this.hGridMap.ChannelInfo.GridElectrode(cc+offset-1),...
                    this.hGridMap.ChannelInfo.AmplifierChannel(cc+offset-1),...
                    this.hGridMap.ChannelInfo.RecordingChannel(cc+offset-1));
            end
        end
    end
end
set(this.guiHandles.listboxChannelInfo,'String',listboxString);

% update fields from auto-selected first listbox entry
if this.hGridMap.NumGrids>0
    [selectedRow,selectedGrid] = gui__getSelectedGrid(this);
    if isempty(selectedRow)
        selectedRow = 1;
        selectedGrid = 1;
    end
    if selectedGrid>this.hGridMap.NumGrids
        selectedGrid = this.hGridMap.NumGrids;
        selectedRow = find(this.listboxGridIndex==selectedGrid,1,'first');
        assert(~isempty(selectedRow),'Could not find selected grid');
    end
    set(this.guiHandles.listboxGridInfo,'Value',selectedRow);
end
refreshGridSummaryFromSelected(this);

% set grid summary values
if this.hGridMap.NumGrids>0
    gridLabelsString = cell(1,this.hGridMap.NumGrids);
    for gg=1:this.hGridMap.NumGrids
        chans = this.hGridMap.ChannelInfo.RecordingChannel(this.hGridMap.ChannelInfo.GridID==this.hGridMap.GridInfo.GridID(gg));
        gridLabelsString{gg} = sprintf('%s (%d)',this.hGridMap.GridInfo.Label{gg},length(chans));
    end
    gridLabelsString = strjoin(gridLabelsString,', ');
    
    % compute how many lines and adjust height/position accord
    gridLabelsString = textwrap(this.guiHandles.textGridLabels,{gridLabelsString});
    pos = get(this.guiHandles.textGridLabels,'position');
    defaultHeight = 17; % see "summary_field_height_small" in layout
    defaultSpacingSmall = 4; % see "summary_field_vertical_spacing_small" in layout
    defaultSpacing = 8; % see "summary_field_vertical_spacing" in layout
    
    pos1 = get(this.guiHandles.textNumGridsValue,'Position');
    pos2 = get(this.guiHandles.textNumChannelsValue,'Position');
    textSizeCurrent = (pos1(2) - pos2(2) - pos2(4)) - defaultSpacing - defaultSpacingSmall;
    textSizeNeeded = length(gridLabelsString)*defaultHeight;
    if textSizeNeeded~=textSizeCurrent
        diffHeight = textSizeNeeded - textSizeCurrent;
        
        % set the grid labels text box
        pos(2) = pos(2) - diffHeight;
        pos(4) = pos(4) + diffHeight;
        set(this.guiHandles.textGridLabels,'Position',pos);
        
        % channel label/value
        pos = get(this.guiHandles.textNumChannelsLabel,'Position');
        pos(2) = pos(2) - diffHeight;
        set(this.guiHandles.textNumChannelsLabel,'Position',pos);
        pos = get(this.guiHandles.textNumChannelsValue,'Position');
        pos(2) = pos(2) - diffHeight;
        set(this.guiHandles.textNumChannelsValue,'Position',pos);
        
        % central channel label/value
        pos = get(this.guiHandles.textMaxCentralChannelLabel,'Position');
        pos(2) = pos(2) - diffHeight;
        set(this.guiHandles.textMaxCentralChannelLabel,'Position',pos);
        pos = get(this.guiHandles.textMaxCentralChannelValue,'Position');
        pos(2) = pos(2) - diffHeight;
        set(this.guiHandles.textMaxCentralChannelValue,'Position',pos);
        
        % central channel label/value
        pos = get(this.guiHandles.textCentralChannelsSkippedLabel,'Position');
        pos(2) = pos(2) - diffHeight;
        set(this.guiHandles.textCentralChannelsSkippedLabel,'Position',pos);
        pos = get(this.guiHandles.textCentralChannelsSkippedValue,'Position');
        pos(2) = pos(2) - diffHeight;
        set(this.guiHandles.textCentralChannelsSkippedValue,'Position',pos);
    end
    
    % update values
    set(this.guiHandles.textNumGridsValue,'String',sprintf('%d',this.hGridMap.NumGrids));
    set(this.guiHandles.textGridLabels,'String',gridLabelsString);
    set(this.guiHandles.textNumChannelsValue,'String',sprintf('%d',this.hGridMap.NumChannels));
    set(this.guiHandles.textMaxCentralChannelValue,'String',sprintf('%d',max(this.hGridMap.ChannelInfo.AmplifierChannel)));
    set(this.guiHandles.textCentralChannelsSkippedValue,'String',sprintf('%d',max(this.hGridMap.ChannelInfo.AmplifierChannel)-this.hGridMap.NumChannels));
else
    set(this.guiHandles.textNumGridsValue,'String','[No Grids Defined]');
    set(this.guiHandles.textGridLabels,'String','[No Grids Defined]');
    set(this.guiHandles.textNumChannelsValue,'String','[No Grids Defined]');
    set(this.guiHandles.textMaxCentralChannelValue,'String','[No Grids Defined]');
    set(this.guiHandles.textCentralChannelsSkippedValue,'String','[No Grids Defined]');
end

% ready to go
setStatus(this,'Ready');