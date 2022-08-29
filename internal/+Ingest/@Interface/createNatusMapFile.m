function exitCode = createNatusMapFile(this)
setUserStatus(this,'Creating map file');
exitCode = 0; % success

% load channel labels from the channel nomenclature file
channel_file = fullfile(getWorkingDirectory(this),sprintf('%s_channel.txt',this.SourceFiles.basename{this.currFileIndex}));
assert(exist(channel_file,'file')==2,'Could not find eeg channel file - make sure AutoIT script completed successfully');
chantable = readtable(channel_file,'FileType','text','ReadVariableNames',true);
channelLabelsMontage = regexprep(chantable.ChannelName,'^([^\d]*)\d*$','$1');
gridLabelsMontage = unique(channelLabelsMontage);

% create table of grids based on GUI entries
griddata = cellfun(@(x)strsplit(x,','),get(this.guiHandles.listboxGrid,'String'),'UniformOutput',false);
griddata = cat(1,griddata{:});
griddata = cellfun(@strtrim,griddata,'UniformOutput',false); % remove leading/trailing whitespace
griddata(:,1) = cellfun(@(x)str2double(x),griddata(:,1),'UniformOutput',false);
maptable = cell2table(griddata,'VariableNames',{'GridID', 'Location', 'Hemisphere', 'Template', 'Label'});

% make sure user grid labels match up to montage channel labels
gridLabelsUser = maptable.Label;
idxNoMatch = find(~ismember(gridLabelsUser,gridLabelsMontage));
for kk=1:length(idxNoMatch)
    oldGridLabel = gridLabelsUser{idxNoMatch(kk)};
    newGridLabel = '';
    while isempty(newGridLabel)
        this.hDebug.log(sprintf('Could not match grid label "%s"',oldGridLabel),'error');
        
        % describe the issue
        fprintf('\n');
        fprintf('Could not match user grid label "%s" to any channels in the montage.\n',oldGridLabel);
        fprintf('Please select a new grid label from the available channel labels:\n');
        
        % list the options
        for nn=1:length(gridLabelsMontage)
            numChannelsMontage = nnz(strcmpi(channelLabelsMontage,gridLabelsMontage{nn}));
            numChannelsUser = 0;
            if ismember(gridLabelsMontage{nn},gridLabelsUser)
                templateDir = fullfile(env.get('code'),'internal','def','grids',maptable.Template{idxNoMatch(kk)});
                templateFiles = dir(fullfile(templateDir,'*.csv'));
                [~,idx] = sort([templateFiles.datenum],'descend');
                templateFile = templateFiles(idx(1));
                template = readtable(fullfile(templateDir,templateFile.name),'ReadVariableNames',true,'HeaderLines',7);
                numChannelsUser = size(template,1);
            end
            fprintf('\t%2d. %-5s (%3d montage; %3d user)\n',nn,gridLabelsMontage{nn},numChannelsMontage,numChannelsUser);
        end
        
        % process user input
        userInput = '';
        while isempty(strtrim(userInput))
            userInput = input('Enter line number or grid label >> ','s');
        end
        if uint8(userInput(1))>=uint8('0') && uint8(userInput(1))<uint8('9') % numeric - line number
            lineNumber =  str2double(userInput);
            if lineNumber<1 || lineNumber>length(gridLabelsMontage)
                fprintf('\n');
                fprintf('The response "%d" is invalid; please try again.\n',lineNumber);
                newGridLabel = '';
            else
                newGridLabel = gridLabelsMontage{lineNumber};
                this.hDebug.log(sprintf('User selected line "%s" as the replacement grid label for "%s"',newGridLabel,oldGridLabel),'info');
            end
        else
            idxUserInputInMontage = strcmpi(userInput,gridLabelsMontage);
            if ~any(idxUserInputInMontage)
                fprintf('\n');
                fprintf('Could not find "%s" in the montage labels; please try again.\n',userInput);
                newGridLabel = '';
            else
                newGridLabel = gridLabelsMontage{idxUserInputInMontage};
                this.hDebug.log(sprintf('User selected line "%s" as the replacement grid label for "%s"',newGridLabel,oldGridLabel),'info');
            end
        end
        if isempty(newGridLabel),continue;end
        
        % confirm selection
        userInput = '';
        while isempty(userInput)
            userInput = input(sprintf('Confirm change from "%s" to "%s" (Y/n) >> ',oldGridLabel,newGridLabel),'s');
            
            % default 'y' if empty response
            if isempty(userInput)
                userInput = 'y';
            end
            
            % if no, set newGridLabel to empty so the loop
            % wraps back around; if neither 'y' or 'n' set
            % userInput to empty so the confirmation loops
            if strcmpi(userInput,'n')
                this.hDebug.log('User chose to redo the grid label selection','info');
                newGridLabel = '';
            elseif ~strcmpi(userInput,'y')
                this.hDebug.log('User confirmed the grid label selection','info');
                userInput = '';
            end
        end
    end
    
    % update the grid label in the map table
    maptable.Label{idxNoMatch(kk)} = newGridLabel;
    gridLabelsUser = maptable.Label;
end

% verify that all labels match
assert(all(ismember(gridLabelsUser,gridLabelsMontage)),'All user grid labels must coincide with a montage label');

% check whether mapfile already exists
recdir = getRecordingDirectory(this);
mapfile = fullfile(recdir,'mapfile.csv');
if exist(mapfile,'file')==2
    this.hDebug.log(sprintf('Selected mapfile "%s" already exists',mapfile),'info');
    
    % file exists: check whether it contains the same, or
    % different information than we would be writing to it
    tmptable = readtable(mapfile);
    if isequal(tmptable,maptable)
        this.hDebug.log('Existing mapfile matches current information exactly - returning without modification','info');
        return; % no need to write anything - they're the same already
    else
        
        % file exists and tables are different: query user on
        % how to proceed
        info = dir(mapfile);
        bytestr = util.bytestr(info.bytes);
        queststr = sprintf('Map file already exists (%s)! Use existing, overwrite, or cancel?',bytestr);
        response = questdlg(queststr,'Map File Exists','Existing','Overwrite','Cancel','Overwrite');
        switch lower(response)
            case 'existing'
                
                % recover: use the existing map file and move on
                this.hDebug.log('User chose to use the existing map file','info');
                return;
            case 'overwrite'
                
                % overwrite: continue executing the method
                this.hDebug.log('User chose to overwrite the existing map file','info');
                true;
                
            case 'cancel'
                
                % cancel: return
                this.hDebug.log('User chose to cancel the conversion process','info');
                exitCode = -1;
                return;
            otherwise
                error('bad code somewhere - no option for "%s"',response);
        end
    end
end

% write the map file
if exist(recdir,'dir')~=7
    [status,msg] = mkdir(recdir);
    assert(status,'Could not create directory "%s": %s',recdir,msg);
    assert(exist(recdir,'dir')==7,'Could not create directory "%s": unknown error',recdir);
    this.hDebug.log(sprintf('Created procedure directory "%s"',recdir),'info');
end
writetable(maptable,mapfile);
this.hDebug.log(sprintf('Wrote map file to "%s"',mapfile),'info');
end % END function createMapFile