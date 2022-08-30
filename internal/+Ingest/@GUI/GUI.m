classdef GUI < handle
    properties
        hInterface % handle to the Ingest.Interface object
        hFigure % handle to the Ingest.GUI figure
        hDebug % debug interface
        name = 'Data Ingester'; % name of the figure
        
        guiHandles % collection of gui element handles
        width = 500; % figure width
        height = 820; % figure height
        screenMargin = [0 40 0 0]; % left/bottom/right/top pixel margins between screen (monitor) edge and figure
        outerSpacing = 20; % spacing around edge of figure
        elemSpacing = 5; % spacing between UI elements
        rowHeight = 22; % height of each row of the UI
        rowSpacing = 8; % space between rows in UI
    end % END properties
    
    properties(SetAccess=private,GetAccess=public)
        currFileInfo
    end % END properties(SetAccess=private,GetAccess=public)
    
    properties(Access=private)
        guiEnableStatus % for disable/enable entire gui
        guiElements = {'buttonBrowse',... % list of GUI elements
            'listboxSourceFiles','buttonReloadDirectory','buttonAddFile',...
            'buttonRemoveFile',...
            ...
            'listboxOutputDirectory','editOutputDirectory',...
            ...
            'listboxParticipant','listboxProcedure','popupProcedureType',...
            'editProcedureDate','editRecordingDate','buttonAutoDetectParticipant',...
            ...
            'editGridLabel','popupGridHemisphere','popupGridLocation',...
            'popupGridTemplate','buttonAddGrid','buttonLoadGrid',...
            'listboxGrid','buttonRemoveGrid',...
            ...
            'buttonRun','buttonRecover','buttonKeyboard'};
        lhInterface
    end % END properties(Access=private)
    
    methods
        function this = GUI(varargin)
            [varargin,this.hDebug,found] = util.argisa('Debug.Debugger',varargin,[]);
            if ~found,this.hDebug=Debug.Debugger('Interface');end
            util.argempty(varargin);
            
            % create interface object
            this.hInterface = Ingest.Interface(this.hDebug);
            this.lhInterface = util.createObjectEventListeners(this.hInterface,@(h,evt)subfcn__processEvents(evt),'ObjectBeingDestroyed');
            
            % create figure elements
            layout(this);
            setUserStatus(this,'Select a data file to process');
            
            function subfcn__processEvents(evt)
                switch evt.EventName
                    case 'FileProcessingEvent'
                        this.currFileInfo = evt.UserData.FileInfo;
                        set(this.guiHandles.listboxSourceFiles,'Value',evt.UserData.currFileIndex);
                        setUserStatus(this,strcat("Converting ",evt.UserData.FileInfo.basename,evt.UserData.FileInfo.extension, ' - File(',num2str(evt.UserData.currFileIndex),'/',num2str(size(evt.Source.SourceFiles,1)),')'));
                    case 'CleaningFileEvent'
                        msg = evt.UserData.Message;
                        setUserStatus(this,msg);
                    case 'StatusMessageEvent'
                        msg = evt.Message;
                        setUserStatus(this,msg);
                    otherwise
                        error('Unknown event "%s"',evt.EventName);
                end
            end % END subfcn__processEvents
        end % END function GUI
        
        function updateSourceFiles(this)
            if isempty(this.hInterface.SourceFiles),return;end
            
            % update the GUI listbox
            set(this.guiHandles.listboxSourceFiles,'Value',[]);
            set(this.guiHandles.listboxSourceFiles,'String',cellfun(@(x,y)sprintf('%s%s',x,y),this.hInterface.SourceFiles.basename,this.hInterface.SourceFiles.extension,'UniformOutput',false));
        end % END function updateSourceFiles
        
        function recover(this)
            if isempty(this.currFileInfo)
                warning('No current file info: the Ingest GUI may be unstable now.');
                enableEntireGUI(this);
            else
                mode = this.currFileInfo.mode;
                if iscell(mode),mode=mode{1};end
                switch lower(mode)
                    case 'natus'
                        if isa(this.hTimer,'timer') && isvalid(this.hTimer) && strcmpi(this.hTimer.Running,'off')
                            this.hDebug.log('Starting the timer for recovery','info');
                            start(this.hTimer);
                        else
                            cl = class(this.hTimer);
                            if ismethod(this.hTimer,'isvalid')
                                vl = isvalid(this.hTimer);
                            else
                                vl = false;
                            end
                            if isprop(this.hTimer,'Running')
                                rn = this.hTimer.Running;
                            end
                            this.hDebug.log(sprintf('Failed attempt to recover; timer object info: class "%s", isvalid %d, running "%s"',cl,vl,rn),'error');
                        end
                    case 'nicolet'
                        enableEntireGUI(this);
                    case 'blackrock'
                        enableEntireGUI(this);
                    otherwise
                        error('Unknown source mode "%s"',mode);
                end
            end
        end % END function recover
        
        function outdir = getSelectedOutputDirectory(this)
            idxOutputDir = get(this.guiHandles.listboxOutputDirectory,'Value');
            outputDirs = get(this.guiHandles.listboxOutputDirectory,'String');
            if idxOutputDir==length(outputDirs)
                outdir = get(this.guiHandles.editOutputDirectory,'String');
            else
                outdir = outputDirs{idxOutputDir};
            end
        end % END function getSelectedOutputDirectory
        
        function [participant,participantInfo] = getSelectedParticipant(this)
            idxSelected = get(this.guiHandles.listboxParticipant,'Value');
            if isempty(idxSelected)
                participant = [];
                participantInfo = [];
            else
                assert(length(idxSelected)==1,'Found multiple participants selected');
                allParticipantIDs = get(this.guiHandles.listboxParticipant,'String');
                participantInfo = this.hInterface.getParticipantInfo(allParticipantIDs{idxSelected});
                participant = participantInfo.ParticipantID{1};
            end
        end % END function getSelectedParticipant
        
        function procedure = getSelectedProcedure(this)
            participant = getSelectedParticipant(this);
            procedureStrings = get(this.guiHandles.listboxProcedure,'String');
            idxSelected = get(this.guiHandles.listboxProcedure,'Value');
            if idxSelected == length(procedureStrings) % "New Procedure"
                procedure = getNewProcedureInfo(this);
            else % some other procedure is selected
                allProcedures = this.hInterface.getParticipantProcedures(participant);
                assert(~isempty(allProcedures),'No procedures found for participant "%s"',participant);
                procedure = allProcedures(idxSelected,:);
            end
        end % END function getSelectedProcedure
        
        function procedure = getNewProcedureInfo(this)
            
            % get participant info
            participant = getSelectedParticipant(this);
            idxType = get(this.guiHandles.popupProcedureType,'Value');
            if idxType==1
                type = [];
            else
                allTypes = get(this.guiHandles.popupProcedureType,'String');
                type = allTypes{idxType};
            end
            
            % process procedure date
            try
                procdate = get(this.guiHandles.editProcedureDate,'String');
                if strcmpi(procdate,'[Procedure Date]')
                    procdate = [];
                else
                    procdate = Ingest.Interface.static__str2date(procdate);
                end
            catch ME
                msg = util.errorMessage(ME,'noscreen','nolink');
                error('Invalid procedure date: %s',msg);
            end
            
            % process recording date
            try
                recdate = get(this.guiHandles.editRecordingDate,'String');
                if strcmpi(recdate,'[Recording Date]')
                    recdate = [];
                else
                    recdate = Ingest.Interface.static__str2date(recdate);
                end
            catch ME
                msg = util.errorMessage(ME,'noscreen','nolink');
                error('Invalid recording date: %s',msg);
            end
            
            % create procedure table
            varnames = this.hInterface.ProcedureList.Properties.VariableNames;
            procedure = cell2table({participant,type,procdate,recdate,recdate},'VariableNames',varnames);
        end % END function getNewProcedureInfo
        
        function keyPressHandler(~,kp)
            switch(kp)
            end
        end % END function keyPressHandler
        
        function close(this)
            delete(this);
        end % END function close
        
        function delete(this)
            try delete(this.hFigure); catch ME, util.errorMessage(ME); end
        end % END function delete
    end % END methods
    
    methods(Access=private)
        function setUserStatus(this,msg)
            set(this.guiHandles.textStatus,'String',msg);
            this.hDebug.log(sprintf('User status changed to "%s"',msg),'debug');
        end % END function setUserStatus
        
        function disableEntireGUI(this)
            this.guiEnableStatus = cell(1,length(this.guiElements));
            for kk=1:length(this.guiElements)
                this.guiEnableStatus{kk} = get(this.guiHandles.(this.guiElements{kk}),'Enable');
                if any(strcmpi(this.guiElements{kk},{'buttonRecover','buttonKeyboard'}))
                    set(this.guiHandles.(this.guiElements{kk}),'Enable','on');
                else
                    set(this.guiHandles.(this.guiElements{kk}),'Enable','off');
                end
            end
        end % END function disableEntireGUI
        
        function enableEntireGUI(this,force)
            if nargin<2||isempty(force),force=false;end
            if ~force&&isempty(this.guiEnableStatus),return;end
            for kk=1:length(this.guiElements)
                if force
                    val = 'on';
                else
                    val = this.guiEnableStatus{kk};
                end
                set(this.guiHandles.(this.guiElements{kk}),'Enable',val);
            end
            this.guiEnableStatus = [];
        end % END function enableEntireGUI
    end % END methods(Access=private)
end % END classdef GUI