classdef Interface < handle
    % Interface
    
    properties
    end % END properties
    
    properties(SetAccess=private,GetAccess=public)
        hDebug % handle to Debug object (mainly for log messages)
        hTimer
        
        ParticipantList % table with list of all participants
        ProcedureTypes % table with list of all procedure types
        ProcedureList % table with list of all procedures
        HospitalList % table with list of all hospitals
        GridLocations % cell array of grid locations
        GridTemplates % cell array of grid templates
        
        hGridMap % grid map object
        SourceFiles % table containing information about the source files
        OutputInfo % struct with information about the output
        ParticipantInfo
        ProcedureInfo
        RecordingInfo
        
        sessionTimestamp % timestamp indicating when this session began
        FlagOutputInfoSet = false
        FlagParticipantInfoSet = false
        FlagProcedureInfoSet = false
        FlagRecordingInfoSet = false
        FlagGridMapSet = false
    end % END properties(SetAccess=private,GetAccess=public)
    
    properties(Access=private)
        currFileIndex = 0;
    end % END properties(Access=private)
    
    events
        FileProcessingEvent
        StatusMessageEvent
        CleaningFileEvent
    end % END events
    
    methods
        function this = Interface(varargin)
            % INTERFACE Constructor for Ingest.Interface class
            %
            %   INTERFACE
            %   Create an Ingest.Interface object, creating a new
            %   Debug.Debugger object internally.
            %
            %   INTERFACE(DBG)
            %   Provide an existing Debug.Debugger object instead of
            %   creating a new one internally.
            [varargin,this.hDebug,found] = util.argisa('Debug.Debugger',varargin,[]);
            if ~found,this.hDebug=Debug.Debugger('Interface');end
            util.argempty(varargin);
            
            % set the timestamp
            this.sessionTimestamp = now;
            
            % load grid variables
            sbfcn__loadGridVariables;
            this.hDebug.log(sprintf('Loaded %d grid templates',height(this.GridTemplates)),'info');
            this.hDebug.log(sprintf('Loaded %d grid locations',length(this.GridLocations)),'info');
            
            % load participants
            sbfcn__loadParticipantList;
            this.hDebug.log(sprintf('Loaded %d anonymized participants',height(this.ParticipantList)),'info');
            
            % load procedure types
            sbfcn__loadProcedureTypes;
            this.hDebug.log(sprintf('Loaded %d procedure types',height(this.ProcedureTypes)),'info');
            
            % load procedures
            sbfcn__loadProcedureList;
            this.hDebug.log(sprintf('Loaded %d procedures',height(this.ProcedureList)),'info');
            
            % load hospitals
            sbfcn__loadHospitalList;
            this.hDebug.log(sprintf('Loaded %d hospitals',height(this.HospitalList)),'info');
            
            % update log
            this.hDebug.log(sprintf('Interface session timestamp: %s',datestr(this.sessionTimestamp)),'info');
            
            function sbfcn__loadGridVariables
                
                % identify the grid template directory
                loc = fullfile(env.get('code'),'internal','def','grids');
                
                % load grid templates
                templateNames = dir(loc);
                templateNames( ~cellfun(@isempty,regexpi({templateNames.name},'^\.+$')) ) = [];
                templateNames = {templateNames.name};
                templateLatestVersion = cell(1,length(templateNames));
                for kk=1:length(templateNames)
                    fn = dir(fullfile(loc,templateNames{kk},'*.csv'));
                    [~,idx] = sort([fn.datenum],'descend');
                    templateLatestVersion{kk} = fn(idx(1)).name;
                end
                this.GridTemplates = cell2table([templateNames(:) templateLatestVersion(:)],...
                    'VariableNames',{'TemplateName','TemplateVersion'});
                
                % identify the grid location file
                GridLocationsFile = fullfile(env.get('code'),'internal','def','GridLocations.csv');
                
                % load grid locations
                t = readtable(GridLocationsFile);
                this.GridLocations = t.LocationID;
            end % END function sbfcn__loadGridVariables
            
            function sbfcn__loadParticipantList
                
                % identify the participant file
                datadirs = util.ascell(env.get('data'));
                flag_found = false;
                for kk=1:length(datadirs)
                    participant_file = fullfile(datadirs{kk},'participants.csv');
                    if exist(participant_file,'file')==2
                        flag_found = true;
                        break;
                    end
                end
                assert(flag_found,'Could not find participants file');
                
                % load the participant list
                this.ParticipantList = readtable(participant_file,'Delimiter',',','ReadVariableNames',true);
            end % END function sbfcn__loadParticipantList
            
            function sbfcn__loadProcedureTypes
                
                % identify the procedure type file
                codedir = env.get('code');
                type_file = fullfile(codedir,'internal','def','ProcedureTypes.csv');
                
                % load the procedure information
                this.ProcedureTypes = readtable(type_file,'Delimiter',',','ReadVariableNames',true);
            end % END function sbfcn__loadProcedureTypes
            
            function sbfcn__loadProcedureList
                
                % identify the procedure file
                datadirs = util.ascell(env.get('data'));
                flag_found = false;
                for kk=1:length(datadirs)
                    procedure_file = fullfile(datadirs{kk},'procedures.csv');
                    if exist(procedure_file,'file')==2
                        flag_found = true;
                        break;
                    end
                end
                assert(flag_found,'Could not find procedures file');
                
                % load the procedure information
                this.ProcedureList = readtable(procedure_file,'Delimiter',',','ReadVariableNames',true);
            end % END function sbfcn__loadProcedureList
            
            function sbfcn__loadHospitalList
                
                % identify the hospitals file
                datadirs = util.ascell(env.get('data'));
                flag_found = false;
                for kk=1:length(datadirs)
                    hospitals_file = fullfile(datadirs{kk},'hospitals.csv');
                    if exist(hospitals_file,'file')==2
                        flag_found = true;
                        break;
                    end
                end
                assert(flag_found,'Could not find procedures file');
                
                % load the procedure information
                this.HospitalList = readtable(hospitals_file,'Delimiter',',','ReadVariableNames',true);
            end % END function sbfcn__loadHospitalList
        end % END function Interface
        
        function addSourceFile(this,varargin)
            [varargin,basename] = util.argkeyval('basename',varargin,nan);
            [varargin,extension] = util.argkeyval('extension',varargin,nan);
            [varargin,directory] = util.argkeyval('directory',varargin,nan);
            [varargin,filepath,~,found_file] = util.argkeyval('file',varargin,nan);
            util.argempty(varargin);
            
            if found_file
                [directory,basename,extension] = fileparts(filepath);
            end
            
            switch lower(extension)
                case '.eeg'
                    this.hDebug.log(sprintf('Found Nicolet file "%s"',filepath),'debug');
                    mode = 'Nicolet';
                case '.e'
                    this.hDebug.log(sprintf('Found Natus file "%s"',filepath),'debug');
                    mode = 'Natus';
                case {'.ns1','.ns2','.ns3','.ns4','.ns5','.ns6','.nev'}
                    this.hDebug.log(sprintf('Found Blackrock file "%s"',filepath),'debug');
                    mode = 'Blackrock';
                otherwise
                    this.hDebug.log(sprintf('Ignoring non-data file "%s"',filepath),'debug');
                    return;
            end
            
            % update the source files property
            if isempty(this.SourceFiles)
                this.SourceFiles = cell2table({directory,basename,extension,mode},'VariableNames',{'directory','basename','extension','mode'});
            else
                this.SourceFiles = sortrows([this.SourceFiles; cell2table({directory,basename,extension,mode},'VariableNames',{'directory','basename','extension','mode'})],'basename');
            end
        end % END function addSourceFile
        
        function removeSourceFile(this,varargin)
            [varargin,src_base,~,found_base] = util.argkeyval('basename',varargin,nan);
            [varargin,src_ext,~,found_ext] = util.argkeyval('extension',varargin,nan);
            [varargin,src_dir,~,found_dir] = util.argkeyval('directory',varargin,nan);
            [varargin,src_file,~,found_file] = util.argkeyval('file',varargin,nan);
            util.argempty(varargin);
            
            % split full file into parts
            if found_file
                [src_dir,src_base,src_ext] = fileparts(src_file);
                found_base = true;
                found_ext = true;
                found_dir = true;
            end
            
            % identify files to remove
            idx_select = true(size(this.SourceFiles,1),1);
            if found_base
                idx_select = idx_select & strcmpi(this.SourceFiles.basename,src_base);
            end
            if found_ext
                idx_select = idx_select & strcmpi(this.SourceFiles.extension,src_ext);
            end
            if found_dir
                idx_select = idx_select & strcmpi(this.SourceFiles.directory,src_dir);
            end
            
            % return if nothing to do, otherwise remove selected files
            if ~any(idx_select),return;end
            this.SourceFiles(idx_select,:) = [];
        end % END function removeSourceFile
        
        function addSourceFilesFromDirectory(this,srcdir)
            info = dir(srcdir);
            info(arrayfun(@(x)~isempty(regexpi(x.name,'^\.+$')),info)) = [];
            
            % loop over directory entries and process subdirs and files
            for ii=1:length(info)
                if info(ii).isdir
                    addSourceFilesFromDirectory(this,fullfile(srcdir,info(ii).name));
                else
                    [~,base,ext] = fileparts(info(ii).name);
                    addSourceFile(this,'directory',srcdir,'basename',base,'extension',ext);
                end
            end
        end % END function addSourceFilesFromDirectory
        
        function [flagOverwrite,flagExisting,flagCancel] = validateOutputFiles(this,outfiles)
            % VALIDATEOUTPUTFILES Make sure planned output files are valid
            % 
            %   VALIDATEOUTPUTFILES({OUTFILE1,OUTFILE2,...})
            %   Provide a cell array of output files (full paths) to be
            %   checked as a group, e.g. if splitting one source into
            %   multiple output files. Single entry okay (but still as
            %   cell).
            
            % default - don't overwrite, and don't cancel
            flagOverwrite = false;
            flagExisting = false;
            flagCancel = false;
            
            % check for existing files (conflicts)
            idx_conflict = cellfun(@(x)exist(x,'file')==2,outfiles);
            if any(idx_conflict)
                
                % get the common substring representing base filename
                % method: get the basename of each file, and starting from
                % the length of the shortest basename, check whether that
                % string is common to all basenames. If not, subtract one
                % from length and repeat.
                % idea here is that there are going to be some source files
                % that represent 24-hour recordings, which we then split up
                % into indexed output files, i.e., SRC-001, SRC-002, etc.,
                % and we want to extract just SRC.
                [~,outbase] = cellfun(@(x)fileparts(x),outfiles,'UniformOutput',false);
                len = min(cellfun(@length,outbase));
                while len>0
                    outbase = cellfun(@(x)x(1:len),outbase,'UniformOutput',false);
                    if numel(unique(outbase))==1
                        outbase = outbase{1}(1:len);
                        break;
                    end
                    len = len - 1;
                end
                this.hDebug.log(sprintf('Output files already exist for "%s"',outbase),'info');
                
                % blc files with current basename exist
                questitle = 'BLC Files Exist';
                queststr = sprintf('Output already exists for %s.\n\nUse existing, overwrite, or cancel?',outbase);
                response = questdlg(queststr,questitle,'Existing','Overwrite','Cancel','Overwrite');
                switch lower(response)
                    case 'existing'
                        this.hDebug.log('User chose to keep the existing files','info');
                        flagOverwrite = false;
                        flagExisting = true;
                        flagCancel = false;
                    case 'overwrite'
                        this.hDebug.log('User chose to overwrite existing files','info');
                        flagOverwrite = true;
                        flagExisting = false;
                        flagCancel = false;
                    case 'cancel'
                        this.hDebug.log('User chose to cancel BLC write operation','info');
                        flagOverwrite = false;
                        flagExisting = false;
                        flagCancel = true;
                    otherwise
                        error('bad code somewhere - no option for "%s"',response);
                end
            end
        end % END function validateOutputFiles
        
        function setGridMap(this,gm)
            % SETGRIDMAP Set value of the hGridMap property to a valid
            % GridMap.Interface object
            if nargin<2
                this.hGridMap = [];
                this.FlagGridMapSet = false;
                return;
            end
            
            % validate input
            assert(isa(gm,'GridMap.Interface'),'Must provide GridMap.Interface object, not "%s"',class(gm));
            
            % set properties
            this.hGridMap = gm;
            this.FlagGridMapSet = true;
        end % END function setGridMap
        
        function setParticipantInfo(this,pinfo)
            % SETPARTICIPANTINFO Set the value of ParticipantInfo property
            %
            %   SETPARTICIPANTINFO(THIS,PINFO)
            %   Provide a struct containing participant info. The struct 
            %   must have fields "Participant" containing the participant
            %   ID and "Hospital" containing the hospital.
            if nargin<2
                this.ParticipantInfo = [];
                this.FlagParticipantInfoSet = false;
                return;
            end
            
            % validate input
            if istable(pinfo),pinfo=table2struct(pinfo);end
            assert(isstruct(pinfo),'Must provide struct, not "%s"',class(pinfo));
            assert(isfield(pinfo,'ParticipantID'),'Must include "ParticipantID" field');
            assert(isfield(pinfo,'HospitalID'),'Must include "HospitalID" field');
            
            % set the participant info
            this.ParticipantInfo = pinfo;
            this.FlagParticipantInfoSet = true;
        end % END function setParticipantInfo
        
        function setProcedureInfo(this,pinfo)
            % SETPROCEDUREINFO Set the value of the ProcedureInfo property
            %
            %   SETPROCEDUREINFO(THIS,PINFO)
            %   Provide a struct containing procedure info. Require "Date"
            %   and "Type" fields. Date field should be datenum. Type field
            %   should be char.
            if nargin<2
                this.ProcedureInfo = [];
                this.FlagProcedureInfoSet = false;
                return;
            end
            
            % validate input
            assert(isstruct(pinfo),'Must provide struct, not "%s"',class(pinfo));
            
            % set procedure info
            this.ProcedureInfo = pinfo;
            this.FlagProcedureInfoSet = true;
        end % END function setProcedureInfo
        
        function setRecordingInfo(this,rinfo)
            % SETRECORDINGINFO Set value of the RecordingInfo property
            %
            %   SETRECORDINGINFO(THIS,RINFO)
            %   Provide a struct containing recording info. Require "Date"
            %   field as datenum.
            if nargin<2
                this.RecordingInfo = [];
                this.FlagRecordingInfoSet = false;
                return;
            end
            
            % validate input
            assert(isstruct(rinfo),'Must provide struct, not "%s"',class(rinfo));
            
            % set recording info
            this.RecordingInfo = rinfo;
            this.FlagRecordingInfoSet = true;
        end % END function setRecordingInfo
        
        function setOutputInfo(this,oinfo)
            % SETOUTPUTINFO Set value of OutputInfo property
            %
            %   SETOUTPUTINFO(THIS,OINFO)
            %   Provide a struct containing output info. Require
            %   "OutputDirectory" field as char.
            if nargin<2
                this.OutputInfo = [];
                this.FlagOutputInfoSet = false;
                return;
            end
            
            % validate input
            assert(isstruct(oinfo),'Must provide struct, not "%s"',class(oinfo));
            
            % set output info
            this.OutputInfo = oinfo;
            this.FlagOutputInfoSet = true;
        end % END function setOutputInfo
        
        function exitCode = run(this)
            % % % % % % % % %
            % %
            % %    To-Do
            % %    - handle empty directories properly in extra files
            % %    - fix error in extra files processing
            % %    - there are some unnecessary Debugger objects (BLc Reader)
            % %    - fix sanity analysis
            % %
            similar_files_action = struct;
            exitCode = 1;
            
            % identify and create data directory
            outdir_data = getDataOutputDirectory(this);
            if exist(outdir_data,'dir')~=7
                [status,msg] = mkdir(outdir_data);
                assert(status,'Could not create directory "%s": %s',outdir_data,msg);
                assert(exist(outdir_data,'dir')==7,'Could not create directory "%s": unknown error',outdir_data);
            end
            
            % identify the participant
            participant = this.ParticipantInfo.ParticipantID;
            idxParticipantList = strcmpi(this.ParticipantList.ParticipantID,participant);
            assert(nnz(idxParticipantList)==1,'Could not identify a (single) matching participant for "%s" in the participant list',participant);
            
            % identify the hospital
            hospital = this.ParticipantInfo.HospitalID;
            
            %  identify recording date
            recording_date = datestr(this.RecordingInfo.Date,'yyyymmdd');
            
            % procedure date/type
            procedure_type = this.ProcedureInfo.Type;
            procedure = sprintf('%s-%s',datestr(this.ProcedureInfo.Date,'yyyymmdd'),procedure_type);
            
            % identify the archive directory
            archivedir_root = getArchiveDirectory(this);
            archivedir_rec = fullfile(archivedir_root,lower(hospital),participant,procedure,recording_date);
            
            % set up user prompt for dealing with similar-named/leftover files
            q_leftover_files = struct;
            q_file_type = struct;
            
            % process the source files
            datafiles = cell(1,size(this.SourceFiles,1));
            kk = 1;
            while kk<=size(this.SourceFiles,1)
                this.currFileIndex = kk;
                
                % broadcast file processing event
                evtdt = util.EventDataWrapper('FileInfo',this.SourceFiles(kk,:),'currFileIndex',kk);
                notify(this,'FileProcessingEvent',evtdt);
                
                % source file info
                srcfile_base = this.SourceFiles.basename{kk};
                srcfile_ext = this.SourceFiles.extension{kk};
                srcfile_filename = sprintf('%s%s',srcfile_base,srcfile_ext);
                srcfile_dir = this.SourceFiles.directory{kk};
                srcfile = fullfile(srcfile_dir,sprintf('%s%s',srcfile_base,this.SourceFiles.extension{kk}));
                srcmode = this.SourceFiles.mode{kk};
                
                % output info
                outfile_base = srcfile_base;
                outdir_rec = getRecordingOutputDirectory(this);
                
                % data conversion
                try
                    assert(exist(srcfile,'file')==2,'Source file "%s" does not exist on disk',srcfile);
                    switch lower(srcmode)
                        case 'blackrock'
                            switch lower(srcfile_ext)
                                case '.nev'
                                    error('NEV files are not supported yet');
                                case {'.ns1','.ns2','.ns3','.ns4','.ns5','.ns6'}
                                    
                                    % set up the prompter
                                    ext_fname = genvarname(srcfile_ext);
                                    if ~isfield(q_file_type,ext_fname)
                                        q_file_type.(ext_fname) = util.UserPrompt(...
                                            'option','Neural Data','option','Behavioral Data','option','Ignore',...
                                            'default','Neural Data','remember');
                                    end
                                    locrsp = q_file_type.(ext_fname).prompt(...
                                        'title',sprintf('Data Type for "%s"',srcfile_ext),...
                                        'question',sprintf('Process "%s" (*%s files) as neural data, behavioral data, or ignore these files?',srcfile_base,srcfile_ext));
                                    
                                    % process response
                                    switch lower(locrsp)
                                        case 'neural data'
                                            
                                            % log the response
                                            this.hDebug.log(sprintf('Processing "%s" as neural data',srcfile_base),'debug');
                                            
                                            % identify and validate output data filenames
                                            [~,datafiles{kk}] = BLc.convert.nsx2blc('srcfile',srcfile,'outdir',outdir_data,'outbase',outfile_base,this.hGridMap,this.hDebug,'overwrite','filenames');
                                            [flagOverwrite,flagExisting,flagCancel] = validateOutputFiles(this,datafiles{kk});
                                            if flagCancel
                                                exitCode = -1;
                                                return;
                                            end
                                            
                                            % run conversion
                                            if (flagExisting && flagOverwrite) || ~flagExisting
                                                args = {};
                                                if flagOverwrite
                                                    args = {'overwrite'};
                                                end
                                                
                                                % create map file
                                                mapfile = fullfile(outdir_data,sprintf('%s.map',outfile_base));
                                                if exist(mapfile,'file')~=2
                                                    this.hGridMap.saveas(mapfile,'RecordingChannel',args{:});
                                                end
                                                
                                                % create BLc files
                                                BLc.convert.nsx2blc('srcfile',srcfile,'outdir',outdir_data,'outbase',outfile_base,this.hGridMap,this.hDebug,args{:});
                                                
                                                % touch file to document source
                                                sbfcn__touchSourceFile(archivedir_rec,srcfile_base,outfile_base,outdir_data);
                                            end
                                        case 'behavioral data'
                                            
                                            % log the response
                                            this.hDebug.log(sprintf('Processing "%s" as behavioral data',srcfile_base),'debug');
                                            
                                            % identify channel labels (these will become separate files)
                                            ns = Blackrock.NSx(srcfile,this.hDebug);
                                            channel_labels = {ns.ChannelInfo.Label};
                                            idx_keep = find(~cellfun(@isempty,channel_labels));
                                            assert(~isempty(idx_keep),'Could not find any labeled channels in "%s"',srcfile);
                                            
                                            % construct tentative table with links between channels
                                            % in NSx and outputs in BLc
                                            behav_cell = cell(length(idx_keep),3);
                                            for cc=1:length(idx_keep)
                                                behav_cell{cc,1} = idx_keep(cc);
                                                behav_cell{cc,2} = channel_labels{idx_keep(cc)};
                                                behav_cell{cc,3} = sprintf('%s-%s',outfile_base,channel_labels{idx_keep(cc)});
                                            end
                                            behav = cell2table(behav_cell,'VariableNames',{'channel','label','basename'});
                                            
                                            % create the outputs
                                            for cc=1:size(behav,1)
                                                
                                                % identify and validate output data filenames
                                                local_map = GridMap.Interface;
                                                local_map.addBehavioralChannel(behav.label{cc},behav.channel(cc));
                                                [~,behavfile] = BLc.convert.nsx2blc('srcfile',srcfile,'outdir',outdir_data,'outbase',behav.basename{cc},local_map,'behavioral',this.hDebug,'overwrite','filenames');
                                                [flagOverwrite,flagExisting,flagCancel] = validateOutputFiles(this,behavfile);
                                                if flagCancel
                                                    exitCode = -1;
                                                    return;
                                                end
                                                
                                                % run conversion
                                                if (flagExisting && flagOverwrite) || ~flagExisting
                                                    args = {};
                                                    if flagOverwrite
                                                        args = {'overwrite'};
                                                    end
                                                    
                                                    % construct objects and convert
                                                    BLc.convert.nsx2blc('srcfile',srcfile,'outdir',outdir_data,'outbase',behav.basename{cc},local_map,'behavioral','maxquantizationerror',100,this.hDebug,args{:});
                                                    
                                                    % touch file to document source
                                                    sbfcn__touchSourceFile(archivedir_rec,srcfile_base,behav.basename{cc},outdir_data);
                                                end
                                            end
                                        case 'ignore'
                                            
                                            % log the response
                                            this.hDebug.log(sprintf('Ignoring "%s"',srcfile_base),'debug');
                                        otherwise
                                            error('Invalid response "%s"',locrsp);
                                    end
                                    
                                otherwise
                                    error('Unknown source file format "%s"',srcfile_ext);
                            end
                        case 'nicolet'
                            
                            % get output filenames
                            pdate = datestr(this.ProcedureInfo.Date,'yyyymmdd');
                            rdate = datestr(this.RecordingInfo.Date,'yyyymmdd');
                            srcfile_base = sprintf('%s-%s-%s-%s',this.ParticipantInfo.ParticipantID,pdate,this.ProcedureInfo.Type,rdate);
                            datafiles{kk} = fullfile(outdir_data,sprintf('%s.blc',srcfile_base));
                            [flagOverwrite,flagCancel] = validateOutputFiles(this,datafiles{kk});
                            if flagCancel
                                exitCode = -1;
                                return;
                            end
                            
                            % create map file
                            mapfile = fullfile(outdir_data,sprintf('%s.map',srcfile_base));
                            this.hGridMap.saveas(mapfile,'RecordingChannel','overwrite');
                            
                            % run conversion
                            args = {};
                            if flagOverwrite,args={'overwrite'};end
                            BLc.convert.e2blc('srcfile',srcfile,'outdir',outdir_data,'outbase',srcfile_base,'mapfile',mapfile,this.hDebug,args{:});
                        case 'natus'
                            error('Not implemented yet');
                            
                            % check whether exported ASCII file already exists
                            pdate = datestr(this.ProcedureInfo.Date,'yyyymmdd');
                            rdate = datestr(this.RecordingInfo.Date,'yyyymmdd');
                            srcfile_base = sprintf('%s-%s-%s-%s',this.ParticipantInfo.ParticipantID,pdate,this.ProcedureInfo.Type,rdate);
                            
                            % create map file
                            mapfile = fullfile(outdir_data,sprintf('%s.map',srcfile_base));
                            this.hGridMap.saveas(mapfile,'RecordingChannel','overwrite');
                            
                            workdir = getWorkingDirectory(this);
                            asciifiles = dir(fullfile(workdir,sprintf('%s_data*.txt',this.SourceFiles.basename)));
                            if ~isempty(asciifiles)
                                this.hDebug.log(sprintf('Found %d existing ascii files with naming convention "%s_data*.txt" in "%s"',length(asciifiles),this.SourceFiles.basename,workdir),'info');
                                
                                % get file sizes
                                bytestr = cell(1,length(asciifiles));
                                for kk=1:length(asciifiles)
                                    asciifile = fullfile(workdir,asciifiles(kk).name);
                                    info = dir(asciifile);
                                    bytestr{kk} = util.bytestr(info.bytes);
                                end
                                this.hDebug.log(sprintf('Existing ascii files have file sizes: %s',strjoin(bytestr,', ')),'info');
                                
                                % query user on how to proceed
                                queststr = sprintf('%d ASCII file(s) already exist (%s)! Use existing, overwrite, or cancel?',length(asciifiles),strjoin(bytestr,', '));
                                response = questdlg(queststr,'ASCII File Exists','Existing','Overwrite','Cancel','Cancel');
                                switch lower(response)
                                    case 'existing'
                                        
                                        % recover: use the existing ASCII file and move on
                                        this.hDebug.log('User chose to use the existing ASCII files','info');
                                        notify(this,'AutoITFinished');
                                    case 'overwrite'
                                        
                                        % overwrite: export from scratch (from Natus)
                                        this.hDebug.log('User chose to re-export the ASCII files','info');
                                        start(this.hTimer);
                                    case 'cancel'
                                        
                                        % exit the callback and return to GUI
                                        this.hDebug.log('User chose to cancel the run operation','info');
                                        return;
                                    otherwise
                                        error('bad code somewhere - no option for "%s"',response);
                                end
                            else
                                
                                % file does not exist: start the Natus export
                                this.hDebug.log('Starting the export operation','info');
                                start(this.hTimer);
                            end
                        otherwise
                            error('Unknown mode "%s"',this.SourceFiles.mode{kk});
                    end
                catch ME
                    msg = util.errorMessage(ME,'noscreen','nolink');
                    
                    % first ask the main question
                    q_srcfile = util.UserPrompt(...
                        'option','Keyboard','option','Skip','option','Cancel',...
                        'default','Skip');
                    response = q_srcfile.prompt(...
                        'title','Ingest Error',...
                        'question',sprintf('Could not process source file "%s%s": %s',srcfile_base,srcfile_ext,msg));
                    switch lower(response)
                        case 'keyboard'

                            % inform user and drop into keyboard
                            util.errorMessage(ME);
                            fprintf('\n');
                            fprintf('****************************************\n');
                            fprintf('* Make changes & press F5 to continue. *\n');
                            fprintf('****************************************\n');
                            fprintf('\n');
                            keyboard;
                        case 'skip'
                            
                            % do nothing and continue on
                            kk = kk+1;
                            continue;
                        case 'cancel'
                            
                            % exit
                            return;
                        otherwise
                            error('Unknown response "%s"',response);
                    end
                end
                
                % move source data file to archive directory
                try
                    
                    % identify subdirectory containing source file
                    if isempty(srcfile_dir)
                        
                        % store in root directory
                        srcfile_subdir = '';
                    else
                        
                        % get rid of training filesep characters
                        if strcmpi(srcfile_dir(end),filesep),srcfile_dir=srcfile_dir(1:end-1);end
                        
                        % split by filesep character, get rid of empty
                        srcfile_dir_hierarchy = strsplit(srcfile_dir,filesep);
                        srcfile_dir_hierarchy(cellfun(@isempty,srcfile_dir_hierarchy)) = [];
                        
                        % last "token" is the subdirectory
                        srcfile_subdir = srcfile_dir_hierarchy{end};
                    end
                    
                    % move the file
                    moveOrCopyFileOrDir(this,srcfile,fullfile(archivedir_rec,srcfile_subdir,srcfile_filename),@movefile);
                catch ME
                    [msg,stack] = util.errorMessage(ME,'noscreen','nolink');
                    
                    % first ask the main question
                    q_srcfile = util.UserPrompt(...
                        'option','Keyboard','option','Skip','option','Cancel',...
                        'default','Skip');
                    response = q_srcfile.prompt(...
                        'title','Ingest Error',...
                        'question',sprintf('Could not archive source file "%s%s": %s %s',srcfile_base,srcfile_ext,msg,stack{1}));
                    switch lower(response)
                        case 'keyboard'

                            % inform user and drop into keyboard
                            util.errorMessage(ME);
                            fprintf('\n');
                            fprintf('****************************************\n');
                            fprintf('* Make changes & press F5 to continue. *\n');
                            fprintf('****************************************\n');
                            fprintf('\n');
                            keyboard;
                        case 'skip'
                            
                            % do nothing and continue on
                            kk = kk+1;
                            continue;
                        case 'cancel'
                            
                            % exit
                            return;
                        otherwise
                            error('Unknown response "%s"',response);
                    end
                end
                
                % copy/move task files to output/archive directories
                try
                    
                    % identify and process task files
                    sbfcn__processTaskFiles(this,srcfile_base,srcfile_dir,srcmode,outdir_rec,archivedir_rec);
                catch ME
                    [msg,stack] = util.errorMessage(ME,'noscreen','nolink');
                    
                    % first ask the main question
                    q_srcfile = util.UserPrompt(...
                        'option','Keyboard','option','Skip','option','Cancel',...
                        'default','Skip');
                    response = q_srcfile.prompt(...
                        'title','Ingest Error',...
                        'question',sprintf('Could not process task files for "%s%s": %s %s',srcfile_base,srcfile_ext,msg,stack{1}));
                    switch lower(response)
                        case 'keyboard'

                            % inform user and drop into keyboard
                            util.errorMessage(ME);
                            fprintf('\n');
                            fprintf('****************************************\n');
                            fprintf('* Make changes & press F5 to continue. *\n');
                            fprintf('****************************************\n');
                            fprintf('\n');
                            keyboard;
                        case 'skip'
                            
                            % do nothing and continue on
                            kk = kk+1;
                            continue;
                        case 'cancel'
                            
                            % exit
                            return;
                        otherwise
                            error('Unknown response "%s"',response);
                    end
                end
                    
                % process files with similar basenames
                try
                    [similar_files_action,q_leftover_files] = sbfcn_processSimilarFiles(this,srcfile_dir,srcfile_base,archivedir_rec,outdir_rec,similar_files_action,q_leftover_files);
                catch ME
                    [msg,stack] = util.errorMessage(ME,'noscreen','nolink');
                    
                    % first ask the main question
                    q_srcfile = util.UserPrompt(...
                        'option','Keyboard','option','Skip','option','Cancel',...
                        'default','Skip');
                    response = q_srcfile.prompt(...
                        'title','Ingest Error',...
                        'question',sprintf('Error processing similar files for "%s%s": %s %s',srcfile_base,srcfile_ext,msg,stack{1}));
                    switch lower(response)
                        case 'keyboard'

                            % inform user and drop into keyboard
                            util.errorMessage(ME);
                            fprintf('\n');
                            fprintf('****************************************\n');
                            fprintf('* Make changes & press F5 to continue. *\n');
                            fprintf('****************************************\n');
                            fprintf('\n');
                            keyboard;
                        case 'skip'
                            
                            % do nothing and continue on
                            kk = kk+1;
                            continue;
                        case 'cancel'
                            
                            % exit
                            return;
                        otherwise
                            error('Unknown response "%s"',response);
                    end
                end
                
                % update loop variable
                kk = kk+1;
            end
            datafiles = cat(2,datafiles{:});
            
            % process any leftover files
            try
                processLeftoverFiles(this,archivedir_rec,q_leftover_files);
            catch ME
                msg = util.errorMessage(ME,'noscreen','nolink');
                
                % first ask the main question
                q_leftover = util.UserPrompt(...
                    'option','Keyboard','option','Skip','option','Cancel',...
                    'default','Skip');
                response = q_leftover.prompt(...
                    'title','Leftover file processing error',...
                    'question',sprintf('Could not process leftover files: %s',msg));
                switch lower(response)
                    case 'keyboard'
                        
                        % inform user and drop into keyboard
                        util.errorMessage(ME);
                        fprintf('\n');
                        fprintf('*********************************************************************\n');
                        fprintf('* Make changes & press F5 to continue.                              *\n');
                        fprintf('*********************************************************************\n');
                        fprintf('\n');
                        keyboard;
                    case 'skip'
                        
                        % do nothing and continue on
                    case 'cancel'
                        
                        % exit
                        return;
                    otherwise
                        error('Unknown response "%s"',response);
                end
            end
            
            % update the procedures list with this run
            try
                updateProcedureList(this);
            catch ME
                msg = util.errorMessage(ME,'noscreen','nolink');
                
                % first ask the main question
                q_proclist = util.UserPrompt(...
                    'option','Keyboard','option','Skip','option','Cancel',...
                    'default','Skip');
                response = q_proclist.prompt(...
                    'title','Procedure list update error',...
                    'question',sprintf('Could not update procedure list: %s',msg));
                switch lower(response)
                    case 'keyboard'
                        
                        % inform user and drop into keyboard
                        util.errorMessage(ME);
                        fprintf('\n');
                        fprintf('*********************************************************************\n');
                        fprintf('* Make changes & press F5 to continue.                              *\n');
                        fprintf('*********************************************************************\n');
                        fprintf('\n');
                        keyboard;
                    case 'skip'
                        
                        % do nothing and continue on
                    case 'cancel'
                        
                        % exit
                        return;
                    otherwise
                        error('Unknown response "%s"',response);
                end
            end
            
            % run sanity analysis
            try
                
                % first ask the main question
                q_sanity1 = util.UserPrompt('option','Yes','option','No','default','No');
                response = q_sanity1.prompt('title','Sanity Analysis',...
                    'question','Run sanity analysis?');
                switch lower(response)
                    case 'yes'
                        sanityAnalysis(this,datafiles);
                    case 'no'
                        % do nothing
                    otherwise
                        error('unknown response "%s"',response);
                end
            catch ME
                msg = util.errorMessage(ME,'noscreen','nolink');
                
                % first ask the main question
                q_sanity2 = util.UserPrompt(...
                    'option','Keyboard','option','Skip','option','Cancel',...
                    'default','Skip');
                response = q_sanity2.prompt(...
                    'title','Sanity analysis error',...
                    'question',sprintf('Could not complete sanity analysis: %s',msg));
                switch lower(response)
                    case 'keyboard'
                        
                        % inform user and drop into keyboard
                        util.errorMessage(ME);
                        fprintf('\n');
                        fprintf('*********************************************************************\n');
                        fprintf('* Make changes & press F5 to continue.                              *\n');
                        fprintf('*********************************************************************\n');
                        fprintf('\n');
                        keyboard;
                    case 'skip'
                        
                        % do nothing and continue on
                    case 'cancel'
                        
                        % exit
                        return;
                    otherwise
                        error('Unknown response "%s"',response);
                end
            end
            
            % backup the log file
            try
                backupLogfile(this,archivedir_rec);
            catch ME
                msg = util.errorMessage(ME,'noscreen','nolink');
                
                % first ask the main question
                q_logfile = util.UserPrompt(...
                    'option','Keyboard','option','Skip','option','Cancel',...
                    'default','Skip');
                response = q_logfile.prompt(...
                    'title','Log file backup error',...
                    'question',sprintf('Could not backup log file: %s',msg));
                switch lower(response)
                    case 'keyboard'
                        
                        % inform user and drop into keyboard
                        util.errorMessage(ME);
                        fprintf('\n');
                        fprintf('*********************************************************************\n');
                        fprintf('* Make changes & press F5 to continue.                              *\n');
                        fprintf('*********************************************************************\n');
                        fprintf('\n');
                        keyboard;
                    case 'skip'
                        
                        % do nothing and continue on
                    case 'cancel'
                        
                        % exit
                        return;
                    otherwise
                        error('Unknown response "%s"',response);
                end
            end
            
            
            
            
            function [similar_files_action,q_leftover_files] = sbfcn_processSimilarFiles(this,srcfile_dir,srcfile_base,archivedir_rec,outdir_rec,similar_files_action,q_leftover_files)
                
                % read out files with same basename, different extension
                similar_files = dir(fullfile(srcfile_dir,sprintf('%s.*',srcfile_base)));
                
                % make sure none of the similar datafiles are source files
                % waiting to be processed
                keep = false(1,length(similar_files));
                for ss=1:length(similar_files)
                    full_similar_file = fullfile(similar_files(ss).folder,similar_files(ss).name);
                    full_source_files = cellfun(@(x,y,z)fullfile(x,sprintf('%s%s',y,z)),this.SourceFiles.directory,this.SourceFiles.basename,this.SourceFiles.extension,'UniformOutput',false);
                    keep(ss) = ~any(strcmpi(full_similar_file,full_source_files));
                end
                similar_files = similar_files(keep);
                
                % query user on how to proceed if any exist
                for ee=1:length(similar_files)
                    file_name = similar_files(ee).name;
                    file_fullpath = fullfile(srcfile_dir,file_name);
                    
                    % identify subdirectory containing source file
                    if isempty(srcfile_dir)
                        
                        % store in root directory
                        dir_name = '';
                    else
                        
                        % get rid of training filesep characters
                        if strcmpi(srcfile_dir(end),filesep),srcfile_dir=srcfile_dir(1:end-1);end
                        
                        % split by filesep character, get rid of empty
                        dir_hierarchy = strsplit(srcfile_dir,filesep);
                        dir_hierarchy(cellfun(@isempty,dir_hierarchy)) = [];
                        
                        % last "token" is the subdirectory
                        dir_name = dir_hierarchy{end};
                    end
                    
                    % log the response
                    this.hDebug.log(sprintf('Found similar file "%s"',file_name),'debug');
                    
                    % process the file
                    archivedir_subdir = dir_name;
                    outdir_subdir = 'data';
                    q_leftover_files = processFile(this,file_fullpath,archivedir_subdir,outdir_subdir,file_name,outdir_rec,archivedir_rec,q_leftover_files);
                end
            end % END function sbfcn_processSimilarFiles
            
            
            
            function sbfcn__touchSourceFile(archivedir_rec,srcfile_base,outfile_base,outdir_data)
                
                % create ingest directory
                archivedir_ingest = fullfile(archivedir_rec,'ingest');
                if exist(archivedir_ingest,'dir')~=7
                    [local_status,local_msg] = mkdir(archivedir_ingest);
                    assert(local_status,'Could not create directory "%s": %s',archivedir_ingest,local_msg);
                    assert(exist(archivedir_ingest,'dir')==7,'Could not create directory "%s": unknown error',archivedir_ingest);
                end
                
                % update or create new
                touched_file = fullfile(archivedir_ingest,sprintf('%s.src',outfile_base));
                if exist(touched_file,'file')==2
                    touched_data = readtable(touched_file,'FileType','text');
                    idx_match = strcmpi(touched_data.src,srcfile_base) & strcmpi(touched_data.out,outfile_base) & strcmpi(touched_data.procdir,outdir_data);
                    if any(idx_match)
                        touched_data.timestamp(idx_match) = now;
                        writetable(touched_data,touched_file,'FileType','text');
                        return;
                    end
                else
                    touched_data = cell2table({now,srcfile_base,outfile_base,outdir_data},'VariableNames',{'timestamp','src','out','procdir'});
                    writetable(touched_data,touched_file,'FileType','text');
                end
            end % END function sbfcn__touchSourceFile
            
            
            function taskfiles = sbfcn__processTaskFiles(this,srcbase,srcdir,srcmode,outdir_rec,archivedir_rec)
                % PROCESSTASKFILES - subfunction to process task files
                % matching a given source data file
                
                % search for path to task folder
                taskfiles = {};
                switch lower(srcmode)
                    case 'blackrock'
                        
                        % get the task directory for this particular
                        % source file
                        [srctaskdir,found_taskdir] = sbfcn__findTaskDirectory(srcdir);
                        if ~found_taskdir
                            this.hDebug.log(sprintf('Could not identify task folder for "%s"',srcbase),'warn');
                        else
                            
                            % find matching files
                            [idx_match,local_taskfiles] = sbfcn__findMatchingTaskFiles(srctaskdir,srcbase);
                            
                            % if no matches, check in the archive directory
                            if any(idx_match)
                                
                                % look for related files
                                taskfiles = arrayfun(@(x)fullfile(x.folder,x.name),local_taskfiles,'UniformOutput',false);
                            end
                        end
                    otherwise
                        
                        % for all other source file modes (e.g. natus,
                        % xltek), assume no task file present
                        this.hDebug.log('For modes other than "blackrock", assuming no task files present','warn');
                        taskfiles = {};
                end
                
                % process any task files found
                for pp=1:length(taskfiles)
                    
                    % identify subdirectory containing task file
                    [local_taskdir,local_taskbase,local_taskext] = fileparts(taskfiles{pp});
                    local_taskfilename = sprintf('%s%s',local_taskbase,local_taskext);
                    if isempty(local_taskdir)
                        
                        % store in root directory
                        local_taskdir_name = '';
                    else
                        
                        % get rid of training filesep characters
                        if strcmpi(local_taskdir(end),filesep),local_taskdir=local_taskdir(1:end-1);end
                        
                        % split by filesep character, get rid of empty
                        local_taskdir_hierarchy = strsplit(local_taskdir,filesep);
                        local_taskdir_hierarchy(cellfun(@isempty,local_taskdir_hierarchy)) = [];
                        
                        % last "token" is the subdirectory
                        local_taskdir_name = local_taskdir_hierarchy{end};
                    end
                    
                    % create full paths to task folders
                    outdir_task = fullfile(outdir_rec,'task');
                    archivedir_task = fullfile(archivedir_rec,local_taskdir_name);
                    
                    % copy files to output directory, move to archive dir
                    moveOrCopyFileOrDir(this,taskfiles{pp},fullfile(outdir_task,local_taskfilename),@copyfile);
                    moveOrCopyFileOrDir(this,taskfiles{pp},fullfile(archivedir_task,local_taskfilename),@movefile);
                end
            end % END function sbfcn__findTaskFiles
            
            function [idx_match,files] = sbfcn__findMatchingTaskFiles(srctaskdir,srcbase)
                % some task files, for example the diary files, don't
                % include the task name in the filename so we have to match
                % on date/time alone. others, like the task data file or
                % the framework config file, do include both the date/time
                % and the task name and we should match on both. these two
                % scenarios are implemented here.
                
                % identify search tokens from data file source name
                if any(srcbase=='-')
                    tokens = strsplit(srcbase,'-');
                elseif any(srcbase=='_')
                    tokens = strsplit(srcbase,'_');
                else
                    tokens = srcbase;
                end
                
                % identify date/time tokens vs. task name tokens
                if iscell(tokens)
                    idx_numeric = ~cellfun(@isempty,regexpi(tokens,'^\d+$'));
                    local_date_tokens = tokens(idx_numeric);
                    local_name_tokens = tokens(~idx_numeric);
                else
                    assert(ischar(tokens),'Invalid token format "%s" (expected char)',class(tokens));
                    idx_numeric = ~isempty(regexpi(tokens,'^\d+$'));
                    if idx_numeric
                        local_date_tokens = {tokens};
                        local_name_tokens = {};
                    else
                        local_date_tokens = {};
                        local_name_tokens = {tokens};
                    end
                end
                
                % list of files in task directory
                local_taskfiles = dir(srctaskdir);
                local_taskfiles(arrayfun(@(x)~isempty(regexpi(x.name,'^\.+$')),local_taskfiles)) = [];
                if isempty(local_taskfiles)
                    files = {};
                    return;
                end
                
                % look for matching date/time vs matching name
                matches_date = arrayfun(@(x)sum(~cellfun(@isempty,regexpi(x.name,local_date_tokens))),local_taskfiles);
                matches_name = arrayfun(@(x)sum(~cellfun(@isempty,regexpi(x.name,local_name_tokens))),local_taskfiles);
                if ~isempty(local_date_tokens)
                    idx_match_date = matches_date>=0.5*length(local_date_tokens);
                else
                    idx_match_date = false(size(matches_date));
                end
                if ~isempty(local_name_tokens)
                    idx_match_name = matches_name>=0.5*length(local_name_tokens);
                else
                    idx_match_name = false(size(matches_date));
                end
                idx_match = idx_match_date | idx_match_name;
                
                % set the file output
                files = local_taskfiles(idx_match);
            end % END function sbfcn__findMatchingTaskFiles
            
            function [taskdir,flag_found] = sbfcn__findTaskDirectory(local_srcdir)
                srcdir_tokens = strsplit(local_srcdir,filesep);
                srcdir_tokens(cellfun(@isempty,srcdir_tokens)) = [];
                flag_found = false;
                for nn=1:length(srcdir_tokens)
                    taskdir = fullfile(local_srcdir(1:regexpi(local_srcdir,srcdir_tokens{end-nn+1})-2),'Task');
                    if exist(taskdir,'dir')==7
                        flag_found = true;
                        break;
                    end
                end
            end % END function sbfcn__findTaskDirectory
        end % END function run
        
        function q_leftover_files = processLeftoverFiles(this,archivedir_rec,q_leftover_files)
            
            % set up prompter for nonempty directory
            q_empty_directory = util.UserPrompt(...
                'remember',...
                'title','Empty directory',...
                'option','Delete','option','Ignore',...
                'default','Delete');
            
            % set up prompter for nonempty directory
            q_nonempty_directory = util.UserPrompt(...
                'title','Nonempty directory',...
                'option','Internal Contents','option','Whole Directory',...
                'default','Internal Contents');
            
            % set up the prompter for leftover whole directory
            q_leftover_dir = util.UserPrompt(...
                'option','Archive Only','option','Source+Archive','option','Ignore',...
                'default','Archive Only');
            
            % identify unique source directories
            source_directories = arrayfun(@(x)this.SourceFiles.directory{x},1:size(this.SourceFiles,1),'un',0);
            source_directories = unique(source_directories);
            
            % look for leftover data files
            for kk=1:length(source_directories)
                
                % get one level up
                srcdir = source_directories{kk};
                tokens = strsplit(srcdir,filesep);
                srcdir_upone = regexprep(srcdir,sprintf('^(.*)\\%s%s.*$',filesep,tokens{end}),'$1');
                
                % log the response
                this.hDebug.log(sprintf('Processing source directory "%s"',srcdir_upone),'debug');
                
                % process the directory
                q_leftover_files = processDirectory(this,srcdir_upone,'.',archivedir_rec,...
                    q_empty_directory,q_nonempty_directory,q_leftover_files,q_leftover_dir);
            end
        end % END function processLeftoverFiles
        
        
        
        function q_leftover_files = processDirectory(this,currdir_fullpath,currdir_name,archivedir_rec,q_empty_directory,q_nonempty_directory,q_leftover_files,q_leftover_dir)
            this.hDebug.log(sprintf('Processing directory "%s"',currdir_name),'info');
            outdir_rec = getRecordingOutputDirectory(this);
            
            % look for files and directories
            dir_contents = dir(currdir_fullpath);
            dir_contents( arrayfun(@(x)~isempty(regexpi(x.name,'^\.+$')),dir_contents) ) = [];
            
            % handle case of empty directory
            if isempty(dir_contents)
                
                % log the response
                this.hDebug.log(sprintf('Found empty directory "%s"',currdir_name),'debug');
                
                % process the empty directory
                processEmptyDirectory(this,currdir_fullpath,q_empty_directory);
            else
                
                % query user about nonempty directory
                rsp = q_nonempty_directory.prompt('question',sprintf('Found directory "%s" with %d files or sub-directories in it. Process contents individually or entire directory?',currdir_fullpath,length(dir_contents)));
                
                % process response
                switch lower(rsp)
                    case 'internal contents'
                        
                        % log the response
                        this.hDebug.log(sprintf('Processing contents of directory "%s" individually',currdir_name),'debug');
                        
                        % loop over each extension
                        for dd=1:length(dir_contents)
                            
                            % branch whether sub-directory or individual file
                            if dir_contents(dd).isdir
                                
                                % name and path of the sub-directory
                                subdir_name = dir_contents(dd).name;
                                subdir_fullpath = fullfile(currdir_fullpath,subdir_name);
                                
                                % log the response
                                this.hDebug.log(sprintf('Found sub-directory "%s"',subdir_name),'debug');
                                
                                % process the directory
                                q_leftover_files = processDirectory(this,subdir_fullpath,subdir_name,archivedir_rec,...
                                    q_empty_directory,q_nonempty_directory,q_leftover_files,q_leftover_dir);
                            else
                                
                                % name and path of the sub-file
                                subfile_name = dir_contents(dd).name;
                                subfile_fullpath = fullfile(currdir_fullpath,subfile_name);
                                
                                % log the response
                                this.hDebug.log(sprintf('Found sub-file "%s"',subfile_name),'debug');
                                
                                % process the file
                                archivedir_subdir = currdir_name;
                                outdir_subdir = currdir_name;
                                q_leftover_files = processFile(this,subfile_fullpath,archivedir_subdir,outdir_subdir,subfile_name,outdir_rec,archivedir_rec,q_leftover_files);
                            end
                        end
                        
                        % check for empty dir
                        dir_contents = dir(currdir_fullpath);
                        dir_contents(arrayfun(@(x)~isempty(regexpi(x.name,'^\.+$')),dir_contents)) = [];
                        if isempty(dir_contents)
                            
                            % log the response
                            this.hDebug.log(sprintf('Found empty directory "%s"',currdir_fullpath),'debug');
                            
                            % process the directory
                            processEmptyDirectory(this,currdir_fullpath,q_empty_directory);
                        end
                    case 'whole directory'
                        
                        % log the response
                        this.hDebug.log(sprintf('Processing whole directory "%s"',currdir_name),'debug');
                        
                        % process the nonempty directory
                        processWholeDirectory(this,currdir_fullpath,currdir_name,outdir_rec,archivedir_rec,q_leftover_dir);
                    otherwise
                        error('Unknown response "%s"',rsp);
                end
            end
        end % END function processDirectory
        
        function processWholeDirectory(this,currdir_fullpath,currdir_name,outdir_rec,archivedir_rec,q_leftover_dir)
            
            % prompt the user
            locrsp = q_leftover_dir.prompt(...
                'title',sprintf('Leftover directory "%s"',currdir_name),...
                'question',sprintf('Found directory "%s". Copy to archive only, source+archive, or ignore?',currdir_name));
            
            % process response
            switch lower(locrsp)
                case 'archive only'
                    
                    % log the response
                    this.hDebug.log(sprintf('User elected to archive only "%s"',currdir_name),'debug');
                    
                    % move to archive
                    moveOrCopyFileOrDir(this,currdir_fullpath,archivedir_rec,@movefile);
                case 'source+archive'
                    
                    % log the response
                    this.hDebug.log(sprintf('User elected to source+archive "%s"',currdir_name),'debug');
                    
                    % copy to source, move to archive
                    moveOrCopyFileOrDir(this,currdir_fullpath,fullfile(outdir_rec,currdir_name),@copyfile);
                    moveOrCopyFileOrDir(this,currdir_fullpath,archivedir_rec,@movefile);
                case 'ignore'
                    
                    % log the response
                    this.hDebug.log(sprintf('User elected to ignore "%s"',currdir_name),'debug');
                otherwise
                    error('Unknown response value "%s"',locrsp);
            end
        end % END function processWholeDirectory
        
        function q_leftover_files = processFile(this,currfile_fullpath,archivedir_subdir,outdir_subdir,currfile_name,outdir_rec,archivedir_rec,q_leftover_files)
            
            % set up the prompter
            [~,~,ext] = fileparts(currfile_fullpath);
            ext_fname = genvarname(ext);
            if ~isfield(q_leftover_files,ext_fname)
                q_leftover_files.(ext_fname) = util.UserPrompt(...
                    'option','Archive Only','option','Source+Archive','option','Ignore',...
                    'default','Archive Only','remember');
            end
            locrsp = q_leftover_files.(ext_fname).prompt(...
                'title',sprintf('Leftover "%s" file',ext),...
                'question',sprintf('Found file "%s". Copy to archive only, source+archive, or ignore?',currfile_fullpath));
            
            % process response
            switch lower(locrsp)
                case 'archive only'
                    
                    % log the response
                    this.hDebug.log(sprintf('User elected to archive only "%s"',currfile_name),'debug');
                    
                    % move to archive
                    moveOrCopyFileOrDir(this,currfile_fullpath,fullfile(archivedir_rec,archivedir_subdir,currfile_name),@movefile);
                case 'source+archive'
                    
                    % log the response
                    this.hDebug.log(sprintf('User elected to source+archive "%s"',currfile_name),'debug');
                    
                    % copy to source, move to archive
                    moveOrCopyFileOrDir(this,currfile_fullpath,fullfile(outdir_rec,outdir_subdir,currfile_name),@copyfile);
                    moveOrCopyFileOrDir(this,currfile_fullpath,fullfile(archivedir_rec,archivedir_subdir,currfile_name),@movefile);
                case 'ignore'
                    
                    % log the response
                    this.hDebug.log(sprintf('User elected to ignore "%s"',currfile_name),'debug');
                otherwise
                    error('Unknown response value "%s"',locrsp);
            end
        end % END function sbfcn__processSingleFile
        
        function processEmptyDirectory(this,currdir,q_empty_directory)
            
            % ask what to do with empty directory
            locrsp = q_empty_directory.prompt('question',sprintf('Found empty directory "%s". Delete or ignore?',currdir));
            
            % process response
            switch lower(locrsp)
                case 'delete'
                    
                    % log the response
                    this.hDebug.log(sprintf('User elected to remove empty directory "%s"',currdir),'debug');
                    
                    % final check on empty dir
                    loctmp = dir(currdir);
                    loctmp( arrayfun(@(x)~isempty(regexpi(x.name,'^\.+$')),loctmp) ) = [];
                    assert(isempty(loctmp),'Directory "%s" must be empty before removal from disk',currdir);
                    
                    % remove the directory
                    [lstatus,lmsg] = rmdir(currdir);
                    assert(lstatus>0,'Could not remove directory "%s": %s',currdir,lmsg);
                case 'ignore'
                    
                    % do nothing
                    this.hDebug.log(sprintf('User elected to ignore empty directory "%s"',currdir),'debug');
                otherwise
                    error('Unknown response value "%s"',locrsp);
            end
        end % END function processEmptyDirectory
        
        function moveOrCopyFileOrDir(this,source,destination,fn)
            
            % check whether the destination folder exists
            destination_dir = fileparts(destination);
            if exist(destination_dir,'dir')~=7
                [st,m] = mkdir(destination_dir);
                assert(st>0,'Could not create destination directory "%s": %s',destination_dir,m);
                this.hDebug.log(sprintf('Created directory "%s"',destination_dir),'debug');
            end
            
            % move or copy, then verify
            [local_status,local_msg] = feval(fn,source,destination);
            assert(local_status>0,'Could not move "%s" to "%s": %s',source,destination,local_msg);
            
            % log the operation
            fn_name = fn;
            if isa(fn_name,'function_handle'),fn_name=func2str(fn_name);end
            this.hDebug.log(sprintf('Completed "%s"; source "%s", destination "%s"',fn_name,source,destination),'debug');
        end % END function sbfcn__moveOrCopyFile
        
        function backupLogfile(this,archivedir)
            
            % identify log file
            matlab_old = this.hDebug.getLogfile;
            
            % construct new basename (substring common to all source files)
            matlab_base = this.SourceFiles.basename{1};
            for kk=2:size(this.SourceFiles,1)
                len = min(length(matlab_base),length(this.SourceFiles.basename{kk}));
                if strcmpi(matlab_base(1:len),this.SourceFiles.basename{kk}(1:len))
                    continue;
                else
                    idx_first_discrepancy = find(matlab_base(1:len)~=this.SourceFiles.basename{kk}(1:len),1,'first');
                    if isempty(idx_first_discrepancy)
                        matlab_base = '';
                        break;
                    else
                        if idx_first_discrepancy>5
                            matlab_base = matlab_base(1:idx_first_discrepancy-1);
                        end
                    end
                end
            end
            if matlab_base(end)=='-',matlab_base=matlab_base(1:end-1);end
            matlab_base = sprintf('%s_matlab.txt',matlab_base);
            matlab_new = fullfile(archivedir,'ingest',matlab_base);
            this.hDebug.log(sprintf('Moving log file "%s" to "%s"',matlab_old,matlab_new),'info');
            
            % move the file
            [status,msg] = copyfile(matlab_old,matlab_new);
            assert(status>0,'Could not move "%s" to "%s": %s',matlab_old,matlab_new,msg);
        end % END function backupLogfile
        
        function sanityAnalysis(this,datafiles)
            
            % run sanity analysis
            for kk=1:length(datafiles)
                [datadir,database,dataext] = fileparts(datafiles{kk});
                this.hDebug.log(sprintf('Running sanity analysis for "%s"',sprintf('%s%s',database,dataext)),'info');
                try
                    assert(strcmpi(dataext,'.blc'),'Data files must be BLc files');
                    assert(exist(datafiles{kk},'file')==2,'Could not find "%s"',datafiles{kk});
                    blc = BLc.Reader(datafiles{kk},this.hDebug);
                    a = BLc.Analyze(blc,this.hGridMap,this.hDebug,'numSeconds',60);
                    a.run('outdir',fullfile(datadir,'sanity'),'basename',blc.SourceBasename,'formats',{'fig','png'});
                catch ME
                    util.errorMessage(ME);
                end
            end
        end % END function sanityAnalysis
        
        function debugKeyboard(this)
            
            % if timer is running, stop it
            flagRestartTimer = false;
            if isa(this.hTimer,'timer') && isvalid(this.hTimer) && strcmpi(this.hTimer.Running,'on')
                stop(this.hTimer);
                flagRestartTimer = true;
            end
            
            % print identifying message and drop to keyboard
            fprintf('This is a debug prompt. All MATLAB processes are paused. Press F5 to continue execution.\n');
            keyboard;
            
            % restart the timer if needed
            if flagRestartTimer
                recover(this);
            end
        end % END function debugKeyboard
        
        function workdir = getWorkingDirectory(this)
            
            % review data directory/directories and choose local if
            % there's enough free space
            potentialDirs = [util.ascell(this.OutputInfo.OutputDirectory) util.ascell(env.get('temp'))];
            freeBytes = nan(1,length(potentialDirs));
            totalBytes = nan(1,length(potentialDirs));
            usableBytes = nan(1,length(potentialDirs));
            for kk=1:length(potentialDirs)
                assert(exist(potentialDirs{kk},'dir')==7,'Could not find "%s" on disk',potentialDirs{kk});
                FileObj = java.io.File(potentialDirs{kk});
                freeBytes(kk) = FileObj.getFreeSpace;
                totalBytes(kk) = FileObj.getTotalSpace;
                usableBytes(kk) = FileObj.getUsableSpace;
                this.hDebug.log(sprintf('Evaluating "%s" for working directory: %s free, %s total, %s usable',...
                    potentialDirs{kk},util.bytestr(freeBytes(kk)),util.bytestr(totalBytes(kk)),...
                    util.bytestr(usableBytes(kk))),'info');
            end
            
            % require at least 200 GB free
            idxBad = freeBytes < 200*1024*1024*1024;
            if any(idxBad)
                this.hDebug.log(sprintf('Found %d/%d directories with less than 200 GB free space: %s',nnz(idxBad),numel(idxBad),util.vec2str(find(idxBad))),'info'); %#ok<FNDSB>
            end
            potentialDirs(idxBad) = [];
            assert(~isempty(potentialDirs),'Could not find a path with enough free space to export (require at least 200GB free)');
            
            % check for UNC paths
            idxUNC = cellfun(@(x)strcmp(x(1:2),'\\'),potentialDirs);
            if any(idxUNC)
                this.hDebug.log(sprintf('Found %d/%d directories that look like UNC paths: %s',nnz(idxUNC),numel(idxUNC),util.vec2str(find(idxUNC))),'info'); %#ok<FNDSB>
            end
            if ~all(idxUNC)
                potentialDirs(idxUNC) = [];
            end
            
            % select the first of the remaining directories
            workdir = fullfile(potentialDirs{1},'working');
            this.hDebug.log(sprintf('Selected "%s" as the working directory',workdir),'info');
        end % END function getWorkingDirectory
        
        function datadir = getDataOutputDirectory(this)
            recdir = getRecordingOutputDirectory(this);
            datadir = fullfile(recdir,'data');
        end % END function getDataOutputDirectory
        
        function recdir = getRecordingOutputDirectory(this)
            procdir = getProcedureOutputDirectory(this);
            recordingDate = datestr(this.RecordingInfo.Date,'yyyymmdd');
            recdir = fullfile(procdir,recordingDate);
        end % END function getRecordingOutputDirectory
        
        function procdir = getProcedureOutputDirectory(this)
            participantdir = getParticipantOutputDirectory(this);
            procedureType = this.ProcedureInfo.Type;
            procdir = fullfile(participantdir,sprintf('%s-%s',datestr(this.ProcedureInfo.Date,'yyyymmdd'),procedureType));
        end % END function getProcedureOutputDirectory
        
        function participantdir = getParticipantOutputDirectory(this)
            outdir = this.OutputInfo.OutputDirectory;
            participant = this.ParticipantInfo.ParticipantID;
            participantdir = fullfile(outdir,'source',participant);
        end % END function getParticipantOutputDirectory
        
        function archivedir = getArchiveDirectory(this)
            outdir = this.OutputInfo.OutputDirectory;
            %participant = this.ParticipantInfo.ParticipantID;
            %fullfile(env.get('archive'),lower(hospital),participant,procedure,recordingDate);
            archivedir = fullfile(outdir,'archive');
        end % END function getArchiveDirectory
        
        function participant = getParticipantInfo(this,participant)
            idxParticipant = find(strcmpi(this.ParticipantList.ParticipantID,participant));
            if isempty(idxParticipant)
                propertyList = this.ParticipantList.Properties.VariableNames;
                participant = cell2table(cell(0,length(propertyList)),'VariableNames',propertyList);
            else
                assert(length(idxParticipant)==1,'Found multiple matches for participant "%s"',participant);
                participant = this.ParticipantList(idxParticipant,:);
            end
        end % END function getParticipantInfo
        
        function procedures = getParticipantProcedures(this,participant)
            idxParticipant = find(strcmpi(this.ProcedureList.ParticipantID,participant));
            if isempty(idxParticipant)
                propertyList = this.ProcedureList.Properties.VariableNames;
                procedures = cell2table(cell(0,length(propertyList)),'VariableNames',propertyList);
            else
                procedures = this.ProcedureList(idxParticipant,:);
            end
        end % END function getParticipantProcedures
        
        function updateParticipantList(this)
            
            % get participant information
            participant = this.ParticipantInfo.ParticipantID;
            hospital = this.ParticipantInfo.HospitalID;
            idxParticipantList = strcmpi(this.ParticipantList.ParticipantID,participant);
            if nnz(idxParticipantList)==0
                
                % new participant: create a new entry
                newParticipant = cell2table({participant,hospital},...
                    'VariableNames',this.ParticipantList.Properties.VariableNames);
                if isempty(this.ParticipantInfo)
                    this.ParticipantList = newParticipant;
                else
                    this.ParticipantList = [this.ParticipantList; newParticipant];
                end
                sbfcn__writeParticipantsFile(this);
                this.hDebug.log(sprintf('Created a new participant %s, hospital %s',participant,hospital),'debug');
            else
                
                % existing participant: update the fields
                assert(nnz(idxParticipantList)==1,'Found multiple matches for the participant');
                if hospital ~= this.ParticipantList.HospitalID{idxParticipantList}
                    this.ParticipantList.Hospital{idxParticipantList} = hospital;
                    sbfcn__writeParticipantsFile(this);
                end
                this.hDebug.log(sprintf('Updated participant %s, hospital %s',participant,hospital),'debug');
            end
            
            
            function sbfcn__writeParticipantsFile(this)
                
                % find the procedure list file
                datadirs = env.get('data');
                flag_found = false;
                for kk=1:length(datadirs)
                    participantsFile = fullfile(datadirs{kk},'participants.csv');
                    if exist(participantsFile,'file')==2
                        flag_found = true;
                        break;
                    end
                end
                assert(flag_found,'Could not find participants file');
                this.hDebug.log(sprintf('Found participants file "%s"',participantsFile),'info');
                
                % back up the procedure file
                partdir = fileparts(participantsFile);
                idx = 1;
                backupFile = fullfile(partdir,'backup',sprintf('participants_%s_%03d.csv',datestr(now,'yyyymmdd'),idx));
                while exist(backupFile,'file')==2
                    idx = idx + 1;
                    backupFile = fullfile(partdir,'backup',sprintf('participants_%s_%03d.csv',datestr(now,'yyyymmdd'),idx));
                end
                this.hDebug.log(sprintf('Backing up participants file to "%s"',backupFile),'info');
                [status,msg] = copyfile(participantsFile,backupFile);
                if ~status
                    fprintf('ERROR!\n\n');
                    fprintf('Could not copy participants file "%s" to backup location "%s": %s',participantsFile,backupFile,msg);
                    fprintf('Please create your own backup copy of the participants file and press F5 to continue.\n');
                    keyboard;
                end
                
                % overwrite the procedure file
                writetable(this.ParticipantList,participantsFile);
            end % END function sbfcn__writeParticipantsFile
        end % END function updateParticipantList
        
        function updateProcedureList(this)
            
            % get procedure information: Patient, date, type, etc.
            participant = this.ParticipantInfo.ParticipantID;
            procedureType = this.ProcedureInfo.Type;
            procedureDate = this.ProcedureInfo.Date;
            recordingDate = this.RecordingInfo.Date;
            
            % check whether this is a new or existing procedure
            idxMatch = strcmpi(this.ProcedureList.ParticipantID,participant) & ...
                    strcmpi(this.ProcedureList.ProcedureType,procedureType) & ...
                    this.ProcedureList.ProcedureDate==procedureDate;
            if nnz(idxMatch)==0
                
                % new procedure: create a new entry
                recordingStartDate = recordingDate;
                recordingEndDate = recordingDate;
                newProcedure = cell2table({participant,procedureType,procedureDate,recordingStartDate,recordingEndDate},...
                    'VariableNames',this.ProcedureList.Properties.VariableNames);
                if isempty(this.ProcedureList)
                    this.ProcedureList = newProcedure;
                else
                    this.ProcedureList = [this.ProcedureList; newProcedure];
                end
                sbfcn__writeProcedureFile(this);
                this.hDebug.log(sprintf('Created a new procedure: participant %s, type %s, date %s, start %s, end %s',...
                    participant,procedureType,datestr(procedureDate,'yyyymmdd'),datestr(recordingStartDate,'yyyymmdd'),datestr(recordingEndDate,'yyyymmdd')),'debug');
            else
                
                % existing procedure: update the recording end date
                assert(nnz(idxMatch)==1,'Found multiple matches for the current procedure');
                if recordingDate > this.ProcedureList.RecordingEndDate(idxMatch)
                    this.ProcedureList.RecordingEndDate(idxMatch) = recordingDate;
                    sbfcn__writeProcedureFile(this);
                elseif recordingDate < this.ProcedureList.RecordingStartDate(idxMatch)
                    this.ProcedureList.RecordingStartDate(idxMatch) = recordingDate;
                    sbfcn__writeProcedureFile(this);
                end
                this.hDebug.log(sprintf('Updated procedure: participant %s, date %s, new end date %s',...
                    this.ProcedureList.ParticipantID{idxMatch},this.ProcedureList.ProcedureType{idxMatch},...
                    datestr(this.ProcedureList.RecordingEndDate(idxMatch))),'debug');
            end
            
            
            
            function sbfcn__writeProcedureFile(this)
                
                % find the procedure list file
                datadirs = util.ascell(env.get('data'));
                flag_found = false;
                for kk=1:length(datadirs)
                    procedureFile = fullfile(datadirs{kk},'procedures.csv');
                    if exist(procedureFile,'file')==2
                        flag_found = true;
                        break;
                    end
                end
                assert(flag_found,'Could not find procedures file');
                this.hDebug.log(sprintf('Found procedure file "%s"',procedureFile),'info');
                
                % back up the procedure file
                procdir = fileparts(procedureFile);
                idx = 1;
                backupFile = fullfile(procdir,'backup',sprintf('procedures_%s_%03d.csv',datestr(now,'yyyymmdd'),idx));
                while exist(backupFile,'file')==2
                    idx = idx + 1;
                    backupFile = fullfile(procdir,'backup',sprintf('procedures_%s_%03d.csv',datestr(now,'yyyymmdd'),idx));
                end
                this.hDebug.log(sprintf('Backing up procedure file to "%s"',backupFile),'info');
                [status,msg] = copyfile(procedureFile,backupFile);
                if ~status
                    fprintf('ERROR!\n\n');
                    fprintf('Could not copy procedure file "%s" to backup location "%s": %s',procedureFile,backupFile,msg);
                    fprintf('Please create your own backup copy of the procedure file and press F5 to continue.\n');
                    keyboard;
                end
                
                % overwrite the procedure file
                writetable(this.ProcedureList,procedureFile);
            end % END function sbfcn__writeProcedureFile
        end % END function updateProcedureList
    end % END methods
    
    methods(Static)
        function dt = static__str2date(dt)
            if regexpi(dt,'^\d{2}/\d{2}/\d{4}$')
                dt = datetime(dt,'InputFormat','MM/dd/yyyy');
            elseif regexpi(dt,'^\d{8}$')
                dt = datetime(dt,'InputFormat','yyyyMMdd');
            else
                error('Unknown input format');
            end
        end % END function static_str2date
    end % END methods(Static)
end % END class Interface