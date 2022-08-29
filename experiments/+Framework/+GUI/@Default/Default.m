classdef Default < handle & Framework.GUI.Interface & util.Structable & util.StructableHierarchy
    
    properties
        hFigure
        
        name
        
        memory = 100; % how many samples to display in the GUI
        lineHandles = nan;
        guiHandles = nan;
        linespec = {'b','g','r','m','k','y'};
        yLims = [-2 2];
        
        width = 1000;
        height = 400;
        borderMargin = 20;
        panelMargin = 10;
        elemSpacing = 5;
        rowHeight = 22;
        
        configNames = {};
        configList = {};
    end % END properties
    
    methods
        function this = Default(fw,varargin)
            this = this@Framework.GUI.Interface(fw);
            
            % construct figure name
            if ~isempty(fw.options.subject)
                this.name = sprintf('Framework GUI -- Subject %s',fw.options.subject);
            else
                this.name = 'Framework GUI -- No Subject';
            end
        end % END function Default
        
        function InitFcn(this)
            
            % return if handle already exists
            if ~isempty(this.hFigure) && ishandle(this.hFigure) && isvalid(this.hFigure)
                figure(this.hFigure);
                return;
            end
            
            % delete any old GUIs
            ff = findobj('Name',this.name);
            delete(ff);
            
            % create figure
            this.hFigure = figure(...
                'Units','pixels',...
                'Color',[0.94 0.94 0.94],...
                'IntegerHandle','off',...
                'MenuBar','none',...
                'Name',this.name,...
                'NumberTitle','off',...
                'PaperPosition',get(0,'defaultfigurePaperPosition'),...
                'Position',[450 100 this.width this.height],...
                'Resize','off',...
                'UserData',[],...
                'Tag','fh');
            
            % run layout
            layout(this);
            
            % initialize limit popup/edit boxes
            list = get(this.guiHandles.popupLimit,'String');
            if this.hFramework.options.frameLimit < inf
                valString = this.hFramework.options.frameLimit;
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Frame Limit')));
            elseif this.hFramework.options.timeLimit < inf
                valString = this.hFramework.options.timeLimit;
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Time Limit')));
            elseif this.hFramework.options.enableTask && this.hFramework.options.taskLimit < inf
                valString = this.hFramework.options.taskLimit;
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Task Limit')));
            else
                valString = 'Inf';
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Frame Limit')));
            end
            set(this.guiHandles.editLimit,'String',valString);
            
            % initialize NSP name popup/edit boxes
            if this.hFramework.options.enableNeural
                nsps = this.hFramework.hNeuralSource.getAmplifierLabels;
                if ~isempty(nsps)
                    nspLabels = cell(1,length(nsps));
                    for kk=1:length(nspLabels)
                        nspLabels{kk} = sprintf('NSP %d',kk);
                    end
                    set(this.guiHandles.popupNSPLabels,'String',nspLabels);
                    set(this.guiHandles.popupNSPLabels,'Value',1);
                    set(this.guiHandles.editNSPLabels,'String',nsps{1});
                    set(this.guiHandles.popupNSPLabels,'enable','on');
                    set(this.guiHandles.editNSPLabels,'enable','on');
                end
            else
                set(this.guiHandles.popupNSPLabels,'enable','off');
                set(this.guiHandles.editNSPLabels,'enable','off');
            end
            
            % enable start/stop/close buttons
            set(this.guiHandles.buttonStart,'enable','on');
            set(this.guiHandles.buttonStop,'enable','on');
            set(this.guiHandles.buttonClose,'enable','on');
            
            % Indicate if in dev mode.
            if strcmp(this.hFramework.options.type,'DEVELOPMENT')
                set(gcf,'color','yellow');
                warning('Currently running in DEBUG mode');
            end
        end % END function InitFcn
        
        function StartFcn(this)
            
            % disable popup menus and start/close buttons
            set(this.guiHandles.buttonStart,'enable','off');
            set(this.guiHandles.buttonClose,'enable','off');
            set(this.guiHandles.popupLimit,'enable','off');
            set(this.guiHandles.editLimit,'enable','off');
            if this.hFramework.options.enableNeural
                set(this.guiHandles.popupNSPLabels,'enable','off');
                set(this.guiHandles.editNSPLabels,'enable','off');
            end
            
            % update limit dropdown/edit boxes with runtime values
            list = get(this.guiHandles.popupLimit,'String');
            if this.hFramework.runtime.frameLimit < inf
                valString = this.hFramework.runtime.frameLimit;
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Frame Limit')));
            elseif this.hFramework.runtime.timeLimit < inf
                valString = this.hFramework.runtime.timeLimit;
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Time Limit')));
            elseif this.hFramework.options.enableTask && this.hFramework.runtime.taskLimit < inf
                valString = this.hFramework.runtime.taskLimit;
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Task Limit')));
            else
                valString = 'Inf';
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Frame Limit')));
            end
            set(this.guiHandles.editLimit,'String',valString);
        end % END function StartFcn
        
        function StopFcn(this)
            
            % enable popup menus and start/close buttons
            set(this.guiHandles.buttonStart,'enable','on');
            set(this.guiHandles.buttonClose,'enable','on');
            set(this.guiHandles.popupLimit,'enable','on');
            set(this.guiHandles.editLimit,'enable','on');
            if this.hFramework.options.enableNeural
                set(this.guiHandles.popupNSPLabels,'enable','on');
                set(this.guiHandles.editNSPLabels,'enable','on');
            end
            
            % delete all line handles
            for k=1:length(this.lineHandles)
                if ishandle(this.lineHandles(k))
                    delete(this.lineHandles(k));
                end
            end
            this.lineHandles = nan;
            
            % update limit dropdown/edit boxes to options (permanent) values
            list = get(this.guiHandles.popupLimit,'String');
            if this.hFramework.runtime.frameLimit < inf
                valString = this.hFramework.runtime.frameLimit;
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Frame Limit')));
            elseif this.hFramework.runtime.timeLimit < inf
                valString = this.hFramework.runtime.timeLimit;
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Time Limit')));
            elseif this.hFramework.options.enableTask && this.hFramework.runtime.taskLimit < inf
                valString = this.hFramework.runtime.taskLimit;
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Task Limit')));
            else
                valString = 'Inf';
                set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Frame Limit')));
            end
            set(this.guiHandles.editLimit,'String',valString);
        end % END function StopFcn
        
        function UpdateFcn(this)
            xdata = -(this.memory-1):1:0;
            if this.hFramework.options.enableTask || this.hFramework.options.enablePredictor
                ydata = get(this.hFramework.buffers,'state',this.memory)';
            else
                ydata = [];
            end
            if this.hFramework.options.enableTask
                tdata = get(this.hFramework.buffers,'target',this.memory)';
            else
                tdata = [];
            end
            ydata = [nan(size(ydata,1),this.memory-size(ydata,2)) ydata];
            tdata = [nan(size(tdata,1),this.memory-size(tdata,2)) tdata];
            
            % subsample variables if appropriate
            if ~isempty(this.hFramework.options.nVarsPerDOF)
                
                % just the first variable in each DOF
                ydata = ydata(1:this.hFramework.options.nVarsPerDOF:end,:);
            end
            
            if any(isnan(this.lineHandles))
                hold(this.guiHandles.axisMain,'on');
                idx=1;
                for k=1:size(ydata,1)
                    this.lineHandles(idx) = plot(this.guiHandles.axisMain,xdata,ydata(k,:),this.linespec{k});
                    idx=idx+1;
                end
                for k=1:size(tdata,1)
                    this.lineHandles(idx) = plot(this.guiHandles.axisMain,xdata,tdata(k,:),[this.linespec{k} '.'],'LineWidth',1);
                    idx=idx+1;
                end
                hold(this.guiHandles.axisMain,'off');
                xlim(this.guiHandles.axisMain,[-(this.memory-1) 1]);
                ylim(this.guiHandles.axisMain,this.yLims);
            else
                idx=1;
                for k=1:size(ydata,1)
                    set(this.lineHandles(idx),'XData',xdata,'YData',ydata(k,:));
                    idx=idx+1;
                end
                for k=1:size(tdata,1)
                    set(this.lineHandles(idx),'XData',xdata,'YData',tdata(k,:));
                    idx=idx+1;
                end
            end
            
            set(this.guiHandles.editFrameId,'String',this.hFramework.frameId);
            set(this.guiHandles.editTime,'String',toc(this.hFramework.options.stopwatch));
            set(this.guiHandles.editStepAvg,'String',this.hFramework.hTimer.AveragePeriod);
            set(this.guiHandles.editStepInst,'String',this.hFramework.hTimer.InstantPeriod);
            if(this.hFramework.hTimer.InstantPeriod > this.hFramework.options.timerPeriod*1.05)
                set(this.guiHandles.textStepInst,'BackgroundColor',[0.9 0.1 0.1]);
            else
                set(this.guiHandles.textStepInst,'BackgroundColor',[0.8314 0.8157 0.7843]);
            end
            set(this.guiHandles.editNumFeatures,'String',numScalarsPerEntry(this.hFramework.buffers,'features'));
            set(this.guiHandles.editNumDOFs,'String',this.hFramework.options.nDOF);
            if ~this.hFramework.runtime.limitProcessed
                if this.hFramework.runtime.timeLimit < inf
                    str = sprintf('%.2f',toc(this.hFramework.options.stopwatch));
                    set(this.guiHandles.editLimitStatus,'String',str);
                    set(this.guiHandles.editLimitUnits,'String','sec');
                else
                    if this.hFramework.options.enableTask && this.hFramework.runtime.taskLimit < inf
                        str = sprintf('%d',this.hFramework.hTask.nTrials);
                        set(this.guiHandles.editLimitStatus,'String',str);
                        set(this.guiHandles.editLimitUnits,'String','trials');
                    else
                        str = sprintf('%d',this.hFramework.frameId);
                        set(this.guiHandles.editLimitStatus,'String',str);
                        set(this.guiHandles.editLimitUnits,'String','frames');
                    end
                end
            end
        end % END function UpdateFcn
        
        function setYLim(this,val)
            this.yLims = val;
            ylim(this.guiHandles.axisMain,this.yLims);
        end % END function setYLim
        
        function updateRuntimeLimit(this,which,lim)
            list = get(this.guiHandles.popupLimit,'String');
            switch lower(which)
                case 'task'
                    set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Task Limit')));
                case 'time'
                    set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Time Limit')));
                case 'frame'
                    set(this.guiHandles.popupLimit,'Value',find(strcmpi(list,'Frame Limit')));
            end
            set(this.guiHandles.editLimit,'String',lim);
        end % END function updateRuntimeLimit
        
        function delete(this)
            if ishandle(this.hFigure)
                close(this.hFigure);
            end
        end % END function delete
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Framework.Component(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Framework.Component(this);
            st = util.catstruct(st,st1);
        end % END function structableManualFields
        
    end % END methods
    
end % END classdef Default