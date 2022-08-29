classdef Interface < handle & util.Structable & util.StructableHierarchy
    % INTERFACE information about channel layout for all grids in a dataset
    
    properties
        BankInfo % table containing recording bank info
        BehavInfo % table containing behavioral channel info
        ChannelInfo % table containing channel info
        GridInfo % table containing grid info
        NumGrids % number of grids in the dataset
        GridChannelIndex % cell array where each cell contains list of channel indices for that grid
        NumChannelsPerGrid % number of channels in each grid in the dataset
        NumChannels % total number of data channels
        NumBehav % number of behavioral channels
    end % END properties
    
    methods
        function this = Interface(varargin)
            
            % process user inputs/defaults
            [varargin,banking_scheme] = util.argkeyword({'blackrock_nsp','natus','none'},varargin,'blackrock_nsp');
            [varargin,maptable,found_maptable] = util.argfn(@(x)istable(x),varargin,{});
            [varargin,mapfile,found_mapfile] = util.argfn(@(x)ischar(x)&&exist(x,'file')==2,varargin,{});
            util.argempty(varargin);
            
            % initialize the bank info
            b = GridMap.Bank(banking_scheme);
            this.BankInfo = b.info;
            
            % initialize the channel and grid info tables
            this.ChannelInfo = cell2table(cell(0,7),'VariableNames',{...
                'ChannelID','RecordingChannel','AmplifierChannel',...
                'Label','Bank','GridElectrode','GridID'});
            this.GridInfo = cell2table(cell(0,12),'VariableNames',{'GridID',...
                'Label','Location','Hemisphere','Electrode','BankAlign',...
                'Locked','Template','Type','Subtype','Layout','Custom'});
            this.BehavInfo = cell2table(cell(0,3),'VariableNames',{'BehavID',...
                'Label','AmplifierChannel'});
            
            % load map file into a table
            proc_maptable = false;
            if found_mapfile
                gmf = GridMap.File(mapfile);
                maptable = gmf.read;
                proc_maptable = true;
            elseif found_maptable
                proc_maptable = true;
            end
            
            % process the map file input
            if proc_maptable
                for kk=1:height(maptable)
                    addGrid(this,maptable(kk,:));
                end
            else
                this.NumGrids = 0;
                this.NumChannels = 0;
            end
            
            % set behav channels to zero for now
            this.NumBehav = 0;
        end % END function Interface
        
        function checkGridChannelOverlap(this,varargin)
            warning('This function needs to be re-written after change to recording/amplifier channels and channel IDs');
            [varargin,gids] = util.argkeyval('gids',varargin,this.GridInfo.GridID);
            util.argempty(varargin);
            
            % check whether previous or subsequent grids' channels need to be updated
            for local_gid=gids(:)'
                channels_this_grid = this.ChannelInfo.AmplifierChannel(this.ChannelInfo.GridID==local_gid);
                
                % check for conflict and compute offset to shift ch's
                channels_previous_grids = this.ChannelInfo.AmplifierChannel(this.ChannelInfo.GridID<local_gid);
                offset = nan;
                if any(channels_this_grid(1)<=channels_previous_grids)
                    
                    % fix the current offset
                    offset = channels_previous_grids(end) - channels_this_grid(1) + 1;
                elseif channels_this_grid(1)-max(channels_previous_grids) > 1
                    
                    % fix the current offset
                    offset = max(channels_previous_grids) - channels_this_grid(1) + 1;
                end
                
                % if offset shift ch's and update for bank alignment
                if ~isnan(offset)
                    channels_this_grid = channels_this_grid + offset;
                    
                    % check for bank alignment
                    if this.GridInfo.BankAlign(this.GridInfo.GridID==local_gid)
                        bank1 = find(cellfun(@(x)ismember(channels_this_grid(1),x),this.BankInfo.Channel));
                        assert(~isempty(bank1)&&length(bank1)==1,'Could not identify bank for channel %d',channels_this_grid(1));
                        bank2 = find(cellfun(@(x)ismember(channels_this_grid(end),x),this.BankInfo.Channel));
                        assert(~isempty(bank2)&&length(bank2)==1,'Could not identify bank for channel %d',channels_this_grid(end));
                        if bank1~=bank2
                            offset = this.BankInfo.Channel{bank2}(1) - channels_this_grid(1);
                            channels_this_grid = channels_this_grid + offset;
                        end
                    end
                    
                    % update channel entries
                    this.ChannelInfo.AmplifierChannel(this.ChannelInfo.GridID==local_gid) = channels_this_grid;
                    
                    % update banks
                    banks = arrayfun(@(x)find(cellfun(@(y)ismember(x,y),this.BankInfo.Channel)),channels_this_grid,'UniformOutput',false);
                    banks(~cellfun(@isempty,banks)) = cellfun(@(x)this.BankInfo.Label{x},banks(~cellfun(@isempty,banks)),'UniformOutput',false);
                    this.ChannelInfo.Bank(this.ChannelInfo.GridID==local_gid) = banks;
                end
            end
        end % END function checkGridChannelOverlap
        
        function updateGridID(this,gid,newgid)
            assert(nargin>=2&&~isempty(gid)&&isnumeric(gid)&&gid>=0&&gid<this.NumGrids,'Must provide valid grid ID');
            assert(nargin>=3&&~isempty(newgid)&&isnumeric(newgid)&&newgid>=0&&newgid<this.NumGrids,'Must provide valid new grid ID');
            if newgid==gid,return;end
            
            % identify grid with GridID gid
            idx_gid = find(this.GridInfo.GridID==gid);
            assert(~isempty(idx_gid),'Could not find grid with GridID %d',gid);
            idx_chan = this.ChannelInfo.GridID==gid;
            
            % change GID of the one being moved to something unique
            tempGridInfo = this.GridInfo(idx_gid,:);
            this.GridInfo(idx_gid,:) = [];
            tempChannelInfo = this.ChannelInfo(idx_chan,:);
            this.ChannelInfo(idx_chan,:) = [];
            
            % identify set of grids/channels before/after new location
            if newgid<gid
                
                % moving up: we want up to (not including) new gid for
                % prior, and we want everything after (including) new gid
                % for after
                prevGridInfo = this.GridInfo(this.GridInfo.GridID<newgid,:);
                prevChannelInfo = this.ChannelInfo(this.ChannelInfo.GridID<newgid,:);
                nextGridInfo = this.GridInfo(this.GridInfo.GridID>=newgid,:);
                nextChannelInfo = this.ChannelInfo(this.ChannelInfo.GridID>=newgid,:);
            else
                
                % moving down: we want up to (including) new gid for prior,
                % and we want everything after (but not including) new gid
                % for after
                prevGridInfo = this.GridInfo(this.GridInfo.GridID<=newgid,:);
                prevChannelInfo = this.ChannelInfo(this.ChannelInfo.GridID<=newgid,:);
                nextGridInfo = this.GridInfo(this.GridInfo.GridID>newgid,:);
                nextChannelInfo = this.ChannelInfo(this.ChannelInfo.GridID>newgid,:);
            end
            
            % update Grid IDs
            tempGridInfo.GridID = newgid;
            tempChannelInfo.GridID = repmat(newgid,size(tempChannelInfo,1),1);
            currGID = 0;
            pgd = nan(size(prevChannelInfo,1),1);
            for kk=1:size(prevGridInfo,1)
                idx_gid = prevChannelInfo.GridID==prevGridInfo.GridID(kk);
                prevGridInfo.GridID(kk) = currGID;
                pgd(idx_gid) = repmat(currGID,nnz(idx_gid),1);
                currGID = currGID + 1;
            end
            prevChannelInfo.GridID = pgd;
            currGID = currGID + 1;
            ngd = nan(size(nextChannelInfo,1),1);
            for kk=1:size(nextGridInfo,1)
                idx_gid = nextChannelInfo.GridID==nextGridInfo.GridID(kk);
                nextGridInfo.GridID(kk) = currGID;
                ngd(idx_gid) = repmat(currGID,nnz(idx_gid),1);
                currGID = currGID + 1;
            end
            nextChannelInfo.GridID = ngd;
            
            % re-construct grid info and channel info
            this.GridInfo = [prevGridInfo; tempGridInfo; nextGridInfo];
            this.ChannelInfo = [prevChannelInfo; tempChannelInfo; nextChannelInfo];
            
            % update amplifier and recording channel
            currAmpChannel = 1;
            currRecordingChannel = 1;
            for kk=1:size(this.GridInfo,1)
                currGID = this.GridInfo.GridID(kk);
                
                % check for bank alignment
                currBank = find(cellfun(@(x)ismember(currAmpChannel,x),this.BankInfo.Channel));
                if this.GridInfo.BankAlign(kk)
                    assert(~isempty(currBank),'Could not identify current bank');
                    if currBank < length(this.BankInfo.Channel)
                        currAmpChannel = this.BankInfo.Channel{currBank+1}(1);
                    end
                end
                
                % update the channel properties
                updateAmplifierChannel(this,currGID,currAmpChannel);
                updateRecordingChannel(this,currGID,currRecordingChannel);
                
                % update current channel numbers
                idx_gid = this.ChannelInfo.GridID==currGID;
                currAmpChannel = currAmpChannel + nnz(idx_gid);
                currRecordingChannel = currRecordingChannel + nnz(idx_gid);
            end
        end % END function updateGridID
        
        function updateAmplifierChannel(this,gid,ampch)
            assert(nargin>=2&&~isempty(gid)&&isnumeric(gid)&&gid>=0&&gid<this.NumGrids,'Must provide valid grid ID');
            
            % subselect just the requested electrodes
            idx_chan_grid = this.ChannelInfo.GridID==gid;
            if length(ampch)==1
                ampch = ampch + (0:(nnz(idx_chan_grid)-1));
            end
            assert(nnz(idx_chan_grid)==length(ampch),'Expected %d amplifier channels for grid ID %d, but found %d',nnz(idx_chan_grid),gid,length(ampch));
            
            % make sure no conflicts if shifting channels backward
            currAmpChannel = this.ChannelInfo.AmplifierChannel(idx_chan_grid);
            if ampch(1) < currAmpChannel(1)
                last_chan_prev_grid = max(this.ChannelInfo.AmplifierChannel(this.ChannelInfo.GridID<gid));
                assert(ampch(1)>last_chan_prev_grid,'Max first amplifier channel is %d (requested %d)',last_chan_prev_grid+1,ampch(1));
            end
            
            % update the amplifier channels
            currAmpChannel = ampch(1);
            for gg=gid:(this.NumGrids-1)
                idx_chan = this.ChannelInfo.GridID==gg;
                this.ChannelInfo.AmplifierChannel(idx_chan) = currAmpChannel + (0:(nnz(idx_chan)-1));
                currAmpChannel = currAmpChannel + nnz(idx_chan);
            end
            
            % update the bank
            for cc=this.ChannelInfo.ChannelID(this.ChannelInfo.GridID==gid)'
                idx_ch = this.ChannelInfo.ChannelID==cc & this.ChannelInfo.GridID==gid;
                idx_lbl = cellfun(@(x)ismember(this.ChannelInfo.AmplifierChannel(idx_ch),x),this.BankInfo.Channel);
                this.ChannelInfo.Bank{idx_ch} = this.BankInfo.Label{idx_lbl};
            end
            
            % update channel IDs
            this.ChannelInfo.ChannelID = (0:(size(this.ChannelInfo,1)-1))';
        end % END function updateAmplifierChannel
        
        function updateRecordingChannel(this,gid,recch)
            assert(nargin>=2&&~isempty(gid)&&isnumeric(gid)&&gid>=0&&gid<this.NumGrids,'Must provide valid grid ID');
            
            % subselect just the requested electrodes
            idx_chan_grid = this.ChannelInfo.GridID==gid;
            if nargin<3||isempty(recch)
                recch = max(this.ChannelInfo.RecordingChannel) + 1;
            end
            if length(recch)==1
                recch = recch + (0:(nnz(idx_chan_grid)-1));
            end
            assert(nnz(idx_chan_grid)==length(recch),'Expected %d recording channels for grid ID %d, but found %d',nnz(idx_chan_grid),gid,length(recch));
            
            % make sure no conflicts if decreasing channels
            currRecChannel = this.ChannelInfo.RecordingChannel(idx_chan_grid);
            if recch(1) < currRecChannel(1)
                last_chan_prev_grid = max(this.ChannelInfo.RecordingChannel(this.ChannelInfo.GridID<gid));
                assert(recch(1)>last_chan_prev_grid,'Max first recording channel is %d (requested %d)',last_chan_prev_grid+1,recch(1));
            end
            
            % update the amplifier channels
            currRecChannel = recch(1);
            for gg=gid:(this.NumGrids-1)
                idx_chan = this.ChannelInfo.GridID==gg;
                this.ChannelInfo.RecordingChannel(idx_chan) = currRecChannel + (0:(nnz(idx_chan)-1));
                currRecChannel = currRecChannel + nnz(idx_chan);
            end
        end % END function updateRecordingChannel
        
        function updateLabel(this,gid,label)
            assert(nargin>=2&&~isempty(gid)&&isnumeric(gid)&&gid>=0&&gid<this.NumGrids,'Must provide valid grid ID');
            
            % subselect just the requested electrodes
            idx_chan_grid = this.ChannelInfo.GridID==gid;
            labels = arrayfun(@(x)sprintf('%s%d',label,x),this.ChannelInfo.GridElectrode(idx_chan_grid),'UniformOutput',false);
            
            % update the labels
            this.GridInfo.Label{this.GridInfo.GridID==gid} = label;
            this.ChannelInfo.Label(idx_chan_grid) = labels;
        end % END function updateChannelLabel
        
        function updateChannelBanks(this,gid)
            
            % create cell arrays of banks
            ampchannels = this.ChannelInfo.AmplifierChannel(this.ChannelInfo.GridID==gid);
            banks = arrayfun(@(x)find(cellfun(@(y)ismember(x,y),this.BankInfo.Channel)),ampchannels,'UniformOutput',false);
            banks(~cellfun(@isempty,banks)) = cellfun(@(x)this.BankInfo.Label{x},banks(~cellfun(@isempty,banks)),'UniformOutput',false);
            
            this.ChannelInfo.Bank(this.ChannelInfo.GridID==gid) = banks;
        end % END function updateChannelBanks
        
        function updateGridTemplate(this,gid,template,electrodes)
            assert(nargin>=2&&~isempty(gid)&&isnumeric(gid)&&gid>=0&&gid<this.NumGrids,'Must provide valid grid ID');
            t = GridMap.Template(template);
            [template_gridinfo,template_chaninfo] = t.read;
            
            % get grid electrodes
            if nargin>=4 && ~isempty(electrodes)
                gridelectrodes = electrodes;
            else
                gridelectrodes = (1:height(template_chaninfo))';
            end
            
            % subselect just the requested electrodes
            idx_chan_grid = ismember(template_chaninfo.GridElectrode,gridelectrodes);
            template_chaninfo = template_chaninfo(idx_chan_grid,:);
            
            % get channel numbers
            idx_gid = this.GridInfo.GridID==gid;
            ampchannels = this.ChannelInfo.AmplifierChannel(this.ChannelInfo.GridID==gid);
            ampchannels = ampchannels(1)-1 + gridelectrodes(:);
            recchannels = this.ChannelInfo.RecordingChannel(this.ChannelInfo.GridID==gid);
            recchannels = recchannels(1)-1 + gridelectrodes(:);
            
            % get miscellaneous
            label = this.GridInfo.Label{idx_gid};
            labels = arrayfun(@(x)sprintf('%s%d',label,x),gridelectrodes,'UniformOutput',false);
            layout = arrayfun(@(x)struct('row',template_chaninfo.GridRow(x),'col',template_chaninfo.GridColumn(x),'electrode',x),gridelectrodes);
            
            % check for bank alignment
            if this.GridInfo.BankAlign(idx_gid)
                bank1 = find(cellfun(@(x)ismember(ampchannels(1),x),this.BankInfo.Channel));
                assert(~isempty(bank1)&&length(bank1)==1,'Could not identify bank for channel %d',ampchannels(1));
                bank2 = find(cellfun(@(x)ismember(ampchannels(end),x),this.BankInfo.Channel));
                assert(~isempty(bank2)&&length(bank2)==1,'Could not identify bank for channel %d',ampchannels(end));
                if bank1~=bank2 && length(ampchannels)<=length(this.BankInfo.Channel{bank1})
                    offset = this.BankInfo.Channel{bank2}(1) - ampchannels(1);
                    ampchannels = ampchannels + offset;
                end
            end
            banks = arrayfun(@(x)find(cellfun(@(y)ismember(x,y),this.BankInfo.Channel)),ampchannels,'UniformOutput',false);
            banks(~cellfun(@isempty,banks)) = cellfun(@(x)this.BankInfo.Label{x},banks(~cellfun(@isempty,banks)),'UniformOutput',false);
            
            % common vs custom variables
            commonLabels = {'GridID','ChannelNumber','Label','Location','Hemisphere','BankAlign','Locked','Template','Type','Subtype'};
            customLabels = fieldnames(template_gridinfo);
            customLabels(arrayfun(@(x)any(strcmpi(x,commonLabels)),customLabels)) = [];
            customValues = cellfun(@(x)template_gridinfo.(x),customLabels,'UniformOutput',false);
            custom = [customLabels(:)'; customValues(:)'];
            
            % create grid info
            this.GridInfo.Electrode{idx_gid} = gridelectrodes;
            this.GridInfo.Template{idx_gid} = template;
            this.GridInfo.Type{idx_gid} = template_gridinfo.Type;
            this.GridInfo.Subtype{idx_gid} = template_gridinfo.Subtype;
            this.GridInfo.Layout{idx_gid} = layout;
            this.GridInfo.Custom{idx_gid} = struct(custom{:});
            
            % create channel info
            chaninfo = cell2table(cell(length(ampchannels),7),'VariableNames',{...
                'ChannelID','RecordingChannel','AmplifierChannel',...
                'Label','Bank','GridElectrode','GridID'});
            chaninfo.ChannelID = height(this.ChannelInfo)-1 + (1:length(ampchannels))';
            chaninfo.RecordingChannel = recchannels;
            chaninfo.AmplifierChannel = ampchannels;
            chaninfo.Label = labels;
            chaninfo.Bank = banks;
            chaninfo.GridElectrode = gridelectrodes;
            chaninfo.GridID = repmat(gid,length(gridelectrodes),1);
            
            % swap out channel info entries
            idx_chan = find(this.ChannelInfo.GridID==gid);
            assert(~isempty(idx_chan),'Could not find channels with GridID %d',gid);
            this.ChannelInfo = [this.ChannelInfo(1:(idx_chan(1)-1),:); chaninfo; this.ChannelInfo((idx_chan(end)+1):end,:)];
            
            % update metadata properties
            this.NumChannelsPerGrid = arrayfun(@(x)nnz(this.ChannelInfo.GridID==x),0:this.NumGrids-1);
            this.NumChannels = sum(this.NumChannelsPerGrid);
            this.GridChannelIndex = arrayfun(@(x)find(this.ChannelInfo.GridID==x),0:this.NumGrids-1,'UniformOutput',false);
        end % END function updateGridTemplate
        
        function updateBankAlign(this,gid)
            warning('This function needs to be re-written after change to recording/amplifier channels and channel IDs');
            
            % check whether previous or subsequent grids' channels need to be updated
            channels_this_grid = this.ChannelInfo.AmplifierChannel(this.ChannelInfo.GridID==gid);
            
            % check for bank alignment
            if this.GridInfo.BankAlign(this.GridInfo.GridID==gid)
                
                % if aligned, make sure channels stick with one bank
                warning('What happens if electrode grid has too many electrodes for one grid?');
                bank1 = find(cellfun(@(x)ismember(channels_this_grid(1),x),this.BankInfo.Channel));
                assert(~isempty(bank1)&&length(bank1)==1,'Could not identify bank for channel %d',channels_this_grid(1));
                bank2 = find(cellfun(@(x)ismember(channels_this_grid(end),x),this.BankInfo.Channel));
                assert(~isempty(bank2)&&length(bank2)==1,'Could not identify bank for channel %d',channels_this_grid(end));
                if bank1~=bank2
                    offset = this.BankInfo.Channel{bank2}(1) - channels_this_grid(1);
                    channels_this_grid = channels_this_grid + offset;
                end
            else
                
                % if not aligned, make sure no gap from previous to this
                channels_previous_grids = this.ChannelInfo.AmplifierChannel(this.ChannelInfo.GridID<gid);
                offset = channels_this_grid(1)-channels_previous_grids(end);
                
                % if offset shift ch's and update for bank alignment
                if offset>1
                    channels_this_grid = channels_this_grid - offset + 1;
                end
            end
            
            % update channel entries
            this.ChannelInfo.AmplifierChannel(this.ChannelInfo.GridID==gid) = channels_this_grid;
            
            % update banks
            banks = arrayfun(@(x)find(cellfun(@(y)ismember(x,y),this.BankInfo.Channel)),channels_this_grid,'UniformOutput',false);
            banks(~cellfun(@isempty,banks)) = cellfun(@(x)this.BankInfo.Label{x},banks(~cellfun(@isempty,banks)),'UniformOutput',false);
            this.ChannelInfo.Bank(this.ChannelInfo.GridID==gid) = banks;
            
            % check channel overlap
            checkGridChannelOverlap(this);
        end % END function updateBankAlign
        
        function removeGrid(this,gid)
            warning('This function needs to be re-written after change to recording/amplifier channels and channel IDs');
            assert(nargin>=2&&~isempty(gid)&&isnumeric(gid)&&gid>=0&&gid<this.NumGrids,'Must provide valid grid ID');
            
            % identify the grid entry
            idx = find(this.GridInfo.GridID==gid);
            assert(~isempty(idx),'Could not find grid with GridID %d',gid);
            
            % remove the GridInfo entry
            oldGridInfo = this.GridInfo(idx,:);
            this.GridInfo(idx,:) = [];
            
            % remove ChannelInfo entries
            this.ChannelInfo(this.ChannelInfo.GridID==gid,:) = [];
            
            % update subsequent grids' grid IDs and channel numbers
            idx_grids = find(this.GridInfo.GridID>oldGridInfo.GridID);
            for gg=idx_grids(:)'
                oldGridID = this.GridInfo.GridID(gg);
                newGridID = this.GridInfo.GridID(gg)-1;
                updateGridID(this,oldGridID,newGridID);
            end
            
            % update number of grids and channels
            this.NumChannels = height(this.ChannelInfo);
            this.NumGrids = height(this.GridInfo);
        end % END function removeGrid
        
        function editGrid(this,gid,mapdata,ch)
            warning('This function needs to be re-written after change to recording/amplifier channels and channel IDs');
            assert(nargin>=2&&~isempty(gid)&&isnumeric(gid)&&gid>=0&&gid<this.NumGrids,'Must provide valid grid ID');
            
            % update the template to handle things like channels
            updateGridTemplate(this,mapdata.GridID,mapdata.Template,mapdata.GridElectrode(:));
            
            % update channel info fields
            updateLabel(this,gid,mapdata.Label);
            updateAmplifierChannel(this,gid,ch);
            updateRecordingChannel(this,gid);
            
            % update grid info fields
            idx_grid = find(this.GridInfo.GridID==gid);
            assert(~isempty(idx_grid),'Could not find grid with GridID %d',gid);
            this.GridInfo.Label(idx_grid) = {mapdata.Label};
            this.GridInfo.Location(idx_grid) = {mapdata.Location};
            this.GridInfo.Hemisphere(idx_grid) = {mapdata.Hemisphere};
            this.GridInfo.BankAlign(idx_grid) = mapdata.BankAlign;
            this.GridInfo.BankLock(idx_grid) = mapdata.BankLock;
            
            % update bank alignment
            updateBankAlign(this,gid);
            updateChannelBanks(this,gid);
            
            % add metadata properties
            this.NumChannelsPerGrid = arrayfun(@(x)nnz(this.ChannelInfo.GridID==x),0:this.NumGrids-1);
            this.NumChannels = sum(this.NumChannelsPerGrid);
            this.GridChannelIndex = arrayfun(@(x)find(this.ChannelInfo.GridID==x),0:this.NumGrids-1,'UniformOutput',false);
        end % END function editGrid
        
        function addGrid(this,maptable,ch)
            if isstruct(maptable),maptable=struct2table(maptable);end
            assert(istable(maptable),'Must provide maptable as a table, not "%s"',class(maptable));
            if nargin<3||isempty(ch),ch=nan;end
            template_name = maptable.Template;
            if iscell(template_name),template_name=template_name{1};end
            template = GridMap.Template(template_name);
            [template_gridinfo,template_chaninfo] = template.read;
            
            % get grid electrodes (these are the physical electrodes
            if any(strncmpi(maptable.Properties.VariableNames,'GridElectrode',6))
                gridelectrodes = maptable.GridElectrode{1}(:);
            else
                gridelectrodes = (1:height(template_chaninfo))';
            end
            layout = arrayfun(@(x)struct('row',template_chaninfo.GridRow(x),'col',template_chaninfo.GridColumn(x),'electrode',x),gridelectrodes);
            
            % subselect just the requested electrodes
            idx_chan_grid = ismember(template_chaninfo.GridElectrode,gridelectrodes);
            template_chaninfo = template_chaninfo(idx_chan_grid,:);
            
            % check for bank align field
            if any(strcmpi(maptable.Properties.VariableNames,'BankAlign'))
                bankalign = maptable.BankAlign;
            else
                bankalign = false;
            end
            
            % check for bank align field
            if any(strcmpi(maptable.Properties.VariableNames,'BankLock'))
                banklock = maptable.BankLock;
            else
                banklock = true;
            end
            
            % label, hemisphere, location
            if any(strcmpi(maptable.Properties.VariableNames,'Label'))
                label = maptable.Label;
                if iscell(label),label=label{1};end
            else
                error('Must provide grid label');
            end
            if any(strcmpi(maptable.Properties.VariableNames,'Hemisphere'))
                hemisphere = maptable.Hemisphere;
                if iscell(hemisphere),hemisphere=hemisphere{1};end
            else
                error('Must provide grid hemisphere');
            end
            if any(strcmpi(maptable.Properties.VariableNames,'Location'))
                location = maptable.Location;
                if iscell(location),location=location{1};end
            else
                error('Must provide grid location');
            end
            
            % get channel numbers
            if any(strncmpi(maptable.Properties.VariableNames,'Channel',4))
                ampchannels = maptable.Channel;
                if iscell(ampchannels),ampchannels=ampchannels{1};end
                ampchannels = ampchannels(idx_chan_grid)';
                if length(ampchannels)<height(template_chaninfo)
                    template_chaninfo((length(ampchannels)+1):end,:) = [];
                end
            else
                ampchannels = (1:height(template_chaninfo))';
            end
            if isnan(ch)
                if any(strcmpi(maptable.Properties.VariableNames,'Channel'))
                    ch = ampchannels(1);
                else
                    if isempty(this.ChannelInfo)
                        ch = 1;
                    else
                        ch = max(this.ChannelInfo.AmplifierChannel) + 1;
                    end
                end
            end
            ampchannels = (ch-ampchannels(1)) + ampchannels;
            
            % validate
            assert(length(ampchannels)==length(gridelectrodes),'Must provide one grid electrode value per channel (found %d grid electrodes and %d channels)',length(gridelectrodes),length(ampchannels));
            
            % check for bank alignment
            if bankalign
                bank1 = find(cellfun(@(x)ismember(ampchannels(1),x),this.BankInfo.Channel));
                assert(~isempty(bank1)&&length(bank1)==1,'Could not identify bank for channel %d',ampchannels(1));
                bank2 = find(cellfun(@(x)ismember(ampchannels(end),x),this.BankInfo.Channel));
                assert(~isempty(bank2)&&length(bank2)==1,'Could not identify bank for channel %d',ampchannels(end));
                if bank1~=bank2
                    offset = this.BankInfo.Channel{bank2}(1) - ampchannels(1);
                    ampchannels = ampchannels + offset;
                end
            end
            
            % recording channels
            if isempty(this.ChannelInfo)
                recchannels = (1:length(ampchannels))';
            else
                recchannels = (1:length(ampchannels))' + max(this.ChannelInfo.RecordingChannel);
            end
            
            % common vs custom variables
            commonLabels = {'GridID','ChannelNumber','Label','Location','Hemisphere','BankAlign','Locked','Template','Type','Subtype'};
            customLabels = fieldnames(template_gridinfo);
            customLabels(arrayfun(@(x)any(strcmpi(x,commonLabels)),customLabels)) = [];
            customValues = cellfun(@(x)template_gridinfo.(x),customLabels,'UniformOutput',false);
            custom = [customLabels(:)'; customValues(:)'];
            
            % create cell arrays of labels/banks
            labels = arrayfun(@(x)sprintf('%s%d',label,template_chaninfo.GridElectrode(x)),(1:height(template_chaninfo))','UniformOutput',false);
            banks = arrayfun(@(x)find(cellfun(@(y)ismember(x,y),this.BankInfo.Channel)),ampchannels,'UniformOutput',false);
            banks(~cellfun(@isempty,banks)) = cellfun(@(x)this.BankInfo.Label{x},banks(~cellfun(@isempty,banks)),'UniformOutput',false);
            
            % create grid info
            gridinfo = cell2table(cell(1,12),'VariableNames',{'GridID',...
                'Label','Location','Hemisphere','Electrode','BankAlign',...
                'Locked','Template','Type','Subtype','Layout','Custom'});
            gridinfo.GridID = maptable.GridID;
            gridinfo.Label = {label};
            gridinfo.Location = {location};
            gridinfo.Hemisphere = {hemisphere};
            gridinfo.Electrode = {gridelectrodes};
            gridinfo.BankAlign = bankalign;
            gridinfo.Locked = banklock;
            gridinfo.Template = {template_name};
            gridinfo.Type = {template_gridinfo.Type};
            gridinfo.Subtype = {template_gridinfo.Subtype};
            gridinfo.Layout = {layout};
            gridinfo.Custom = {struct(custom{:})};
            
            % create channel info
            chaninfo = cell2table(cell(length(ampchannels),7),'VariableNames',{...
                'ChannelID','RecordingChannel','AmplifierChannel',...
                'Label','Bank','GridElectrode','GridID'});
            chaninfo.ChannelID = height(this.ChannelInfo)-1 + (1:length(ampchannels))';
            chaninfo.RecordingChannel = recchannels;
            chaninfo.AmplifierChannel = ampchannels;
            chaninfo.Label = labels;
            chaninfo.Bank = banks;
            chaninfo.GridElectrode = gridelectrodes;
            chaninfo.GridID = repmat(gridinfo.GridID,length(gridelectrodes),1);
            
            % update object properties
            this.GridInfo = [this.GridInfo; gridinfo];
            this.ChannelInfo = [this.ChannelInfo; chaninfo];
            
            % add metadata properties
            this.NumGrids = height(this.GridInfo);
            this.NumChannelsPerGrid = arrayfun(@(x)nnz(this.ChannelInfo.GridID==x),0:this.NumGrids-1);
            this.NumChannels = sum(this.NumChannelsPerGrid);
            this.GridChannelIndex = arrayfun(@(x)find(this.ChannelInfo.GridID==x),0:this.NumGrids-1,'UniformOutput',false);
        end % END function addGrid
        
        function addBehavioralChannel(this,label,ampchannel)
            
            % create grid info
            behavinfo = cell2table(cell(1,3),'VariableNames',{'BehavID','AmplifierChannel','Label'});
            behavinfo.BehavID = height(this.BehavInfo);
            behavinfo.AmplifierChannel = ampchannel;
            behavinfo.Label = {label};
            
            % update object properties
            this.BehavInfo = [this.BehavInfo; behavinfo];
            
            % add metadata properties
            this.NumBehav = height(this.BehavInfo);
        end % END function addBehavioral
        
        function lt = gridlayout(this,g,varargin)
            % GRIDLAYOUT Get electrode layout for a grid
            g = find(this.GridInfo.GridID==g);
            lt = vec2gridlayout(this,g,this.GridInfo.GridElectrode{g},varargin{:});
        end % END function gridlayout
        
        function lt = vec2gridlayout(this,g,vec,varargin)
            % VEC2GRIDLAYOUT Reshape vector into physical layout
            %
            %   LT = VEC2GRIDLAYOUT(THIS,G,VEC)
            %   Create a matrix LT where the Nth element of VEC is at the
            %   array location of channel N for grid G.
            %
            %   VEC2GRIDLAYOUT(...,'INTERP')
            %   Interpolate the values for the empty locations (default
            %   behavior will assign NaN.
            
            % check correct vector input
            assert(ismatrix(vec)&&min(size(vec))==1,'Data input must be a vector');
            if size(vec,2)~=min(size(vec)),vec=vec';end
            assert(length(vec)==this.NumChannelsPerGrid(g),'Input data has length %d, but grid %d has %d channels',length(vec),g,this.NumChannelsPerGrid(g));
            
            % allow user to provide their own ordering of the channel or
            % electrode numbers
            [varargin,FlagInterp] = util.argflag('interpolate',varargin,false);
            util.argempty(varargin);
            
            % map vector into rows x cols matrix
            idx = this.GridChannelIndex{g};
            numcol = max(this.ChannelInfo.GridColumn(idx)) - min(this.ChannelInfo.GridColumn(idx)) + 1;
            numrow = max(this.ChannelInfo.GridRow(idx)) - min(this.ChannelInfo.GridRow(idx)) + 1;
            lt = nan(numrow,numcol);
            c = this.ChannelInfo.GridColumn(this.GridChannelIndex{g});
            r = this.ChannelInfo.GridRow(this.GridChannelIndex{g});
            [x,y] = gcr2gxy(this,g,c,r);
            for el=1:length(vec)
                lt(y(el),x(el)) = vec(el);
            end
            lt = flipud(lt);
            
            % interpolate values into the empty positions
            if FlagInterp
                [nanX,nanY] = find(isnan(lt));
                for nn=1:length(nanX)
                    x=nanX(nn);
                    y=nanY(nn);
                    if x==1 && y==1
                        lt(x,y) = nanmean([lt(2,1) lt(2,2) lt(1,2)]);
                    elseif x==1 && y==10
                        lt(x,y) = nanmean([lt(9,1) lt(9,2) lt(10,2)]);
                    elseif x==10 && y==10
                        lt(x,y) = nanmean([lt(10,9) lt(9,9) lt(9,10)]);
                    elseif x==10 && y==1
                        lt(x,y) = nanmean([lt(1,9) lt(2,9) lt(2,10)]);
                    else
                        lt(x,y) = nanmean([...
                            lt(x-1,y-1) lt(x,y-1) lt(x+1,y-1) ...
                            lt(x-1,y) lt(x,y) lt(x+1,y) ...
                            lt(x-1,y+1) lt(x,y+1) lt(x+1,y+1)]);
                    end
                end
            end
        end % END function vec2gridlayout
        
        function [x,y] = gcr2gxy(this,g,c,r)
            % GCR2GXY Convert grid col/row to linear idx for layout matrix
            %
            %   [X,Y] = GCR2GXY(THIS,G,C,R)
            %   Convert grid positions in grid G, specified by columns (C)
            %   and rows (R), into array or subplot positions identified by
            %   their subscript (e.g., X/Y) values. In effect, this
            %   translates column and row indexing (which may or may not
            %   start at 1) into a 1-based vector. Note that the y-position
            %   remains vertically flipped from the MATLAB array indexing
            %   paradigm, but is correctly oriented for MATLAB subplot
            %   indexing.
            assert(ismember(g,1:this.NumGrids),'Must provide valid grid number in the range [1,%d]',this.NumGrids);
            
            % list all possible array columns and rows
            idx = this.GridChannelIndex{g};
            arrcol = min(this.ChannelInfo.GridColumn(idx)):max(this.ChannelInfo.GridColumn(idx));
            arrrow = min(this.ChannelInfo.GridRow(idx)):max(this.ChannelInfo.GridRow(idx));
            
            % validate inputs
            assert(all(ismember(c,arrcol)),'Could not find some columns in the list of array columns');
            assert(all(ismember(r,arrrow)),'Could not find some rows in the list of array rows');
            assert(length(c)==length(r),'Must provide same number of columns and rows');
            
            % convert array column and row into 1-based x/y indices
            x = nan(1,length(c));
            y = nan(1,length(c));
            for ii=1:length(c)
                x(ii) = find(arrcol==c(ii));
                y(ii) = find(arrrow==r(ii));
            end
        end % END function cr2xy
        
        function tbl = table(this,varargin)
            [varargin,chmode] = util.argkeyword({'recording','amplifier'},varargin,'amplifier');
            util.argempty(varargin);
            
            % generate grid table (replicating information in map file)
            GridID = this.GridInfo.GridID;
            Template = this.GridInfo.Template;
            Location = this.GridInfo.Location;
            Hemisphere = this.GridInfo.Hemisphere;
            Label = this.GridInfo.Label;
            switch lower(chmode)
                case 'recording'
                    Channel = this.ChannelInfo.RecordingChannel;
                case 'amplifier'
                    Channel = this.ChannelInfo.AmplifierChannel;
                otherwise
                    error('unknown channel model "%s"',chmode);
            end
            tbl = table(GridID,Template,Location,Hemisphere,Label,Channel);
        end % END function
        
        function saveas(this,mapfile,varargin)
            gmf = GridMap.File(mapfile);
            gmf.write(this,varargin{:});
        end % END function saveas
    end % END methods
end % END classdef Interface
