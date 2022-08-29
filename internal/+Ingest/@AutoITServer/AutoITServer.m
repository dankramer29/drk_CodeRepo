classdef AutoITServer < handle
    properties
        hTimer % timer to check external program process
        autoITExecutablePath % path to auto IT executable
        autoITScriptPath % path to auto IT script
    end % END properties
    
    properties(Access=private)
        lhInterface % handles to event listeners
    end % END properties(Access=private)
    
    properties(SetAccess=private,GetAccess=public)
        stopwatch % for tic-toc
        eventTime % to measure time past an event
    end % END properties(SetAccess=private,GetAccess=public)
    
    events
        AutoITError % event that fires when AutoIT encounters an error
        AutoITFinished % event that fires when AutoIT finishes
    end % END events
    
    methods
        function this = AutoITServer(varargin)
            [varargin,this.autoITExecutablePath] = util.argkeyval('autoitpath',varargin,env.get('autoitpath'));
            [varargin,this.autoITScriptPath] = util.argkeyval('scriptpath',varargin,fullfile(env.get('code'),'internal','AutoIt','export_natus.au3'));
            util.argempty(varargin);
            
            % set up the timer
            this.hTimer = timer(...
                'ExecutionMode', 'fixedRate',...
                'Name', 'InterfaceTimer',...
                'Period', 5,...
                'TimerFcn', @timerTimerfcn,...
                'StartFcn', @timerStartfcn,...
                'StartDelay', 10);
            
            % validate inputs
            assert(exist(this.autoITExecutablePath,'file')==2,'Could not find AutoIT executable "%s"',this.autoITExecutablePath);
            assert(exist(this.autoITScriptPath,'file')==2,'Could not find AutoIT script "%s"',this.autoITScriptPath);
            
            % create event listener for events in this object
            this.lhInterface = util.createObjectEventListeners(this,@(h,evt)processEvents(evt),'ObjectBeingDestroyed');
            
            % update user
            this.hDebug.log(sprintf('autoITExecutablePath: %s',this.autoITExecutablePath),'info');
            this.hDebug.log(sprintf('autoITScriptPath: %s',this.autoITScriptPath),'info');
            
            
            
            
            function timerStartfcn(~, ~)
                
                % check for autoit process
                [~,r] = system('tasklist');
                autoit_process_running = contains(r,'AutoIt3'); % true means still running
                natus_process_running = contains(r,'Wave.exe'); % true means still running
                
                % if neither is running, kick it off
                if autoit_process_running && natus_process_running
                    queststr = sprintf('Recover Data Conversion Process?');
                    response = questdlg(queststr,'Process Recovery','Recover','Cancel','Cancel');
                    switch lower(response)
                        case 'recover'
                            this.hDebug.log('User elected to recover the data conversion process','info');
                            setUserStatus(this,'Recovered session: Exporting ASCII data from Natus');
                            disableEntireGUI(this);
                        case 'cancel'
                            this.hDebug.log('User elected to cancel the recovery process','info');
                            stop(this.hTimer);
                            return;
                        otherwise
                            error('bad code somewhere - no option for "%s"',response);
                    end
                elseif autoit_process_running || natus_process_running
                    this.hDebug.log('Either Natus or AutoIT is running. Please close both before proceeding.','critical');
                    stop(this.hTimer);
                    setUserStatus(this,'Error: Either Natus or AutoIT is running. Please close both before proceeding.');
                    enableEntireGUI(this);
                    return;
                else
                    setUserStatus(this,'Exporting ASCII data from Natus');
                    disableEntireGUI(this);
                    this.stopwatch = tic;
                    this.hDebug.log(sprintf('started (%.2f sec)', toc(this.stopwatch)),'info');
                    natusFile = fullfile(this.sourceFiles.directory,sprintf('%s%s',this.sourceFiles.basename,this.sourceFiles.extension));
                    workdir = [getWorkingDirectory(this) filesep];
                    cmd = sprintf('"%s" "%s" /NatusFile@"%s" /OutputDirectory@"%s"', ...
                        this.autoITExecutablePath,...
                        this.autoITScriptPath,...
                        natusFile,...
                        workdir);
                    system(cmd);
                end
            end % END function timerStartfcn
            
            function timerTimerfcn(hTimer, ~)
                
                % check for autoit process
                [~,r] = system('tasklist');
                autoit_process_running = contains(r,'AutoIt3'); % true means still running
                natus_process_running = contains(r,'Wave.exe'); % true means still running
                
                % read status file
                status_file = fullfile(getWorkingDirectory(this),sprintf('%s.STATUS',this.sourceFiles.basename{this.currFileIndex}));
                assert(exist(status_file,'file')==2,'Could not find Natus status file "%s"',status_file);
                status = strtrim(fileread(status_file));
                if ~isempty(regexpi(status,'SUCCESS'))
                    this.hDebug.log('Encountered SUCCESS in the AutoIT status file','info');
                    natus_status_success = true;
                elseif ~isempty(regexpi(status,'RUNNING'))
                    natus_status_success = false;
                else
                    if ~isempty(regexpi(status,'ERROR'))
                        this.hDebug.log(sprintf('Encountered "ERROR" in the Natus status file (%.2f sec)', toc(this.stopwatch)),'error');
                    else
                        this.hDebug.log(sprintf('Unknown Natus status "%s"',status),'error');
                    end
                    enableEntireGUI(this);
                    stop(hTimer);
                    notify(this,'AutoITError');
                    return;
                end
                
                % process autoit and natus status
                if ~autoit_process_running && ~natus_process_running && natus_status_success % both done, and success code on natus status
                    this.hDebug.log(sprintf('AutoIT process ended successfully (%.2f sec)',toc(this.stopwatch)),'info');
                    stop(hTimer);
                    notify(this,'AutoITFinished');
                elseif autoit_process_running && natus_process_running % both still running (errors caught above so we don't worry about that here)
                    this.hDebug.log(sprintf('AutoIT process still running (%d iterations, %.2f sec)', hTimer.TasksExecuted, toc(this.stopwatch)),'debug');
                    setUserStatus(this,sprintf('Exporting ASCII data from Natus (%.2f sec)',toc(this.stopwatch)));
                elseif xor(autoit_process_running,natus_process_running) % one running but not the other
                    if isempty(this.eventTime),this.eventTime=tic;end
                    if ~isempty(this.eventTime) && toc(this.eventTime)>300
                        this.eventTime = [];
                        this.hDebug.log(sprintf('AutoIT process running: %d; Natus process running: %d (%.2f sec)',autoit_process_running,natus_process_running,toc(this.stopwatch)),'error');
                        enableEntireGUI(this);
                        stop(hTimer);
                        notify(this,'AutoITError');
                        return;
                    end
                end
            end % END function timerTimerfcn
            
            function processEvents(evt)
                switch evt.EventName
                    case 'AutoITError'
                        setUserStatus(this,'Error encountered while exporting ASCII data from Natus');
                        this.hDebug.log(sprintf('AutoIT encountered an error! Please check logs, output, and code, resolve the issue, then retry.'),'error');
                    case 'AutoITFinished'
                        
                        % create the map file
                        try
                            exitCode = createMapFile(this);
                        catch ME
                            util.errorMessage(ME);
                            enableEntireGUI(this);
                            this.hDebug.log(sprintf('createMapFile encountered an error! Resolve the issue then press F5 to continue.'),'error');
                            keyboard
                            disableEntireGUI(this);
                        end
                        if exitCode<0,return;end
                        
                        % run ascii to blc conversion
                        try
                            exitCode = ascii2blx(this);
                        catch ME
                            util.errorMessage(ME);
                            enableEntireGUI(this);
                            this.hDebug.log(sprintf('ascii2blx encountered an error! Resolve the issue then press F5 to continue.'),'error');
                            keyboard
                            disableEntireGUI(this);
                        end
                        if exitCode<0,return;end
                        
                        % update the list of procedures
                        try
                            exitCode = updateProcedureList(this);
                        catch ME
                            util.errorMessage(ME);
                            enableEntireGUI(this);
                            this.hDebug.log(sprintf('updateProcedureList encountered an error! Resolve the issue then press F5 to continue.'),'error');
                            keyboard
                            disableEntireGUI(this);
                        end
                        if exitCode<0,return;end
                        
                        % generate basic analyses
                        try
                            exitCode = sanityAnalysis(this);
                        catch ME
                            util.errorMessage(ME);
                            enableEntireGUI(this);
                            this.hDebug.log(sprintf('sanityAnalysis encountered an error! Resolve the issue then press F5 to continue.'),'error');
                            keyboard
                            disableEntireGUI(this);
                        end
                        if exitCode<0,return;end
                        
                        % copy files to final destinations
                        try
                            exitCode = copyFiles(this);
                        catch ME
                            util.errorMessage(ME);
                            enableEntireGUI(this);
                            this.hDebug.log(sprintf('copyFiles encountered an error! Resolve the issue then press F5 to continue.'),'error');
                            keyboard
                            disableEntireGUI(this);
                        end
                        if exitCode<0,return;end
                        
                        % archive source files
                        try
                            exitCode = archiveSourceData(this);
                        catch ME
                            util.errorMessage(ME);
                            enableEntireGUI(this);
                            this.hDebug.log(sprintf('archiveSourceData encountered an error! Resolve the issue then press F5 to continue.'),'error');
                            keyboard
                            disableEntireGUI(this);
                        end
                        if exitCode<0,return;end
                        
                        % clean up GUI
                        setUserStatus(this,sprintf('Process completed successfully: %s',util.hms(toc(this.stopwatch))));
                        enableEntireGUI(this);
                    otherwise
                        warning('Unhandled event ''%s''',evt.EventName);
                end
            end % END function processEvents
        end % END function AutoITServer
        
        function delete(this)
            try util.destroyObjectEventListeners(this.lhInterface); catch ME, util.errorMessage(ME); end
        end % END function delete
    end % END methods
end % END classdef AutoITServer