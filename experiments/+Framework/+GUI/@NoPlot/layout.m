function layout(this)

%{

    |-------------------------------|
    |               |               |
    |               |               |
    |    fields     |     axis      |
    |               |               |
    |               |               |
    |-------------------------------|
    
%}

columnWidths(1) = round(0.4*this.width);
columnWidths(2) = this.width - columnWidths(1);

% config/status panel
currLeft = this.borderMargin + this.elemSpacing;
currBottom = this.borderMargin + this.elemSpacing;
localWidth = columnWidths(1) - 2*this.elemSpacing;
localHeight = this.height - 2*this.borderMargin;
panelConfigStatus = uipanel(...
    'Parent',this.hFigure,...
    'Units','pixels',...
    'Title','Config and Status',...
    'Tag','panelConfigStatus',...
    'Position',[currLeft currBottom localWidth localHeight]);

% axis
currLeft = columnWidths(1) + this.elemSpacing + 50;
currBottom = this.borderMargin + 20 + this.elemSpacing;
localWidth = columnWidths(2) - 2*this.elemSpacing - 50 - this.borderMargin;
localHeight = this.height - 2*this.borderMargin - 2*this.elemSpacing - 20;
axes(...
    'Parent',this.hFigure,...
    'Units','pixels',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Box','on',...
    'Tag','axisMain'...
    );


% task selectors
parentPosition = get(panelConfigStatus,'position');
currLeft = this.panelMargin;
currBottom = parentPosition(4) - 5 - this.panelMargin - this.rowHeight - this.elemSpacing;
localWidth = 100;
localHeight = this.rowHeight;
uicontrol(...
    'HorizontalAlignment','left',...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom-5 localWidth localHeight],...
    'String','Task: ',...
    'Style','text');

currLeft = currLeft + 100 + this.elemSpacing;
localWidth = parentPosition(3) - 2*this.panelMargin - this.elemSpacing - localWidth;
str = this.taskNames;
if ~this.hFramework.options.enableTask
    str = 'Recording Mode';
end
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String',str,...
    'Style','popupmenu',...
    'Tag','popupTaskNames',...
    'Callback',@(h,evt)popupTaskNames_Callback);

currLeft = this.panelMargin;
currBottom = currBottom - 1*this.rowHeight - 1*this.elemSpacing;
localWidth = 100;
localHeight = this.rowHeight;
uicontrol(...
    'HorizontalAlignment','left',...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom-5 localWidth localHeight],...
    'String','Config: ',...
    'Style','text');

currLeft = currLeft + 100 + this.elemSpacing;
localWidth = parentPosition(3) - 2*this.panelMargin - this.elemSpacing - localWidth;
localHeight = this.rowHeight;
str = 'N/A';
if ~this.hFramework.options.enableTask
    str = 'Recording Mode';
end
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String',str,...
    'Style','popupmenu',...
    'Tag','popupConfigNames',...
    'Callback',@(h,evt)popupConfigNames_Callback);


% start, stop, close buttons
currLeft = this.panelMargin;
currBottom = currBottom - 2*this.rowHeight - 3*this.elemSpacing;
localWidth = 120;
localHeight = 2*this.rowHeight;
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','Start',...
    'Style','pushbutton',...
    'Tag','buttonStart',...
    'Callback',@(h,evt)buttonStart_Callback);
currLeft = currLeft + localWidth + this.elemSpacing;
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','Stop',...
    'Style','pushbutton',...
    'Tag','buttonStop',...
    'Callback',@(h,evt)buttonStop_Callback);
currLeft = currLeft + localWidth + this.elemSpacing;
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom localWidth localHeight],...
    'Enable','off',...
    'String','Close',...
    'Style','pushbutton',...
    'Tag','buttonClose',...
    'Callback',@(h,evt)buttonClose_Callback);

% Frame
currLeft = this.panelMargin;
currBottom = currBottom - 2*this.rowHeight - this.elemSpacing;
localWidth = 60;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',panelConfigStatus,...
    'HorizontalAlignment','right',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String','Frame: ',...
    'Style','text');
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 80;
uicontrol(...
    'Parent',panelConfigStatus,...
    'enable','off',...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String','0',...
    'Style','edit',...
    'Tag','editFrameId');

% Limit Status
currLeft = this.panelMargin + 177;
localWidth = 93;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',panelConfigStatus,...
    'HorizontalAlignment','right',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String','Runtime Progress: ',...
    'Style','text');
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 40;
uicontrol(...
    'Parent',panelConfigStatus,...
    'enable','off',...
    'HorizontalAlignment','right',...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String','',...
    'Style','edit',...
    'Tag','editLimitStatus');
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 48;  
uicontrol(...
    'Parent',panelConfigStatus,...
    'enable','off',...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String','',...
    'Style','edit',...
    'Tag','editLimitUnits');

