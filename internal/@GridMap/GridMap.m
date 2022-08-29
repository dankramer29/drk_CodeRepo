classdef GridMap < util.Structable & util.StructableHierarchy
    % GRIDMAP information about channel layout for all grids in a dataset
    
    properties
        ChannelInfo % table containing channel info
        GridInfo % table containing grid info
        NumGrids % number of grids in the dataset
        GridChannelIndex % cell array where each cell contains list of channel indices for that grid
        NumChannelsPerGrid % number of channels in each grid in the dataset
        NumChannels % total number of channels
    end % END properties
    
    properties(Access=private)
        TemplateDirectory % directory containing grid templates
        TemplateSuffix % template basename has this at the end
        TemplateExt % file extension of templates
    end % END properties(Access=private)
    
    methods
        function this = GridMap(varargin)
            
            % process user inputs/defaults
            [varargin,this.TemplateDirectory] = util.argkeyval('template_dir',varargin,fullfile(env.get('internal'),'def','grids'));
            [varargin,this.TemplateSuffix] = util.argkeyval('template_suffix',varargin,'');
            [varargin,this.TemplateExt] = util.argkeyval('template_ext',varargin,'.csv');
            [varargin,maptable,found_maptable] = util.argfn(@(x)istable(x),varargin,{});
            [varargin,mapfile,found_mapfile] = util.argfn(@(x)ischar(x)&&exist(x,'file')==2,varargin,{});
            util.argempty(varargin);
            assert(found_mapfile|found_maptable,'Could not find map info');
            
            % initialize the grid info table
            this.ChannelInfo = cell2table(cell(0,7),'VariableNames',{'Channel','Label','Bank','GridElectrode','GridRow','GridColumn','GridNumber'});
            this.GridInfo  = cell2table(cell(0,13),'VariableNames',{'GridID','Channel','GridElectrode','Label','Location','Hemisphere','Manufacturer','Model','Name','Template','Type','Subtype','Custom'});
            
            % load map file into a table
            if found_mapfile
                assert(ischar(mapfile)&&exist(mapfile,'file')==2,'Mapfile input must be char and must be the full path to an existing file');
                fid = util.openfile(mapfile,'r'); % open the file
                header = fgetl(fid); % read first line
                while ~isempty(regexpi(header,'^\s*$')) || ~isempty(regexpi(header,'^\s*%')) % keep reading until we get to content
                    header = fgetl(fid);
                end
                varNames = cellfun(@strtrim,strsplit(header,','),'UniformOutput',false);
                inputFormats = repmat({'%s'},1,length(varNames));
                fileContents = textscan(fid,strjoin(inputFormats,' '),'Delimiter',',');
                idxCommented = cellfun(@(x)~isempty(x)&&ischar(x)&&ismember('%',x),fileContents{1});
                fileContents = cellfun(@(x)x(~idxCommented),fileContents,'UniformOutput',false);
                util.closefile(fid);
                mapdata = cell2table(cat(2,fileContents{:}),'VariableNames',varNames);
                idx = strcmpi(varNames,'GridID');
                if any(idx)
                    gridIdLabel = varNames{idx};
                    mapdata.(gridIdLabel) = cellfun(@(x)str2double(x),mapdata.(gridIdLabel));
                end
                idx = strncmpi(varNames,'Channel',4);
                if any(idx)
                    channelLabel = varNames{idx};
                    mapdata.(channelLabel) = cellfun(@(x)eval(x),mapdata.(channelLabel),'UniformOutput',false);
                end
                idx = strncmpi(varNames,'GridElectrode',6);
                if any(idx)
                    gridElectrodeLabel = varNames{idx};
                    mapdata.(gridElectrodeLabel) = cellfun(@(x)eval(x),mapdata.(gridElectrodeLabel),'UniformOutput',false);
                end
            elseif found_maptable
                mapdata = maptable;
                assert(all(ismember({'GridId','Template','Location','Hemisphere','Label','Channel'},mapdata.VariableNames)),'Invalid map table');
                for kk=1:size(mapdata,1)
                    if ischar(mapdata.Channel{kk})
                        mapdata.Channel{kk} = str2double(mapdata.Channel{kk});
                    end
                end
            end
            
            % process the map file input
            ch = 0;
            for kk=1:height(mapdata)
                templateDir = fullfile(this.TemplateDirectory,mapdata.Template{kk});
                assert(exist(templateDir,'dir')==7,'Could not find template "%s"',mapdata.Template{kk});
                templateFiles = dir(fullfile(templateDir,sprintf('*%s',this.TemplateExt)));
                assert(~isempty(templateFiles),'Could not find any templates matching "%s"',mapdata.Template{kk});
                [~,idx] = sort([templateFiles.datenum],'descend');
                templateFullFile = fullfile(templateDir,templateFiles(idx(1)).name);
                
                % process the grid template file
                fid = util.openfile(templateFullFile,'r');
                try
                    
                    % run through any empty lines at the top
                    gridline = fgetl(fid);
                    while ~isempty(regexpi(gridline,'^\s*$'))
                        gridline = fgetl(fid);
                    end
                    
                    % pull out metadata in the header
                    while any(cellfun(@isempty,regexpi(gridline,{'GridElectrode','GridRow','GridColumn','Bank'})))
                        if isempty(gridline),continue;end
                        terms = strsplit(gridline,',');
                        terms(cellfun(@isempty,terms)) = [];
                        if ~isempty(terms)&&~all(cellfun(@isempty,terms))
                            gridinfo.(terms{1}) = terms{2};
                        end
                        gridline = fgetl(fid);
                    end
                    
                    % find out how many channels
                    chaninfo = cell(1024,1);
                    gg = 1;
                    while ~feof(fid)
                        chaninfo{gg} = fgetl(fid);
                        gg = gg+1;
                    end
                    chaninfo(gg:end) = [];
                    chaninfo = cellfun(@(x)strsplit(x,','),chaninfo,'UniformOutput',false);
                    chaninfo = cat(1,chaninfo{:});
                    chaninfo = cellfun(@str2double,chaninfo,'UniformOutput',false);
                    chaninfo = cell2table(chaninfo,'VariableNames',{'GridElectrode','GridRow','GridColumn','Bank'});
                catch ME
                    util.closefile(fid);
                    rethrow(ME);
                end
                util.closefile(fid);
                
                % get grid electrodes (these are the physical electrodes
                if any(strncmpi(mapdata.Properties.VariableNames,'GridElectrode',6))
                    gridelectrodes = mapdata.(gridElectrodeLabel){kk}(:);
                else
                    gridelectrodes = (1:height(chaninfo))';
                end
                
                % subselect just the requested electrodes
                idx_chan_grid = ismember(chaninfo.GridElectrode,gridelectrodes);
                chaninfo = chaninfo(idx_chan_grid,:);
                
                % get channel numbers
                if any(strncmpi(mapdata.Properties.VariableNames,'Channel',4))
                    if length(mapdata.(channelLabel){kk})==nnz(idx_chan_grid)
                        channels = ch + mapdata.(channelLabel){kk}(:);
                    else
                        assert(length(mapdata.(channelLabel){kk})==length(idx_chan_grid),'Invalid channel specification');
                        channels = ch + mapdata.(channelLabel){kk}(idx_chan_grid)';
                        if length(channels)<height(chaninfo)
                            chaninfo((length(channels)+1):end,:) = [];
                        end
                    end
                else
                    channels = ch+(1:height(chaninfo))';
                    channels = channels(idx_chan_grid);
                end
                
                % validate
                assert(length(channels)==length(gridelectrodes),'Must provide one grid electrode value per channel (found %d grid electrodes and %d channels)',length(gridelectrodes),length(channels));
                
                % clean up the data
                commonLabels = {'GridNumber','ChannelNumber','Label','Location','Hemisphere','Manufacturer','Model','Name','Template','Type','Subtype'};
                customLabels = fieldnames(gridinfo);
                customLabels(arrayfun(@(x)any(strcmpi(x,commonLabels)),customLabels)) = [];
                customValues = cellfun(@(x)gridinfo.(x),customLabels,'UniformOutput',false);
                custom = [customLabels(:)'; customValues(:)'];
                common.GridID = kk-1;
                common.Channel = {channels};
                common.GridElectrode = {gridelectrodes};
                common.Label = mapdata.Label(kk);
                common.Location = mapdata.Location(kk);
                common.Hemisphere = mapdata.Hemisphere(kk);
                common.Manufacturer = {gridinfo.Manufacturer};
                common.Model = {gridinfo.Model};
                common.Name = {gridinfo.Name};
                common.Template = mapdata.Template(kk);
                common.Type = {gridinfo.Type};
                common.Subtype = {gridinfo.Subtype};
                common.Custom = {struct(custom{:})};
                
                % read body of the grid template to get channel info
                labels = arrayfun(@(x)sprintf('%s%d',mapdata.Label{kk},chaninfo.GridElectrode(x)),(1:height(chaninfo))','UniformOutput',false);
                props = cell2table(...
                    [arrayfun(@(x)x,channels,'UniformOutput',false), labels, repmat({kk-1},height(chaninfo),1)],...
                    'VariableNames',{'Channel','Label', 'GridNumber'});
                
                this.GridInfo = [this.GridInfo; struct2table(common)];
                this.ChannelInfo = [this.ChannelInfo; [chaninfo props]];
                ch = max(channels); % height(chaninfo)
            end
            
            % add metadata properties
            this.NumGrids = height(mapdata);
            this.NumChannelsPerGrid = arrayfun(@(x)nnz(this.ChannelInfo.GridNumber==x),0:this.NumGrids-1);
            this.NumChannels = sum(this.NumChannelsPerGrid);
            this.GridChannelIndex = arrayfun(@(x)find(this.ChannelInfo.GridNumber==x),0:this.NumGrids-1,'UniformOutput',false);
        end % END function GridMap
        
        function lt = gridlayout(this,g,varargin)
            % GRIDLAYOUT Get electrode layout for a grid
            lt = vec2gridlayout(this,g,1:this.NumChannelsPerGrid(g),varargin{:});
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
            [varargin,chmode] = util.argkeyword({'contiguous','asrecorded'},varargin,'asrecorded');
            util.argempty(varargin);
            
            % generate grid table (replicating information in map file)
            GridID = this.GridInfo.GridNumber;
            Template = this.GridInfo.Template;
            Location = this.GridInfo.Location;
            Hemisphere = this.GridInfo.Hemisphere;
            Label = this.GridInfo.Label;
            Channel = this.GridInfo.Channel;
            if strcmpi(chmode,'contiguous')
                currChannel = 1;
                for kk=1:length(Channel)
                    Channel{kk} = Channel{kk} - (Channel{kk}(1)-currChannel);
                    currChannel = currChannel + length(Channel{kk});
                end
            end
            tbl = table(GridID,Template,Location,Hemisphere,Label,Channel);
        end % END function
        
        function saveas(this,mapfile,varargin)
            [varargin,overwrite] = util.argflag('overwrite',varargin,false);
            [varargin,chmode] = util.argkeyword({'contiguous','asrecorded'},varargin,'asrecorded');
            util.argempty(varargin);
            assert(overwrite||exist(mapfile,'file')~=2,'Output file already exists and overwrite is disabled');
            
            % open the file
            args = {};
            if overwrite,args={'overwrite'};end
            fid = util.openfile(mapfile,'w',args{:}); % open the file
            
            % contiguous channels if requested
            Channel = this.GridInfo.Channel;
            if strcmpi(chmode,'contiguous')
                currChannel = 1;
                for gg=1:length(Channel)
                    Channel{gg} = Channel{gg} - (Channel{gg}(1)-currChannel);
                    currChannel = currChannel + length(Channel{gg});
                end
            end
            
            % write out the grid info
            try
                fprintf(fid,'GridId,Template,Location,Hemisphere,Label,Channel,GridElectrode\n');
                for gg=1:this.NumGrids
                    fprintf(fid,'%d,%s,%s,%s,%s,%d:%d,',gg-1,...
                        this.GridInfo.Template{gg},...
                        this.GridInfo.Location{gg},...
                        this.GridInfo.Hemisphere{gg},...
                        this.GridInfo.Label{gg},...
                        Channel{gg}(1),Channel{gg}(end));
                    if all(diff(this.GridInfo.GridElectrode{gg})==1)
                        fprintf(fid,'%d:%d\n',this.GridInfo.GridElectrode{gg}(1),this.GridInfo.GridElectrode{gg}(end));
                    else
                        fprintf(fid,'%s\n',util.vec2str(this.GridInfo.GridElectrode{gg}));
                    end
                end
            catch ME
                util.errorMessage(ME);
            end
            
            % close the file
            util.closefile(fid);
        end % END function saveas
    end % END methods
end % END classdef GridMap
