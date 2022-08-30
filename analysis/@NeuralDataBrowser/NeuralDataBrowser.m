classdef NeuralDataBrowser < handle
    % NEURALDATABROWSER
    %
    % To-do
    %  * "go-to" field/button (select either time or trial, and enter
    %    the time/trial, then click apply)
    %  * incorporate binned spike counts and/or rasters
    %  * "single-channel" mode where you can click any of the channels and
    %    it replaces the current selection instead of adding to it
    %  * single apply button for groups of fields, for example, chronux
    %    fields, so that you don't have to wait for the spectrogram to keep
    %    getting recomputed every time you change a parameter
    %  * more robust error handling
    %  * create a similar GUI for trial-averaged data?
    %  * provide a field where users can specify a task criteria to look
    %    for markers?
    %  * figure out how to determine dependencies so you can avoid
    %    recalculating stuff all the time (or integrate the cache?)
    
    properties
        name = 'Neural Data Browser'; % name of the figure
        linespec = {'b','g','r','m','k','y'}; % when plotting multiple lines
        lineHandles % collection of line handles returned by plot
        markerHandles % collection of handles to markers
        guiHandles % collection of gui element handles
        
        plotType = 'broadband';
        window = 0.25;
        step = 0.05;
        pad = 2;
        tapers = [3 5];
        normFreq = true;
        pwr2db = true;
        
        width = 950; % figure width
        height = 850; % figure height
        screenMargin = [0 40 0 0]; % left/bottom/right/top pixel margins between screen (monitor) edge and figure
        outerSpacing = 20; % spacing around edge of figure
        elemSpacing = 5; % spacing between UI elements
        rowHeight = 22; % height of each row of the UI
        titleHeight = 20;
        axisHeight
        axisSpacing = 20;
        axisLeftSpacing = 70;
        axisConfigSpacing = 45;
        
        timeRange = 10; % in seconds, amount of data to show
        timeStep = 1; % in seconds, amount of data to skip ahead
        yLimitMinimum = -1500; % units dependent on data
        yLimitMaximum = 1500; % units dependent on data
        yLimitAutoScale = true; % autoscale the y-axis limits
        
        dataDirectory % current data directory
        dataFiles % list of all .ns* and .nev files in data directory
        dataValid % whether the data file is valid
        
        taskDirectory
        taskFiles
        taskValid
        
        currentDataPosition % current position for data
        currentData % avoid re-loading/re-calculating from scratch
        currentChannels % list of currently displayed channels
        
        flagIncludeTask = true;
        flagOverrideDefaultUserStatus = false;
    end % END properties
    
    properties(SetAccess=private,GetAccess=public)
        hFigure % handle to the GUI figure
        hDebugger % handle to debugger object
        hArrayMap % handle to Blackrock.ArrayMap object
        hNeural % Blackrock.NSx and .NEV objects for each data file
        hTask % FrameworkTask objects
        hNeuralCurrent % currently displayed data object
        hTaskCurrent % currently displayed task object
        lastUsedDirectory % remember the last used directory
        sessionTimestamp % timestamp indicating when this session began
    end % END properties(SetAccess=private,GetAccess=public)
    
    methods
        function this = NeuralDataBrowser(varargin)
            this.sessionTimestamp = now;
            
            % set up debugger
            [varargin,this.hDebugger,found] = util.argisa('Debug.Debugger',varargin,[]);
            if ~found
                this.hDebugger = Debug.Debugger(sprintf('NeuralDataBrowser_%s',datestr(this.sessionTimestamp,'yyyymmdd-HHMMSS'))); %,varargin{:}
            end
            
            % data/task directories
            [varargin,datadir] = util.argkeyval('datadir',varargin,'');
            [varargin,taskdir] = util.argkeyval('taskdir',varargin,'');
            
            % make sure no orphan input arguments
<<<<<<< .mine
            util.argempty(varargin);
||||||| .r234
            Utilities.ProcVarargin(varargin);
=======
            util.ProcVarargin(varargin);
