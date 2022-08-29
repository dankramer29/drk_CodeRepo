classdef File < handle
    % FILE information about channel layout for all grids in a dataset
    
    properties
        mapfile
    end % END properties
    
    methods
        function this = File(mapfile)
            
            % process user inputs/defaults
            if nargin>=1
                this.mapfile = mapfile;
            end
        end % END function File
        
        function mapdata = read(this)
            
            % load map file into a table
            assert(ischar(this.mapfile)&&exist(this.mapfile,'file')==2,'Mapfile input must be char and must be the full path to an existing file');
            fid = util.openfile(this.mapfile,'r'); % open the file
            header = fgetl(fid); % read first line
            while ~isempty(regexpi(header,'^\s*$')) || ~isempty(regexpi(header,'^\s*%')) % keep reading until we get to content
                header = fgetl(fid);
            end
            
            % process file contents
            varNames = cellfun(@strtrim,strsplit(header,','),'UniformOutput',false);
            inputFormats = repmat({'%s'},1,length(varNames));
            fileContents = textscan(fid,strjoin(inputFormats,' '),'Delimiter',',');
            idxCommented = cellfun(@(x)~isempty(x)&&ischar(x)&&ismember('%',x),fileContents{1});
            fileContents = cellfun(@(x)x(~idxCommented),fileContents,'UniformOutput',false);
            util.closefile(fid);
            
            % standardize the header labels
            idx = strcmpi(varNames,'GridID');
            if any(idx)
                varNames{idx} = 'GridID';
            end
            idx = strncmpi(varNames,'Channel',4);
            if any(idx)
                varNames{idx} = 'Channel';
            end
            idx = strncmpi(varNames,'GridElectrode',6);
            if any(idx)
                varNames{idx} = 'GridElectrode';
            end
            
            % create the table
            mapdata = cell2table(cat(2,fileContents{:}),'VariableNames',varNames);
            if ismember('GridID',varNames)
                mapdata.GridID = cellfun(@(x)str2double(x),mapdata.GridID);
            end
            if ismember('Channel',varNames)
                mapdata.Channel = cellfun(@(x)eval(x),mapdata.Channel,'UniformOutput',false);
            end
            if ismember('GridElectrode',varNames)
                mapdata.GridElectrode = cellfun(@(x)eval(x),mapdata.GridElectrode,'UniformOutput',false);
            end
            if ismember('BankAlign',varNames)
                mapdata.BankAlign = cellfun(@(x)str2double(x),mapdata.BankAlign);
            end
        end % END function loadMapfile
        
        function write(this,gm,varargin)
            [varargin,overwrite] = util.argflag('overwrite',varargin,false);
            [varargin,chmode] = util.argkeyword({'recordingchannel','amplifierchannel'},varargin,'recordingchannel');
            util.argempty(varargin);
            assert(overwrite||exist(this.mapfile,'file')~=2,'Output file already exists and overwrite is disabled');
            
            % open the file
            args = {};
            if overwrite,args={'overwrite'};end
            fid = util.openfile(this.mapfile,'w',args{:}); % open the file
            
            % contiguous channels if requested
            switch lower(chmode)
                case 'recordingchannel'
                    fld = 'RecordingChannel';
                case 'amplifierchannel'
                    fld = 'AmplifierChannel';
                otherwise
                    error('Unknown channel mode "%s"',chmod);
            end
            
            % write out the grid info
            try
                fprintf(fid,'GridId,Template,Location,Hemisphere,Label,Channel,GridElectrode\n');
                for gg=1:height(gm.GridInfo)
                    ch = gm.ChannelInfo.(fld)(gm.ChannelInfo.GridID==gm.GridInfo.GridID(gg));
                    if all(diff(ch)==1)
                        chstr = sprintf('%d:%d',ch(1),ch(end));
                    else
                        chstr = util.vec2str(ch);
                    end
                    gr = gm.GridInfo.Electrode{gg};
                    if all(diff(gr)==1)
                        grstr = sprintf('%d:%d',gr(1),gr(end));
                    else
                        grstr = util.vec2str(gr);
                    end
                    fprintf(fid,'%d,%s,%s,%s,%s,%s,%s\n',...
                        gg-1,...
                        gm.GridInfo.Template{gg},...
                        gm.GridInfo.Location{gg},...
                        gm.GridInfo.Hemisphere{gg},...
                        gm.GridInfo.Label{gg},...
                        chstr,grstr);
                end
            catch ME
                util.errorMessage(ME);
            end
            
            % close the file
            util.closefile(fid);
        end % END function write
    end % END methods
end % END classdef File