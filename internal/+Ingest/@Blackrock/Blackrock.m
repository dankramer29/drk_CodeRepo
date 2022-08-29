classdef Blackrock < handle
    properties
        hDebug % handle to Debug.Debugger object
        hGridMap % handle to grid map object
        sourceFiles % full path to existing *.nsX file to be ingested
        patientInfo % information about patient (struct with field "patientID")
        procedureInfo % information about procedure (struct with fields "date", "type")
        recordingInfo % information recording (struct with field "date")
        neuralDirectory % full path to parent directory for saving the converted file(s)
    end % END properties
    events
        updatedFileInProcess
    end % END events
    methods
        function this = Blackrock(varargin)
            
            % process inputs
            [varargin,map,~,found_map] = util.argkeyval('map',varargin,[]);
            if found_map,setMap(this,map);end
            [varargin,src,~,found_src] = util.argkeyval('src',varargin,[]);
            if found_src,addFile(this,src);end
            [varargin,this.hDebug,found_debug] = util.argisa('Debug.Debugger',varargin,[]);
            if ~found_debug,this.hDebug=Debug.Debugger('Ingest.Blackrock');end
            util.argempty(varargin);
            
            % data dir is almost always the same
            setNeuralDirectory(this,'\\STRIATUM\Data\neural');
        end % END function Blackrock
        
        function addFile(this,file,varargin)
            % ADDFILE Add a file to be converted from Blackrock to BLc
            %
            %  inputs
            %  MODE:    'framework-experiment' or 'patient-date'
            %           use framework-style filenames (i.e., don't rename)
            %           or rename to patient/date string
            [varargin,mode] = util.argkeyval('mode',varargin,'framework-experiment'); % 'framework-experiment' or 'patient-date'
            util.argempty(varargin);
            
            % validate input - full path to valid Blackrock data file
            if isa(file,'Blackrock.NSx')
                file = fullfile(file.SourceDirectory,sprintf('%s%s',file.SourceBasename,file.SourceExtension));
            end
            if ismember('*',file)
                list = dir(file);
                assert(~isempty(list),'Could not find any files matching input string "%s"',file);
                arrayfun(@(x)this.addFile(fullfile(x.folder,x.name),'mode',mode),list);
                return;
            end
            assert(ischar(file)&&exist(file,'file')==2,'Must provide full path to existing file');
            [srcdir,srcbase,srcext] = fileparts(file);
            assert(ismember(lower(srcext),{'.ns1','.ns2','.ns3','.ns4','.ns5','.ns6'}),'Must provide valid Blackrock data file (extension *.nsX, not %s)',srcext);
            
            % add to source file table
            newsrc = cell2table({srcdir,srcbase,srcext,mode,{},{}},'VariableNames',{'directory','basename','extension','mode','output_file','archive_dir'});
            if ~isempty(this.sourceFiles)
                this.sourceFiles = [this.sourceFiles; newsrc];
            else
                this.sourceFiles = newsrc;
            end
            
            % log the results
            this.hDebug.log(sprintf('Source file "%s" (%s) added',file,mode),'info');
        end % END function addFile
        
        function setMap(this,map)
            % SETMAP Set the GridMap object
            %
            %   inputs
            %   MAP:    Full path to existing map file, or table with grid
            %           map information, or GridMap object
            
            % process/validate input
            if ischar(map)&&exist(map,'file')==2
                map = GridMap(map);
            elseif istable(map)
                map = GridMap(map);
            end
            assert(isa(map,'GridMap'),'Must provide valid GridMap object, not "%s"',class(map));
            
            % set GridMap property
            this.hGridMap = map;
            
            % log the results
            this.hDebug.log(sprintf('Grid map object with %d channels across %d grids loaded',map.NumChannels,map.NumGrids),'info');
        end % END function setMap
        
        function autoIdentify(this)
            % automatically identify patient, procedure, recording info
            
            % get master list
            master = hst.getMaster;
            
            try
                % extract tokens from the source directory and basename
                sourceTokensBasenames = regexpi(this.sourceFiles.basename,'\w+','match');
                sourceTokensBasenames = unique(cat(2,sourceTokensBasenames{:}));
                sourceTokensDirectory = regexpi(this.sourceFiles.directory,'\w+','match');
                sourceTokensDirectory = unique(cat(2,sourceTokensDirectory{:}));
                sourceTokens = [sourceTokensDirectory(:); sourceTokensBasenames(:)];
                idxTooSmall = cellfun(@(x)length(x)<3,sourceTokens);
                sourceTokens(idxTooSmall) = [];
                sourceTokens = unique(sourceTokens);
                
                % try to match tokens from the path to patient first/last name
                hits = zeros(height(master),1);
                for pp=1:height(master)
                    hits(pp) = hits(pp) + ...
                        nnz(~cellfun(@isempty,regexpi(sourceTokens,master.FirstName{pp}))) + ...
                        nnz(~cellfun(@isempty,regexpi(sourceTokens,master.LastName{pp}))) + ...
                        nnz(~cellfun(@isempty,regexpi(sourceTokens,master.PatientID{pp})));
                end
                [numHits,idxMatch] = max(hits);
                assert(nnz(hits==numHits)==1,'Could not match a unique patient');
                pid = master.PatientID{idxMatch};
                
                % identify the parent directory
                hits = zeros(1,length(sourceTokensDirectory));
                for ss=1:length(sourceTokensDirectory)
                    hits(ss) = ...
                        nnz(strcmpi(sourceTokensDirectory{ss},master.FirstName{idxMatch})) + ...
                        nnz(strcmpi(sourceTokensDirectory{ss},master.LastName{idxMatch})) + ...
                        nnz(strcmpi(sourceTokensDirectory{ss},master.PatientID{idxMatch}));
                end
                numHits = max(hits);
                tokenMatches = sourceTokensDirectory(hits==numHits);
                tokenIdx = cellfun(@(x)regexpi(x,tokenMatches),this.sourceFiles.directory,'UniformOutput',false);
                [~,tokenIdx] = min(cell2mat(cat(1,tokenIdx{:})),[],2);
                tokenMatches = arrayfun(@(x)tokenMatches{x},tokenIdx,'UniformOutput',false);
                folderNames = cellfun(@(x)strsplit(x,filesep),this.sourceFiles.directory,'UniformOutput',false);
                folderMatches = cellfun(@(x,y)x{~cellfun(@isempty,regexpi(x,y))},folderNames,tokenMatches,'UniformOutput',false);
                this.sourceFiles.archive_dir = cellfun(@(x,y)regexprep(x,sprintf('^.*(%s.*)$',y),'$1'),this.sourceFiles.directory,folderMatches,'UniformOutput',false);
                
                %token = sourceTokensDirectory{idxMatch};
                %this.sourceFiles.archive_dir = regexprep(this.sourceFiles.directory,sprintf('^.*(%s.*)$',token),'$1');
            catch ME
                rethrow(ME);
            end
            assert(hst.isValidPatient(pid),'Could not identify patient');
            patient = hst.getPatients(pid);
            assert(~isempty(patient)&&istable(patient)&&size(patient,1)==1,'Could not identify a unique patient for "%s"',pid);
            patientID = patient.PatientID{1};
            patientHospital = patient.Hospital{1};
            this.hDebug.log(sprintf('Auto-detect inferred patient ID "%s"',pid),'info');
            
            % get recording date, phase type, day value from file name
            idx = ~cellfun(@isempty,regexpi(sourceTokens,'^\d{8}$'));
            assert(nnz(idx)==1,'Could not identify a token with YYYYMMDD format');
            tokens = regexpi(sourceTokens{idx},'^(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})','names');
            recordingDate = datetime(str2double(tokens.year),str2double(tokens.month),str2double(tokens.day));
            assert(isa(recordingDate,'datetime'),'Could not identify valid recording date');
            this.hDebug.log(sprintf('Auto-detect inferred recording date %s',datestr(recordingDate)),'info');
            
            % look for existing procedures for the selected patient
            patientProcedures = hst.getProcedures(pid);
            assert(~isempty(patientProcedures),'Could not identify any procedures for patient %s',pid);
            [val,idx] = min(days(recordingDate - patientProcedures.ProcedureDate));
            assert(val<=21,'Could not find a procedure date within 3 weeks of the recording date %s',datestr(recordingDate));
            assert(patientProcedures.RecordingStartDate(idx)<=recordingDate && patientProcedures.RecordingEndDate(idx)>=recordingDate,'Current recording date %s is not in the recording start/end dates of the matched procedure (%s - %s)',datestr(recordingDate),datestr(patientProcedures.RecordingStartDate(idx)),datestr(patientProcedures.RecordingEndDate(idx)));
            procedureDate = patientProcedures.ProcedureDate(idx);
            procedureType = patientProcedures.ProcedureType{idx};
            this.hDebug.log(sprintf('Auto-detect inferred procedure date %s (type %s)',datestr(procedureDate),procedureType),'info');
            
            % save the results
            setPatient(this,patientID,patientHospital);
            setRecording(this,recordingDate);
            setProcedure(this,procedureDate,procedureType);
        end % END autoIdentify
        
        function setPatient(this,pid,hosp)
            assert(hst.isValidPatient(pid),'Must provide valid patient ID, not "%s"',pid);
            this.patientInfo.patientID = pid;
            this.patientInfo.hospital = hosp;
        end % END function setPatient
        
        function setProcedure(this,date,type)
            assert(isa(date,'datetime'),'Must provide valid datetime object for procedure date');
            assert(ismember(upper(type),{'PH1','PH2'}),'Must provide either PH1 or PH2 as procedure type');
            this.procedureInfo.date = date;
            this.procedureInfo.type = type;
        end % END function setProcedure
        
        function setRecording(this,date)
            assert(isa(date,'datetime'),'Must provide valid datetime object for procedure date');
            this.recordingInfo.date = date;
        end % END function setRecording
        
        function setNeuralDirectory(this,ndir)
            % setNeuralDirectory Set the parent folder for output data files
            %
            %   inputs
            %   DTDIR:  Full path to parent folder for output data files;
            %           this should be the main folder for all output
            %           neural data files, and subfolders for patient,
            %           procedure, recording date, etc. will be appended
            %           automatically.
            
            % process inputs
            assert(ischar(ndir),'Must provide char input, not "%s"',class(ndir));
            
            % create directory if needed
            util.mkdir(ndir);
            
            % assign property
            this.neuralDirectory = ndir;
            
            % log the results
            this.hDebug.log(sprintf('Neural directory set to "%s"',ndir),'info');
        end % END function setOutputDirectory
        
        function exitCode = convertToBLc(this)
            % CONVERTTOBLC Convert source files from Blackrock to BLc
            exitCode = 0; % success
            
            % loop over source files
            flagGlobalOverwrite = nan;
            numPrompts = 0;
            numResponses = 0;
            for kk=1:size(this.sourceFiles,1)
                evtdata = util.EventDataWrapper('sourceFileIndex',kk,...
                    'sourceDirectory',this.sourceFiles.directory{kk},...
                    'sourceBasename',this.sourceFiles.basename{kk},...
                    'sourceExtension',this.sourceFiles.extension{kk},...
                    'sourceFormat','Blackrock',...
                    'filenameMode',this.sourceFiles.mode{kk});
                notify(this,'updatedFileInProcess',evtdata);
                
                % get basename
                blcbase = getOutputBasename(this,'source_index',kk,'mode',this.sourceFiles.mode{kk});
                blcdir = getOutputDirectory(this);
                srcdir = this.sourceFiles.directory{kk};
                srcfile = sprintf('%s%s',this.sourceFiles.basename{kk},this.sourceFiles.extension{kk});
                
                % create directory if it doesn't exist already
                if exist(blcdir,'dir')~=7
                    util.mkdir(blcdir);
                end
                
                % make sure map file exists
                mapfile = fullfile(blcdir,sprintf('%s.map',blcbase));
                if exist(mapfile,'file')~=2
                    tbl = this.hGridMap.table('channel_numbers','contiguous');
                    Ingest.helper.createMapFile('MapTable',tbl,'OutDir',blcdir,'MapFile',blcbase);
                end
                assert(exist(mapfile,'file')==2,'Could not save source map as new map file');
                
                % get output filenames
                [~,outputFiles] = BLc.convert.nsx2blc('srcfile',fullfile(srcdir,srcfile),...
                    'outdir',blcdir,'outbase',blcbase,this.hGridMap,this.hDebug,'overwrite','filenames');
                idx_conflict = cellfun(@(x)exist(x,'file')==2,outputFiles);
                this.sourceFiles.output_file{kk} = outputFiles;
                flagOverwrite = false;
                if any(idx_conflict)
                    if ~isnan(flagGlobalOverwrite)
                        if flagGlobalOverwrite
                            flagOverwrite = true;
                        else
                            continue;
                        end
                    else
                        this.hDebug.log(sprintf('Output files already exist for "%s"',srcfile),'info');
                        
                        % blc files with current basename exist
                        queststr = sprintf('Output already exists for %s.\n\nUse existing, overwrite, or cancel?',sprintf('%s%s',this.sourceFiles.basename{kk},this.sourceFiles.extension{kk}));
                        response = questdlg(queststr,'BLC Files Exist','Existing','Overwrite','Cancel','Overwrite');
                        switch lower(response)
                            case 'existing'
                                
                                % skip: move on to the next step in the conversion process
                                this.hDebug.log('User chose to keep the existing files','info');
                                if numResponses==0 || numResponses>=100
                                    numResponses = 1;
                                elseif numResponses>0 && numResponses<100
                                    numResponses = numResponses + 1;
                                end
                                if numResponses<100 && numResponses>=2 && ismember(numPrompts,0:2)
                                    numPrompts = numPrompts + 1;
                                    response = questdlg('Do you want to use existing for all following conflicts?','Apply to all following conflicts','Yes','No','Yes');
                                    if strcmpi(response,'yes')
                                        flagGlobalOverwrite = false;
                                    end
                                end
                                continue;
                            case 'overwrite'
                                
                                % overwrite: use the existing map file and move on
                                this.hDebug.log('User chose to overwrite existing files','info');
                                flagOverwrite = true;
                                if numResponses<100
                                    numResponses = 101;
                                elseif numResponses>=100 && numResponses<200
                                    numResponses = numResponses + 1;
                                end
                                if numResponses>=102 && ismember(numPrompts,0:2)
                                    numPrompts = numPrompts + 1;
                                    response = questdlg('Do you want to overwrite all following conflicts?','Apply to all following conflicts','Yes','No','Yes');
                                    if strcmpi(response,'yes')
                                        flagGlobalOverwrite = true;
                                    end
                                end
                            case 'cancel'
                                
                                % cancel: end the whole process prematurely
                                this.hDebug.log('User chose to cancel BLC write operation','info');
                                exitCode = -1;
                                return;
                            otherwise
                                error('bad code somewhere - no option for "%s"',response);
                        end
                    end
                end
                
                % call the conversion function
                args = {};
                if flagOverwrite,args={'overwrite'};end
                BLc.convert.nsx2blc(...
                    'srcfile',fullfile(this.sourceFiles.directory{kk},sprintf('%s%s',this.sourceFiles.basename{kk},this.sourceFiles.extension{kk})),...
                    'outdir',blcdir,'outbase',blcbase,this.hGridMap,this.hDebug,args{:});
            end
        end % END function convertToBLc
        
        function exitCode = sanityAnalysis(this)
            
            % loop over BLC files and run basic analyses
            for ss=1:size(this.sourceFiles,1)
                for kk=1:length(this.sourceFiles.output_file{ss})
                    [outdir,outbase] = fileparts(this.sourceFiles.output_file{ss}{kk});
                    this.hDebug.log(sprintf('Running sanity analysis for "%s" in directory "%s"',outbase,outdir),'info');
                    assert(exist(this.sourceFiles.output_file{ss}{kk},'file')==2,'Could not find BLc file "%s"',this.sourceFiles.output_file{ss}{kk});
                    try
                        blc = BLc.Reader(this.sourceFiles.output_file{ss}{kk});
                        a = BLc.Analyze(blc,this.hGridMap,this.hDebug,'numSeconds',60);
                        a.run('outdir',fullfile(outdir,'sanity'),'basename',blc.SourceBasename,'formats',{'fig','png'});
                    catch ME
                        util.errorMessage(ME);
                        exitCode = -1;
                    end
                end
            end
        end % END function sanityAnalysis
        
        function exitCode = copyFiles(this)
            exitCode = 0; % success
            
            % copy debugger log file to source directory
            matlab_old = this.hDebug.getLogfile;
            matlab_base = this.sourceFiles.basename{1};
            for kk=2:size(this.sourceFiles,1)
                len = min(length(matlab_base),length(this.sourceFiles.basename{kk}));
                if strcmpi(matlab_base(1:len),this.sourceFiles.basename{kk}(1:len))
                    continue;
                else
                    idx_first_discrepancy = find(matlab_base(1:len)~=this.sourceFiles.basename{kk}(1:len),1,'first');
                    if isempty(idx_first_discrepancy)
                        matlab_base = '';
                        break;
                    else
                        matlab_base = matlab_base(1:idx_first_discrepancy-1);
                    end
                end
            end
            if matlab_base(end)=='-',matlab_base=matlab_base(1:end-1);end
            matlab_base = sprintf('%s_matlab.txt',matlab_base);
            outdir = getOutputDirectory(this);
            matlab_new = fullfile(outdir,'ingest',matlab_base);
            try
                this.hDebug.log(sprintf('Copying Debug log file from %s to %s',matlab_old,matlab_new),'info');
                Ingest.helper.moveFile(matlab_old,matlab_new,'MATLAB log',@copyfile,this.hDebug);
                this.hDebug.log(sprintf('Copied "%s" to "%s"',matlab_old,matlab_new),'info');
            catch ME
                util.errorMessage(ME);
                fprintf('\n\n');
                fprintf('-----\n');
                fprintf('Could not move debug log file from "%s" to "%s".\n',matlab_old,matlab_new);
                fprintf('Move the file manually and press F5 to continue.\n');
                fprintf('-----\n');
                fprintf('\n\n');
                keyboard;
            end
            
            % copy Task folder
            for kk=1:size(this.sourceFiles,1)
                srcdir_tokens = strsplit(this.sourceFiles.directory{kk},filesep);
                srcdir_tokens(cellfun(@isempty,srcdir_tokens)) = [];
                taskdir_old = '';
                flag_found = false;
                for mm=1:length(srcdir_tokens)
                    taskdir_old = fullfile(this.sourceFiles.directory{kk}(1:regexpi(this.sourceFiles.directory{kk},srcdir_tokens{end-mm+1})-2),'Task');
                    if exist(taskdir_old,'dir')==7
                        flag_found = true;
                        break;
                    end
                end
                if flag_found
                    outdir = getOutputDirectory(this);
                    taskdir_new = fullfile(regexprep(outdir,'^(.*).data.*$','$1'),'task');
                    try
                        this.hDebug.log(sprintf('Copying task folder from %s to %s',taskdir_old,taskdir_new),'info');
                        Ingest.helper.moveDirectory(taskdir_old,taskdir_new,'Task',@copyfile,this.hDebug);
                        this.hDebug.log(sprintf('Moved "%s" to "%s"',taskdir_old,taskdir_new),'info');
                    catch ME
                        util.errorMessage(ME);
                        fprintf('\n\n');
                        fprintf('-----\n');
                        fprintf('Could not move Task directory from "%s" to "%s".\n',taskdir_old,taskdir_new);
                        fprintf('Move the directory manually and press F5 to continue.\n');
                        fprintf('-----\n');
                        fprintf('\n\n');
                        keyboard;
                    end
                    break;
                end
            end
            
            % create a text file to indicate new anonymized basename
            for kk=1:size(this.sourceFiles,1)
                srcdir = fullfile(this.sourceFiles.directory{kk},'ingest');
                if exist(srcdir,'dir')~=7,util.mkdir(srcdir);end
                outdir = getOutputDirectory(this);
                new_basename = getOutputBasename(this,'source_index',kk,'mode',this.sourceFiles.mode{kk});
                touched_file = fullfile(srcdir,sprintf('%s.txt',new_basename));
                this.hDebug.log(sprintf('Writing text file to document new source info: %s',touched_file),'info');
                fid = util.openfile(touched_file,'wt','overwrite');
                fprintf(fid,'Anonymized basename: "%s"\n',new_basename);
                fprintf(fid,'Procedure directory: "%s"\n',outdir);
                util.closefile(fid);
            end
        end % END function copyFiles
        
        function archiveSourceData(this,varargin)
            [varargin,flag_misc] = util.argkeyword({'sourceonly','sourceplus'},varargin,'sourceplus');
            util.argempty(varargin);
            
            % move the source files specifically processed
            for ss=1:size(this.sourceFiles,1)
                for kk=1:length(this.sourceFiles.output_file{ss})
                    archive_tokens = strsplit(this.sourceFiles.archive_dir{ss},filesep);
                    source_file = sprintf('%s%s',this.sourceFiles.basename{ss},this.sourceFiles.extension{ss});
                    datafile_original = fullfile(this.sourceFiles.directory{ss},source_file);
                    if exist(datafile_original,'file')~=2
                        this.hDebug.log(sprintf('Could not find source file "%s"',datafile_original),'warn');
                        continue;
                    end
                    archive_dir = fullfile(this.neuralDirectory,'archive',this.patientInfo.hospital,archive_tokens{:});
                    datafile_archive = fullfile(archive_dir,source_file);
                    this.hDebug.log(sprintf('Moving %s from %s to %s',source_file,this.sourceFiles.directory{ss},archive_dir),'info');
                    Ingest.helper.moveFile(datafile_original,datafile_archive,sprintf('Source %d/%d',ss,size(this.sourceFiles,1)),@movefile,this.hDebug);
                    
                    % if not processing misc files, move on
                    if ~flag_misc,continue;end
                    
                    % process anything matching basename of source file
                    source_match = sprintf('%s.*',this.sourceFiles.basename{ss});
                    list = dir(fullfile(this.sourceFiles.directory{ss},source_match));
                    for nn=1:length(list)
                        misc_original = fullfile(this.sourceFiles.directory{ss},list(nn).name);
                        if exist(misc_original,'file')~=2,continue;end
                        misc_archive = fullfile(archive_dir,list(nn).name);
                        this.hDebug.log(sprintf('Moving %s from %s to %s',list(nn).name,this.sourceFiles.directory{ss},archive_dir),'info');
                        Ingest.helper.moveFile(misc_original,misc_archive,sprintf('Misc %d/%d (Source %d/%d)',nn,length(list),ss,size(this.sourceFiles,1)),@movefile,this.hDebug);
                    end
                    
                    %  process ingest directory
                    ingest_original = fullfile(this.sourceFiles.directory{ss},'ingest');
                    ingest_archive = fullfile(archive_dir,'ingest');
                    this.hDebug.log(sprintf('Moving ingest folder from %s to %s',this.sourceFiles.directory{ss},archive_dir),'info');
                    Ingest.helper.moveDirectory(ingest_original,ingest_archive,'ingest',@movefile,this.hDebug);
                    
                    % process the task directory
                    source_tokens = strsplit(this.sourceFiles.directory{ss},filesep);
                    flag_found = false;
                    for nn=length(source_tokens):-1:1
                        task_original = fullfile(regexprep(this.sourceFiles.directory{ss},sprintf('^(.*%s).*$',source_tokens{nn}),'$1'),'Task');
                        if exist(task_original,'dir')==7
                            flag_found = true;
                            break;
                        end
                    end
                    if ~flag_found,continue;end
                    task_archive_tokens = archive_tokens(1:end-1);
                    task_archive_dir = fullfile(this.neuralDirectory,'archive',this.patientInfo.hospital,task_archive_tokens{:});
                    task_archive = fullfile(task_archive_dir,'task');
                    this.hDebug.log(sprintf('Moving task folder from %s to %s',this.sourceFiles.directory{ss},archive_dir),'info');
                    Ingest.helper.moveDirectory(task_original,task_archive,'task',@movefile,this.hDebug);
                end
            end
        end % END function archiveSourceData
        
        function archdir = getArchiveDirectory(this,varargin)
            archdir = fullfile(this.neuralDirectory,'archive');
        end % END function getArchiveDirectory
        
        function outdir = getOutputDirectory(this,varargin)
            patient = this.patientInfo.patientID;
            procedure = sprintf('%s-%s',datestr(this.procedureInfo.date,'yyyymmdd'),this.procedureInfo.type);
            recording = datestr(this.recordingInfo.date,'yyyymmdd');
            outdir = fullfile(this.neuralDirectory,'source',patient,procedure,recording,'data');
        end % END function getOutputDirectory
        
        function outbase = getOutputBasename(this,varargin)
            [varargin,idx] = util.argkeyval('source_index',varargin,nan);
            [varargin,mode] = util.argkeyval('mode',varargin,'patient-date'); % 'patient-date' or 'experiment'
            util.argempty(varargin);
            switch lower(mode)
                case 'patient-date'
                    patient = this.patientInfo.patientID;
                    procedureDate = datestr(this.procedureInfo.date,'yyyymmdd');
                    procedureType = this.procedureInfo.type;
                    recordingDate = datestr(this.recordingInfo.date,'yyyymmdd');
                    outbase = sprintf('%s-%s-%s-%s',patient,procedureDate,procedureType,recordingDate);
                case 'framework-experiment'
                    assert(isnumeric(idx)&&idx>0&&idx<=size(this.sourceFiles,1),'Invalid source index');
                    outbase = this.sourceFiles.basename{idx};
                otherwise
                    error('Unrecognized basename mode "%s"',mode);
            end
        end % END function getOutputBasename
    end % END methods
end % END classdef Blackrock