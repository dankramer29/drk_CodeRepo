function layout(this)

% delete any old GUIs
ff = findobj('Name',this.name);
delete(ff);

% set figure position based on screen dimensions
figpos = [250 40 this.width this.height];
set(0,'units','pixels');
rootProps = get(0);
if isfield(rootProps,'ScreenSize')
    figleft = max(rootProps.ScreenSize(1)+this.screenMargin(1)-1,(rootProps.ScreenSize(3)-this.width-this.screenMargin(3))/2);
    figbottom = max(rootProps.ScreenSize(2)+this.screenMargin(2)-1,(rootProps.ScreenSize(4)-this.height-this.screenMargin(4))/2);
    figpos = [figleft figbottom this.width this.height];
end

% create the figure
this.hFigure = figure(...
    'Units','pixels',...
    'Color',[0.94 0.94 0.94],...
    'Position',figpos,...
    'PaperPositionMode','auto',...
    'NumberTitle','off',...
    'WindowKeyPressFcn',@(h,kp)keyPressHandler(this,kp),...
    'Resize','off',...
    'MenuBar','none',...
    'name',this.name,...
    'ToolBar','none',...
    'Tag','ndb');
this.hFigure.CloseRequestFcn = @(src,dt)close(this);

% status readout
currLeft = this.outerSpacing;
currBottom = 0;
localWidth = this.width-2*10;
localHeight = 20;
uicontrol(...
    'Parent',this.hFigure,...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','',...
    'HorizontalAlignment','left',...
    'Style','text',...
    'FontSize',8,...
    'Tag','textStatus');


%--------------%
% SOURCE PANEL %
%--------------%
currLeft = this.outerSpacing;
currBottom = this.height - this.outerSpacing - 2*this.outerSpacing - 5*this.rowHeight - 2*this.rowSpacing;
localWidth = this.width - 2*this.outerSpacing;
localHeight = 2*this.rowSpacing + 5*this.rowHeight + 2*this.outerSpacing + this.rowSpacing;
sourcePanel = uipanel(...
    'Parent',this.hFigure,...
    'Units','pixels',...
    'Title','Source',...
    'Tag','panelSource',...
    'Position',[currLeft currBottom localWidth localHeight]);
sourcePanelPosition = get(sourcePanel,'position');

% directory selector
currLeft = this.outerSpacing;
currBottom = sourcePanelPosition(4) - this.outerSpacing - this.rowSpacing - this.rowHeight;
localHeight = this.rowHeight;
localWidth = sourcePanelPosition(3) - 2*this.outerSpacing - 100 - this.elemSpacing;
uicontrol(...
    'Parent',sourcePanel,...
    'FontSize',7,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom+2 localWidth localHeight-2],...
    'String','[Select data folder]',...
    'enable','off',...
    'Style','edit',...
    'Tag','editDataFolder');
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 100;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',sourcePanel,...
    'Position',[currLeft currBottom+1 localWidth localHeight],...
    'Style','pushbutton',...
    'Tag','buttonBrowse',...
    'String','Browse',...
    'Callback',@(h,evt)buttonBrowse_Callback);

% file selector
currLeft = this.outerSpacing;
currBottom = currBottom - 2*this.rowSpacing - 4*this.rowHeight;
localHeight = 4*this.rowHeight;
localWidth = sourcePanelPosition(3) - 2*this.outerSpacing - 100 - this.elemSpacing;
listboxSourceFiles = uicontrol(...
    'Parent',sourcePanel,...
    'FontSize',7,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom+2 localWidth localHeight-2],...
    'String',{'[No files added]'},...
    'enable','off',...
    'max',2,'min',0,...
    'Value',[],...
    'Style','listbox',...
    'Tag','listboxSourceFiles',...
    'Callback',@(h,evt)listboxSourceFiles_Callback);
set(listboxSourceFiles,'Value',[]);

% Reload directory
currLeft = currLeft + localWidth + this.elemSpacing;
currBottom = sourcePanelPosition(4) - this.outerSpacing - 3*this.rowSpacing - 2*this.rowHeight;
localWidth = 100;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',sourcePanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','Reload Directory',...
    'Style','pushButton',...
    'Tag','buttonReloadDirectory',...
    'Callback',@(h,evt)buttonReloadDirectory_Callback);

% Add file
currBottom = currBottom - this.rowHeight - this.rowSpacing;
localWidth = 100;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',sourcePanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','Add File',...
    'Style','pushButton',...
    'Tag','buttonAddFile',...
    'Callback',@(h,evt)buttonAddFile_Callback);

% Remove file
currBottom = currBottom - this.rowHeight - this.rowSpacing;
localWidth = 100;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',sourcePanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','Remove File',...
    'Style','pushButton',...
    'Tag','buttonRemoveFile',...
    'Callback',@(h,evt)buttonRemoveFile_Callback);


%--------------%
% OUTPUT PANEL %
%--------------%
currLeft = this.outerSpacing;
currBottom = sourcePanelPosition(2) - 2*this.elemSpacing - 3*this.rowSpacing - 3*this.rowHeight - 2*this.outerSpacing;
localWidth = this.width - 2*this.outerSpacing;
localHeight = 3*this.rowSpacing + 3*this.rowHeight + 2*this.outerSpacing;
outputPanel = uipanel(...
    'Parent',this.hFigure,...
    'Units','pixels',...
    'Title','Output',...
    'Tag','panelOutput',...
    'Position',[currLeft currBottom localWidth localHeight]);
outputPanelPosition = get(outputPanel,'position');

% output directory
currLeft = this.outerSpacing;
currBottom = outputPanelPosition(4) - this.outerSpacing - 2*this.rowSpacing - 2*this.rowHeight - 1*this.elemSpacing;
localHeight = 2*this.rowHeight + 1*this.rowSpacing + 2*this.elemSpacing;
localWidth = outputPanelPosition(3) - 2*this.outerSpacing;
listboxOutputDirectory = uicontrol(...
    'Parent',outputPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String',[util.ascell(env.get('data')) {'Custom Path'}],...
    'Enable','off',...
    'max',2,'min',0,...
    'Value',[],...
    'Style','listbox',...
    'Tag','listboxOutputDirectory',...
    'Callback',@(h,evt)listboxOutputDirectory_Callback);
