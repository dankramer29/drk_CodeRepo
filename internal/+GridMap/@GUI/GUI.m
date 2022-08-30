classdef GUI < handle
    
    properties
        hFigure
        hGridMap
    end % END properties
    
    properties(Access=private)
        Mapfile
        SavedState % saving enable/disable state
        GuiMode = 'view'; % view, new, edit
        ChannelDisplayMode = 'allgrids'; % allgrids or selectedgrid
        listboxGridIndex
        guiHandles
    end % END properties(Access=private)

    methods
        function this = GUI(varargin)
            warning('when a grid is edited, you need to check whether the number of channels has changed and if so update all the subsequent grids');
            this.hGridMap = GridMap.Interface;
            layout(this);
            
            % templates
            templates = dir(fullfile(env.get('code'),'internal','def','grids'));
            templates(~cellfun(@isempty,regexpi({templates.name},'^\.+$'))) = [];
            templates = [{'None'} {templates.name} {'Gap'}];
            set(this.guiHandles.popupTemplate,'String',templates);
            
            % locations
            locationFile = fullfile(env.get('code'),'internal','def','GridLocations.csv');
            fid = util.openfile(locationFile,'r');
            try
                
                % run through any empty lines at the top
                locline = fgetl(fid);
                while ~isempty(regexpi(locline,'^\s*$'))
                    locline = fgetl(fid);
                end
                
                % spool up to the header line
                while any(cellfun(@isempty,regexpi(locline,{'LocationID','LocationDescription'})))
                    locline = fgetl(fid);
                end
                
                % header fields
                varNames = strsplit(locline,',');
                
                % find out how many channels
                locinfo = cell(1024,1);
                ii = 1;
                while ~feof(fid)
                    locinfo{ii} = fgetl(fid);
                    ii = ii+1;
                end
                locinfo(ii:end) = [];
                locinfo = cellfun(@(x)strsplit(x,','),locinfo,'UniformOutput',false);
                locinfo = cat(1,locinfo{:});
                locinfo = cell2table(locinfo,'VariableNames',varNames);
            catch ME
                util.closefile(fid);
                rethrow(ME);
            end
            util.closefile(fid);
            set(this.guiHandles.popupLocation,'String',[{'None'}; locinfo.LocationID]);
            
            % hemisphere
            set(this.guiHandles.popupHemisphere,'String',{'None','Left','Right'});
            
            % update status
            refreshContent(this);
            configureGUI(this,'mapfile__enabled','gridinfo__limited','channelinfo__disabled','gridsummary__disabled');
            setStatus(this,'Ready');
        end % END function GUI
        
        function gm__addGrid(this,template,location,hemisphere,label,electrode,firstampchan,bankalign,banklock)
            mapdata = struct(...
                'GridID',this.hGridMap.NumGrids,...
                'GridElectrode',{{electrode(:)'}},...
                'Label',{{label}},...
                'Location',{{location}},...
                'Hemisphere',{{hemisphere}},...
                'Template',{{template}},...
                'BankAlign',bankalign,...
                'BankLock',banklock);
            this.hGridMap.addGrid(mapdata,firstampchan);
        end % END function gm__addGrid
        
        function gm__editGrid(this,gid,template,location,hemisphere,label,electrode,firstampchan,bankalign,banklock)
            mapdata = struct(...
                'GridID',gid,...
                'GridElectrode',{electrode(:)'},...
                'Label',{label},...
                'Location',{location},...
                'Hemisphere',{hemisphere},...
                'Template',{template},...
                'BankAlign',bankalign,...
                'BankLock',banklock);
            this.hGridMap.editGrid(gid,mapdata,firstampchan);
        end % END function gm__editGrid
        
        function gui__selectMapfile(this,varargin)
            setStatus(this,'User select mapfile');
            
            % let user select file
            srcdir = env.get('data');
            srcext = {...
                '*.map','*.map files'; ...
                '*.csv','*.csv files'};
            [mapfile,mapdir] = uigetfile(srcext,'Select a map file',fullfile(srcdir{1},'*.map'));
            if isnumeric(mapfile)&&mapfile==0
                return;
            end
            this.Mapfile = fullfile(mapdir,mapfile);
            
            % update GUI
            refreshContent(this);
            configureGUI(this,'mapfile__enabled','gridinfo__limited','channelinfo__disabled','gridsummary__disabled');
            setStatus(this,'Ready');
        end % END function gui__selectMapfile
        
        function gui__loadMapfile(this)
            setStatus(this,sprintf('Reading mapfile "%s"',this.Mapfile));
            
            % reset the grid map
            this.hGridMap = GridMap.Interface(this.Mapfile);
            
            % update fields from auto-selected first listbox entry
            refreshContent(this);
            if isempty(this.hGridMap) || this.hGridMap.NumGrids==0
                configureGUI(this,'mapfile__enabled','gridinfo__limited','channelinfo__disabled','gridsummary__disabled');
            else
                configureGUI(this,'mapfile__enabled','gridinfo__enabled','channelinfo__enabled','gridsummary__disabled');
            end
            setStatus(this,'Ready');
        end % END function gui__loadMapfile
        
        function gui__newGrid(this)
            set(this.guiHandles.popupTemplate,'Value',1);
            set(this.guiHandles.popupLocation,'Value',1);
            set(this.guiHandles.popupHemisphere,'Value',1);
            set(this.guiHandles.editLabel,'String','');
            set(this.guiHandles.editElectrode,'String','');
            set(this.guiHandles.editFirstAmpChannel,'String','NaN');
            set(this.guiHandles.checkboxBankAlign,'Value',0);
            set(this.guiHandles.checkboxBankLock,'Value',0);
            
            % configure the GUI
            configureGUI(this,'mapfile__disabled','gridinfo__disabled','channelinfo__disabled','gridsummary__enabled');
            setStatus(this,'Save, reset, or cancel grid');
        end % END function gui__newGrid
        
        function gui__editGrid(this,selectedGridRow)
            assert(nargin>=2 && ~isempty(selectedGridRow),'Must select grid first');
            set(this.guiHandles.listboxGridInfo,'Value',selectedGridRow);
            refreshContent(this);
            
            % configure the GUI
            configureGUI(this,'mapfile__disabled','gridinfo__disabled','channelinfo__disabled','gridsummary__enabled');
            setStatus(this,'Save, reset, or cancel grid');
        end % END function gui__editGrid
        
        function gui__moveGrid(this,direction)
            
            % make sure there's something to move
            if direction==0,return;end
            [selectedRow,~,gid] = gui__getSelectedGrid(this);
            if isnan(selectedRow),return;end
            
            % validate move
            if gid+sign(direction)<0 || gid+sign(direction)>=this.hGridMap.NumGrids
                return;
            end
            
            % move the grid up or down
            this.hGridMap.updateGridID(gid,gid+sign(direction));
            
            % update selected row
            selectedRow = selectedRow + sign(direction);
            set(this.guiHandles.listboxGridInfo,'Value',selectedRow);
            
            % update the GUI
            refreshContent(this);
        end % END function gui_moveGrid
        
        function gui__saveGrid(this)
            
            % check whether it's a gap entry or a grid entry
            templateStrings = get(this.guiHandles.popupTemplate,'String');
            templateIndex = get(this.guiHandles.popupTemplate,'Value');
            if templateIndex==length(templateStrings)
                
                % updating or adding a gap: updating the following grid
                selectedRow = gui__getSelectedGrid(this);
                assert(selectedRow<length(this.listboxGridIndex),'Cannot add a gap at the end of the grid map');
                assert(selectedRow>1,'Cannot add a gap at the beginning of the grid map');
                nextGrid = this.listboxGridIndex(selectedRow+1);
                nextGridID = this.hGridMap.GridInfo.GridID(nextGrid);
                prevGrid = this.listboxGridIndex(selectedRow-1);
                prevGridID = this.hGridMap.GridInfo.GridID(prevGrid);
                template = this.hGridMap.GridInfo.Template{nextGrid};
                location = this.hGridMap.GridInfo.Location{nextGrid};
                hemisphere = this.hGridMap.GridInfo.Hemisphere{nextGrid};
                label = this.hGridMap.GridInfo.Label{this.hGridMap.GridInfo.GridID==nextGridID};
                idx_ch = this.hGridMap.ChannelInfo.GridID==nextGridID;
                assert(nnz(idx_ch)>0,'Could not find any channels for grid ID %d',nextGridID);
                electrode = this.hGridMap.ChannelInfo.GridElectrode(idx_ch);
                gapelectrodes = eval(get(this.guiHandles.editElectrode,'String'));
                lastgridlastchan = this.hGridMap.ChannelInfo.AmplifierChannel(find(this.hGridMap.ChannelInfo.GridID==prevGridID,1,'last'));
                firstampchan = lastgridlastchan + length(gapelectrodes) + 1;
                bankalign = this.hGridMap.GridInfo.BankAlign(nextGrid);
                banklock = this.hGridMap.GridInfo.Locked(nextGrid);
                
                % update the grid
                gm__editGrid(this,nextGridID,template,location,hemisphere,label,electrode,firstampchan,bankalign,banklock);
            else
                
                % get information from the GUI
                template = templateStrings{templateIndex};
                locationStrings = get(this.guiHandles.popupLocation,'String');
                locationIndex = get(this.guiHandles.popupLocation,'Value');
                location = locationStrings{locationIndex};
                hemisphereStrings = get(this.guiHandles.popupHemisphere,'String');
                hemisphereIndex = get(this.guiHandles.popupHemisphere,'Value');
                hemisphere = hemisphereStrings{hemisphereIndex};
                label = get(this.guiHandles.editLabel,'String');
                electrode = eval(get(this.guiHandles.editElectrode,'String'));
                firstampchan = eval(get(this.guiHandles.editFirstAmpChannel,'String'));
                bankalign = get(this.guiHandles.checkboxBankAlign,'Value');
                banklock = get(this.guiHandles.checkboxBankLock,'Value');
                
                % updating or adding a grid
                if strcmpi(this.GuiMode,'new')
                    gm__addGrid(this,template,location,hemisphere,label,electrode,firstampchan,bankalign,banklock);
                elseif strcmpi(this.GuiMode,'edit')
                    [~,~,gid] = gui__getSelectedGrid(this);
                    gm__editGrid(this,gid,template,location,hemisphere,label,electrode,firstampchan,bankalign,banklock);
                end
            end
            this.GuiMode = 'view';
            gui__cancelGrid(this);
        end % END function gui__saveGrid
        
        function [selectedRow,selectedGrid,selectedGridID] = gui__getSelectedGrid(this)
            % selectedRow - nan = no grid map or no grids in grid map
            %             - empty = nothing selected in the listbox
            %             - numeric = index of row selected in listbox
            % selectedGrid - nan = no grid map / no grids in grid map /
            %                      nothing selected in listbox / gap entry
            %                      selected in listbox
            %              - numeric = index of the grid entry in grid map
            % selectedGridID - nan = all of the above
            %                - numeric = grid id of selected grid
            selectedRow = nan;
            selectedGrid = nan;
            selectedGridID = nan;
            if isempty(this.hGridMap) || this.hGridMap.NumGrids==0
                return;
            end
            selectedRow = get(this.guiHandles.listboxGridInfo,'Value');
            if isempty(selectedRow)
                return;
            end
            selectedGrid = this.listboxGridIndex(selectedRow);
            if isnan(selectedGrid)
                return;
            end
            selectedGridID = this.hGridMap.GridInfo.GridID(selectedGrid);
        end % END function gui__getSelectedGrid
        
        function [amplifierChannels,recordingChannels] = gui__getGapChannels(this,selectedRow)
            
            % figure out range of amplifier channel numbers from
            % previous/next grids
            if selectedRow==1
                
                % gap is at the beginning (really this should never happen)
                error('Invalid to have a gap at the beginning...');
            elseif selectedRow==length(this.listboxGridIndex)
                
                % gap is at the end (this should never happen)
                error('Invalid to have a gap at the end...');
            else
                
                % find previous amplifier/recording channels
                prevGrid = find(~isnan(this.listboxGridIndex(1:selectedRow)),1,'last');
                assert(~isempty(prevGrid),'Invalid to have gap starting at amplifier channel 1');
                prevGrid = this.listboxGridIndex(prevGrid);
                idxLastChanPrevGrid = find(this.hGridMap.ChannelInfo.GridID==this.hGridMap.GridInfo.GridID(prevGrid),1,'last');
                assert(~isempty(idxLastChanPrevGrid),'Logical problem - could not identify previous amplifier channel');
                prevAmplifierChannel = this.hGridMap.ChannelInfo.AmplifierChannel(idxLastChanPrevGrid);
                prevRecordingChannel = this.hGridMap.ChannelInfo.RecordingChannel(idxLastChanPrevGrid);
                
                % find next amplifier/recording channels
                nextGrid = selectedRow + find(~isnan(this.listboxGridIndex(selectedRow:end)),1,'first') - 1;
                assert(~isempty(nextGrid),'Invalid to have gap ending with last amplifier channel');
                nextGrid = this.listboxGridIndex(nextGrid);
                idxFirstChanNextGrid = find(this.hGridMap.ChannelInfo.GridID==this.hGridMap.GridInfo.GridID(nextGrid),1,'first');
                assert(~isempty(idxFirstChanNextGrid),'Logical problem - could not identify next amplifier channel');
                nextAmplifierChannel = this.hGridMap.ChannelInfo.AmplifierChannel(idxFirstChanNextGrid);
                nextRecordingChannel = this.hGridMap.ChannelInfo.RecordingChannel(idxFirstChanNextGrid);
                
                % set amplifier/recording channels for gap
                amplifierChannels = (prevAmplifierChannel+1):(nextAmplifierChannel-1);
                recordingChannels = (prevRecordingChannel+1):(nextRecordingChannel-1);
            end
        end % END function gui__getGapChannels
        
        function gui__resetGrid(this)
            refreshContent(this);
        end % END function gui__resetGrid
        
        function gui__cancelGrid(this)
            refreshContent(this);
            if isempty(this.hGridMap) || this.hGridMap.NumGrids==0
                configureGUI(this,'mapfile__enabled','gridinfo__limited','channelinfo__disabled','gridsummary__disabled');
            else
                configureGUI(this,'mapfile__enabled','gridinfo__enabled','channelinfo__enabled','gridsummary__disabled');
            end
        end % END function gui__cancelGrid
        
        function gui__deleteGrid(this,selectedGridIndex)
            this.hGridMap.removeGrid(this.hGridMap.GridInfo.GridID(selectedGridIndex));
            
            % refresh display
            refreshContent(this);
            if isempty(this.hGridMap) || this.hGridMap.NumGrids==0
                configureGUI(this,'mapfile__enabled','gridinfo__limited','channelinfo__disabled','gridsummary__disabled');
            else
                configureGUI(this,'mapfile__enabled','gridinfo__enabled','channelinfo__enabled','gridsummary__disabled');
            end
        end % END function gui__deleteGrid
        
        function setStatus(this,msg)
            set(this.guiHandles.textStatus,'String',msg);
            drawnow;
        end % END function setStatus
        
        function close(this)
            delete(this);
        end % END function close
        
        function delete(this)
            delete(this.hFigure);
        end % END function delete
    end % END methods
end % END classdef GUI