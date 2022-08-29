classdef FrameworkTask < handle & util.Structable
    % FRAMEWORKTASK Represents access to all aspects of Framework tasks
    %
    %   The FRAMEWORKTASK object includes properties and methods that expose
    %   all recorded aspects of Framework tasks. To construct the FRAMEWORKTASK
    %   object, provide the full path to a Framework output MAT file:
    %
    %     >> task = FrameworkTask('/path/to/file.mat')
    %
    %   To get objects for reading neural data:
    %
    %     >> nv = task.getNeuralDataObjects('nv');
    %     >> ns6 = task.getNeuralDataObjects('ns6');
    %
    %   To get objects for electrode array layout:
    %
    %     >> map = task.getArrayMapObject;
    %
    %   To get the average relative timing of phases:
    %
    %     >> relt = mean(task.phaseTimes - repmat(task.phaseTimes(:,1),[1 task.numPhases]),1)
    %
    %   To check the timing of the Framework with respect to neural data:
    %
    %     >> task.checkTiming(true);
    %
    %   See the help for individual methods and properties for additional
    %   information.
    
    properties
        hDebug % handle to Debug.Debugger object
        hParameters % handle to Parameters.Dyanmic object
    end % END properties
    
    properties(SetAccess=public,GetAccess=public)
        idString % the ID string of the Framework session (typically YYYYMMDD-HHMMSS')
        taskString % the task string of the Framework session (typically sprintf('%s-HHMMSS',idString) with the time of the framework start)
        taskName % the name of the task
        parameterName % the basename of the task parameters file (no path or extension)
        userEndComment % the comment provided by the user at the end of the task
        session % the session string (typically YYYYMMDD)
        subject % the subject ID string
        researcher % the researcher ID string
        sessionPath % the path to the directory containing data for the session containing this task
        nspNames % the names of the electrode arrays
        numNSPs % the number of electrode arrays
        neuralBasenames % the basenames of the neural data recording files for this task
        neuralSourceIsSimulated % logical value indicating whether the neural data were simulated (true) or measured/recorded (false)
        opticalPulsePresent % logical value indicating whether the optical pulses was enabled and recorded for this task
        numFrames % the number of Framework frames executed for this task
        block % block index (only applicable for old block file structure)
        numBlocks % number of blocks in the file (only applicable for old block file structure)
        
        srcDir % full path to the directory containing the task file
        srcFile % basename of the task file
        srcExt % file extension of the task file
        
        options % the Framework options struct
        runtime % the Framework runtime struct
        data % the Framework data struct
        task % the Framework task struct
        predictor % the Framework predictor struct
        neuralSource % the Framework neuralSource struct
        other % any root-level fields not processed/expected by FrameworkTasks
        
        trialdata % the trial data struct array copied from the Framework task struct
        trialparams % the trail params struct array copied from the Framework task struct
        numTrials % the number of trials executed in this task
        numPhases % the number of phases per task
        phaseNames % the names of the task phases
        phaseTimes % the timing of each phase in each trial (N rows, K columns for N trials and K phases)
        trialTimes % the start and length of each trial (N rows for N trials)
        
        eventFs = 30e3; % the sampling frequency of the NEV file
    end % END properties(SetAccess=private,GetAccess=public)
    
    properties(Access=private)
        defaultOpticalPulseLag = 0.0; % default lag to be used when optical pulses not recorded
        opticalProcessed = false; % flag to indicate that the optical pulses have been processed
        nsPulseTimes % the neural times at which sync pulses were registered
        fwPulseTimes % the framework timestamps at which sync pulses were registered
        fwPulseFrames % the framework frame in which sync pulses were registered
    end % END properties(Access=private)
    
    methods
        function this = FrameworkTask(fwfile,varargin)
            
            % set up parameters
            [varargin,this.hParameters] = util.argisa('Parameters.Interface',varargin,[]);
            if isempty(this.hParameters)
                this.hParameters = Parameters.Dynamic(@Parameters.Config.FrameworkTask);
            end
            assert(isa(this.hParameters,'Parameters.Interface'),'Parameters object should be ''Parameters.Interface'', not ''%s''',class(this.hParameters));
            [varargin,this.hDebug] = util.argisa('Debug.Debugger',varargin,[]);
            if isempty(this.hDebug)
                this.hDebug = Debug.Debugger(sprintf('FrameworkTask_%s',datestr(now,'yyyymmdd-HHMMSS')),varargin{:});
            end
            
            % get the block ID
            [varargin,this.block] = util.argkeyval('block',varargin,1);
            
            % make sure no unused inputs
            util.argempty(varargin);
            
            % if just a basename, parse out the session and infer path
            tokens = regexpi(fwfile,'^(?<session>\d{8})-\d{6}-\d{6}-\w+$','names');
            if ~isempty(tokens)
                subjects = hst.getSubjects;
                for ss=1:length(subjects)
                    fwdir = hst.getSessionPath(tokens.session,subjects{ss});
                    tmpfile = fullfile(fwdir,'Task',sprintf('%s.mat',fwfile));
                    if exist(tmpfile,'file')==2,break;end
                end
                assert(exist(tmpfile,'file')==2,'Could not identify the path for data file ''%s''',fwfile);
                fwfile = tmpfile;
            end
            
            % check for directory input
            if exist(fwfile,'dir')==7
                
                % user select file(s)
                [fwfile,fwdir] = uigetfile(fullfile(fwfile,'*.mat'),'Select MAT file','MultiSelect','off');
                if isnumeric(fwfile)
                    log(this.hDebug,'No data files selected','warn');
                    return;
                end
                assert(ischar(fwfile),'Invalid file input: must be char, not ''%s''',class(fwfile));
                fwfile = fullfile(fwdir,fwfile);
            end
            
            % check input
            assert(nargin>=1&&exist(fwfile,'file')==2,'Must provide valid path to task file');
            [this.srcDir,this.srcFile,this.srcExt] = fileparts(fwfile);
            assert(strcmpi(this.srcExt,'.mat'),'Must provide path to valid Framework task file with .mat extension, not ''%s''',this.srcExt);
            
            % load task file
            taskfile = fullfile(this.srcDir,sprintf('%s%s',this.srcFile,this.srcExt));
            log(this.hDebug,sprintf('Loading task file ''%s''',taskfile),'debug');
            fw = load(taskfile);
            
            % support for old block file structure (multiple runs in a
            % single file)
            if isfield(fw,'Block')
                
                % custom code for old block structure
                processBlockStructure(this);
            else
                
                % pull out high-level framework data
                this.idString = fw.idString;
                this.taskString = fw.Runtime.baseFilename;
                this.taskName = fw.Options.runName;
                if iscell(fw.Options.taskConfig) && ~isempty(fw.Options.taskConfig{1})
                    prmName = strsplit(fw.Options.taskConfig{1},'.');
                    this.parameterName = prmName{end};
                end
                cmt = fw.Data.comments{end}{2};
                this.userEndComment = cmt((strfind(cmt,' : ')+3):end);
                this.runtime = fw.Runtime;
                this.data = fw.Data;
                this.options = fw.Options;
                if isfield(fw,'Predictor')
                    this.predictor = fw.Predictor;
                end
                if isfield(fw,'NeuralSource')
                    this.neuralSource = fw.NeuralSource;
                end
                if isfield(fw,'Task')
                    this.task = fw.Task;
                end
            end
            this.numFrames = length(this.data.frameId);
            assert(this.numFrames>1,'Insufficient frames (numFrames = %d)',this.numFrames);
            
            datafields = fieldnames(this.data);
            datafields(~cellfun(@(x)isnumeric(this.data.(x)),datafields)) = [];
            allNumFrames = cellfun(@(x)size(this.data.(x),1),datafields);
            if ~all(allNumFrames==this.numFrames)
                minNumFrames = min(allNumFrames);
                maxNumFrames = max(allNumFrames);
                log(this.hDebug,sprintf('Data fields %s have between [%d,%d] frames, which is different from %d frameId entries',strjoin(datafields(allNumFrames~=this.numFrames),', '),minNumFrames,maxNumFrames,this.numFrames),'warn');
            end
            
            % pull out trial data
            if ~isempty(this.task) && isstruct(this.task)
                if isfield(this.task,'TrialData')
                    this.trialdata = this.task.TrialData;
                elseif isfield(this.task,'trials')
                    this.trialdata = this.task.trials;
                end
                if isfield(this.trialdata,'eT_trialStart')
                    fld_start = 'eT_trialStart';
                    fld_completed = 'eT_trialCompleted';
                elseif isfield(this.trialdata,'et_trialStart')
                    fld_start = 'et_trialStart';
                    fld_completed = 'et_trialCompleted';
                end
                if ~isempty(this.trialdata)
                    % extra checkpoint for empty trial at the end (possible
                    % FrameworkWork error (?)
                    if all(structfun(@isempty,this.trialdata(end)))
                        this.trialdata(end) = [];
                    end
                    assert(this.numFrames>=max(this.trialdata(end).(fld_start),this.trialdata(end).(fld_completed)),...
                        'Insufficient data (trial %d, frames %d)',max(this.trialdata(end).(fld_start),this.trialdata(end).(fld_completed)),this.numFrames);
                end
            end
            if isfield(this.task,'TrialParams') && ~isempty(this.task.TrialParams)
                this.trialparams = this.task.TrialParams;
            end
            if ~isempty(this.trialdata)
                this.numTrials = length(this.trialdata);
                empty = false(1,this.numTrials);
                for kk=1:this.numTrials
                    flds = fieldnames(this.trialdata(kk));
                    flds(strcmpi(flds,'TrialParams')) = [];
                    empty(kk) = all(cellfun(@(x)isempty(this.trialdata(kk).(x)),flds));
                end
                if any(empty)
                    log(this.hDebug,sprintf('There are %d TrialData entries, but %d of them are empty',this.numTrials,nnz(empty)),'warning');
                    this.trialdata(empty) = [];
                    this.numTrials = nnz(~empty);
                end
            elseif isfield(this.task,'trials')
                this.numTrials = length(this.task.trials);
            else
                log(this.hDebug,'Found 0 trials','warning');
                this.numTrials = 0;
            end
            if isfield(this.task,'hTrial') && isfield(this.task.hTrial,'phaseNames')
                this.phaseNames = this.task.hTrial.phaseNames;
            else
                this.phaseNames = {'PhaseDummy'};
                for tt=1:this.numTrials
                    if this.trialdata(tt).(fld_start) > this.trialdata(tt).(fld_completed)
                        this.trialdata(tt).(fld_start) = 1; % first trial of block>=2 often retains last frameId of previous block
                    end
                    this.trialdata(tt).et_phase = this.trialdata(tt).(fld_start); % add in the start time of the trial as the start of the dummy phase
                    if ~strcmp(fld_completed,'et_trialCompleted')
                        this.trialdata(tt).et_trialCompleted = this.trialdata(tt).(fld_completed); % for convenience, replicate trial completion into the expected field
                    end
                end
            end
            this.numPhases = length(this.phaseNames);
            
            % identify session
            tk = regexpi(this.idString,'^(\d{8})','tokens');
            assert(~isempty(tk)&&iscell(tk)&&~isempty(tk{1}),'Could not identify session');
            this.session = tk{1}{1};
            
            % identify subject
            if isfield(this.options,'subject')
                sb = this.options.subject;
                this.subject = sb;
            end
            
            % identify researcher
            if isfield(this.options,'researcher')
                rs = this.options.researcher;
                this.researcher = rs;
            end
            
            % print identifying information
            log(this.hDebug,sprintf('Session ''%s''',this.session),'info');
            log(this.hDebug,sprintf('Researcher ''%s''',this.researcher),'info');
            log(this.hDebug,sprintf('Subject ''%s''',this.subject),'info');
            log(this.hDebug,sprintf('Task ''%s''',this.taskName),'info');
            log(this.hDebug,sprintf('Parameters ''%s''',this.parameterName),'info');
            log(this.hDebug,sprintf('%d trials',this.numTrials),'info');
            
            % get the session folder
            if (ischar(this.options.debug)&&strcmpi(this.options.debug,'off')) || ((islogical(this.options.debug)||isnumeric(this.options.debug))&&~this.options.debug)
                pth = fwfile(1:strfind(fwfile,'Task')-2);
                assert(~isempty(pth)&&exist(pth,'dir'),'Session path ''%s'' is not a valid directory',pth);
                this.sessionPath = pth;
            else
                pth = env.get('data');
                for kk=1:length(pth)
                    tmppth = fullfile(pth{kk},this.subject,this.session);
                    if exist(tmppth,'dir')==7
                        this.sessionPath = tmppth;
                        break;
                    end
                    if strncmpi(fwfile,pth{kk},length(pth{kk}))
                        this.sessionPath = regexprep(fwfile,sprintf('^(.*)\\%s[tT]ask.*$',filesep),'$1');
                        break;
                    end
                end
                assert(~isempty(this.sessionPath)&&exist(this.sessionPath,'dir')==7,'Could not find session path "%s"',this.sessionPath);
            end
            
            % configure neural data
            if isfield(this.options,'neuralConstructor')
                pinfo = meta.class.fromName(this.options.neuralConstructor);
                this.neuralSourceIsSimulated = pinfo.PropertyList(strcmpi({pinfo.PropertyList.Name},'isSimulated')).DefaultValue;
                if isfield(fw.Options,'neuralConstructor') && strcmpi(fw.Options.neuralConstructor,'Framework.NeuralSource.Rand')
                    this.neuralSourceIsSimulated = true;
                    log(this.hDebug,'Neural source was simulated','warn');
                end
            else
                log(this.hDebug,'Cannot tell whether neural data were simulated or real (for convenience, assuming neural data are real)','info');
                this.neuralSourceIsSimulated = false;
            end
            
            % pull out array information from saved Framework data
            if this.neuralSourceIsSimulated
                if ~isfield(this.options,'arrays')
                    this.nspNames = {};
                else
                    this.nspNames = this.options.arrays;
                end
            else
                
                % load array names from Framework options
                if isfield(fw.Options,'nsps')
                    this.nspNames = fw.Options.nsps;
                elseif isfield(fw.Options,'arrays')
                    this.nspNames = fw.Options.arrays;
                else
                    error('Could not identify array names');
                end
                
                % assume for now that all trials recorded to same neural file
                if isfield(fw,'NeuralSource') && isfield(fw.NeuralSource,'hCBMEX')
                    this.neuralBasenames = fw.NeuralSource.hCBMEX.recordFilenames;
                elseif isfield(this.trialdata,'neu_filenames') && this.numTrials>0 && ~isempty(this.trialdata(1).neu_filenames)
                    this.neuralBasenames = this.trialdata(1).neu_filenames;
                elseif isfield(this.trialdata,'nspFilenames') && ~isempty(this.trialdata(1).nspFilenames)
                    this.neuralBasenames = this.trialdata(1).nspFilenames;
                end
                assert(~isempty(this.neuralBasenames),'Could not identify the filename of the recorded neural data');
                this.numNSPs = length(this.nspNames);
                assert(this.numNSPs==length(this.nspNames),'Number of neural files must agree with number of array names');
            end
            this.numNSPs = length(this.nspNames);
            log(this.hDebug,sprintf('Electrode array names %s',strjoin(this.nspNames,', ')),'info');
            
            % print end comment
            log(this.hDebug,sprintf('Comment ''%s''',this.userEndComment),'info');
            
            % determine the units of neural times
            neuralTimeInSamples = (nnz(diff(this.data.neuralTime)>=1)/(numel(this.data.neuralTime)-1)) > 0.99;
            neuralTimeInSerialDatenum = (nnz(diff(this.data.neuralTime)<1e-4)/(numel(this.data.neuralTime)-1)) > 0.99;
            if neuralTimeInSamples
                this.data.neuralTime = this.data.neuralTime/this.eventFs;
            elseif neuralTimeInSerialDatenum
                this.data.neuralTime = [0; cumsum(seconds(diff(this.data.neuralTime(:)))*36*2400)];
            end
            
            if ~this.neuralSourceIsSimulated
                [list,~,nfile] = availableNeuralDataTypes(this,this.nspNames{1});
                list = util.ascell(list);
                nfile = util.ascell(nfile);
                for kk=1:length(list)
                    if isempty(list{kk}),continue;end
                    if strcmpi(list{kk}(1:2),'ns')
                        this.eventFs = Blackrock.readNSxHeader(nfile{kk},'TimestampTimeResolution');
                        break;
                    end
                end
            end
            
            % convert samples into times
            this.trialTimes = zeros(this.numTrials,2);
            this.phaseTimes = zeros(this.numTrials,this.numPhases);
            if this.numPhases>0
                this.phaseTimes = getPhaseTime(this);
            end
            if this.numTrials>0
                [this.trialTimes(:,1),this.trialTimes(:,2)] = getTrialTime(this);
            end
            for tt=1:this.numTrials
                this.trialdata(tt).TrialParams = getTrialParams(this,tt);
            end
            
            % detect whether optical pulse was recorded
            this.opticalPulsePresent = false;
            if isfield(this.data,'sync')
                this.opticalPulsePresent = any(nnz(this.data.sync));
            elseif isfield(this.data,'lightMeter')
                this.opticalPulsePresent = ~isempty(this.data.lightMeter);
            end
            if this.opticalPulsePresent
                log(this.hDebug,'Optical sync pulse found (must call @processOpticalTiming to evaluate lag)','info');
            else
                log(this.hDebug,sprintf('Optical sync pulse NOT found (will use default lag %g sec)',this.defaultOpticalPulseLag),'warn');
            end
            % if ~flagFastLoad && this.numTrials>0
            %     processOpticalTiming(this);
            % end
        end % END function FrameworkTask
        
        function processBlockStructure(this)
            % PROCESSBLOCKSTRUCTURE Process task elements specific to block
            
            % number of blocks
            this.numBlocks = length(fw.Block);
            log(this.hDebug,sprintf('Loading block %d/%d',this.block,this.numBlocks),'info');
            
            % pull out high-level framework data
            if isfield(fw.Block(this.block),'idString')
                this.idString = fw.Block(this.block).idString;
            else
                [~,this.idString] = fileparts(fwfile);
            end
            if isfield(fw.Block(this.block),'Runtime')
                if isfield(fw.Block(this.block).Runtime,'baseFilename')
                    this.taskString = fw.Block(this.block).Runtime.baseFilename;
                end
                this.runtime = fw.Block(this.block).Runtime;
            else
                [~,this.taskString] = fileparts(fwfile);
            end
            if isfield(fw.Block(this.block),'Options')
                if isfield(fw.Block(this.block).Options,'runName')
                    this.taskName = fw.Block(this.block).Options.runName;
                else
                    parts = strsplit(fw.Block(this.block).Options.taskConstructor,'.');
                    if strcmpi(parts{1},'Experiment')
                        this.taskName = parts{3};
                    elseif strcmpi(parts{1},'Experiment2')
                        this.taskName = parts{2};
                    elseif strcmpi(parts{1},'Task')
                        this.taskName = parts{2};
                    else
                        error('Unknown task package ''%s''',parts{1});
                    end
                end
                if isfield(fw.Block(this.block).Options,'taskConfig') && ~isempty(fw.Block(this.block).Options.taskConfig)
                    if iscell(fw.Block(this.block).Options.taskConfig)
                        parts = strsplit(fw.Block(this.block).Options.taskConfig{1},'.');
                        this.parameterName = parts{end};
                    elseif ischar(fw.Block(this.block).Options.taskConfig)
                        parts = strsplit(fw.Block(this.block).Options.taskConfig,'.');
                        this.parameterName = parts{end};
                    else
                        error('Unknown data type ''%s'' for taskConfig',class(fw.Block(this.block).Options.taskConfig));
                    end
                end
                this.options = fw.Block(this.block).Options;
            end
            if isfield(fw.Block(this.block),'Data')
                if isfield(fw.Block(this.block).Data,'comments')
                    cmt = fw.Block(this.block).Data.comments{end}{2};
                    if contains(cmt,' : ')
                        this.userEndComment = cmt((strfind(cmt,' : ')+3):end);
                    end
                end
                this.data = fw.Block(this.block).Data;
            end
            if isfield(fw.Block(this.block),'Predictor')
                this.predictor = fw.Block(this.block).Predictor;
            elseif isfield(fw.Block(this.block),'Decoder')
                this.predictor = fw.Block(this.block).Decoder;
            end
            if isfield(fw.Block(this.block),'NeuralSource')
                this.neuralSource = fw.Block(this.block).NeuralSource;
            end
            if isfield(fw.Block(this.block),'Task')
                this.task = fw.Block(this.block).Task;
            end
            
            % look for other fields that haven't been processed
            block_fields = fieldnames(fw.Block(this.block));
            idx_processed = ismember(block_fields,{'Task','NeuralSource','Predictor','Decoder','Data','Options','idString','Runtime'});
            idx_unproc = find(~idx_processed);
            for kk=1:length(idx_unproc)
                this.other.(block_fields{idx_unproc(kk)}) = fw.Block(this.block).(block_fields{idx_unproc(kk)});
            end
        end % END function processBlockStructure
        
        function [tm,len] = getPhaseTime(this,trials,phases,units)
            % GETPHASETIME Get the timing of each trial
            %
            %  [TM,LEN] = GETPHASETIME(THIS)
            %  Get the start time TM and the length LEN of each phase in
            %  each trial in the task.
            %
            %  [TM,LEN] = GETPHASETIME(THIS,TRIALS)
            %  Specify the numerical index of a subset of trials for which
            %  the phase times will be returned.
            %
            %  [TM,LEN] = GETPHASETIME(THIS,TRIALS,PHASES)
            %  Specify the numerical index of a subset of phases, or the
            %  names of a subset of trials (see property 'phaseNames') for
            %  which the timing will be returned.
            %
            %  [TM,LEN] = GETPHASETIME(THIS,TRIALS,PHASES,UNITS)
            %  Specify the unit of the timing outputs. UNITS may take the
            %  following values: 'seconds', 'samples', or 'frames'. The
            %  default unit is 'seconds'.
            
            % check for odd/rare conditions that cause problems
            idx = arrayfun(@(x)find(diff(this.data.neuralTime(:,x))<0),1:size(this.data.neuralTime,2),'UniformOutput',false); % account for multiple arrays (as multiple columns)
            num_restart = cellfun(@length,idx); % look for restarts (indices where clock goes backwards)
            num_restart_beginning = cellfun(@(x)nnz(x<100),idx); % count how many of the restarts occurred within 100 samples
            assert(all(num_restart==0)||all(num_restart_beginning==num_restart),'Neural time restarted during task - must handle manually'); % assert than no restarts happened, or that all were at the beginning (i.e. for nsp sync)
            
            % process inputs
            if nargin<4||isempty(units),units='seconds';end
            assert(ischar(units),'Units must be of type char, not ''%s''',class(units));
            assert(any(strcmpi(units,{'seconds','samples','frames'})),'Invalid units input ''%s'' (allowed values are ''samples'', ''seconds'', or ''frames'')',units);
            
            % set up trials
            if nargin<=1 || isempty(trials)
                trials = 1:this.numTrials;
            end
            if islogical(trials)
                assert(length(trials)==this.numTrials,'Invalid logical trial indexing');
                trials = find(trials);
            end
            
            % set up phases
            if nargin<=2 || isempty(phases)
                phases = 1:this.numPhases;
            end
            if islogical(phases)
                assert(length(phases)==this.numPhases,'Invalid logical phase indexing');
                phases = find(phases);
            end
            if ischar(phases)
                phases = find(strcmpi(this.phaseNames,phases));
                assert(~isempty(phases),'Could not identify phase ''%s''',phases);
            elseif iscell(phases)
                orig = phases;
                phases = nan(1,length(orig));
                for pp=1:length(orig)
                    tmp = find(strcmpi(this.phaseNames,orig{pp}));
                    assert(~isempty(tmp),'Could not identify phase ''%s''',orig{pp});
                    phases(pp) = tmp;
                end
            end
            assert(isnumeric(phases)&&min(phases)>=1&&max(phases)<=this.numPhases,...
                'Must provide phase name(s) as char or cell array of chars, or phase indices as vector of indices');
            
            % loop over trials
            tm = nan(length(trials),length(phases));
            len = nan(length(trials),length(phases));
            nt = this.data.neuralTime;
            if length(nt)<this.numFrames
                nt = [nt; nt(end)+mode(diff(nt))];
            end
            for tt=1:length(trials)
                tr = trials(tt);
                trdata = this.trialdata(tr);
                if isempty(trdata.et_phase),continue;end
                
                % loop over phases
                for pp=1:length(phases)
                    ph = phases(pp);
                    
                    % get the phase start frame ID
                    idx1 = [true; false(length(this.data.frameId)-1,1)];
                    if isnan(trdata.et_phase(ph)),continue;end
                    if trdata.et_phase(ph)>0
                        idx1 = this.data.frameId==trdata.et_phase(ph);
                    end
                    
                    % get the next phase start frame ID
                    if ph<length(trdata.et_phase) && ~isnan(trdata.et_phase(ph+1))
                        idx2 = this.data.frameId==trdata.et_phase(ph+1);
                    else
                        idx2 = this.data.frameId==trdata.et_trialCompleted;
                    end
                    
                    % calculate the trial start and length in neural times
                    if strcmpi(units,'frames')
                        tm(tt,pp) = find(idx1,1,'first');
                        len(tt,pp) = diff(find(idx1|idx2))+1;
                    else
                        try
                            tm(tt,pp) = nt(idx1);
                            if idx1==idx2
                                len(tt,pp) = 0;
                            else
                                len(tt,pp) = diff(nt(idx1|idx2));
                            end
                        catch ME
                            util.errorMessage(ME);
                            keyboard
                        end
                    end
                end
            end
            
            % convert units if needed
            if strcmpi(units,'samples')
                tm = round(tm*this.eventFs);
                len = round(len*this.eventFs);
            end
        end % END function getPhaseTime
        
        function [tm,len] = getTrialTime(this,trials,units)
            % GETTRIALTIME Get the timing of each trial
            %
            %  [TM,LEN] = GETTRIALTIME(THIS)
            %  Get the start time TM and the length LEN of each trial in
            %  the task.
            %
            %  [TM,LEN] = GETTRIALTIME(THIS,TRIALS)
            %  Specify the numerical index of a subset of trials for which
            %  the trial start time and length will be returned.
            %
            %  [TM,LEN] = GETTRIALTIME(THIS,TRIALS,UNITS)
            %  Specify the unit of the timing outputs. UNITS may take the
            %  following values: 'seconds', 'samples', or 'frames'. The
            %  default unit is 'seconds'.
            
            % check for odd/rare conditions that cause problems
            idx = arrayfun(@(x)find(diff(this.data.neuralTime(:,x))<0),1:size(this.data.neuralTime,2),'UniformOutput',false);
            num_restart = cellfun(@length,idx);
            restart_beginning = cellfun(@(x)isempty(x)||all(x<100),idx);
            assert(all(num_restart==0)||all(restart_beginning),'Neural time restarted during task - must handle manually');
            
            % process inputs
            if nargin<3||isempty(units),units='seconds';end
            assert(ischar(units),'Units must be of type char, not ''%s''',class(units));
            assert(any(strcmpi(units,{'seconds','samples','frames'})),'Invalid units input ''%s'' (allowed values are ''samples'', ''seconds'', or ''frames'')',units);
            
            % set up trials
            if nargin<2||isempty(trials),trials=1:this.numTrials;end
            if islogical(trials)
                assert(length(trials)==this.numTrials,'Invalid logical trial indexing');
                trials = find(trials);
            end
            
            % loop over trials
            tm = nan(length(trials),1);
            len = nan(length(trials),1);
            nt = this.data.neuralTime;
            if length(nt)<this.numFrames
                nt = [nt; nt(end)+mode(diff(nt))];
            end
            for tt=1:length(trials)
                try
                    
                    % get the trial start frame ID
                    tr = trials(tt);
                    if isfield(this.trialdata(tr),'et_trialStart')
                        fld_start = 'et_trialStart';
                        fld_completed = 'et_trialCompleted';
                    elseif isfield(this.trialdata(tr),'eT_trialStart')
                        fld_start = 'eT_trialStart';
                        fld_completed = 'eT_trialCompleted';
                    end
                    if isempty(this.trialdata(tr).(fld_start)),continue;end
                    if this.trialdata(tr).(fld_start)==0
                        idx_st = false(this.numFrames,1);
                        idx_st(1) = true;
                    else
                        idx_st = this.data.frameId==this.trialdata(tr).(fld_start);
                    end
                    assert(nnz(idx_st)==1,'Multiple frames match trial start time');
                    
                    % get the trial completion frame ID
                    idx_lt = this.data.frameId==this.trialdata(tr).(fld_completed);
                    assert(nnz(idx_lt)==1,'Multiple frames match trial completion time');
                    
                    % calculate the trial start and length in neural times
                    if strcmpi(units,'frames')
                        tm(tt) = find(idx_st,1,'first');
                        len(tt) = diff(find(idx_st|idx_lt))+1;
                    else
                        tm(tt) = nt(idx_st);
                        len(tt) = diff(nt(idx_st|idx_lt));
                    end
                catch ME
                end
            end
            
            % convert units if needed
            if strcmpi(units,'samples')
                tm = round(tm*this.eventFs);
                len = round(len*this.eventFs);
            end
        end % END function getTrialTime
        
        function prm = getTrialParams(this,trials)
            % GETTRIALPARAMS Get the trial parameters
            %
            %  PRM = GETTRIALPARAMS(THIS)
            %  Retrieve the struct array containing parameters for each
            %  trial.
            %
            %  PRM = GETTRIALPARAMS(THIS,TRIALS)
            %  Specify the numerical index of a subset of trials for which
            %  to retrieve parameters in the struct array PRM.
            
            prm = [];
            if nargin<=1
                trials = 1:this.numTrials;
            end
            if ~isempty(this.trialparams)
                if this.numTrials > length(this.trialparams)
                    prm = this.trialparams;
                else
                    prm = this.trialparams(trials);
                end
            end
        end % END function getTrialParams
        
        function prm = getTaskParams(this)
            prm = [];
            if isfield(this.task,'params')
                prm = this.task.params;
            end
        end % END function getTaskParams
        
        function processOpticalTiming(this,method)
            % PROCESSOPTICALTIMING Interpolate lag from optical sync
            %
            %  PROCESSOPTICALTIMING(THIS)
            %  Calculate the difference in Framework and optical timing for
            %  each sync pulse available in the data. Populate relevant
            %  properties of the FRAMEWORKTASK object, including an
            %  interpolated value of lag for each Framework timer period.
            if nargin<2||isempty(method),method='file_mean';end
            assert(ischar(method),'Must provide string input for method, not ''%s''',class(method));
            if ~this.opticalPulsePresent
                log(this.hDebug,'No optical pulse recorded: setting processed to TRUE.','warning');
                this.opticalProcessed = true;
                return;
            end
            
            % get data objects
            try
                ns = getNeuralDataObject(this,'ns5',this.hDebug);
            catch ME
                msg = util.errorMessage(ME,'noscreen','nolink');
                log(this.hDebug,sprintf('Could not find the NS5 files with light sensor data: %s',msg),'error');
                this.opticalProcessed = true;
                return;
            end
            
            % process Framework data
            if isfield(this.data,'sync')
                fwOptical = this.data.sync;
            elseif isfield(this.data,'lightMeter')
                fwOptical = false(1,this.numFrames);
                fwOptical(this.data.lightMeter) = true;
                fwOptical = zscore(fwOptical);
            else
                log(this.hDebug,'No light sensor data available','error');
                this.opticalProcessed = true;
                return;
            end
            fwTrialStart = min([this.trialdata.et_trialStart]);
            fwTrialStart = max(1,fwTrialStart); % no zeros
            fwTrialEnd = max([this.trialdata.et_trialCompleted]); % doing it this way avoids possible empty struct fields
            fwPulses = find(diff(fwOptical)>0)+1;
            fwPulses(find(diff(fwPulses)<=5)+1) = [];
            fwPulses( fwPulses<fwTrialStart | fwPulses>=fwTrialEnd ) = [];
            fwTrialStartTime = this.data.neuralTime(fwTrialStart);
            fwTrialEndTime = this.data.neuralTime(fwTrialEnd);
            tmpPulseTimes = this.data.neuralTime(fwPulses);
            this.fwPulseFrames = fwPulses(:);
            this.fwPulseTimes = tmpPulseTimes(:);
            
            % loop over arrays
            this.nsPulseTimes = cell(1,this.numNSPs);
            for kk=1:this.numNSPs
                if isempty(ns{kk}) || ~isa(ns{kk},'Blackrock.NSx')
                    log(this.hDebug,sprintf('No light sensor data available for array ''%s''',this.nspNames{kk}),'warn');
                    this.nsPulseTimes{kk} = nan;
                    continue;
                end
                
                % read ns5 data
                if isfield(this.data,'sync')
                    nsOptical = ns{kk}.read('channel','lightSensor','normalized');
                elseif isfield(this.data,'lightMeter')
                    nsOptical = ns{kk}.read('normalized');
                else
                    log(this.hDebug,'No light sensor data available','error');
                    this.nsPulseTimes{kk} = nan;
                    continue;
                end
                
                % check for bad data
                if max(abs(nsOptical(:)))<1e4
                    log(this.hDebug,sprintf('Bad recording of optical trigger on NSP ''%s'' (will copy data from other NSP if available)',this.nspNames{kk}),'warn');
                    this.nsPulseTimes{kk} = nan;
                    continue;
                end
                
                % process NS5
                nsOptical = zscore(nsOptical);
                [~,packet] = max(ns{kk}.PointsPerDataPacket);
                nsTime = ns{kk}.Timestamps(packet)/ns{kk}.TimestampTimeResolution + (0:length(nsOptical)-1)/this.eventFs;
                nsPulses = find(diff(nsOptical)>1)+1;
                nsPulses( find(diff(nsPulses)<=5)+1) = []; % remove indices that are within 5 samples of each other
                nsPulses( nsTime(nsPulses)<fwTrialStartTime | nsTime(nsPulses)>fwTrialEndTime ) = []; % remove pulses before trials began or after trials ended
                nsPulses( nsOptical(nsPulses-5)>1 ) = []; % remove indices on falling edge
                tmpPulseTimes = nsTime(nsPulses);
                this.nsPulseTimes{kk} = tmpPulseTimes(:);
                
                % validate
                if length(this.nsPulseTimes{kk})~=length(this.fwPulseFrames)
                    log(this.hDebug,sprintf('Mismatched number of pulses inferred from Framework (%d) and NS5 file (%d) (marked as bad)',length(this.fwPulseFrames),length(this.nsPulseTimes{kk})),'warn');
                    this.nsPulseTimes{kk} = nan;
                    continue;
                end
            end
            
            % check for the bad data condition
            numNans = cellfun(@(x)nnz(isnan(x)),this.nsPulseTimes);
            isEmpty = cellfun(@isempty,this.nsPulseTimes);
            if all(numNans==1) || all(isEmpty)
                log(this.hDebug,sprintf('No good optical trigger recordings; removing all relevant data from object properties'),'warn');
                this.fwPulseFrames = [];
                this.fwPulseTimes = [];
                this.nsPulseTimes = [];
            elseif nnz(numNans==1)==1 && this.numNSPs>1
                badNSP = numNans==1;
                goodNSP = find(numNans~=1,1,'first');
                this.nsPulseTimes{badNSP} = this.nsPulseTimes{goodNSP};
            end
            
            % update optical processed flag
            this.opticalProcessed = true;
        end % END function processOpticalTiming
        
        function lag = getLag(this,win,method,arrays)
            % GETLAG Get the lag from Framework to display
            %
            %   LAG is a positive value indicating the amount of time by
            %   which the Framework time *precedes* the display time. It is
            %   measured using an optical detector to sense when a small
            %   square on the task display becomes bright. Specifically,
            %   the Framework records NSP timestamps associated with its
            %   commands to change the square's brightness. An optical
            %   detector converts the brightness of that area on the task
            %   display into a low or high voltage signal, and the NSP
            %   records that voltage through its analog inputs. The time
            %   difference between these two pulse trains becomes LAG.
            %
            %   LAG = GETLAG(THIS)
            %   Calculate the average lag for the entire file for both
            %   arrays. LAG will be a cell array with one value per array
            %   (if there are more than one arrays) or a scalar value (if
            %   only one array).
            %
            %   LAG = GETLAG(THIS,WIN)
            %   Specify the window of time as [START END], in seconds,
            %   over which to calculate the lag. Provide empty WIN for
            %   default (the whole file).
            %
            %   LAG = GETLAG(THIS,WIN,METHOD)
            %   Specify the method to use in calculating the lag. Provide
            %   empty METHOD for default (average). Otherwise, the
            %   following methods are available:
            %
            %     Interpolation of instantaneous lags
            %     -----------------------------------
            %     interp_linear - "linear" option for INTERP1
            %     interp_nearest - "nearest" option for INTERP1
            %     interp_next - "next" option for INTERP1
            %     interp_previous - "previous" option for INTERP1
            %     interp_pchip - "pchip" option for INTERP1
            %     interp_cubic - "cubic" option for INTERP1
            %     interp_spline - "spline" option for INTERP1
            %
            %     Task-related lags
            %     -----------------
            %     file_mean - average all lags over the entire file
            %     file_median - median of all lags over entire file
            %     trial_mean - average of all lags within each trial
            %     trial_median - median of lags within each trial
            %     phase_mean - average of lags within each phase per trial
            %     phase_median - median of lags within each phase per trial
            %
            %     Constant values
            %     ---------------
            %     constant_value - return a constant value
            %
            %   The size of the output will vary based on the method
            %   selected. For file averages, output will be scalar. For
            %   trial averages, output will be vectors with one value per
            %   trial. For phase averages, output will be matrix with one
            %   row per trial and one column per phase. For interpolation,
            %   output will be vector with one entry per frame. In all
            %   cases, output will be limited by the timing specified in
            %   WIN.
            %
            %   LAG = GETLAG(THIS,WIN,METHOD,ARRAYS)
            %   Specify the array or arrays for which to calculate the
            %   lags. Indicate array names as strings matching entries in
            %   THIS.nspNames. Provide multiple array names as a cell
            %   array. Alternatively, provide arrays as numerical indices.
            %   Default is all available arrays.
            if nargin<2||isempty(win)
                win(1) = this.data.neuralTime(1);
                win(2) = this.data.neuralTime(end);
            end
            if nargin<3||isempty(method),method='file_mean';end
            if nargin<4||isempty(arrays),arrays=this.nspNames;end
            arrays = util.ascell(arrays);
            for kk=1:length(arrays)
                if isnumeric(arrays{kk})
                    assert(ismember(arrays{kk},1:this.numNSPs),'If numerical, must provide a valid array index (%d is not in %s)',arrays{kk},util.vec2str(1:this.numNSPs));
                    arrays{kk}=this.nspNames{arrays{kk}};
                end
            end
            for kk=1:length(arrays)
                assert(ischar(arrays{kk}),'Must provide char array input, not ''%s''',class(arrays{kk}));
                assert(any(strcmpi(arrays{kk},this.nspNames)),'Must provide valid array names as input (%s is not in %s)',arrays{kk},strjoin(this.nspNames,', '));
            end
            
            % process optical if not done yet
            if ~this.opticalProcessed
                processOpticalTiming(this);
            end
            
            % check for valid data to work with
            if isempty(this.nsPulseTimes) || ~iscell(this.nsPulseTimes) || length(this.nsPulseTimes)~=this.numNSPs
                log(this.hDebug,sprintf('Invalid NS pulse times, so returning the likely value %g for all electrode arrays',this.defaultOpticalPulseLag),'warn');
                lag = arrayfun(@(x)this.defaultOpticalPulseLag,1:length(arrays),'UniformOutput',false);
                if length(lag)==1,lag=lag{1};end
                return;
            end
            
            % compute frame indices for the requested window
            st = win(1);
            lt = 0;
            if length(win)>1,lt=win(2);end
            assert(st>=this.data.neuralTime(1),'Must provide starting time greater than %.3f',this.data.neuralTime(1));
            assert(lt<=this.data.neuralTime(end),'The block cannot extend past %.3f',this.data.neuralTime(end));
            
            % translate to framework indices
            fwst = find(this.data.neuralTime>=st,1,'first');
            fwlt = find(lt>=this.data.neuralTime,1,'last');
            
            % translate to pulse indices
            pulsest = find(this.fwPulseTimes>=st,1,'first');
            pulselt = find(lt>=this.fwPulseTimes,1,'last');
            
            % loop over arrays
            lag = cell(1,length(arrays));
            for kk=1:length(arrays)
                idxArray = strcmpi(this.nspNames,arrays{kk});
                
                % calculate lags, average lag
                lags = this.nsPulseTimes{idxArray} - this.fwPulseTimes;
                
                % parse out the method string
                assert(~isempty(strfind(method,'_')),'Method must be in the form UNIT_FCN where UNIT is file, trial, or phase and FCN is mean, median, or std');
                parts = strsplit(method,'_');
                
                % identify the function to use in the lag calculation
                switch lower(parts{2})
                    case {'mean','avg'},fn=@nanmean;
                    case 'median',fn=@nanmedian;
                    case 'std',fn=@nanstd;
                    case {'linear','nearest','next','previous','pchip','cubic','spline'},fn=parts{2};
                    otherwise
                        error('Unknown processing function ''%s''',parts{2});
                end
                
                % based on the base unit, identify lags and combine
                switch lower(parts{1})
                    case 'constant'
                        lag{kk} = this.defaultOpticalPulseLag;
                    case 'interp'
                        lag{kk} = interp1(this.fwPulseFrames,lags,this.data.frameId(fwst:fwlt),fn);
                    case 'file'
                        lag{kk} = fn(lags(pulsest:pulselt));
                    case 'trial'
                        t1 = find(this.trialTimes(:,1)>=st,1,'first');
                        t2 = find(lt>=(this.trialTimes(:,1)+this.trialTimes(:,2)),1,'last');
                        assert(~isempty(t1)&&~isempty(t2),'Must provide start and end times that include at least one whole trial');
                        lag{kk} = nan(t2-t1+1,1);
                        for tt=t1:t2
                            tr_start = this.trialTimes(tt,1);
                            tr_end = this.trialTimes(tt,1) + this.trialTimes(tt,2);
                            idx_pulse = this.fwPulseTimes>=tr_start & this.fwPulseTimes<tr_end;
                            if ~any(idx_pulse),continue;end
                            lag{kk}(tt-t1+1) = fn(lags(idx_pulse));
                        end
                    case 'phase'
                        t1 = find(this.trialTimes(:,1)>=st,1,'first');
                        t2 = find(lt>=(this.trialTimes(:,1)+this.trialTimes(:,2)),1,'last');
                        assert(~isempty(t1)&&~isempty(t2),'Must provide start and end times that include at least one whole trial');
                        lag{kk} = nan(t2-t1+1,this.numPhases);
                        for tt=t1:t2
                            for pp=1:this.numPhases
                                ph_start = this.phaseTimes(tt,pp);
                                if pp<this.numPhases
                                    ph_end = this.phaseTimes(tt,pp+1);
                                else
                                    ph_end = this.trialTimes(tt,1) + this.trialTimes(tt,2);
                                end
                                idx_pulse = this.fwPulseTimes>=ph_start & this.fwPulseTimes<ph_end;
                                if ~any(idx_pulse),continue;end
                                lag{kk}(tt-t1+1,pp) = fn(lags(idx_pulse));
                            end
                        end
                    otherwise
                        error('Unknown processing unit ''%s''',parts{1});
                end
            end
            
            % pull out of cell array if single value
            if length(arrays)==1
                lag = lag{1};
            end
        end % END function getLag
        
        function [data_type,nsp,fs,files] = availableNeuralDataTypes(this,varargin)
            % AVAILABLENEURALDATATYPES Get a list of available neural data
            %
            %  TYPES = AVAILABLENEURALDATATYPES(THIS)
            %  By default, return all available neural data types for all
            %  available arrays. The output TYPES will be a cell array,
            %  with one cell per array.
            %
            %  [TYPES,NSPS] = AVAILABLENEURALDATATYPES(...)
            %  Additionally return the list of NSPs.
            %
            %  [TYPES,NSPS,FS] = AVAILABLENEURALDATATYPES(...)
            %  Additionally return the list of sampling rates FS.
            %
            %  [TYPES,NSPS,FS,FILES] = AVAILABLENEURALDATATYPES(...)
            %  Additionally return the full path to the file corresponding
            %  to each of the entries in TYPES.
            %
            %  [...] = AVAILABLENEURALDATATYPES(...,TYPES)
            %  Specify a subset of the possible neural data types to be
            %  used in the search.
            %
            %  [...] = AVAILABLENEURALDATATYPES(...,NSPS)
            %  Specify a subset of the possible NSPs to be used in the
            %  search.
            %
            %  [...] = AVAILABLENEURALDATATYPES(...,FS)
            %  Specify a subset of the possible sampling rates to be used
            %  in the search.
            %
            %  SEE ALSO getNeuralDataObject.
            
            % check for empty basenames
            assert(~isempty(this.neuralBasenames),'Neural basenames not defined');
            % process inputs
            [varargin,data_type] = util.argkeywords({'blc'},varargin,'blc');
            data_type = util.ascell(data_type);
            fs = cell(1,1);
            behav_data = cell(1,1);
            [varargin,behav_data] = util.argfns(@(x)ischar(x)&&~isempty(regexpi(x,'^.*(Mic\w+\-fs\d+k?|Opt\w+\-fs\d+k?).*$')),varargin,'');
            [varargin,fs] = util.argfns(@(x)ischar(x)&&~isempty(regexpi(x,'^fs\d+k?$')),varargin,'');
            if isempty(fs) && isempty(behav_data)
                list = dir(fullfile(this.sessionPath,'data','*fs*.*'));
                fs = unique(regexprep({list.name},'^.*(fs\d+k?).*$','$1'));
                behav_ind = ~cellfun(@isempty,regexp({list.name},'^.*(Mic\w+\-fs\d+k?|Opt\w+\-fs\d+k?).*$'));
                behav_data = unique(regexprep({list(behav_ind).name},'^.*(Mic\w+\-fs\d+k?|Opt\w+\-fs\d+k?).*$','$1'));
            end
            fs = util.ascell(fs);
            [varargin,lmcontext] = util.argkeyval('lmcontext',varargin,'');
            lm_subdir = '';
            if ~isempty(lmcontext)
                lm_subdir = sprintf('lm_%s',lmcontext');
            end
            [varargin,lmresid] = util.argflag('lmresid',varargin,false);
            [varargin,lmfit] = util.argflag('lmfit',varargin,false);
            lm_str = '';
            if lmresid
                lm_str = '_lmresid';
            elseif lmfit
                lm_str = '_lmfit';
            end
            [varargin,nsp] = util.argkeywords(this.nspNames,varargin,this.nspNames);
            nsp = util.ascell(nsp);
            util.argempty(varargin);
            % loop over NSPs, data types, sampling rates
            data_types = cell(1,length(nsp)*length(fs)*length(data_type));
            nsps = cell(1,length(nsp)*length(fs)*length(data_type));
            fss = cell(1,length(nsp)*length(fs)*length(data_type));
            files = cell(1,length(nsp)*length(fs)*length(data_type)*length(behav_data));
            exists = false(1,length(nsp)*length(fs)*length(data_type));
            idx_files = 1;
            for aa=1:length(nsp)
                idx_nsp = ~cellfun(@isempty,regexpi(this.neuralBasenames,nsp{aa}));
                basename = this.neuralBasenames{idx_nsp};
                if ~isempty(fs)
                    for bb=1:length(fs)
                        for cc=1:length(data_type)
                            if ~isempty(lm_subdir)
                                fl = fullfile(this.sessionPath,'data',lm_subdir,sprintf('%s-%s%s.%s',basename,fs{bb},lm_str,data_type{cc}));
                            else
                                fl = fullfile(this.sessionPath,'data',sprintf('%s-%s%s.%s',basename,fs{bb},lm_str,data_type{cc}));
                            end
                            if exist(fl,'file')==2
                                files{idx_files} = fl;
                                exists(idx_files) = true;
                                data_types{idx_files} = data_type{cc};
                                fss{idx_files} = fs{bb};
                                nsps{idx_files} = nsp{aa};
                            end
                            idx_files = idx_files + 1;
                        end
                    end
                end
                if ~isempty(behav_data)
                    for bb=1:length(behav_data)
                        for cc=1:length(data_type)
                            if ~isempty(lm_subdir)
                                fl = fullfile(this.sessionPath,'data',lm_subdir,sprintf('%s-%s%s.%s',basename,behav_data{bb},lm_str,data_type{cc}));
                            else
                                fl = fullfile(this.sessionPath,'data',sprintf('%s-%s%s.%s',basename,behav_data{bb},lm_str,data_type{cc}));
                            end
                            if exist(fl,'file')==2
                                files{idx_files} = fl;
                                exists(idx_files) = true;
                                data_types{idx_files} = data_type{cc};
                                fss{idx_files} = fs{bb};
                                nsps{idx_files} = nsp{aa};
                            end
                            idx_files = idx_files + 1;
                        end
                    end
                end
            end
            
            % subsample type list
            files = files(exists);
            data_type = data_types(exists);
            fs = fss(exists);
            nsp = nsps(exists);
        end % END function availableNeuralDataTypes
        
        function obj = getNeuralDataObject(this,varargin)
            % GETNEURALDATAOBJECT Retrieve neural data associated with task
            %
            %  OBJ = GETNEURALDATAOBJECT(THIS)
            %  By default, returns the neural data object associated with
            %  all available neural data types from each available array.
            %  The output will be arranged in a cell array with one cell
            %  per array; each of these cells will be a cell array with one
            %  cell per available neural data type. The neural data objects
            %  will be of type Blackrock.NSx or Blackrock.NEV.
            %
            %  OBJ = GETNEURALDATAOBJECT(...,NSPS)
            %  Specify a single char or cell array of chars indicating
            %  NSP names. These strings must match (case-insensitive)
            %  with an entry in the property 'nspNames'.
            %
            %  OBJ = GETNEURALDATAOBJECT(...,TYPES)
            %  Specify a single char or cell array of chars indicating
            %  neural data types.
            %
            %  OBJ = GETNEURALDATAOBJECT(...,VARARGIN)
            %  Any input not matching the above configurations will be
            %  passed along to the constructor(s) of the requested neural
            %  data objects.
            %
            %  SEE ALSO AVAILABLENEURALDATATYPES, Blackrock.NSx,
            %  Blackrock.NEV.
            if this.neuralSourceIsSimulated
                log(this.hDebug,'Neural source is simulated','warn');
                obj = [];
                return;
            end
            [varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,[]);
            if ~found_debug,debug=this.hDebug;end
            
            % get list of files
            [data_type,~,~,files] = availableNeuralDataTypes(this,varargin{:});
            obj = cell(1,length(files));
            for ff=1:length(files)
                switch lower(data_type{ff})
                    case 'blc'
                        obj{ff} = BLc.Reader(files{ff},debug);
                end
            end
        end % END function getNeuralDataObject
        
        function obj = getGridMapObject(this,varargin)
            % GETGRIDMAPOBJECT Retrieve neural data associated with task
            %
            %  OBJ = GETGRIDMAPOBJECT(THIS)
            %  By default, returns the array map object associated with all
            %  available arrays. The output will be arranged in a cell
            %  array with one cell per array. The array map objects will be
            %  of type Blackrock.ArrayMap.
            %
            %  OBJ = GETGRIDMAPOBJECT(...,NSPS)
            %  Specify a single char or cell array of chars indicating
            %  array names. These strings must match (case-insensitive)
            %  with an entry in the property 'nspNames'.
            %
            %  OBJ = GETGRIDMAPOBJECT(...,VARARGIN)
            %  Any input not matching the above configurations will be
            %  passed along to the constructor(s) of the requested array
            %  map objects.
            %
            %  SEE ALSO availableNeuralDataTypes, Blackrock.NSx,
            %  Blackrock.NEV.
            if this.neuralSourceIsSimulated
                log(this.hDebug,'Neural source is simulated','warn');
                obj = [];
                return;
            end
            [~,~,~,files] = availableNeuralDataTypes(this,varargin{:});
            obj = cell(1,length(files));
            for ff=1:length(files)
                [fdir,fbase] = fileparts(files{ff});
                fbase = regexprep(fbase,'^(.*)-fs\d+k?(.*)$','$1$2');
                mapfile = fullfile(fdir,sprintf('%s.map',fbase));
                assert(exist(mapfile,'file')==2,'Could not find map file "%s"',mapfile);
                obj{ff} = GridMap(mapfile);
            end
        end % END function getArrayMapObject
        
        function [ok,errfw,errnev,avglag,lags,featdef,featlbl,optlag] = checkTiming(this,verbosity)
            % CHECKTIMING Analyze the timing of the Framework's inner loop
            %
            %   OK = CHECKTIMING(THIS)
            if nargin<2||isempty(verbosity)
                verbosity = false;
            end
            
            % default output values if neural source is simulated
            ok2 = true;
            ok3 = true;
            ok4 = true;
            errnev = nan;
            avglag = nan;
            lags = nan;
            featdef = [];
            featlbl = {};
            
            % run framework timing analysis
            [ok1,errfw] = checkFrameworkTiming(this,verbosity);
            
            % check neural, framework-neural timing analysis
            if ~this.neuralSourceIsSimulated
                [ok2,errnev] = checkNeuralTiming(this,verbosity);
%                 [ok3,avglag,lags,featdef,featlbl] = checkFrameworkNeuralTiming(this,verbosity);
                if this.opticalPulsePresent
                    [ok4,optlag] = checkOpticalTiming(this,verbosity);
                end
            end
            
            % all ok or not
            ok = ok1 & ok2 & ok3 & ok4;
        end % END function checkTiming
        
        function [ok,err] = checkFrameworkTiming(this,verbosity)
            if nargin<2||isempty(verbosity)
                verbosity = false;
            end
            
            % identify Framework's cycle time
            fwdt = this.options.timerPeriod;
            
            % computer time: results of "now" command
            ctime_orig = this.data.computerTime;
            ctime_orig = rem(ctime_orig,1); % get just the fractional part
            ctime_orig = ctime_orig*1e3*60*60*24; % convert to number of milliseconds
            ctime = diff(ctime_orig);
            
            % elapsed time: results of tic/toc
            if isfield(this.data,'elapsedTime')
                etime_orig = 1e3*this.data.elapsedTime;
                etime = diff(etime_orig);
            else
                etime_orig = ctime_orig;
                etime = ctime;
            end
            
            % arbitrary measure of things being okay (10% error)
            err = abs((mode(etime)/1e3 - fwdt)/fwdt);
            ok = err <= 0.1;
            okstr = sprintf('OK (timing error %.2f <= 0.1)',err);
            if ~ok,okstr = sprintf('NOT OK (timing error %.2f > 0.1)',err);end
            
            % generate plots
            if verbosity
                fig = plt.sighist('box',[0 0.5 1 0.5],[ctime(:) etime(:)],...
                    'title','Framework Timer Intervals and Histogram',...
                    'legend',{'Interval (now)','Interval (tic-toc)'},...
                    'sigylabel','Time (msec)');
                plt.sighist(fig,'box',[0 0 1 0.5],ctime-etime,...
                    'legend',{'Difference (msec)'},...
                    'sigylabel','Time (msec)',...
                    'sigxlabel','Framework cycle');
                
                fprintf('\n\n');
                fprintf('Framework Timing: %s\n',okstr);
                fprintf('---------------------------\n');
                
                % report difference between computer time and elapsed time
                fprintf('Computer Time (now):    %.3f sec, [% 5.4f,% 5.4f] sec\n',sum(ctime/1e3),0,diff(ctime_orig([1 end]))/1e3);
                fprintf('Elapsed Time (tic/toc): %.3f sec, [% 5.4f,% 5.4f] sec\n',sum(etime/1e3),0,diff(etime_orig([1 end]))/1e3);
                fprintf('Difference: %.3f msec\n',abs(sum(ctime)-sum(etime)));
                
                % report distribution stats
                errfn = @(vec,thresh)100*nnz(abs(vec-1e3*fwdt) <= thresh) / numel(vec);
                fprintf('%.2f%% / %.2f%% of the data are within 0.1 msec of the target %d msec\n',errfn(ctime,0.1),errfn(etime,0.1),1e3*fwdt);
                fprintf('%.2f%% / %.2f%% of the data are within 1.0 msec of the target %d msec\n',errfn(ctime,1),errfn(etime,1),1e3*fwdt);
                fprintf('%.2f%% / %.2f%% of the data are within 10.0 msec of the target %d msec\n',errfn(ctime,10),errfn(etime,10),1e3*fwdt);
                
                % print basic information
                fprintf('Requested Interval:     %.3f seconds\n',fwdt);
                fprintf('Interval Mode (ct/et):  %.3f / %.3f msec\n',mode(ctime)/1e3,mode(etime)/1e3);
                fprintf('Interval Mean (ct/et):  %.3f / %.3f ± %.3f / %.3f seconds\n',mean(ctime)/1e3,mean(etime)/1e3,std(ctime)/1e3,std(etime)/1e3);
            end
        end % END function checkFrameworkTiming
        
        function [ok,err] = checkNeuralTiming(this,verbosity)
            ok = false;
            
            if this.neuralSourceIsSimulated
                log(this.hDebug,'Neural source is simulated','warn');
                return;
            end
            if nargin<2||isempty(verbosity)
                verbosity = false;
            end
            
            % identify Framework's cycle time
            fwdt = this.options.timerPeriod;
            
            % computer time: results of "now" command
            ntime = 1e3*diff(this.data.neuralTime);
            
            % handle case where cbmex returns same timestamp in consecutive frames
            same_idx = find(diff(this.data.neuralTime)==0)+1;
            if ~isempty(same_idx)
                log(this.hDebug,sprintf('Found %d instances of nonincreasing timestamps returned by CBMEX',length(same_idx)),'warn');
            end
            
            % arbitrary measure of things being okay (10% error)
            err = abs(mode(ntime)/1e3 - fwdt)/fwdt;
            ok = err <= 0.1;
            okstr = sprintf('OK (timing error %.2f <= 0.1)',err);
            if ~ok,okstr = sprintf('NOT OK (timing error %.2f > 0.1)',err);end
            
            % generate plots
            if verbosity
                plt.sighist(ntime(:),...
                    'legend',{'Interval (neural)'},...
                    'sigylabel','Time (msec)',...
                    'title','Neural Timestamp Intervals and Histogram',...
                    'sigxlabel','Framework cycle');
                
                fprintf('\n\n');
                fprintf('Neural Timing: %s\n',okstr);
                fprintf('------------------------\n');
                
                % report distribution stats
                errfn = @(vec,thresh)100*nnz(abs(vec-1e3*fwdt) <= thresh) / numel(vec);
                fprintf('%.2f%% of the data are within 0.1 msec of the target %d msec\n',errfn(ntime,0.1),1e3*fwdt);
                fprintf('%.2f%% of the data are within 1.0 msec of the target %d msec\n',errfn(ntime,1),1e3*fwdt);
                fprintf('%.2f%% of the data are within 10.0 msec of the target %d msec\n',errfn(ntime,10),1e3*fwdt);
                
                % print basic information
                fprintf('%.3f sec, [%5.4f,% 8.4f] sec\n',sum(ntime/1e3),this.data.neuralTime(1),this.data.neuralTime(end));
                fprintf('Requested Interval: %.3f seconds\n',fwdt);
                fprintf('Interval Mode:      %.3f seconds\n',mode(ntime)/1e3);
                fprintf('Interval Mean:      %.3f ± %.3f seconds\n',mean(ntime)/1e3,std(ntime)/1e3);
            end
        end % END function checkNeuralTiming
        
        function [ok,avglag,lags,featdef,featlbl] = checkFrameworkNeuralTiming(this,verbosity)
            %
            %   [OK,AVGLAG,LAGS] = CHECKTIMING(THIS)
            if nargin<2||isempty(verbosity)
                verbosity = false;
            end
            
            % get binned NEV data
            nv = this.getNeuralDataObject('nev',this.hDebug);
            timestamps = cell(1,this.numNSPs);
            channels = cell(1,this.numNSPs);
            units = cell(1,this.numNSPs);
            for kk=1:this.numNSPs
                spk = nv{kk}.read;
                timestamps{kk} = spk.Timestamps/nv{kk}.ResolutionTimestamps;
                channels{kk} = spk.Channels;
                units{kk} = spk.Units;
            end
            params = Parameters.Dynamic(@Parameters.Config.SpikeSorting,...
                'spk.unsorted',true,'spk.noise',false,'spk.fs',nv{1}.ResolutionTimestamps,'spk.smooth',false,'spk.timestampunits','seconds');
            fwdt = this.options.timerPeriod;
            [allbin,nevt,featdef,featlbl] = proc.bin(timestamps,channels,units,fwdt,params);
            nevdt = mode(diff(nevt));
            
            % pull out framework data matching binned NEV data
            fwdata = this.data.features(:,featdef(:,3));
            
            % verify that they contain the same number of features
            assert(size(allbin,2)==size(fwdata,2),'Cannot handle the case where Framework features include sorted units or LFPs');
            
            % get timing data from NEV/Framework
            ntime = this.data.neuralTime;
            ntime_orig = ntime;
            assert(abs(fwdt-nevdt)<0.001,'Framework timing is not stable enough to continue (delta dt %.4f greater than 1 msec threshold)\n',abs(fwdt-nevdt));
            
            % computer time: results of "now" command
            ctime = this.data.computerTime;
            ctime = rem(ctime,1); % get just the fractional part
            ctime = ctime*1e3*60*60*24; % convert to number of milliseconds
            
            % handle case where cbmex returns same timestamp in consecutive frames
            same_idx = find(diff(ntime)==0)+1;
            if ~isempty(same_idx)
                fwdata(same_idx,:) = [];
                ntime(same_idx) = [];
            end
            
            % identify common start/end times
            st = nanmax(nevt(1),ntime(1));
            lt = nanmin(nevt(end),ntime(end));
            
            % calculate start and end indices for binned NEV data
            % contract indices by a few samples on each end because we'll
            % resample framework data to NEV timing below and need NEV
            % time range to be a subset of Framework time range
            nevst = find(nevt>=st,1,'first')+2;
            nevlt = find(nevt>=lt,1,'first')-2;
            assert(~isempty(nevst)&&~isempty(nevlt),'Could not identify start and end indices for binned NEV timing');
            
            % calculate start and end indices for Framework data
            fwst = find(ntime>=st,1,'first');
            fwlt = find(ntime>=lt,1,'first');
            assert(~isempty(fwst)&&~isempty(fwlt),'Could not identify start and end indices for Framework timing');
            
            % calculate cross-correlation lag for each channel
            lags = nan(1,size(featdef,1));
            numspk = nan(1,size(featdef,1));
            for kk=1:size(featdef,1)
                
                % pull out Framework data
                fwbin = fwdata(fwst:fwlt,kk);
                
                % smooth the framework data
                fwbin = proc.smooth(fwbin,'mj',struct('kernelwidth',0.25,'period',0.05));
                
                % resample framework data to match binned NEV timing
                fwbin = interp1(ntime(fwst:fwlt),fwbin,nevt(nevst:nevlt));
                
                % pull out binned NEV data and smooth
                nevbin = allbin(nevst:nevlt,kk);
                numspk(kk) = sum(nevbin);
                nevbin = proc.smooth(nevbin,'mj',struct('kernelwidth',0.25,'period',0.05));
                
                % calculate cross-correlation
                [rr,ll] = xcorr(fwbin(1:min(length(fwbin),length(nevbin))),nevbin(1:min(length(fwbin),length(nevbin))),'coeff');
                [~,idx] = max(rr);
                lags(kk) = ll(idx)*nevdt;
            end
            
            % calculate outliers and mean without outliers
            idx_outlier = util.outliers(lags,[15 85],1.5);
            idx_keep = setdiff(1:size(featdef,1),idx_outlier);
            avglag = mean(lags(idx_keep));
            
            % define "okay" (completely arbitrary)
            ok = avglag<=0.05;
            okstr = sprintf('OK (avglag %.3f <= 0.05)',avglag);
            if ~ok,okstr = sprintf('NOT OK (avglag > 0.05)');end
            
            % print final results
            if verbosity
                
                figure
                plot(diff(ctime),1e3*diff(ntime_orig),'x');
                xlabel('Framework Timer Interval (msec)');
                ylabel('Neural Timestamp Interval (msec)');
                title('Framework-Neural Timing Intervals');
                
                fprintf('\n\n');
                fprintf('Framework-Neural Timing: %s\n',okstr);
                fprintf('----------------------------------\n');
                fprintf('CBMEX Timestamps:  %.3f sec, [% 5.4f,% 5.4f] sec\n',sum(diff(ntime)),ntime(1),ntime(end));
                fprintf('NEV Spike Timing:  %.3f sec, [% 5.4f,% 5.4f] sec\n',sum(diff(nevt)),nevt(1),nevt(end));
                fprintf('CC Lag (mn ± sd): %+.3f ± %.3f msec\n',1e3*avglag,1e3*std(lags(idx_keep)));
                fprintf('%d outliers:\n',length(idx_outlier));
                for kk=1:length(idx_outlier)
                    fprintf('\tFeature %3d (NSP %1d, Channel %2d):\t%+8.3f seconds\n',idx_outlier(kk),featdef(idx_outlier(kk),strcmpi(featlbl,'nsp')),featdef(idx_outlier(kk),strcmpi(featlbl,'channel')),lags(idx_outlier(kk)));
                end
            end
        end % END function checkFrameworkNeuralTiming
        
    function [ok,lags] = checkOpticalTiming(this,verbosity)
% PROCESSOPTICALTIMING Interpolate lag from optical sync
%
%  PROCESSOPTICALTIMING(THIS)
%  Calculate the difference in Framework and optical timing for
%  each sync pulse available in the data. Populate relevant
%  properties of the FRAMEWORKTASK object, including an
%  interpolated value of lag for each Framework timer period.
%             if nargin<2||isempty(method),method='file_mean';end
%             assert(ischar(method),'Must provide string input for method, not ''%s''',class(method));
%             if ~opticalPulsePresent
%                 log(Debug,'No optical pulse recorded: setting processed to TRUE.','warning');
%                 opticalProcessed = true;
%                 return;
%             end
%
lags = 0;
ok = 0;
if isfield(this.data,'sync')
    blcOpticalSyncCell = this.getNeuralDataObject('nsp1','OpticalSync-fs30k');
    opticalReader = blcOpticalSyncCell{1};
    opticalSync = opticalReader.read();
    fwOptical = this.data.sync;
else
    log(this.hDebug,'No light sensor data available','error');
    this.opticalProcessed = true;
    this.nsPulseTimes = nan;
    return;
end

if ~isempty(this.task.TrialData)
    this.numNSPs=length(this.options.nsps);
    fwPulses = find(diff(fwOptical)>0)+1;
    fwPulses(find(diff(fwPulses)<=5)+1) = [];
    fwTime=this.data.neuralTime;
    fwTrialStart = max(1,min([this.task.TrialData.et_trialStart])); % no zeros
    fwTrialEnd = max([this.task.TrialData.et_trialCompleted]); % doing it this way avoids possible empty struct fields
    fwPulses( fwPulses<fwTrialStart | fwPulses>=fwTrialEnd ) = []; %making sure that the framework pulses start at the beginning of trial and end with trial
    fwTrialEndInd = [this.task.TrialData(1:end).et_trialCompleted];
    fwTrialStartTime = fwTime(fwTrialStart);
    fwTrialEndTime = fwTime(fwTrialEnd);
    this.fwPulseFrames = fwPulses(:);
    this.fwPulseTimes = fwTime(fwPulses);
    % check for bad data
    if max(abs(opticalSync(:)))<200
        log(this.Debug,sprintf('Bad recording of optical trigger on NSP ''%s'' (will copy data from other NSP if available)',this.nspNames{kk}),'warn');
    end
    opticalSyncTime = (0:length(opticalSync)-1)/opticalReader.SamplingRate;
    opticalSync = zscore(opticalSync);
    opticalSyncPulse = zeros(size(opticalSync));
    opticalSyncPulse(opticalSync>0.5) = 1;
    opticalPulseEdgeInd=find(abs(diff(opticalSyncPulse)) == 1);
    for ii = 1:length(opticalPulseEdgeInd)-1
        if opticalPulseEdgeInd(ii+1)-opticalPulseEdgeInd(ii) < 4000 % to avoid fringes with width less than 4000
            opticalSyncPulse(opticalPulseEdgeInd(ii):opticalPulseEdgeInd(ii+1)) = 0;
            narrowPulseEdgeInd(ii) = opticalPulseEdgeInd(ii);
        end
    end
    
    opticalPulseEdgeInd=setdiff(opticalPulseEdgeInd,narrowPulseEdgeInd);
    % remove pulses before trials began or after trials ended
    opticalPulseEdgeInd(opticalSyncTime(opticalPulseEdgeInd)<fwTrialStartTime | opticalSyncTime(opticalPulseEdgeInd)>fwTrialEndTime ) = [];
    if (opticalSyncTime(opticalPulseEdgeInd(1))-fwTrialStartTime<3)
        opticalPulseEdgeInd=opticalPulseEdgeInd(2:end);
    end
    % remove rising edges of pulse and preseve dropping edges of pulse
    opticalPulseEdgeInd = opticalPulseEdgeInd(1:2:end);
    pulseTimes = opticalSyncTime(opticalPulseEdgeInd);
    
    if any(diff(opticalSyncTime(opticalPulseEdgeInd))<1)
        indx=find(diff(opticalSyncTime(opticalPulseEdgeInd))<1)+1;
        opticalPulseEdgeInd(indx:end)=[opticalPulseEdgeInd(indx+1:end),find(opticalSyncTime==fwTrialEndTime)];
    end
    % validate
    if abs(length(opticalPulseEdgeInd)-length(this.fwPulseFrames))==1
        opticalPulseEdgeInd=[opticalPulseEdgeInd;find(opticalSyncTime==fwTrialEndTime)];
    elseif abs(length(opticalPulseEdgeInd)-length(this.fwPulseFrames))>1
        log(this.hDebug,sprintf('Mismatched number of pulses inferred from Framework (%d) and NS5 file (%d) (marked as bad)',length(this.fwPulseFrames),length(pulseTimes)),'warn');
        return;
    end
    %finding mean and std
    lags = opticalSyncTime(opticalPulseEdgeInd)-fwTime(fwTrialEndInd)';
    if any(lags<0)
        lags=0;
        return;
    end
    outlier = lags(isoutlier(lags,'quartiles'));
    if isempty(outlier)
        avglag = mean(lags);
        dev = std(lags);
        minlag = min(lags);
        maxlag = max(lags);
    else
        avglag = mean(setdiff(lags,outlier));
        dev = std(setdiff(lags,outlier));
        minlag = min(setdiff(lags,outlier));
        maxlag = max(setdiff(lags,outlier));
    end
    this.opticalProcessed = true;
    % define "okay" (completely arbitrary)
    ok = avglag<=50;
    okstr = sprintf('OK (avglag %.3f <= .05)',avglag);
    if ~ok,okstr = sprintf('NOT OK (avglag %.1f > 50)',avglag*1e3);end
    % print final results
    if verbosity
        fprintf('\n\n');
        fprintf('Optical Pulse Timing: %s\n',okstr);
        fprintf('----------------------------------\n');
        fprintf('(%s) Range of Lags : [%.3f %.3f] msec\n',this.nspNames{1},1e3*min(lags),1e3*max(lags));
        fprintf('(%s) Range of Lags (excluding outlier) : [%.3f %.3f] msec\n',this.nspNames{1},1e3*minlag,1e3*maxlag);
        fprintf('(%s) Average Lag  (excluding outlier) :    %.3f ± %.3f msec\n',this.nspNames{1},avglag*1e3,dev*1e3);
        % plot the time courses of both framework and neural optical pulses
        fig = figure('Position',[100 100 1600 800]);
        ax = axes('Position',[0.04 0.55 0.93 0.38]);
        plot(ax,fwTime,fwOptical);
        hold(ax,'on');
        plot(ax,opticalSyncTime,opticalSync);
        plot(ax,opticalSyncTime(opticalPulseEdgeInd(:)),opticalSyncPulse(opticalPulseEdgeInd(:)),'g*');
        xline(fwTrialStartTime,'k-.',{'Trial','Start'});
        xline(fwTrialEndTime,'k-.',{'Trial','End'});
        hold(ax,'off');
        title(sprintf('Framework and Neural Optical Pulse Records - %s : %s',this.subject,this.taskString));
        ax.XLim=[0,max(ceil(opticalSyncTime'/10))*10];
        xlabel('Time (sec)');
        ylabel('Amplitude (z-score)');
        legend(ax,{'Framework','Neural','Optical Pulses'});
        plt.sighist(fig,'box',[0 0 1 0.55],lags(:),...
            'legend',{'Difference (msec)'},...
            'title','Optical Pulse Differences and Histogram',...
            'sigylabel','Difference',...
            'sigxlabel','Pulse Index','hstxlabel','Frequency', 'sigxlim',[0 length(lags(:))+1],'hstnorm','count');
    end
else
    log(this.hDebug,sprintf('Empty TrialData'),'warn');
    return;
end

end % END function checkOpticalTiming
    end % END methods
end % END classdef FrameworkTask