% Time
currLeft = this.panelMargin;
currBottom = currBottom - this.rowHeight - this.elemSpacing;
localWidth = 60;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',panelConfigStatus,...
    'HorizontalAlignment','right',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String','Time: ',...
    'Style','text');
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 80;
uicontrol(...
    'Parent',panelConfigStatus,...
    'enable','off',...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String','0',...
    'Style','edit',...
    'Tag','editTime');

% Limit
currLeft = this.panelMargin + 192;
localWidth = 78;
localHeight = this.rowHeight;
opts = {'Frame Limit','Time Limit'};
if this.hFramework.options.enableTask
    opts = [opts {'Task Limit'}];
end
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String',opts,...
    'Style','popupmenu',...
    'Tag','popupLimit',...
    'Callback',@(h,evt)popupLimit_Callback);
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 40;
uicontrol(...
    'Parent',panelConfigStatus,...
    'enable','on',...
    'HorizontalAlignment','right',...
    'BackgroundColor',[1 1 1],...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String',num2str(this.hFramework.options.taskLimit),...
    'Style','edit',...
    'Tag','editLimit',...
    'Callback',@(h,evt)editLimit_Callback,...
    'KeypressFcn',@(h,evt)editLimit_KeypressFcn(evt));
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 50;
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'Enable','off',...
    'String','Apply',...
    'Style','pushbutton',...
    'Tag','buttonApplyLimit',...
    'Callback',@(h,evt)buttonApplyLimit_Callback);

% Average Step
currLeft = this.panelMargin;
currBottom = currBottom - this.rowHeight - this.elemSpacing;
localWidth = 60;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',panelConfigStatus,...
    'HorizontalAlignment','right',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String','Step (Avg): ',...
    'Style','text');
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 80;
uicontrol(...
    'Parent',panelConfigStatus,...
    'enable','off',...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String','0',...
    'Style','edit',...
    'Tag','editStepAvg');

% Verbosity Level
currLeft = this.panelMargin + 160;
localWidth = 110;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String',{'Buffer Verbosity','Screen Verbosity','Neural Verbosity'},...
    'Style','popupmenu',...
    'Tag','popupVerbosity',...
    'Callback',@(h,evt)popupVerbosity_Callback);
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 40;
uicontrol(...
    'Parent',panelConfigStatus,...
    'enable','on',...
    'HorizontalAlignment','right',...
    'BackgroundColor',[1 1 1],...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String',num2str(this.hFramework.options.verbosityBuffer),...
    'Style','edit',...
    'Tag','editVerbosity',...
    'Callback',@(h,evt)editVerbosity_Callback,...
    'KeypressFcn',@(h,evt)editVerbosity_KeypressFcn(evt));
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 50;
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'Enable','off',...
    'String','Apply',...
    'Style','pushbutton',...
    'Tag','buttonApplyVerbosity',...
    'Callback',@(h,evt)buttonApplyVerbosity_Callback);

% Instantaneous Step
currLeft = this.panelMargin;
currBottom = currBottom - this.rowHeight - this.elemSpacing;
localWidth = 60;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',panelConfigStatus,...
    'HorizontalAlignment','right',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String','Step (Inst): ',...
    'Style','text',...
    'Tag','textStepInst');
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 80;
uicontrol(...
    'Parent',panelConfigStatus,...
    'enable','off',...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String','0',...
    'Style','edit',...
    'Tag','editStepInst');

% NSP names
currLeft = this.panelMargin + 210;
localWidth = 60;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String',{'No NSPs'},...
    'Style','popupmenu',...
    'Enable','off',...
    'Tag','popupNSPLabels',...
    'Callback',@(h,evt)popupNSPLabels_Callback);
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 40;
uicontrol(...
    'Parent',panelConfigStatus,...
    'enable','off',...
    'HorizontalAlignment','right',...
    'BackgroundColor',[1 1 1],...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String','N/A',...
    'Style','edit',...
    'Tag','editNSPLabels',...
    'Callback',@(h,evt)editNSPLabels_Callback,...
    'KeypressFcn',@(h,evt)editNSPLabels_KeypressFcn(evt));
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 50;
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'Enable','off',...
    'String','Apply',...
    'Style','pushbutton',...
    'Tag','buttonApplyNSPLabels',...
    'Callback',@(h,evt)buttonApplyNSPLabels_Callback);

