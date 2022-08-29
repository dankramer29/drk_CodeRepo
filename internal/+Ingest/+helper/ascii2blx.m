function exitCode = ascii2blx(this)
exitCode = 0; % success
workdir = getWorkingDirectory(this);
asciifiles = dir(fullfile(workdir,sprintf('%s_data*.txt',this.sourceBasename)));
assert(~isempty(asciifiles),'Could not find any exported ASCII files (looked for "%s_data*.txt" in "%s"',this.SourceFiles.basename{this.currFileIndex},this.SourceFiles.directory{this.currFileIndex});
startidx = 0;
for kk=1:length(asciifiles)
    
    % get procedure directory
    setUserStatus(this,sprintf('Preparing for BLC conversion of ASCII file (%d/%d)',kk,length(asciifiles)));
    recdir = getRecordingDirectory(this);
    if exist(recdir,'dir')~=7
        [status,msg] = mkdir(recdir);
        assert(status,'Could not create directory "%s": %s',recdir,msg);
        assert(exist(recdir,'dir')==7,'Could not create directory "%s": unknown error',recdir);
    end
    this.hDebug.log(sprintf('Procedure directory is "%s"',recdir),'info');
    
    % check whether blc file(s) already exist
    blcbase = this.SourceFiles.basename{kk};
    flagFound = false;
    try
        blcfiles = dir(fullfile(recdir,sprintf('%s*.blc',blcbase)));
        idx = arrayfun(@(x)str2double(regexprep(x.name,'^.*-(\d{3})\.blc$','$1')),blcfiles);
        if any(idx>=startidx)
            this.hDebug.log(sprintf('Found existing BLC files with indices %s',util.vec2str(idx)),'info');
            flagFound = true;
        end
    catch ME
        util.errorMessage(ME);
        idx = 0:length(blcfiles)-1;
        for nn=1:length(blcfiles)
            if strcmpi(blcfiles(nn).name,sprintf('%s-%03d.blc',blcbase,idx(nn)))
                this.hDebug.log(sprintf('Found conflict with index %d: "%s"',idx(nn),blcfiles(nn).name),'info');
                flagFound = true;
                break;
            end
        end
    end
    
    flagOverwrite = false;
    if flagFound
        this.hDebug.log(sprintf('BLC files with basename "%s" already exist',blcbase),'info');
        
        % blc files with current basename exist
        queststr = sprintf('BLC files already exists (%d files)! Use existing, overwrite, or cancel?',length(blcfiles));
        response = questdlg(queststr,'BLC Files Exist','Existing','Overwrite','Cancel','Overwrite');
        switch lower(response)
            case 'existing'
                
                %skip: move on to the next step in the conversion process
                this.hDebug.log('User chose to keep the existing BLC files','info');
                return;
            case 'overwrite'
                
                % overwrite: use the existing map file and move on
                this.hDebug.log('User chose to overwrite existing BLC files','info');
                flagOverwrite = true;
            case 'cancel'
                
                % cancel: end the whole process prematurely
                this.hDebug.log('User chose to cancel BLC write operation','info');
                exitCode = -1;
                return;
            otherwise
                error('bad code somewhere - no option for "%s"',response);
        end
    end
    
    % make sure map file exists
    mapfile = fullfile(recdir,'mapfile.csv');
    if exist(mapfile,'file')~=2 % blc files with current basename exist
        this.hDebug.log(sprintf('Map file "%s" does not exist',mapfile),'info');
        queststr = 'Map file does not exist! Create map file, skip BLC conversion, or cancel altogether?';
        response = questdlg(queststr,'Map File Does Not Exist','Create','Skip','Cancel','Create');
        switch lower(response)
            case 'skip'
                
                % skip: move to the next step in the process
                this.hDebug.log('User chose to skip BLC conversion','info');
                return;
            case 'create'
                
                % create: create a new mapfile
                this.hDebug.log('User chose to create a map file','info');
                
                % create the map file
                exitCode = createMapFile(this);
                if exitCode<0,return;end
            case 'cancel'
                
                % cancel: return from this method
                this.hDebug.log('User chose to cancel BLC write operation','info');
                exitCode = -1;
                return;
            otherwise
                error('bad code somewhere - no option for "%s"',response);
        end
    end
    
    % create XLT object (preprocess ASCII file)
    try
        setUserStatus(this,sprintf('Loading ASCII file (%d/%d)',kk,length(asciifiles)));
        asciifile = fullfile(workdir,asciifiles(kk).name);
        assert(exist(asciifile,'file')==2,'Could not find the Natus export ASCII file "%s"',asciifile);
        this.hDebug.log(sprintf('Opening ASCII file "%s"',asciifile),'info');
        xlt = Natus.XLTekTxt(asciifile,this.hDebug);
        this.hDebug.log('Finished loading ASCII file','info');
    catch ME
        util.errorMessage(ME);
        fprintf('Error encountered (see output above). Please resolve, then press F5 to continue.\n');
        keyboard
    end
    
    % create blc files
    try
        setUserStatus(this,sprintf('Converting ASCII (%d/%d) to BLC format',kk,length(asciifiles)));
        blcw = BLc.Writer(xlt,'SecondsPerOutputFile',3600,'MapFile',mapfile,this.hDebug);
        this.hDebug.log(sprintf('Saving BLC file(s) with basename "%s"',blcbase),'info');
        args = {};
        if flagOverwrite,args={'overwrite'};end
        files = blcw.save('dir',recdir,'base',blcbase,'start',startidx,args{:});
        this.hDebug.log(sprintf('Finished saving %d BLC file(s)',length(files)),'info');
        startidx = startidx + length(files);
    catch ME
        util.errorMessage(ME);
        fprintf('Error encountered (see output above). Please resolve, then press F5 to continue.\n');
        keyboard
    end
    
    % cleanup the writer and xlt objects
    delete(xlt);
    delete(blcw);
    setUserStatus(this,sprintf('Successfully created %d BLC files from ASCII (%d/%d)',length(files),kk,length(asciifiles)));
end
end % END function ascii2blx