set(listboxOutputDirectory,'Value',[]);
currBottom = currBottom - this.rowSpacing - this.rowHeight;
localHeight = this.rowHeight;
localWidth = outputPanelPosition(3) - 2*this.outerSpacing - this.elemSpacing - 100;
uicontrol(...
    'Parent',outputPanel,...
    'enable','off',...
    'FontSize',7,...
    'HorizontalAlignment','left',...
    'Enable','off',...
    'ForegroundColor',[0.6 0.6 0.6],...
    'Position',[currLeft currBottom+2 localWidth localHeight-2],...
    'String','[Select output directory]',...
    'Style','edit',...
    'Tag','editOutputDirectory');

% apply custom path button
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 100;
uicontrol(...
    'Parent',outputPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','Apply',...
    'Style','pushButton',...
    'Tag','buttonApplyCustomPath',...
    'Callback',@(h,evt)buttonApplyCustomPath_Callback);


%-------------------------%
% PATIENT/PROCEDURE PANEL %
%-------------------------%
currLeft = this.outerSpacing;
currBottom = outputPanelPosition(2) - 2*this.elemSpacing - 4*this.rowSpacing - 4*this.rowHeight - 2*this.outerSpacing;
localWidth = this.width - 2*this.outerSpacing;
localHeight = 3*this.rowSpacing + 4*this.rowHeight + 2*this.outerSpacing;
participantPanel = uipanel(...
    'Parent',this.hFigure,...
    'Units','pixels',...
    'Title','Participant / Procedure',...
    'Tag','panelParticipant',...
    'Position',[currLeft currBottom localWidth localHeight]);
participantPanelPosition = get(participantPanel,'position');

% participant selector
currLeft = this.outerSpacing;
currBottom = this.outerSpacing;
localWidth = 80;
localHeight = participantPanelPosition(4) - 2*this.outerSpacing;
listboxParticipant = uicontrol(...
    'Parent',participantPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String', unique(this.hInterface.ParticipantList.ParticipantID),...
    'Enable','off',...
    'max',2,'min',0,...
    'Value',[],...
    'Style', 'listbox',...
    'Tag', 'listboxParticipant',...
    'Callback',@(h,evt)listboxParticipant_Callback);
set(listboxParticipant,'Value',[]);

% procedure selector
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 150;
uicontrol(...
    'Parent',participantPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String',{},...
    'Style', 'listbox',...
    'Value',1,...
    'Tag', 'listboxProcedure',...
    'Callback',@(h,evt)listboxProcedure_Callback);

% Procedure Type
currLeft = currLeft + localWidth + 3*this.elemSpacing;
currBottom = participantPanelPosition(4) - this.outerSpacing - this.rowHeight;
localWidth = participantPanelPosition(3) - currLeft - this.outerSpacing;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',participantPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String',[{'[Procedure Type]'}; this.hInterface.ProcedureTypes.ProcedureDescription],...
    'Style', 'popupmenu',...
    'Tag', 'popupProcedureType');

% Procedure Date
currBottom = currBottom - this.rowSpacing - this.rowHeight;
localWidth = participantPanelPosition(3) - currLeft - this.outerSpacing;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',participantPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'ForegroundColor',[0.6 0.6 0.6],...
    'String', '[Procedure Date YYYYMMDD]',...
    'Style', 'edit',...
    'Tag', 'editProcedureDate');

% Recording Date
currBottom = currBottom - this.rowSpacing - this.rowHeight;
localWidth = participantPanelPosition(3) - currLeft - this.outerSpacing;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',participantPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'ForegroundColor',[0.6 0.6 0.6],...
    'String', '[Recording Date YYYYMMDD]',...
    'Style', 'edit',...
    'Tag', 'editRecordingDate');

% Auto-detect button
currBottom = currBottom - this.rowSpacing - this.rowHeight;
localWidth = participantPanelPosition(3) - currLeft - this.outerSpacing;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',participantPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','Auto-Detect',...
    'Style','pushButton',...
    'Tag','buttonAutoDetectParticipant',...
    'Callback',@(h,evt)buttonAutoDetectParticipant_Callback);



%------------%
% GRID PANEL %
%------------%
currLeft = this.outerSpacing;
currBottom = participantPanelPosition(2) - 2*this.elemSpacing - 6*this.rowSpacing - 6*this.rowHeight - 2*this.outerSpacing;
localWidth = this.width - 2*this.outerSpacing;
localHeight = 5*this.rowSpacing + 6*this.rowHeight + 2*this.outerSpacing;
gridPanel = uipanel(...
    'Parent',this.hFigure,...
    'Units','pixels',...
    'Title','Grids',...
    'Tag','panelParticipant',...
    'Position',[currLeft currBottom localWidth localHeight]);
gridPanelPosition = get(gridPanel,'position');

% Grid Label
fullWidthAvailable = gridPanelPosition(3) - 2*this.outerSpacing - 3*this.elemSpacing;
currLeft = this.outerSpacing;
currBottom = gridPanelPosition(4) - this.outerSpacing - this.rowSpacing - this.rowHeight;
localHeight = this.rowHeight;
localWidth = 0.15*fullWidthAvailable;
uicontrol(...
    'Parent',gridPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom+2 localWidth localHeight-2],...
    'String','[Label]',...
    'Enable','off',...
    'ForegroundColor',[0.6 0.6 0.6],...
    'Style','edit',...
    'Tag', 'editGridLabel');