>>>>>>> .r251
            
            % check for source directories
            if ~isempty(datadir)
                assert(exist(datadir,'dir')==7,'Could not find data directory ''%s''',datadir);
                this.dataDirectory = datadir;
            end
            if ~isempty(taskdir)
                assert(exist(taskdir,'dir')==7,'Could not find task directory ''%s''',taskdir);
                this.taskDirectory = taskdir;
            end
            
            % create default Blackrock.ArrayMap object
            if isempty(this.hArrayMap)
                this.hArrayMap = Blackrock.ArrayMap('quiet');
            end
            
            % create figure elements
            layout(this);
            
            % process data directory if it's been specified already
            if ~isempty(this.dataDirectory)
                updateGUI_ChangeDataDirectory(this);
            end
            if ~isempty(this.taskDirectory)
                updateGUI_ChangeTaskDirectory(this);
            end
            updateGUI_DisplayFile(this)
            
            % update status
            setUserStatus(this);
        end % END function NeuralDataBrowser
        
        function loadDataFile(this)
            which = get(this.guiHandles.popupDataFiles,'Value');
            this.currentDataPosition = 0;
            this.currentChannels = 1:96;
            this.hNeuralCurrent = this.hNeural{which};
            updateGUI_DisplayFile(this);
        end % END function loadDataFile
        
        function loadTaskFile(this)
            which = get(this.guiHandles.popupTaskFiles,'Value');
            this.hTaskCurrent = this.hTask{which};
            updateGUI_DisplayFile(this);
        end % END function loadDataFile
        
        function navigate(this,tm)
            if nargin<2||isempty(tm),tm=this.timeStep;end
            currpos = this.currentDataPosition;
            winsize = this.timeRange;
            avail = max(this.hNeuralCurrent.PointsPerDataPacket)/this.hNeuralCurrent.Fs;
            if winsize>avail,winsize=avail;end
            minpos = 0;
            maxpos = avail-winsize;
            if isinf(tm)
                if tm<0, newpos = minpos; end
                if tm>0, newpos = maxpos; end
            else
                newpos = currpos + tm;
                newpos = max(minpos,newpos);
                newpos = min(maxpos,newpos);
            end
            log(this,sprintf('Navigate %+.2f sec to [%.2f %.2f] sec',currpos-newpos,currpos,currpos+winsize),'info');
            this.currentDataPosition = newpos;
            updateGUI_DisplayFile(this);
        end % END function navigate
        
        function log(this,msg,priority,varargin)
            % LOG Log a message
            
            % default message priority
            if nargin<3||isempty(priority),priority=Debug.PriorityLevel.ERROR;end
            
            % pass message to each registered logger
            this.hDebugger.log(msg,varargin{:},priority);
        end % END function log
        
        function setUserStatus(this,msg)
            if nargin<2||isempty(msg)
                %if this.flagOverrideDefaultUserStatus>0,return;end
                msg = 'Ready (press ''h'' for help)';
                log(this,sprintf('Called setUserStatus with no arg; will display ''%s''',msg),'debug');
            else
                log(this,sprintf('Called setUserStatus with arg ''%s''',msg),'debug');
            end
            set(this.guiHandles.textStatus,'String',msg);
            drawnow;
        end % END function setUserStatus
        
        function updateGUI_ChangeDataDirectory(this)
            
            % update the GUI's directory field
            set(this.guiHandles.editDataDirectory,'String',this.dataDirectory);
            
            % get a list of neural data files
            files = dir(this.dataDirectory);
            files( ~cellfun(@isempty,regexp({files.name},'^\.+$')) ) = [];
            files( cellfun(@isempty,regexpi({files.name},'\.nev$')) & cellfun(@isempty,regexpi({files.name},'\.ns\d$')) ) = [];
            this.dataFiles = files;
            
            % create neural data objects for each file
            this.hNeural = cell(1,length(this.dataFiles));
            this.dataValid = nan(1,length(this.dataFiles));
            popupString = cell(1,length(this.dataFiles));
            for kk=1:length(this.dataFiles)
                setUserStatus(this,sprintf('Processing ''%s''',this.dataFiles(kk).name));
                try
                    [~,~,ext] = fileparts(this.dataFiles(kk).name);
                    if strcmpi(ext,'.nev')
                        
                        % NEV file - create Blackrock.NEV object
                        this.hNeural{kk} = Blackrock.NEV(fullfile(this.dataDirectory,this.dataFiles(kk).name),this.hArrayMap,'quiet');
                        log(this,sprintf('Loaded NEV file ''%s''',this.dataFiles(kk).name),'info');
                        this.dataValid(kk) = true;
                        popupString{kk} = sprintf('%s (%s)',this.dataFiles(kk).name,'1');
                    elseif strncmpi(ext,'.ns',3)
                        
                        % NSx file - create Blackrock.NSx object
                        this.hNeural{kk} = Blackrock.NSx(fullfile(this.dataDirectory,this.dataFiles(kk).name),this.hArrayMap,'quiet');
                        log(this,sprintf('Loaded NSx file ''%s''',this.dataFiles(kk).name),'info');
                        this.dataValid(kk) = true;
                        popupString{kk} = sprintf('%s (%s)',this.dataFiles(kk).name,'2');
                    else
                        
                        % unknown file - issue "error" and set valid false
                        this.hNeural{kk} = [];
                        log(this,sprintf('Unknown format for neural data file ''%s''',this.dataFiles(kk).name),'error');
                        this.dataValid(kk) = false;
                        popupString{kk} = sprintf('%s (%s)',this.dataFiles(kk).name,'3');
                    end
                catch ME
                    setUserStatus(this,sprintf('Could not process ''%s''',this.dataFiles(kk).name));
                    this.hNeural{kk} = [];
                    this.dataValid(kk) = false;
                    popupString{kk} = sprintf('%s (%s)',this.dataFiles(kk).name,'4');
                    
                    process(this.hDebugger,ME);
                end
            end
            
            % get a list of task files
            files = dir(this.dataDirectory);
            files( ~cellfun(@isempty,regexp({files.name},'^\.+$')) ) = [];
            files( cellfun(@isempty,regexpi({files.name},'\.nev$')) & cellfun(@isempty,regexpi({files.name},'\.ns\d$')) ) = [];
            this.dataFiles = files;
            
            % update the GUI's list of files
            if ~isempty(popupString)
                set(this.guiHandles.popupDataFiles,'String',popupString);
                set(this.guiHandles.popupDataFiles,'enable','on');
            end
            
            % reset status
            setUserStatus(this);
        end % END function updateGUI_ChangeDataDirectory
        
        function updateGUI_ChangeTaskDirectory(this)
            
            % update the GUI's directory field
            set(this.guiHandles.editTaskDirectory,'String',this.taskDirectory);
            
            % get a list of neural data files
            files = dir(this.taskDirectory);
            files( ~cellfun(@isempty,regexp({files.name},'^\.+$')) ) = [];
            files( cellfun(@isempty,regexpi({files.name},'\.mat$')) ) = [];
            this.taskFiles = files;
            
            % create neural data objects for each file
            this.hTask = cell(1,length(this.taskFiles));
            this.taskValid = nan(1,length(this.taskFiles));
            popupString = cell(1,length(this.taskFiles));
            for kk=1:length(this.taskFiles)
                setUserStatus(this,sprintf('Processing ''%s''',this.taskFiles(kk).name));
                try
                    
                    % create FrameworkTask object
                    this.hTask{kk} = FrameworkTask(fullfile(this.taskDirectory,this.taskFiles(kk).name));%,'quiet');
                    log(this,sprintf('Loaded task file ''%s''',this.taskFiles(kk).name),'info');
                    this.taskValid(kk) = true;
                    popupString{kk} = sprintf('%s',this.taskFiles(kk).name);
                catch ME
                    setUserStatus(this,sprintf('Could not process ''%s''',this.taskFiles(kk).name));
                    this.hTask{kk} = [];
                    this.taskValid(kk) = false;
                    popupString{kk} = sprintf('%s',this.taskFiles(kk).name);
                    process(this.hDebugger,ME);
                end
            end
            
            % get a list of task files
            files = dir(this.taskDirectory);
            files( ~cellfun(@isempty,regexp({files.name},'^\.+$')) ) = [];
            files( cellfun(@isempty,regexpi({files.name},'\.mat$')) ) = [];
            this.taskFiles = files;
            
            % update the GUI's list of files
            if ~isempty(popupString)
                set(this.guiHandles.popupTaskFiles,'String',popupString);
                set(this.guiHandles.popupTaskFiles,'enable','on');
            end
            
            % reset status
            setUserStatus(this);
        end % END function updateGUI_ChangeTaskDirectory
        
        function updateGUI_DisplayFile(this)
            
            % update GUI
            if isempty(this.hNeuralCurrent)
                set(this.guiHandles.editTimeRange,'Enable','off');
                set(this.guiHandles.editTimeStep,'Enable','off');
                set(this.guiHandles.editYLimitMinimum,'Enable','off');
                set(this.guiHandles.editYLimitMaximum,'Enable','off');
                set(this.guiHandles.checkboxYLimitAutoScale,'Enable','off');
                for kk=1:96
                    set(this.guiHandles.(sprintf('button%02d',kk)),'Enable','off');
                end
                set(this.guiHandles.buttonSelectAllChannels,'Enable','off');
                set(this.guiHandles.buttonDeselectAllChannels,'Enable','off');
                set(this.guiHandles.popupPlotType,'Enable','off');
                set(this.guiHandles.editWindow,'Enable','off');
                set(this.guiHandles.editStep,'Enable','off');
                set(this.guiHandles.editTapers,'Enable','off');
                set(this.guiHandles.editPad,'Enable','off');
            else
                
                % update data info
                if isempty(this.hTaskCurrent)
                    str = sprintf('%d channels, %.2f seconds',this.hNeuralCurrent.ChannelCount,max(this.hNeuralCurrent.PointsPerDataPacket)/this.hNeuralCurrent.Fs);
                else
                    str = sprintf('%d channels, %.2f seconds, %d trials',this.hNeuralCurrent.ChannelCount,max(this.hNeuralCurrent.PointsPerDataPacket)/this.hNeuralCurrent.Fs,this.hTaskCurrent.numTrials);
                end
                set(this.guiHandles.textDataInfo,'String',str);
                
                avail = max(this.hNeuralCurrent.PointsPerDataPacket)/this.hNeuralCurrent.Fs;
                if this.timeRange>avail,this.timeRange=avail;end
                
                if isempty(this.currentChannels)
                    delete(this.lineHandles);
                    this.lineHandles = [];
                else
                    assert(isa(this.hNeuralCurrent,'Blackrock.NSx'),'No support for NEV files yet');
                    if strcmpi(this.plotType,'broadband')
                        setUserStatus(this,sprintf('Loading data from ''%s''',this.hNeuralCurrent.SourceBasename));
                        
                        % read data
                        st = this.currentDataPosition;
                        lt = this.currentDataPosition+this.timeRange;
                        data = read(this.hNeuralCurrent,'time',[st lt],'microvolts','channels',this.currentChannels);
                        t = linspace(st,lt,length(data)+1);
                        
                        % plot
                        this.lineHandles = plot(this.guiHandles.axisMain,t(1:end-1),data);
                        xlim(this.guiHandles.axisMain,[st lt]);
                        ylabel(this.guiHandles.axisMain,'Amplitude (microvolts)');
                        xlabel(this.guiHandles.axisMain,'Time (seconds)');
                    elseif strcmpi(this.plotType,'mn+std')
                        setUserStatus(this,sprintf('Loading data from ''%s''',this.hNeuralCurrent.SourceBasename));
                        
                        % read data
                        st = this.currentDataPosition;
                        lt = this.currentDataPosition+this.timeRange;
                        data = read(this.hNeuralCurrent,'time',[st lt],'microvolts','channels',this.currentChannels);
                        t = linspace(st,lt,length(data)+1);
                        
                        % colors
                        colors = get(this.guiHandles.axisMain,'ColorOrder');
                        
                        % plot data
                        try
                            dt = data';
                            for kk=1:size(dt,2)
                                dt(:,kk) = proc.gauss_smooth(dt(:,kk),5);
                            end
                            xx = repmat(t(:),1,1);
                            yy = mean(dt,2);
                            zz = repmat(std(dt,[],2),[1 2]);
                            cla(this.guiHandles.axisMain);
                            [hl,hp] = util.boundedline(xx(1:end-1),yy,zz,'alpha','cmap',colors,'transparency',0.5,this.guiHandles.axisMain);
                            this.lineHandles = [hl hp];
                            set(hl,'LineWidth',2);
                        catch ME
                            util.errorMessage(ME);
                            keyboard;
                        end
                        
                        % plot
                        xlim(this.guiHandles.axisMain,[st lt]);
                        ylabel(this.guiHandles.axisMain,'Amplitude (microvolts)');
                        xlabel(this.guiHandles.axisMain,'Time (seconds)');
                    elseif strcmpi(this.plotType,'spectrogram')
                        setUserStatus(this,sprintf('Calculating specotrogram from ''%s''',this.hNeuralCurrent.SourceBasename));
                        
                        % read data
                        pre = min(this.currentDataPosition,2*this.window);
                        avail = max(this.hNeuralCurrent.PointsPerDataPacket)/this.hNeuralCurrent.Fs;
                        post = min(avail-(this.currentDataPosition+this.timeRange),2*this.window);
                        st = this.currentDataPosition;
                        lt = this.currentDataPosition+this.timeRange;
                        data = read(this.hNeuralCurrent,'time',[st-pre lt+post],'microvolts','channels',this.currentChannels);
                        fpass = [0 this.hNeuralCurrent.Fs/2];
                        if ~this.yLimitAutoScale
                            fpass = [max(fpass(1),this.yLimitMinimum) min(fpass(2),this.yLimitMaximum)];
                        end
                        [S,t,f] = chronux.ct.mtspecgramc(data',[this.window this.step],struct(...
                            'Fs',this.hNeuralCurrent.Fs,'trialave',1,...
                            'tapers',this.tapers,'pad',this.pad,'fpass',fpass));
                        t = t-pre;
                        t = t + this.currentDataPosition;
                        S = S';
                        if this.pwr2db
                            S = proc.pwr2db(S);
                        end
                        if this.normFreq
                            S = S - repmat(min(S,[],2),1,size(S,2));
                            S = S ./repmat(max(S,[],2),1,size(S,2));
                        end
                        try
                            S = proc.gauss_smooth(S,1);
                        catch ME
                            process(this.hDebugger,ME);
                        end
                        imagesc(t,f,proc.gauss_smooth(S,1),'Parent',this.guiHandles.axisMain);
                        axis(this.guiHandles.axisMain,'xy');
                        box(this.guiHandles.axisMain,'on');
                        xlim(this.guiHandles.axisMain,[st lt]);
                        ylabel(this.guiHandles.axisMain,'Frequency (Hz)');
                        xlabel(this.guiHandles.axisMain,'Time (seconds)');
                        this.yLimitMinimum = fpass(1);
                        this.yLimitMaximum = fpass(2);
                    end
                end
                
                % set ylimit
                if ~this.yLimitAutoScale
                    ylim(this.guiHandles.axisMain,[this.yLimitMinimum this.yLimitMaximum]);
                end
                
                set(this.guiHandles.checkboxYLimitAutoScale,'Value',this.yLimitAutoScale);
                ylims = get(this.guiHandles.axisMain,'ylim');
                set(this.guiHandles.editYLimitMinimum,'String',num2str(ylims(1)));
                set(this.guiHandles.editYLimitMaximum,'String',num2str(ylims(2)));
                set(this.guiHandles.editTimeRange,'String',num2str(this.timeRange));
                set(this.guiHandles.editTimeStep,'String',num2str(this.timeStep));
                if this.yLimitAutoScale
                    set(this.guiHandles.editYLimitMinimum,'Enable','off');
                    set(this.guiHandles.editYLimitMaximum,'Enable','off');
                else
                    set(this.guiHandles.editYLimitMinimum,'Enable','on');
                    set(this.guiHandles.editYLimitMaximum,'Enable','on');
                end
                
                % add task information
                if ~isempty(this.hTaskCurrent) && this.flagIncludeTask
                    trange = get(this.guiHandles.axisMain,'xlim');
                    trialTimes = this.hTaskCurrent.getTrialTime;
                    trialIDs = 1:length(trialTimes);
                    trialIDs(trialTimes<trange(1)|trialTimes>trange(2)) = [];
                    trialTimes(trialTimes<trange(1)|trialTimes>trange(2)) = [];
                    this.markerHandles = util.plotMarkerLines(this.guiHandles.axisMain,trialTimes,...
                        'MarkerLabels',arrayfun(@(x)sprintf('Trial %d',x),trialIDs,'UniformOutput',false),...
                        'VerticalAlignment','top',...
                        'VerticalOffset',10,...
                        'HorizontalOffset',12,...
                        'FontSize',12);
                end
                
                set(this.guiHandles.editTimeRange,'Enable','on');
                set(this.guiHandles.editTimeStep,'Enable','on');
                set(this.guiHandles.editYLimitMinimum,'Enable','on');
                set(this.guiHandles.editYLimitMaximum,'Enable','on');
                set(this.guiHandles.checkboxYLimitAutoScale,'Enable','on');
                
                for kk=1:96
                    set(this.guiHandles.(sprintf('button%02d',kk)),'Enable','on');
                    set(this.guiHandles.(sprintf('button%02d',kk)),'Value',ismember(kk,this.currentChannels));
                end
                set(this.guiHandles.buttonSelectAllChannels,'Enable','on');
                set(this.guiHandles.buttonDeselectAllChannels,'Enable','on');
                
                set(this.guiHandles.popupPlotType,'Enable','on');
                if strcmpi(this.plotType,'spectrogram')
                    set(this.guiHandles.editWindow,'Enable','on');
                    set(this.guiHandles.editStep,'Enable','on');
                    set(this.guiHandles.editTapers,'Enable','on');
                    set(this.guiHandles.editPad,'Enable','on');
                else
                    set(this.guiHandles.editWindow,'Enable','off');
                    set(this.guiHandles.editStep,'Enable','off');
                    set(this.guiHandles.editTapers,'Enable','off');
                    set(this.guiHandles.editPad,'Enable','off');
                end
            end
            
            % reset status
            setUserStatus(this);
        end % END function updateGUI_DisplayFile
        
        function help(this)
            log(this,'Called help','debug');
            helpString = help(class(this));
            fprintf('%s',helpString);
        end % END function help
        
        function keyPressHandler(this,kp)
            % KEYPRESSHANDLER
            %
            %   left-arrow      n/a
            %  right-arrow      n/a
            %     up-arrow      n/a
            %   down-arrow      n/a
            %            h      help
            %       ctrl+o      open a NEV (spike data) or MAT (sorting operations) file
            %    shift+esc      exit the NeuralDataBrowser GUI
            
            mstr = '';
            if ~isempty(kp.Modifier)
                if length(kp.Modifier)>1
                    mstr = sprintf(' with modifiers %s',util.cell2str(kp.Modifier));
                else
                    mstr = sprintf(' with modifier %s',kp.Modifier{1});
                end
            end
            log(this,sprintf('Pressed ''%s''%s',kp.Key,mstr),'debug');
            switch kp.Key
                case 'leftarrow'
                case 'rightarrow'
                case 'uparrow'
                case 'downarrow'
                case 'h'
                    log(this,'h -> help','debug');
                    help(this);
                case 'o'
                    if any(strcmpi(kp.Modifier,'control'))
                        log(this,'ctrl+o -> open','debug');
                        try
                            open(this);
                        catch ME
                            process(this.hDebugger,ME);
                        end
                        if this.nFiles>0
                            log(this,sprintf('ctrl+o -> jumpToChannel(%d)',this.idxCurrentChannel),'debug');
                            jumpToChannel(this,this.idxCurrentChannel);
                        end
                    end
                case 'escape'
                    if any(strcmpi(kp.Modifier,'shift'))
                        log(this,'shift+esc -> close','debug');
                        close(this);
                    end
            end
        end % END function keyPressHandler
        
        function errorHandler(this,ME,dl)
            % ERRORHANDLER Procedure for handling errors.
            %
            %   ERRORHANDLER(THIS,ME,DL)
            %   Print the error message; if DL is set to TRUE, will call 
            %   DELETE method to free all resources.
            
            % set dl default to FALSE (no cleanup unless rethrow error)
            if nargin<3,dl=false;end
            
            % handle the case where options haven't been set yet
            if isempty(this.debug)
                util.errorMessage(ME);
                if dl, delete(this); end
            else
                
                % print the error message
                % only if debug is not validation (==2)
                % only if verbosity is >=1
                if this.debug<2 && this.verbosity>=1
                    util.errorMessage(ME);
                end
                
                % cleanup/delete, throw the error if in validation
                if this.debug==2
                    if dl, delete(this); end
                    rethrow(ME);
                elseif dl
                    delete(this);
                end
            end
        end % END function errorHandler
        
        function close(this)
            log(this,'Called close','debug');
            
            % delete the GUI
            delete(this);
        end % END function close
        
        function delete(this)
            % update user
            log(this,sprintf('NeuralDataBrowser session began at %s and lasted %s',datestr(this.sessionTimestamp),util.hms(etime(datevec(now),datevec(this.sessionTimestamp)),'hh:mm:ss')),'info');
            
            % delete figure
            try delete(this.hFigure); catch ME, util.errorMessage(ME); end
            
            % delete the data objects
            if ~isempty(this.hNeural) && iscell(this.hNeural)
                try cellfun(@delete,this.hNeural); catch ME, util.errorMessage(ME); end
            end
            
            % delete loggers
            try delete(this.hDebugger); catch ME, util.errorMessage(ME); end
        end % END function delete
        
        function st = toStruct(this,varargin)
            skip = [{'hFigure','guiHandles'} varargin];
            st = toStruct@util.Structable(this,skip{:});
        end % END function toStruct
    end % END methods
end % END classdef