% Num Features
currLeft = this.panelMargin;
currBottom = currBottom - this.rowHeight - this.elemSpacing;
localWidth = 60;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',panelConfigStatus,...
    'HorizontalAlignment','right',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String','# Features: ',...
    'Style','text');
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 80;
uicontrol(...
    'Parent',panelConfigStatus,...
    'enable','off',...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String','0',...
    'Style','edit',...
    'Tag','editNumFeatures');

% Num DOFs
currLeft = this.panelMargin;
currBottom = currBottom - this.rowHeight - this.elemSpacing;
localWidth = 60;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',panelConfigStatus,...
    'HorizontalAlignment','right',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String','# DOFs: ',...
    'Style','text');
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 80;
uicontrol(...
    'Parent',panelConfigStatus,...
    'enable','off',...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom+4 localWidth localHeight],...
    'String','0',...
    'Style','edit',...
    'Tag','editNumDOFs');

% comment field
currLeft = this.panelMargin;
currBottom = this.panelMargin;
localWidth = columnWidths(1) - 2*this.elemSpacing - 2*this.panelMargin - 60 - this.elemSpacing;
localHeight = this.rowHeight;
uicontrol(...
    'Parent',panelConfigStatus,...
    'HorizontalAlignment','left',...
    'Position',[currLeft currBottom localWidth localHeight],...
    'BackgroundColor',[1 1 1],...
    'String','',...
    'Style','edit',...
    'Tag','editComment');
currLeft = currLeft + localWidth + this.elemSpacing;
localWidth = 60;
uicontrol(...
    'Parent',panelConfigStatus,...
    'Position',[currLeft currBottom localWidth localHeight],...
    'String','Comment',...
    'Style','pushbutton',...
    'Tag','buttonComment',...
    'Callback',@(~,~)comment__);