% Grid Hemisphere
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 0.15*fullWidthAvailable;
uicontrol(...
    'Parent',gridPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String', {'Left', 'Right'},...
    'Style', 'popupmenu',...
    'Tag', 'popupGridHemisphere');

% Grid Location
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 0.4*fullWidthAvailable;
uicontrol(...
    'Parent',gridPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String', this.hInterface.GridLocations,...
    'Style', 'popupmenu',...
    'Tag', 'popupGridLocation');

% Grid Template
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 0.3*fullWidthAvailable;
uicontrol(...
    'Parent',gridPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String', this.hInterface.GridTemplates.TemplateName,...
    'Style', 'popupmenu',...
    'Tag', 'popupGridTemplate');

% Load Grid Button
currLeft = currLeft + localWidth - 200 - this.elemSpacing;
currBottom = currBottom - this.rowSpacing - this.rowHeight;
localWidth = 100;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',gridPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','Load Grid',...
    'Style','pushButton',...
    'Tag','buttonLoadGrid',...
    'Callback',@(h,evt)buttonLoadGrid_Callback);

% Add Grid Button
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 100;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',gridPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','Add Grid',...
    'Style','pushButton',...
    'Tag','buttonAddGrid',...
    'Callback',@(h,evt)buttonAddGrid_Callback);

% Added Grids Listbox
currLeft = this.outerSpacing;
currBottom = currBottom - 3*this.rowSpacing - 3*this.rowHeight;
localWidth = gridPanelPosition(3) - 2*this.outerSpacing;
localHeight = 3*this.rowHeight;
uicontrol(...
    'Parent',gridPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'Style','listbox',...
    'Tag', 'listboxGrid');

% remove grid pushbutton
currLeft = currLeft + localWidth - 100;
currBottom = currBottom - this.rowSpacing - this.rowHeight;
localWidth = 100;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',gridPanel,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','Remove Grid',...
    'Style','pushbutton',...
    'Tag','buttonRemoveGrid',...
    'Callback',@(h,evt)buttonRemoveGrid_Callback);




%-----------%
% EXECUTION %
%-----------%

% Run Button
currBottom = this.outerSpacing + this.elemSpacing;
currLeft = this.outerSpacing;
localWidth = (1/3)*(this.width - 2*this.outerSpacing - 2*this.elemSpacing);
localHeight = gridPanelPosition(2) - 2*this.outerSpacing;
uicontrol(...
    'Parent',this.hFigure,...
    'HorizontalAlignment','right',...
    'Position',[currLeft currBottom+2 localWidth localHeight],...
    'Enable','off',...
    'String','Run',...
    'Style','pushbutton',...
    'Tag','buttonRun',...
    'Callback',@(h,evt)buttonRun_Callback);

% Recover Button
currBottom = this.outerSpacing + this.elemSpacing;
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = (1/3)*(this.width - 2*this.outerSpacing - 2*this.elemSpacing);
localHeight = gridPanelPosition(2) - 2*this.outerSpacing;
uicontrol(...
    'Parent',this.hFigure,...
    'HorizontalAlignment','right',...
    'Position',[currLeft currBottom+2 localWidth localHeight],...
    'Enable','off',...
    'String','Recover',...
    'Style','pushbutton',...
    'Tag','buttonRecover',...
    'Callback',@(h,evt)buttonRecover_Callback);

% Keyboard Button
currBottom = this.outerSpacing + this.elemSpacing;
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = (1/3)*(this.width - 2*this.outerSpacing - 2*this.elemSpacing);
localHeight = gridPanelPosition(2) - 2*this.outerSpacing;
uicontrol(...
    'Parent',this.hFigure,...
    'HorizontalAlignment','right',...
    'Position',[currLeft currBottom+2 localWidth localHeight],...
    'Enable','off',...
    'String','Keyboard',...
    'Style','pushbutton',...
    'Tag','buttonKeyboard',...
    'Callback',@(h,evt)buttonKeyboard_Callback);



