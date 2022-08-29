classdef ecogTask < handle & util.Structable
    %{
        ECOGTASK to access artificial sensation ECoG data and task events

    Examples to use:
    
        pathToFile= 'full path name'
        makes sure the events file with 'full path name_Events' (export the
        events panel on the left side of the natus viewer
        ecog = ArtSens.ecogTask(pathToFile,'readChan',[40:48 54:56]);
    
        ecog = ecogTask(pathToFile,'readChan',[40 47 48 56],'bipolar',true,'elecPairs',[40 48;47 56]);
    
    
    NOTE:
        (07/25/2016): code is set to expect extra channel outside of the
        minigrid (since data were imported like this). This additional
        channels is the first column of data, after the "bytes" column. It
        also expects the data to have the "trigger" information in the last
        column. If data textfile changes, lines 128-130 will have to
        change, and also edit the 'Delimiter' values in line 133.
    
    Object class based of FrameworkTask object
        (skellis@vis.caltech.edu)
    
    ToDo:
     07/25/2016: finish documentation/function header for methods
    %}
    
    properties
        % task and data related properties
        hEvents                 % handle for events file
        numChannels = 20;       % number of channels on grid (m) CHANGE BACK TO 64 FOR MINI
        hLogger                 % handle for debugger
        hErrorHandler           % handle for error log
        rawVt                   % cell array of 1-by-k voltage values, each cell has n-by-N double matrix
        vtFrames                % cell arary of 1-by-k frames corresponding to voltage values
        vtTimeStamps            % cell array of 1-by-k time stamps, corresponding to voltage values
        evtNames                % cell array of k task event identifiers
        evtData                 % cell array of 1-by-k event markers
        evtTimeStamp            % cell array of 1-by-k time stamps
        eventFs = 2e3;          % data sampling rate
        trialdata               % structure of trial parsed data
        hParameters             % handle for parameter object
        readChan                % vector of channels number to access data (N)
        iti                     % structure of ITI voltgages and frames across events
        bipolar = false;        % Boolean value to compute bipolar referenced signals. 
        elecPairs = [];         % If set bipolar is to true, an n-by-2 matrix of electrode pairs has to be provided
        
        % data file properties
        srcDir                  % full path to the directory containing the data file
        srcFile                 % basename of the data file
        srcExt                  % file extension of the data file
        
        % Debugging properties
        verbosityScreen = Debug.PriorityLevel.ERROR;        % level of screen output
        verbosityLogfile = Debug.PriorityLevel.INSANITY;    % level of logfile output
        debugMode                                           % 0=> disabled, 1=> enabled, 2=> validation
        sessionTimestamp                                    % mark the time at which this object was created
    end
    methods
        function this = ecogTask(ecogFile,varargin)
            
            % verbosity and debug defaults
            [verbosity,debug] = env.get('verbosity','debug'); %you can comment out this line and assign verbosity = 0; and debug = 0;
            this.sessionTimestamp = now;
            
            % process property name-value pairs
            varargin = util.argobjprop(this, varargin);
            
            % set up parameters 
            idx = strcmpi(varargin,'params');
            if any(idx)
                prm = varargin{circshift(idx,1,2)};
                varargin(idx|circshift(idx,1,2)) = [];
                switch class(prm)
                    case 'char'
                        this.hParameters = Parameters.Dynamic(str2func(prm));
                    case 'function_handle'
                        this.hParameters = Parameters.Dynamic(prm);
                    case 'Parameters.Interface'
                        this.hParameters = prm;
                    otherwise
                        error('Unrecognized class ''%s'' for params input',class(prm));
                end
            else
                this.hParameters = Parameters.Dynamic(@Parameters.Config.FrameworkTask);
            end
            assert(isa(this.hParameters,'Parameters.Interface'),'Invalid parameters object of class ''%s''',class(this.hParameters));
            
            % check if number of channels was specified
            idx = find(strcmpi(varargin,'channels'),1);
            if ~isempty(idx)
                this.numChannels = varargin{idx+1};
                varargin(idx:idx+1) = [];
            end
            
            assert(isempty(varargin),'Unknown inputs');
            
            % Set up debug mode and levels of screen outputs
            if isempty(this.verbosityScreen)
                this.verbosityScreen = Debug.PriorityLevel(verbosity);
            end
            if isempty(this.verbosityLogfile)
                this.verbosityLogfile = Debug.PriorityLevel(verbosity);
            end
            if isempty(this.debugMode)
                this.debugMode = Debug.Mode(debug);
            end
            
            % set up debugger
            this.hErrorHandler = Debug.ErrorHandler(...
                'dbMessage',true,...
                'dbKeyboard',false,...
                'dbRethrow',false);
            for kk = 1:length(this.hLogger)
                this.hErrorHandler.addLogger(this.hLogger{kk});
            end
            
            % Check input given to load file
            if exist(ecogFile,'dir') == 7
                % user select file(s)
                [ecogFile,ecogDir] = uigetfile(fullfile(fwfile,'*.txt'),'Select TXT file','MultiSelect','off');
                if isnumeric(ecogFile)
                    log(this,'No data files selected','warn');
                    return;
                end
                assert(ischar(ecogFile),'Invalid file input: must be char, not ''%s''',class(fwfile));
                ecogFile = fullfile(ecogDir,ecogFile);
            end
            
            assert(nargin >= 1 && exist(ecogFile,'file') == 2,'Must provide valid path to data file');
            [this.srcDir,this.srcFile,this.srcExt] = fileparts(ecogFile);
            
            % variables to data file
            format = {'%s','%s','%f'};
            format(4:3+this.numChannels+1) = cellstr(repmat('%s',this.numChannels+1,1)); % change +1 to +2 if extra channel is present
            %varName = {'date','time','byte','extrachan'}; % uncomment if extra channel is present
            varName = {'date','time','byte'}; % comment out if extra channel is present
            c = length(varName)+1;
            for n = 1:this.numChannels; varName{c} = ['C',num2str(n)]; c = c + 1; end
            varName{c} = 'trigger';
            ds = datastore(fullfile(this.srcDir,sprintf('%s%s',this.srcFile,this.srcExt)),'ReadVariableNames',false,'NumHeaderLines',15,'Delimiter',{' ','\t','\t ','\t     '},'TextscanFormats',format','Readsize',1000000, 'TreatAsMissing', {'OFF', 'OFF\n', 'SHORT', 'SHOR.', 'AMPSAT'});
            ds.VariableNames = varName;
            
            % check for event file
            fid = fopen(fullfile(this.srcDir,sprintf('%s%s%s',this.srcFile,'_Events',this.srcExt)));
            evt = textscan(fid,'%s %s','HeaderLines',6,'Delimiter','\t');
            fclose(fid);
            
            [this.evtData,this.evtTimeStamp,this.evtNames] = getEventData(this,evt);
            
            p = parpool(); % start parallel computing
            
            [this.rawVt,this.vtTimeStamps,this.vtFrames] = parseRawData(this,ds);
            
            [this.trialdata,this.iti] = parseTrials(this);
            
            delete(p); % close the parallel pool
        end % END of ecogTask function
        
        function [vt,ts,frames] = parseRawData(this,ds,varargin)
            
            % First divide per event/trial type
            ts = cell(1,length(this.evtNames));
            frames = cell(1,length(this.evtNames));
            vt = cell(1,length(this.evtNames));
            
            parfor nn = 1:length(this.evtData)
                % Get range of marked events (X = start touch, Z = end
                % touch)
                idx1 = find(strcmp(this.evtData{nn},'XX'),1,'first');
                idx2 = find(strcmp(this.evtData{nn},'ZZ'),1,'last');
                iniTs = this.evtTimeStamp{nn}{idx1}(1:end-2);
                endTs = this.evtTimeStamp{nn}{idx2}(1:end-2);
                
                tempts = []; tempfr = []; tempvt = [];
                idxTs1 = []; idxTs2 = [];
                while isempty(ts{nn}) % Loop through dataset until we find first and last trial times
                    data = read(ds);
                    if isempty(idxTs1)
                        idxTs1 = find(strcmp(data.time,iniTs),1,'first');
                    end
                    if isempty(idxTs2)
                        idxTs2 = find(strcmp(data.time,endTs),1,'last');
                    end
                    if ~isempty(idxTs1) && isempty(idxTs2)
                        tempts = [tempts;data.time(idxTs1:end)];
                        tempfr = [tempfr;data.byte(idxTs1:end)];
                        tempvt = [tempvt;getChanVoltages(this,data,[idxTs1 length(data.time)])];
                        idxTs1 = 1;
                    elseif ~isempty(idxTs1) && ~isempty(idxTs2)
                        tempts = [tempts;data.time(1:idxTs2)];
                        tempfr = [tempfr;data.byte(1:idxTs2)];
                        tempvt = [tempvt;getChanVoltages(this,data,[1 idxTs2])];
                        
                        ts{nn} = tempts;
                        frames{nn} = tempfr;
                        vt{nn} = cellfun(@str2double,tempvt);
                    end
                end
            end
        end % END of parseRawData function
        
        function [evt,ts,names] = getEventData(this,evtcell,varargin)
            % [EVT,TS,NAMES] = GETEVENTDATA(THIS,EVTCELL,VARARGIN) Get
            % timestamps of marked events.
            
            % check for phase/task names
            idx = ~cellfun(@isempty,(cellfun(@(x)strfind(x,'TOUCH'),evtcell{2},'UniformOutput',false)));
            names = evtcell{2}(idx)';
            
            % get range of times for each phase/task name
            evt = cell(1,length(names));
            ts = evt;
            ik = find(idx);
            for nn = 1:length(ik)
                if nn < length(ik)
                    evt{nn} = evtcell{2}(ik(nn)+1:ik(nn+1)-1);
                    ts{nn} = evtcell{1}(ik(nn)+1:ik(nn+1)-1);
                else
                    evt{nn} = evtcell{2}(ik(nn)+1:end);
                    ts{nn} = evtcell{1}(ik(nn)+1:end);
                end
            end
        end % END of getEventData
        
        function vtmat = getChanVoltages(this,data,indices)
            a = indices(1); b = indices(2); % extra vars to avoid overhead during parallel computing
            if this.bipolar
                pairs1 = this.elecPairs(:,1); pairs2 = this.elecPairs(:,2); % extra vars to avoid ovearhead communication
                parfor kk = 1:length(pairs1)
                    var1 = ['C',num2str(pairs1(kk))];
                    var2 = ['C',num2str(pairs2(kk))];
                    chan1 = cellfun(@str2num,data.(var1)(a:b));
                    chan2 = cellfun(@str2num,data.(var2)(a:b));
                    vtmat(:,kk) = cellstr(num2str(detrend(chan1)-detrend(chan2))); % zero mean before substracting
                end
            else
                channels = this.readChan;
                parfor kk = 1:length(channels)
                    var = ['C',num2str(channels(kk))];
                    vtmat(:,kk) = data.(var)(a:b);
                end
            end
        end % END of getChanVoltages function
        
        function [trials,iti] = parseTrials(this,varargin)
            trials = cell(1,length(this.evtData));
            iti = cell(size(trials));
            
            parfor kk = 1:length(this.evtData)
                trialSt = struct; itiSt = struct;
                
                % get indices of trial start and finishing
                trStart = find(strcmp(this.evtData{kk},'XX'));
                trEnd = find(strcmp(this.evtData{kk},'ZZ'));
                
                % check all "starts" have and "end"
                if length(trStart) ~= length(trEnd)
                    a = trStart - trStart(1);
                    b = trEnd - trStart(1);
                    if length(trStart) > length(trEnd)
                        c = [];
                        for nn = 1:length(a)-1
                            if ~any(b > a(nn) & b < a(nn+1))
                                c = [c,nn];
                            end
                        end
                        trStart(c) = [];
                    end
                end
                prev = 1;
                for nn = 1:length(trStart) % loop through the trials
                    idx1 = find(strcmp(this.vtTimeStamps{kk},this.evtTimeStamp{kk}{trStart(nn)}(1:end-2)),1,'first');
                    idx2 = find(strcmp(this.vtTimeStamps{kk},this.evtTimeStamp{kk}{trEnd(nn)}(1:end-2)),1,'last');
                    
                    if isempty(idx1) && nn == 1; idx1 = 1; end; % case where voltage data started with original "X" marker and not "XX" from video
                    
                    % get "in-between" times for ITI
                    if nn > 1
                        idx = prev:idx1-1;
                        itiSt(nn-1).voltage = this.rawVt{kk}(idx,:);
                        itiSt(nn-1).frames = this.vtFrames{kk}(idx);
                        itiSt(nn-1).timestamps = this.vtTimeStamps{kk}(idx);
                    end
                    prev = idx2+1;
                    if ~isempty(idx1) && ~isempty(idx2)
                        trialSt(nn).voltage = this.rawVt{kk}(idx1:idx2,:);
                        trialSt(nn).frames = this.vtFrames{kk}(idx1:idx2);
                        trialSt(nn).timestamps = this.vtTimeStamps{kk}(idx1:idx2);
                    end
                end
                trials{kk} = trialSt;
                iti{kk} = itiSt;
            end
            
        end % END of parseTrials function
    end
end % END of ecogTask classdef