% pull out gui handles
this.guiHandles = guihandles(this.hFigure);



    function comment__
        comment(this.hFramework,'USER',get(this.guiHandles.editComment,'String'));
    end % END function comment

    function val = getNSPLabel(which)
        which = str2double(which(end));
        names = this.hFramework.hNeuralSource.getNSPLabels;
        val = names{which};
    end % END function getNSPLabel

    function setNSPLabel(which,name)
        which = str2double(which(end)); % assumes which='NSPx'
        this.hFramework.hNeuralSource.setNSPLabels({name},which);
    end % END function setNSPLabel

    function popupNSPLabels_Callback
        
        % pull together info and run the generic callback
        hPopup = this.guiHandles.popupNSPLabels;
        hEdit = this.guiHandles.editNSPLabels;
        names = get(hPopup,'String');
        peaPopupCallback(hPopup,hEdit,names,@getNSPLabel);
    end % END function popupNSPLabels_Callback

    function editNSPLabels_Callback
        
        % pull together info and run the generic callback
        hPopup = this.guiHandles.popupNSPLabels;
        hEdit = this.guiHandles.editNSPLabels;
        hApply = this.guiHandles.buttonApplyNSPLabels;
        names = get(hPopup,'String');
        peaEditCallback(hPopup,hEdit,hApply,names,@getNSPLabel,@setNSPLabel,@(x)x,false,false);
    end % END function editNSPLabels_Callback

    function editNSPLabels_KeypressFcn(evt)
        
        % pull together info and run the generic callback
        hEdit = this.guiHandles.editNSPLabels;
        peaEditKeypress(evt,hEdit);
    end % END function editNSPLabels_KeypressFcn

    function buttonApplyNSPLabels_Callback
        
        % pull together info and run the generic callback
        hPopup = this.guiHandles.popupVerbosity;
        hEdit = this.guiHandles.editVerbosity;
        hApply = this.guiHandles.buttonApplyVerbosity;
        names = {'verbosityBuffer','verbosityScreen','verbosityNeural'};
        peaApplyCallback(hPopup,hEdit,hApply,names,@setNSPLabel,@(x)x,false,false);
    end % END function buttonApplyNSPLabels_Callback

    function popupVerbosity_Callback
        
        % pull together info and run the generic callback
        hPopup = this.guiHandles.popupVerbosity;
        hEdit = this.guiHandles.editVerbosity;
        names = {'verbosityBuffer','verbosityScreen','verbosityNeural'};
        peaPopupCallback(hPopup,hEdit,names,@getFrameworkOption);
    end % END function popupVerbosity_Callback

    function editVerbosity_Callback
        
        % pull together info and run the generic callback
        hPopup = this.guiHandles.popupVerbosity;
        hEdit = this.guiHandles.editVerbosity;
        hApply = this.guiHandles.buttonApplyVerbosity;
        names = {'verbosityBuffer','verbosityScreen','verbosityNeural'};
        peaEditCallback(hPopup,hEdit,hApply,names,@getFrameworkOption,@setFrameworkOption,@restoreFrameworkOption,false,true);
    end % END function editVerbosity_Callback

    function editVerbosity_KeypressFcn(evt)
        
        % pull together info and run the generic callback
        hEdit = this.guiHandles.editVerbosity;
        peaEditKeypress(evt,hEdit);
    end % END function editVerbosity_KeypressFcn

    function buttonApplyVerbosity_Callback
        
        % pull together info and run the generic callback
        hPopup = this.guiHandles.popupVerbosity;
        hEdit = this.guiHandles.editVerbosity;
        hApply = this.guiHandles.buttonApplyVerbosity;
        names = {'verbosityBuffer','verbosityScreen','verbosityNeural'};
        peaApplyCallback(hPopup,hEdit,hApply,names,@setFrameworkOption,@restoreFrameworkOption,false,true);
    end % END function buttonApplyVerbosity_Callback

    function popupLimit_Callback
        
        % pull together info and run the generic callback
        hPopup = this.guiHandles.popupLimit;
        hEdit = this.guiHandles.editLimit;
        names = {'frameLimit','timeLimit','taskLimit'};
        peaPopupCallback(hPopup,hEdit,names,@getFrameworkOption);
    end % END function popupLimit_Callback

    function editLimit_Callback
        
        % pull together info and run the generic callback
        hPopup = this.guiHandles.popupLimit;
        hEdit = this.guiHandles.editLimit;
        hApply = this.guiHandles.buttonApplyLimit;
        names = {'frameLimit','timeLimit','taskLimit'};
        peaEditCallback(hPopup,hEdit,hApply,names,@getFrameworkOption,@setFrameworkOption,@restoreFrameworkOption,true,true);
    end % END function editLimit_Callback

    function editLimit_KeypressFcn(evt)
        
        % pull together info and run the generic callback
        hEdit = this.guiHandles.editLimit;
        peaEditKeypress(evt,hEdit);
    end % END function editLimit_KeypressFcn

    function buttonApplyLimit_Callback
        
        % pull together info and run the generic callback
        hPopup = this.guiHandles.popupLimit;
        hEdit = this.guiHandles.editLimit;
        hApply = this.guiHandles.buttonApplyLimit;
        names = {'frameLimit','timeLimit','taskLimit'};
        peaApplyCallback(hPopup,hEdit,hApply,names,@setFrameworkOption,@restoreFrameworkOption,true,true);
    end % END function buttonApplyLimit_Callback

    function val = getFrameworkOption(name)
        val = this.hFramework.options.(name);
    end % END function getFrameworkOption

    function setFrameworkOption(name,val)
        this.hFramework.options.(name) = val;
    end % END function setFrameworkOption

    function restoreFrameworkOption(name)
        restore(this.hFramework.options,name);
    end % END function restoreFrameworkOption

    function peaPopupCallback(hPopup,hEdit,names,getVal)
        % PEAPOPUPCALLBACK Generic popup callback for a specific context
        %
        %   PEA stands for Popup / Edit / Apply.  It describes a specific
        %   setup of UI controls in which a popup list allows selection of
        %   one of a category of things, the value associated with that
        %   category is populated into the edit box, and then the user may
        %   change that value, and either press enter or click an apply
        %   button.
        %
        %   The popup's purpose is to select from among multiple
        %   categories, and this callback's purpose is to update the
        %   value displayed in the edit box if the selection changes.
        %
        %   PEAPOPUPCALLBACK(HPOPUP,HEDIT,NAMES)
        %   Run the generic callback for the popup HPOPUP using the edit
        %   HEDIT, and the Framework Option property names NAMES.  The
        %   entries of NAMES must correspond to the entries of the popup,
        %   and in the same order.
        
        % get the selected limit category
        which = get(hPopup,'Value');
        
        % set the edit box to the value of the selected limit category
        set(hEdit,'String',feval(getVal,names{which}));
        
    end % END function pebPopupCallback

    function peaEditCallback(hPopup,hEdit,hApply,names,getVal,setVal,restoreVal,FlagRestore,FlagNumeric)
        % PEAEDITCALLBACK Generic edit callback for a specific context
        %
        %   PEA stands for Popup / Edit / Apply.  It describes a specific
        %   setup of UI controls in which a popup list allows selection of
        %   one of a category of things, the value associated with that
        %   category is populated into the edit box, and then the user may
        %   change that value, and either press enter or click an apply
        %   button.
        %
        %   The edit's purpose is to display and allow edits of the current
        %   category's value, and this callback's purpose is to detect
        %   changes and either directly apply them (enter key pressed) or
        %   enable the apply button.
        %
        %   PEAEDITCALLBACK(HPOPUP,HEDIT,HAPPLY,NAMES)
        %   Run the generic callback for the edit HEDIT using the popup
        %   HPOPUP, the apply button HAPPLY, and the Framework Option
        %   property names NAMES.  The entries of NAMES must correspond to
        %   the entries of the popup, and in the same order.
        
        % get category selection
        which = get(hPopup,'Value');
        
        % get new and old values
        newVal = get(hEdit,'String');
        if FlagNumeric, newVal = str2double(newVal); end
        oldVal = feval(getVal,names{which});
        
        % check if an updated value has been entered
        if (FlagNumeric && newVal == oldVal) || (~FlagNumeric && strcmpi(newVal,oldVal))
            
            % same as old value, so no action
            set(hApply,'enable','off');
        else
            
            % detect enter/return, or enable apply button
            if get(hEdit,'Value')
                
                % keypress sets value=1, so directly update value
                set(hEdit,'Value',0);
                peaApplyCallback(hPopup,hEdit,hApply,names,setVal,restoreVal,FlagRestore,FlagNumeric);
            else
                
                % enable the apply button
                set(hApply,'enable','on');
            end
        end
    end % END function peaEditCallback

    function peaEditKeypress(evt,hEdit)
        % PEAEDITKEYPRESS Generic edit keypress for a specific context
        %
        %   PEA stands for Popup / Edit / Apply.  It describes a specific
        %   setup of UI controls in which a popup list allows selection of
        %   one of a category of things, the value associated with that
        %   category is populated into the edit box, and then the user may
        %   change that value, and either press enter or click an apply
        %   button.
        %
        %   The edit's purpose is to display and allow edits of the current
        %   category's value, and this keypress's purpose is to detect
        %   when an enter or return key is pressed.
        %
        %   PEAEDITKEYPRESS(EVT,HEDIT)
        %   Run the generic keypress for the edit HEDIT using the event
        %   data EVT provided by MATLAB for a keypress event.
        
        if strcmpi(evt.Key,'enter')||strcmpi(evt.Key,'return')
            set(hEdit,'Value',1);
        end
    end % END function peaEditKeypress

    function peaApplyCallback(hPopup,hEdit,hApply,names,setVal,restoreVal,FlagRestore,FlagNumeric)
        % PEAAPPLYCALLBACK Generic button callback for a specific context
        %
        %   PEA stands for Popup / Edit / Apply.  It describes a specific
        %   setup of UI controls in which a popup list allows selection of
        %   one of a category of things, the value associated with that
        %   category is populated into the edit box, and then the user may
        %   change that value, and either press enter or click an apply
        %   button.
        %
        %   The apply button's purpose is to allow the user to apply
        %   changes made to the value of the selected category, and this
        %   callback's purpose is to save the value once the user has
        %   pressed the button.
        %
        %   PEAAPPLYCALLBACK(HPOPUP,HEDIT,HAPPLY,NAMES)
        %   Run the generic callback for the apply button HAPPLY using the
        %   edit HEDIT, the popup HPOPUP, and the Framework Option property
        %   names NAMES.  The entries of NAMES must correspond to the
        %   entries of the popup, and in the same order.
        
        % make sure apply button is off
        set(hApply,'Enable','off');
        
        % get the new value
        list = get(hPopup,'String');
        which = get(hPopup,'Value');
        val = get(hEdit,'String');
        if FlagNumeric, val = str2double(val); end
        
        % udpate the requested value and restore others to original values
        for kk=1:length(list)
            if kk==which
                feval(setVal,names{kk},val);
                if FlagNumeric
                    str = sprintf('%d',val);
                else
                    str = sprintf('%s',val);
                end
                comment(this,sprintf('Set %s to %s',list{kk},str),3);
            elseif FlagRestore
                feval(restoreVal,names{kk});
            end
        end
    end % END function peaApplyCallback

    function popupTaskNames_Callback
        setTask(this);
    end % END function popupTaskNames_Callback

    function popupConfigNames_Callback
        setConfig(this);
    end % END function popupConfigNames_Callback

    function buttonStart_Callback
        start(this.hFramework);
    end % END function buttonStart_Callback
    function buttonStop_Callback
        stop(this.hFramework);
    end % END function buttonStop_Callback
    function buttonClose_Callback
        close(this.hFramework);
    end % END function buttonClose_Callback

end % END function gui