% pull out gui handles
this.guiHandles = guihandles(this.hFigure);



    function buttonBrowse_Callback(~,~,srcdir)
        try
            if nargin<3 || exist(srcdir,'dir')~=7
                datapath = util.ascell(env.get('data'));
                if exist(fullfile(datapath{1},'incoming'),'dir')==7
                    srcdir = uigetdir(fullfile(datapath{1},'incoming'),'Select Data Folder');
                elseif exist(datapath{1},'dir')==7
                    srcdir = uigetdir(datapath{1},'Select Data Folder');
                else
                    srcdir = uigetdir('.','Select Data Folder');
                end
            else
                assert(exist(srcdir,'dir')==7,'Could not find source directory "%s"',srcdir);
            end
            if ~ischar(srcdir)||isempty(srcdir),return;end
        catch ME
            util.errorMessage(ME);
        end
        
        % process the established source directory
        set(this.guiHandles.editDataFolder,'String',srcdir);
        this.hInterface.addSourceFilesFromDirectory(srcdir);
        this.updateSourceFiles;
        
        % configure the GUI for the next step
        set(this.guiHandles.listboxSourceFiles,'Enable','on');
        set(this.guiHandles.buttonReloadDirectory,'Enable','on');
        set(this.guiHandles.buttonAddFile,'Enable','on');
        set(this.guiHandles.buttonRemoveFile,'Enable','on');
        set(this.guiHandles.listboxOutputDirectory,'Enable','on');
        set(this.guiHandles.editOutputDirectory,'Enable','on');
        setUserStatus(this,'Select output directory');
    end % END function buttonBrowse_Callback

    function listboxSourceFiles_Callback
    end % END function listboxSourceFiles_Callback

    function buttonReloadDirectory_Callback
        buttonBrowse_Callback(true,true,get(this.guiHandles.editDataFolder,'String'));
    end % END function buttonReloadDirectory_Callback

    function buttonAddFile_Callback
        srcfiles = get(this.guiHandles.listboxSourceFiles,'String');
        srcdir = get(this.guiHandles.editDataFolder,'String');
        [srcfile_new,srcdir_new] = uigetfile({...
                '*.ns1;*.ns2;*.ns3;*.ns4;*.ns5;*.ns6;*.nev','Blackrock Files (*.ns1, *.ns2, *.ns3, *.ns4, *.ns5, *.ns6, *.nev)';
                '.e','Natus Files (*.e)';
                '.eeg','Nicolet Files (*.eeg)';
                '*.*','All Files (*.*)'},'Select a Data File',srcdir,'MultiSelect','on');
        if isempty(srcfile_new) || (isnumeric(srcfile_new) && srcfile_new==0)
            this.hDebug.log('No files selected','error');
            return;
        end
        if ~iscell(srcfile_new),srcfile_new={srcfile_new};end
        for kk=1:length(srcfile_new)
            if ismember(srcfile_new{kk},srcfiles)
                this.hDebug.log(sprintf('File "%s" already present in list of source files',srcfile_new),'error');
                return;
            end
            [~,srcfile_base,srcfile_ext] = fileparts(srcfile_new{kk});
            this.hInterface.addSourceFile('directory',srcdir_new,'basename',srcfile_base,'extension',srcfile_ext);
        end
        updateSourceFiles(this);
    end % END function buttonAddFile_Callback

    function buttonRemoveFile_Callback
        currSelect = get(this.guiHandles.listboxSourceFiles,'Value');
        assert(length(currSelect)>=1,'No files selected');
        currSources = get(this.guiHandles.listboxSourceFiles,'String');
        [~,src_base,src_ext] = cellfun(@fileparts,currSources(currSelect),'un',0);
        for kk=1:length(src_base)
            this.hInterface.removeSourceFile('basename',src_base{kk},'extension',src_ext{kk});
        end
        updateSourceFiles(this);
    end % END function buttonRemoveFile_Callback

    function listboxOutputDirectory_Callback
        
        % enable or disable the "custom path" edit box
        allOutputDirectories = get(this.guiHandles.listboxOutputDirectory,'String');
        idx = get(this.guiHandles.listboxOutputDirectory,'Value');
        flagOutputDirectorySet = false;
        if idx==length(allOutputDirectories)
            set(this.guiHandles.editOutputDirectory,'Enable','on');
            set(this.guiHandles.editOutputDirectory,'ForegroundColor',[0 0 0]);
            set(this.guiHandles.editOutputDirectory,'String','[Enter custom path]');
            set(this.guiHandles.buttonApplyCustomPath,'Enable','on');
            this.hDebug.log('User selected custom output directory','info');
        else
            flagOutputDirectorySet = true;
            selectedOutputDirectory = allOutputDirectories{idx};
            set(this.guiHandles.buttonApplyCustomPath,'Enable','off');
            set(this.guiHandles.editOutputDirectory,'Enable','off');
            set(this.guiHandles.editOutputDirectory,'ForegroundColor',[0.6 0.6 0.6]);
            set(this.guiHandles.editOutputDirectory,'String',selectedOutputDirectory);
            this.hDebug.log(sprintf('User selected output directory "%s"',selectedOutputDirectory),'info');
        end
        
        % check whether output is set
        if flagOutputDirectorySet
            buttonApplyCustomPath_Callback;
        end
    end % END function listboxOutputDirectory_Callback

    function buttonApplyCustomPath_Callback
        
        % set up output info
        outdir = getSelectedOutputDirectory(this);
        if exist(outdir,'dir')~=7
            hPrompt = util.UserPrompt(...
                'title','Create Output Directory',...
                'question',sprintf('Output directory "%s" does not exist. Create or cancel?',outdir),...
                'option','Create','option','Cancel',...
                'default','Cancel');
            rsp = hPrompt.prompt;
            switch lower(rsp)
                case 'create'
                    [status,msg] = mkdir(outdir);
                    assert(status>0,'Could not create directory "%s": %s',outdir,msg);
                    this.hDebug.log(sprintf('User chose to create output directory "%s"',outdir),'debug');
                case 'cancel'
                    this.hDebug.log(sprintf('User chose not to create output directory "%s"',outdir),'debug');
                    this.hInterface.setOutputInfo;
                    return;
            end
        end
        outputInfo = struct('OutputDirectory',outdir);
        this.hInterface.setOutputInfo(outputInfo);
        
        % enable the participant listbox and the auto-detect button
        set(this.guiHandles.listboxParticipant,'Enable','on');
        set(this.guiHandles.buttonAutoDetectParticipant,'Enable','on');
        setUserStatus(this,'Select a participant, or auto-detect the participant/procedure');
    end % END function buttonApplyCustomPath_Callback

    function buttonAutoDetectParticipant_Callback
        
        % find the master file
        masterfile = 'master.xlsx';
        masterdir = util.ascell(env.get('data'));
        exists = cellfun(@(x)exist(fullfile(x,masterfile),'file')==2,masterdir);
        assert(any(exists),'Could not find master excel file "%s" in any of the data folders %s',masterfile,strjoin(masterdir));
        assert(nnz(exists)==1,'There should only be one master excel file "%s" (found copies in %s)',masterfile,strjoin(masterdir(exists)));
        masterdir = masterdir{exists};
        
        % read participant list from master excel file
        excel = actxserver('excel.application');
        
        % get the master password from the user
        prompt = {'Enter master password:'};
        name = 'Master Authorization';
        defaultans = {''};
        password = util.inputdlg(prompt,name,[1 50],defaultans);
        if isempty(password),return;end
        
        try
            
            % get access to resources
            workbook = excel.Workbooks.Open(fullfile(masterdir,masterfile), [], true, [], password{1});
            sheets = get(workbook,'sheets');
            sheet = get(sheets,'Item',1);
            cells = get(sheet,'Cells');
            
            % determine size of range containing data
            lastRow = sheet.Range('A1').End('xlDown').Row;
            lastCol = sheet.Range('A1').End('xlToRight').Column;
            
            % read participant ID, first, and last name
            vars = cells.Range(sprintf('A1:%s1',uint8('A')+lastCol-1)).Value;
            master = cell(lastRow,3);
            idx = 1;
            for vv=1:length(vars)
                if any(strcmpi(vars{vv},{'ParticipantID','LastName','FirstName'}))
                    col = uint8('A')+vv-1;
                    master(:,idx) = cells.Range(sprintf('%s1:%s%d',col,col,lastRow)).Value;
                    idx = idx + 1;
                end
            end
            master = cell2table(master(2:end,:),'VariableNames',master(1,:));
        catch ME
            Quit(excel);
            delete(excel);
            rethrow(ME);
        end
        Quit(excel);
        delete(excel);
        
        % extract tokens from the source directory and basename
        sourceTokensBasenames = regexpi(this.hInterface.SourceFiles.basename,'\w+','match');
        sourceTokensBasenames = unique(cat(2,sourceTokensBasenames{:}));
        sourceTokensDirectory = regexpi(this.hInterface.SourceFiles.directory,'\w+','match');
        sourceTokensDirectory = unique(cat(2,sourceTokensDirectory{:}));
        sourceTokens = [sourceTokensDirectory(:); sourceTokensBasenames(:)];
        idxTooSmall = cellfun(@(x)length(x)<3,sourceTokens);
        sourceTokens(idxTooSmall) = [];
        sourceTokens = unique(sourceTokens);
        
        % try to match tokens from the path to participant first/last name
        hits = zeros(height(master),1);
        for pp=1:height(master)
            
            % construct set of master tokens to search for in the source
            masterTokens = cell(1,3);
            if ischar(master.ParticipantID{pp}) && ~isempty(master.ParticipantID{pp})
                masterTokens{1} = master.ParticipantID{pp};
            end
            if ischar(master.FirstName{pp}) && ~isempty(master.FirstName{pp})
                masterTokens{2} = master.FirstName{pp};
            end
            if ischar(master.LastName{pp}) && ~isempty(master.LastName{pp})
                masterTokens{3} = master.LastName{pp};
            end
            masterTokens(cellfun(@isempty,masterTokens)) = [];
            
            % count hits on the master tokens
            for tt=1:length(masterTokens)
                hits(pp) = hits(pp) + nnz(~cellfun(@isempty,regexpi(sourceTokens,masterTokens{tt})));
            end
        end
        [numHits,idxMatch] = max(hits);
        assert(nnz(hits==numHits)==1,'Could not match a unique participant');
        pid = master.ParticipantID{idxMatch};
        
        hits = cellfun(@(x)nnz(strcmpi(sourceTokens,x)),this.hInterface.HospitalList.HospitalID);
        assert(nnz(hits)==1,'Could not match a unique hospital');
        hid = this.hInterface.HospitalList.HospitalID{hits>0};
        
        this.hDebug.log(sprintf('Auto-detect selected participant "%s", hospital "%s"',pid,hid),'info');
        
        % select the appropriate participant in the participant listbox
        allParticipantIDs = get(this.guiHandles.listboxParticipant,'String');
        idxParticipant = strcmpi(allParticipantIDs,pid);
        if nnz(idxParticipant)==0
            this.hInterface.setParticipantInfo(struct('ParticipantID',pid,'HospitalID',hid));
            this.hInterface.updateParticipantList;
            allParticipantIDs = this.hInterface.ParticipantList.ParticipantID;
            set(this.guiHandles.listboxParticipant,'String',allParticipantIDs);
            idxParticipant = strcmpi(allParticipantIDs,pid);
        end
        set(this.guiHandles.listboxParticipant,'Value',find(idxParticipant));
        listboxParticipant_Callback;
        
        % get recording date, phase type, day value from file name
        [recordingDate,phaseval,dayval] = getInfoFromFilename(sourceTokens);
        this.hDebug.log(sprintf('Auto-detect inferred recording date %s',datestr(recordingDate)),'info');
        
        % look for existing procedures for the selected participant
        participantProcedures = this.hInterface.getParticipantProcedures(pid);
        if height(participantProcedures)>0
            this.hDebug.log(sprintf('Found %d existing procedures for participant "%s"',height(participantProcedures),pid),'info');
            daysDiff = days(recordingDate - participantProcedures.RecordingStartDate);
            [minDays,idxProcedure] = min(daysDiff);
            assert(nnz(daysDiff==minDays)==1,'Could not identify a unique procedure');
            if minDays>21 % 3 weeks
                flagInferNewProcedure = true;
                this.hDebug.log(sprintf('Closest procedure for participant "%s" is %d days from the recording date (threshold 21 days), so inferring new procedure',pid,minDays),'info');
            else
                flagInferNewProcedure = false;
                this.hDebug.log(sprintf('Closest procedure for participant "%s" is %d days from the recording date (threshold 21 days), so updating that procedure',pid,minDays),'info');
            end
        else
            flagInferNewProcedure = true;
            this.hDebug.log(sprintf('No procedures exist yet for participant "%s" so inferring new procedure',pid),'info');
        end
        
        % infer information for a new procedure, or update for existing
        if flagInferNewProcedure
            
            % select "New Procedure" in the procedure listbox
            allProcedureStrings = get(this.guiHandles.listboxProcedure,'String');
            idxProcedureString = strcmpi(allProcedureStrings,'New Procedure');
            assert(nnz(idxProcedureString)==1,'Could not find "New Procedure" in the list of procedures');
            set(this.guiHandles.listboxProcedure,'Value',find(idxProcedureString));
            
            % see if we can get procedure type, date, etc. from file
            procedureDate = nan;
            if ~isnan(dayval)
                procedureDate = recordingDate - days(dayval-1); % day 1 is the procedure date (confirm?)
                this.hDebug.log(sprintf('Auto-detect inferred procedure date %s',datestr(procedureDate)),'info');
            end
            procedureType = nan;
            if ~isnan(phaseval)
                procedureTypeIndex = find(strcmpi(this.hInterface.ProcedureTypes.ProcedureID,sprintf('PH%d',phaseval)));
                procedureType = this.hInterface.ProcedureTypes.ProcedureID{procedureTypeIndex};
                procedureTypeValue = 1+procedureTypeIndex; % +1 because first is "New Procedure"
                assert(~isempty(procedureTypeIndex),'Could not find a procedure type matching "%s"',sprintf('PH%d',phaseval));
                this.hDebug.log(sprintf('Auto-detect inferred procedure type %s',procedureType),'info');
            end
            
            % fill in the procedure type, date, recording date
            listboxProcedure_Callback;
            if ~isnan(procedureType)
                set(this.guiHandles.popupProcedureType,'Value',procedureTypeValue);
            end
            if ~isnan(procedureDate)
                set(this.guiHandles.editProcedureDate,'String',datestr(procedureDate,'mm/dd/yyyy'));
            end
            set(this.guiHandles.editRecordingDate,'String',datestr(recordingDate,'mm/dd/yyyy'));
        else
            
            % find the procedure with the closest start date
            procedureString = sprintf('%s (%s)',participantProcedures.ProcedureType{idxProcedure},participantProcedures.ProcedureDate(idxProcedure));
            this.hDebug.log(sprintf('Set procedure string to "%s"',procedureString),'info');
            
            % select the appropriate procedure in the procedure listbox
            allProcedureStrings = get(this.guiHandles.listboxProcedure,'String');
            idxProcedureString = strcmpi(allProcedureStrings,procedureString);
            assert(nnz(idxProcedureString)==1,'Could not identify a unique procedure');
            set(this.guiHandles.listboxProcedure,'Value',find(idxProcedureString));
            listboxProcedure_Callback;
            set(this.guiHandles.editRecordingDate,'String',datestr(recordingDate,'mm/dd/yyyy'));
        end
        
