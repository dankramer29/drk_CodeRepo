function refreshGridSummaryFromSelected(this)
[selectedRow,selectedGrid] = gui__getSelectedGrid(this);
if isempty(selectedRow) || (~isempty(selectedRow)&&isnan(selectedRow))
    set(this.guiHandles.popupTemplate,'Value',1);
    set(this.guiHandles.popupLocation,'Value',1);
    set(this.guiHandles.popupHemisphere,'Value',1);
    
    if strcmpi(this.GuiMode,'new') || strcmpi(this.GuiMode,'edit')
        set(this.guiHandles.editLabel,'String','');
        set(this.guiHandles.editElectrode,'String','');
        set(this.guiHandles.editCentralChannel,'String','');
        set(this.guiHandles.checkboxBankAlign,'Value',0);
        set(this.guiHandles.checkboxBankLock,'Value',0);
    else
        set(this.guiHandles.editLabel,'String','[No Grids Defined]');
        set(this.guiHandles.editElectrode,'String','[No Grids Defined]');
        set(this.guiHandles.editFirstAmpChannel,'String','NaN');
        set(this.guiHandles.checkboxBankAlign,'Value',0);
        set(this.guiHandles.checkboxBankLock,'Value',0);
    end
else
    if isnan(selectedGrid)
        amplifierChannels = gui__getGapChannels(this,selectedRow);
        set(this.guiHandles.popupTemplate,'Value',length(get(this.guiHandles.popupTemplate,'String')));
        set(this.guiHandles.popupLocation,'Value',1);
        set(this.guiHandles.popupHemisphere,'Value',1);
        set(this.guiHandles.editLabel,'String','[GAP]');
        set(this.guiHandles.editElectrode,'String',util.vec2str(1:length(amplifierChannels)));
        set(this.guiHandles.editFirstAmpChannel,'String',sprintf('%d',amplifierChannels(1)));
        set(this.guiHandles.checkboxBankAlign,'Value',0);
        set(this.guiHandles.checkboxBankLock,'Value',0);
    else
        selGridInfo = this.hGridMap.GridInfo(selectedGrid,:);
        selChanInfo = this.hGridMap.ChannelInfo(this.hGridMap.ChannelInfo.GridID==selGridInfo.GridID,:);
        try
            assert(~isempty(selGridInfo.Template)&&iscell(selGridInfo.Template),'Invalid mapdata template');
        catch ME
            util.errorMessage(ME);
            keyboard
        end
        idxTemplate = find(strcmpi(get(this.guiHandles.popupTemplate,'String'),selGridInfo.Template{1}));
        if isempty(idxTemplate)
            warning('Could not match stored template "%s" to any available definition',selGridInfo.Template{1});
            set(this.guiHandles.popupTemplate,'Value',1);
        else
            set(this.guiHandles.popupTemplate,'Value',idxTemplate);
        end
        idxLocation = find(strcmpi(get(this.guiHandles.popupLocation,'String'),selGridInfo.Location{1}));
        if isempty(idxLocation)
            warning('Could not match stored location "%s" to any available definition',selGridInfo.Location{1});
            set(this.guiHandles.popupLocation,'Value',1);
        else
            set(this.guiHandles.popupLocation,'Value',idxLocation);
        end
        idxHemisphere = find(strcmpi(get(this.guiHandles.popupHemisphere,'String'),selGridInfo.Hemisphere{1}));
        if isempty(idxHemisphere)
            warning('Could not match stored hemisphere "%s" to any available definition',selGridInfo.Hemisphere{1});
            set(this.guiHandles.popupHemisphere,'Value',1);
        else
            set(this.guiHandles.popupHemisphere,'Value',idxHemisphere);
        end
        set(this.guiHandles.editLabel,'String',selGridInfo.Label{1});
        set(this.guiHandles.editElectrode,'String',util.vec2str(selGridInfo.Electrode{1}));
        set(this.guiHandles.editFirstAmpChannel,'String',selChanInfo.AmplifierChannel(1));
        set(this.guiHandles.checkboxBankAlign,'Value',selGridInfo.BankAlign(1));
        set(this.guiHandles.checkboxBankLock,'Value',selGridInfo.Locked(1));
    end
end