%         % update status
%         setUserStatus(this,'Click "run" to begin processing');
    end % END function buttonAutoDetectParticipant_Callback

    function listboxParticipant_Callback
        selectedParticipant = this.getSelectedParticipant;
        if isempty(selectedParticipant),return;end
        participantProcedures = this.hInterface.getParticipantProcedures(selectedParticipant);
        participantProcedureStrings = arrayfun(@(x)sprintf('%s (%s)',participantProcedures.ProcedureType{x},participantProcedures.ProcedureDate(x)),1:height(participantProcedures),'UniformOutput',false);
        set(this.guiHandles.listboxProcedure,'String',[participantProcedureStrings {'New Procedure'}]);
        set(this.guiHandles.listboxProcedure,'Value',[],'Max',2,'Min',0);
        set(this.guiHandles.listboxProcedure,'Enable','on');
        set(this.guiHandles.popupProcedureType,'Enable','off');
        set(this.guiHandles.editProcedureDate,'Enable','off','ForegroundColor',[0.6 0.6 0.6]);
        set(this.guiHandles.editRecordingDate,'Enable','off','ForegroundColor',[0.6 0.6 0.6]);
        set(this.guiHandles.popupProcedureType,'Value',1);
        set(this.guiHandles.editProcedureDate,'String','[Procedure Date YYYYMMDD]');
        set(this.guiHandles.editRecordingDate,'String','[Recording Date YYYYMMDD]');
        
        % update status
        setUserStatus(this,sprintf('Identify the procedure for participant "%s"',selectedParticipant));
    end % END function listboxParticipant_Callback

    function listboxProcedure_Callback
        selectedParticipant = getSelectedParticipant(this);
        participantProcedures = this.hInterface.getParticipantProcedures(selectedParticipant);
        
        % populate fields with procedure information
        idxProcedure = get(this.guiHandles.listboxProcedure,'Value');
        if idxProcedure<=height(participantProcedures)
            selectedProcedure = participantProcedures(idxProcedure,:);
            set(this.guiHandles.popupProcedureType,'Enable','off');
            set(this.guiHandles.editProcedureDate,'Enable','off','ForegroundColor',[0.6 0.6 0.6]);
            set(this.guiHandles.editRecordingDate,'Enable','on','ForegroundColor',[0 0 0]);
            set(this.guiHandles.popupProcedureType,'Value',find(strcmpi(this.hInterface.ProcedureTypes.ProcedureID,selectedProcedure.ProcedureType{1}))+1);
            set(this.guiHandles.editProcedureDate,'String',datestr(selectedProcedure.ProcedureDate(1),'mm/dd/yyyy'));
            set(this.guiHandles.editRecordingDate,'String',sprintf('[Latest Recording %s]',selectedProcedure.RecordingEndDate(1)));
        else
            set(this.guiHandles.popupProcedureType,'Enable','on');
            set(this.guiHandles.editProcedureDate,'Enable','on','ForegroundColor',[0.0 0.0 0.0]);
            set(this.guiHandles.editRecordingDate,'Enable','on','ForegroundColor',[0.0 0.0 0.0]);
            set(this.guiHandles.popupProcedureType,'Value',1);
            set(this.guiHandles.editProcedureDate,'String','[Procedure Date YYYYMMDD]');
            set(this.guiHandles.editRecordingDate,'String','[Recording Date YYYYMMDD]');
        end
        
        % enable grid GUI elements
        set(this.guiHandles.editGridLabel,'Enable','on','ForegroundColor',[0 0 0]);
        set(this.guiHandles.popupGridHemisphere,'Enable','on');
        set(this.guiHandles.popupGridLocation,'Enable','on');
        set(this.guiHandles.popupGridTemplate,'Enable','on');
        set(this.guiHandles.buttonAddGrid,'Enable','on');
        set(this.guiHandles.buttonLoadGrid,'Enable','on');
        
        % update status
        setUserStatus(this,'Configure the grids');
    end % END function listboxProcedure_Callback

    function buttonAddGrid_Callback
        
        % compute some of the grid string entries
        locationValue = this.guiHandles.popupGridLocation.String{this.guiHandles.popupGridLocation.Value};
        hemisphereValue = this.guiHandles.popupGridHemisphere.String{this.guiHandles.popupGridHemisphere.Value};
        templateValue = this.guiHandles.popupGridTemplate.String{this.guiHandles.popupGridTemplate.Value};
        gridLabelValue = this.guiHandles.editGridLabel.String;
        
        % construct the grid string
        gridString = strjoin({num2str(length(this.guiHandles.listboxGrid.String)),...
            locationValue,...
            hemisphereValue,...
            templateValue,...
            gridLabelValue},...
            ', ');
        this.guiHandles.listboxGrid.String{end + 1} = gridString;
        this.hDebug.log(sprintf('Added grid with grid string "%s"',gridString),'info');
        
        set(this.guiHandles.buttonRemoveGrid,'Enable','on');
        set(this.guiHandles.listboxGrid,'Enable','on');
        set(this.guiHandles.buttonRun,'Enable','on');
        
        % update status
        setUserStatus(this,'Click "run" to begin processing');
    end % buttonAddGrid_Callback

    function buttonLoadGrid_Callback
        srcdir = get(this.guiHandles.editDataFolder,'String');
        [mapfile,mapdir] = uigetfile(fullfile(srcdir,'*.map;*.csv;*.txt'));
        mapfile = fullfile(mapdir,mapfile);
        if exist(mapfile,'file')~=2
            this.hDebug.log(sprintf('Could not find map file "%s"',mapfile),'error');
            return;
        end
        hMap = GridMap.Interface(mapfile);
        gridString = cell(hMap.NumGrids,1);
        for gg=1:hMap.NumGrids
            gridString{gg} = sprintf('%d,%s,%s,%s,%s',gg,hMap.GridInfo.Location{gg},hMap.GridInfo.Hemisphere{gg},hMap.GridInfo.Template{gg},hMap.GridInfo.Label{gg});
        end
        this.guiHandles.listboxGrid.String = gridString;
        this.hDebug.log(sprintf('Loaded GridMap object with %d grids',hMap.NumGrids),'info');
        
        % configure GUI
        set(this.guiHandles.buttonRemoveGrid,'Enable','on');
        set(this.guiHandles.listboxGrid,'Enable','on');
        set(this.guiHandles.buttonRun,'Enable','on');
        
        % set the interface gridmap object
        this.hInterface.setGridMap(hMap);
        
        % update status
        setUserStatus(this,'Click "run" to begin processing');
    end % buttonLoadGrid_Callback

    function buttonRemoveGrid_Callback
        idx = get(this.guiHandles.listboxGrid,'Value');
        strings = get(this.guiHandles.listboxGrid,'String');
        oldGridString = strings{idx};
        strings(idx) = [];
        set(this.guiHandles.listboxGrid,'String',strings);
        set(this.guiHandles.listboxGrid,'Value',1);
        this.hDebug.log(sprintf('Removed grid entry %d with grid string "%s"',idx,oldGridString),'info');
        
        if isempty(strings)
            set(this.guiHandles.buttonRemoveGrid,'Enable','off');
        end
    end % END function buttonRemoveGrid_Callback

    function buttonRun_Callback
        disableEntireGUI(this);
        
        try
            
            % set up the current participant
            [~,participantInfo] = getSelectedParticipant(this);
            this.hInterface.setParticipantInfo(participantInfo);
            
            % set up the current procedure
            procedure = getSelectedProcedure(this);
            procedureDate = procedure.ProcedureDate;
            assert(isa(procedureDate,'datetime'),'Invalid procedure date');
            procedureType = this.hInterface.ProcedureTypes.ProcedureID{get(this.guiHandles.popupProcedureType,'Value')-1};
            procedureInfo = struct('Date',procedureDate,'Type',procedureType);
            this.hInterface.setProcedureInfo(procedureInfo);
            
            % set up the current recording
            recordingDate = Ingest.Interface.static__str2date(get(this.guiHandles.editRecordingDate,'String'));
            recordingInfo = struct('Date',recordingDate);
            this.hInterface.setRecordingInfo(recordingInfo);
        catch ME
            
            % notify user of problem
            [msg,stack] = util.errorMessage(ME,'noscreen','nolink');
            q_srcfile = util.UserPrompt(...
                'option','Ok','option','Keyboard',...
                'default','Ok');
            response = q_srcfile.prompt(...
                'title','Run start failed',...
                'question',sprintf('Could not start: "%s" %s',msg,stack{1}));
            switch lower(response)
                case 'ok'
                    
                    % do nothing and continue on
                case 'keyboard'
                    
                    % inform user and drop into keyboard
                    util.errorMessage(ME);
                    fprintf('\n');
                    fprintf('*************************\n');
                    fprintf('* Press F5 to continue. *\n');
                    fprintf('*************************\n');
                    fprintf('\n');
                    keyboard;
                otherwise
                    error('Unknown response "%s"',response);
            end
            
            % re-enable the GUI
            enableEntireGUI(this);
            return;
        end
        
        % run conversion
        exitCode = run(this.hInterface);
        
        % re-enable the GUI
        if exitCode>0
            enableEntireGUI(this);
        end
    end % END function buttonRun_Callback

    function buttonRecover_Callback
        this.recover;
    end % END function buttonRecover_Callback

    function buttonKeyboard_Callback
        debugKeyboard(this.hInterface);
    end % END function buttonKeyboard_Callback

    function [dateval,phaseval,dayval] = getInfoFromFilename(sourceTokens)
        
        % break down processing into different modes based on the style of
        % the filename
        mode = nan;
        
        % test for Keck/Natus
        idx_mode1 = ~cellfun(@isempty,regexpi(sourceTokens,'Ph\dD\d$'));
        if any(idx_mode1)
            mode = 1;
        end
        
        % test for Rancho/Nicolet
        idx_mode2_a = ~cellfun(@isempty,regexpi(sourceTokens,'^\d{8}_\d{6}$'));
        idx_mode2_b = ~cellfun(@isempty,regexpi(sourceTokens,'^Participant'));
        if any(idx_mode2_a)&&any(idx_mode2_b)
            mode = 2;
        end
        
        % assume blackrock
        if isnan(mode)
            mode = 3;
        end
        
        % process
        switch mode
            case 1
                [dateval,phaseval,dayval] = getInfoFromKeckNatusFilename(sourceTokens);
            case 2
                [dateval,phaseval,dayval] = getInfoFromRanchoNicoletFilename(sourceTokens);
            case 3
                [dateval,phaseval,dayval] = getInfoFromKeckBlackrockFilename(sourceTokens);
            otherwise
        end
    end % END function getInfoFromFilename

    function [dateval,phaseval,dayval] = getInfoFromKeckBlackrockFilename(sourceTokens)
        idx = find(~cellfun(@isempty,regexpi(sourceTokens,'^\d{8}$')));
        assert(~isempty(idx),'Could not find any YYYYMMDD matches in source tokens');
        if length(idx)>1
            idx = idx(end);
            this.hDebug.log(sprintf('Found multiple YYYYMMDD matches in the source file tokens. Using the last match: %s',sourceTokens{idx}),'warn');
        end
        tokens = regexpi(sourceTokens{idx},'^(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})','names');
        phaseval = 2; % assume always phase 2's
        dateval = datetime(str2double(tokens.year),str2double(tokens.month),str2double(tokens.day));
        dayval = nan; % no way to know what day (since the implant) this was
    end % END function getInfoFromKeckBlackrockFilename

    function [dateval,phaseval,dayval] = getInfoFromRanchoNicoletFilename(sourceTokens)
        idx = ~cellfun(@isempty,regexpi(sourceTokens,'^\d{8}_\d{6}$'));
        tokens = regexpi(sourceTokens{idx},'^(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})','names');
        phaseval = 2; % assume always phase 2's
        dateval = datetime(str2double(tokens.year),str2double(tokens.month),str2double(tokens.day));
        dayval = nan; % no way to know what day (since the implant) this was
    end % END function getInfoFromRanchoNicoletFilename

    function [dateval,phaseval,dayval] = getInfoFromKeckNatusFilename(sourceTokens)
        idx = ~cellfun(@isempty,regexpi(sourceTokens,'Ph\dD\d$'));
        assert(nnz(idx)==1,'Could not identify unique date token');
        tokens = regexpi(sourceTokens{idx},'^.*_(?<dateval>\d+)_Ph(?<phval>\d+)D(?<dayval>\d+)$','names');
        if isempty(tokens),return;end
        dateval = tokens.dateval;
        phaseval = str2double(tokens.phval);
        dayval = str2double(tokens.dayval);
        
        yr = 2000+str2double(dateval(end-1:end)); % last two digits are always the year
        dateval(end-1:end) = []; % remaining digits are MD, MMD, MDD, or MMDD
        mnth = nan;
        dy = nan;
        if str2double(dateval(1))>1 % if first digit >1, must be M (2:9) with D or DD
            mnth = str2double(dateval(1));
            dy = str2double(dateval(2:end));
        else % if first digit ==1, could be M (1) or MM (10:12) with D or DD
            if length(dateval)==2 % must be MD
                mnth = str2double(dateval(1));
                dy = str2double(dateval(2));
            elseif length(dateval)==4 % must be MMDD
                mnth = str2double(dateval(1:2));
                dy = str2double(dateval(3:4));
            elseif length(dateval)==3 % could be MDD or MMD
                month1 = str2double(dateval(1));
                day1 = str2double(dateval(2:3));
                month2 = str2double(dateval(1:2));
                day2 = str2double(dateval(3));
                isvalid1 = month1<=12 && day1<=31;
                isvalid2 = month2<=12 && day2<=31;
                if isvalid1 && ~isvalid2 % process of elimination
                    mnth = month1;
                    dy = day1;
                elseif ~isvalid1 && isvalid2 % process of elimination
                    mnth = month2;
                    dy = day2;
                else
                    
                    % check for a match against existing procedures
                    participant = getSelectedParticipant(this);
                    procedures = getParticipantProcedures(this,participant);
                    flagFound = false;
                    for kk=1:height(procedures)
                        dt1 = datetime(yr,month1,day1);
                        dt2 = datetime(yr,month2,day2);
                        if abs(days(procedures.ProcedureDate(kk) - dt1)) < 10
                            
                            % matched, but make sure it's a unique match
                            if flagFound
                                flagFound = false;
                                break;
                            else
                                mnth = month1;
                                dy = day1;
                                flagFound = true;
                            end
                        elseif abs(days(procedures.ProcedureDate(kk) - dt2)) < 10
                            
                            % matched, but make sure it's a unique match
                            if flagFound
                                flagFound = false;
                                break;
                            else
                                mnth = month2;
                                dy = day2;
                                flagFound = true;
                            end
                        end
                    end
                    
                    % can't auto-identify, so query user
                    if ~flagFound
                        response = {};
                        while isempty(response)
                            prompt = {sprintf('Specify month from "%s": ',dateval),sprintf('Specify day from "%s": ',dateval)};
                            name = sprintf('Clarify Month/Day (%d)',yr);
                            defaultans = {'',''};
                            response = util.inputdlg(prompt,name,[1 50],defaultans);
                        end
                        mnth = str2double(response{1});
                        dy = str2double(response{2});
                    end
                end
            end
        end
        assert(~isnan(mnth)&&~isnan(dy),'Could not determine month and day');
        dateval = datetime(yr,mnth,dy);
    end % END function getInfoFromKeckNatusFilename
end % END function layout