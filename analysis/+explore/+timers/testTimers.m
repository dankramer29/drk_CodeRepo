classdef testTimers < handle & util.Structable
    
    properties
        hFigure
        hTimer
        hDebug
        
        buffers
        stopwatch
        
        guiHandles
        
        timerPeriod
        timerStartDelay
        timerExecutionMode
        timerBusyMode
        timerTasksToExecute
        
        currentExperimentIndex
        experimentData
        
        flagRunning
    end % END properties
    
    methods
        function this = testTimers(varargin)
            [varargin,this.timerPeriod] = util.argkeyval('period',varargin,0.04:0.005:0.06);
            [varargin,this.timerStartDelay] = util.argkeyval('startdelay',varargin,1);
            [varargin,this.timerExecutionMode] = util.argkeyval('executionmode',varargin,'fixedDelay');
            [varargin,this.timerBusyMode] = util.argkeyval('busymode',varargin,'queue');
            [varargin,this.timerTasksToExecute] = util.argkeyval('taskstoexecute',varargin,1e3);
            [varargin,this.hDebug,found_debug] = util.argisa('Debug.Debugger',varargin,nan);
            if ~found_debug,this.hDebug=Debug.Debugger('testTimers');end
            util.argempty(varargin);
            
            layout(this);
        end % END function testTimers
        
        function startTest(this)
            this.flagRunning = true;
            this.currentExperimentIndex = 1;
            set(this.guiHandles.buttonStop,'Enable','on');
            initializeBuffers(this);
            initializeTimer(this);
            startCurrentExperiment(this);
        end % END function startTest
        
        function stopTest(this)
            this.flagRunning = false;
            if ~isempty(this.hTimer) && strcmpi(this.hTimer.Running,'on')
                this.hTimer.stop;
                finalizeCurrentExperiment(this);
            end
            util.deleteTimer(this.hTimer);
            this.hTimer = [];
            this.hDebug.log(sprintf('Finished %d experiments',size(this.experimentData,1)),'info');
            set(this.guiHandles.buttonStop,'Enable','off');
        end % END function stopTest
        
        function startCurrentExperiment(this)
            reset(this.buffers);
            this.hTimer.Period = this.timerPeriod(this.currentExperimentIndex);
            this.hDebug.log(sprintf('Running experiment %d/%d (period = %.3f)',...
                this.currentExperimentIndex,length(this.timerPeriod),...
                this.timerPeriod(this.currentExperimentIndex)),'info');
            set(this.guiHandles.editTestProgress,'String',sprintf('%d/%d',this.currentExperimentIndex,length(this.timerPeriod)));
            drawnow;
            this.hTimer.start;
        end % END function startCurrentExperiment
        
        function finalizeCurrentExperiment(this)
            [buffer_data,buffer_names] = all(this.buffers);
            expdt = [{...
                this.hTimer.Period,...
                this.hTimer.ExecutionMode,...
                this.hTimer.BusyMode,...
                this.hTimer.TasksToExecute,...
                length(buffer_data{1})} ...
                buffer_data(:)'];
            expdt = cell2table(expdt,...
                'VariableNames',[{'Period','ExecutionMode','BusyMode','TasksToExecute','TasksExecuted'} buffer_names(:)']);
            if isempty(this.experimentData)
                this.experimentData = expdt;
            else
                this.experimentData = [this.experimentData; expdt];
            end
        end % END function finalizeCurrentExperiment
        
        function initializeTimer(this)
            this.hTimer = util.getTimer('testTimer',...
                'StartDelay',this.timerStartDelay,...
                'ExecutionMode',this.timerExecutionMode,...
                'BusyMode',this.timerBusyMode,...
                'TasksToExecute',this.timerTasksToExecute,...
                'StartFcn',@(t,evt)timerEventFcn(evt),...
                'TimerFcn',@(t,evt)timerEventFcn(evt),...
                'StopFcn',@(t,evt)timerEventFcn(evt),...
                'ErrorFcn',@(t,evt)timerEventFcn(evt));
            
            function timerEventFcn(evt)
                switch evt.Type
                    case 'StartFcn'
                        this.stopwatch = tic;
                    case 'TimerFcn'
                        this.buffers.add('frameId',this.hTimer.TasksExecuted);
                        this.buffers.add('instantPeriod',this.hTimer.InstantPeriod);
                        this.buffers.add('computerTime',now);
                        this.buffers.add('elapsedTime',toc(this.stopwatch));
                        set(this.guiHandles.editExperimentProgress,'String',sprintf('%d/%d',this.hTimer.TasksExecuted,this.hTimer.TasksToExecute));
                    case 'StopFcn'
                        if ~this.flagRunning,return;end
                        
                        finalizeCurrentExperiment(this);
                        this.currentExperimentIndex = this.currentExperimentIndex + 1;
                        if this.currentExperimentIndex <= length(this.timerPeriod)
                            startCurrentExperiment(this);
                        else
                            stopTest(this);
                        end
                    case 'ErrorFcn'
                        this.hDebug.log('Error!','error');
                    otherwise
                        warning('Unknown event type "%s"',evt.Type);
                end
            end % END function timerEventFcn
        end % END function initializeTimer
        
        function initializeBuffers(this)
            this.buffers = Buffer.DynamicCollection;
            register(this.buffers,'frameId','r');
            register(this.buffers,'computerTime','r');
            register(this.buffers,'elapsedTime','r');
            register(this.buffers,'instantPeriod','r');
        end % END function initializeBuffers
        
        function plotResults(this)
            ed = this.experimentData;
            dt = cellfun(@(x)diff(x)*24*3600,ed.computerTime,'un',0);
            
            figure
            mdl = fitlm(ed.Period,cellfun(@(x)mean(x),dt),'robustopts','on');
            plot(mdl);
            xlabel('Requested Timer Interval (sec)');
            ylabel('Measured Timer Interval (sec)');
            title({'Average Timer Interval',sprintf('b = %.3f, m = %.3f',mdl.Coefficients.Estimate(1),mdl.Coefficients.Estimate(2))});
            
            figure
            mdl = fitlm(ed.Period,cellfun(@(x)median(x),dt),'robustopts','on');
            plot(mdl);
            xlabel('Requested Timer Interval (sec)');
            ylabel('Measured Timer Interval (sec)');
            title({'Median Timer Interval',sprintf('b = %.3f, m = %.3f',mdl.Coefficients.Estimate(1),mdl.Coefficients.Estimate(2))});
            
            figure
            mdl = fitlm(ed.Period,cellfun(@(x)std(x),dt),'robustopts','on');
            plot(mdl);
            xlabel('Requested Timer Interval (sec)');
            ylabel('Measured Std Dev of Timer Interval (sec)');
            title({'Standard Deviation of Timer Interval',sprintf('b = %.3f, m = %.3f',mdl.Coefficients.Estimate(1),mdl.Coefficients.Estimate(2))});
        end % END function plotResults
        
        function layout(this)
            
            % parameters
            name = 'testTimers';
            screenMargin = [100 100 100 100]; % left/bottom/right/top
            outerSpacing = [10 10 10 10]; % left/bottom/right/top
            elementSpacing = 10;
            
            % set figure position based on screen dimensions
            width = 500;
            height = 300;
            figpos = [250 40 width height];
            set(0,'units','pixels');
            rootProps = get(0);
            if isfield(rootProps,'ScreenSize')
                figleft = max(rootProps.ScreenSize(1)+screenMargin(1)-1,(rootProps.ScreenSize(3)-width-screenMargin(3))/2);
                figbottom = max(rootProps.ScreenSize(2)+screenMargin(2)-1,(rootProps.ScreenSize(4)-height-screenMargin(4))/2);
                figpos = [figleft figbottom width height];
            end
            
            % delete any old GUIs
            ff = findobj('Name',name);
            delete(ff);
            
            % create the figure
            this.hFigure = figure(...
                'Units','pixels',...
                'Color',[0.94 0.94 0.94],...
                'Position',figpos,...
                'PaperPositionMode','auto',...
                'NumberTitle','off',...
                'Resize','off',...
                'MenuBar','none',...
                'ToolBar','none',...
                'name',name);
            this.hFigure.CloseRequestFcn = @(src,dt)delete(this);
            
            % add the buttons
            currLeft = outerSpacing(1);
            currBottom = outerSpacing(2);
            localWidth = 100;
            localHeight = 80;
            uicontrol(...
                'Parent',this.hFigure,...
                'Position',[currLeft currBottom localWidth localHeight],...
                'Enable','on',...
                'String','Start',...
                'Style','pushbutton',...
                'Tag','buttonStart',...
                'Callback',@(h,evt)buttonStart_Callback);
            currLeft = currLeft + localWidth + elementSpacing;
            uicontrol(...
                'Parent',this.hFigure,...
                'Position',[currLeft currBottom localWidth localHeight],...
                'Enable','off',...
                'String','Stop',...
                'Style','pushbutton',...
                'Tag','buttonStop',...
                'Callback',@(h,evt)buttonStop_Callback);
            
            % test progress
            currLeft = outerSpacing(1);
            currBottom = 150;
            localWidth = 100;
            localHeight = 20;
            uicontrol(...
                'Parent',this.hFigure,...
                'Position',[currLeft currBottom localWidth localHeight],...
                'Enable','off',...
                'String','Test: ',...
                'HorizontalAlignment','left',...
                'Style','text',...
                'FontSize',8,...
                'Tag','textTestProgress');
            currLeft = currLeft + localWidth + elementSpacing;
            uicontrol(...
                'Parent',this.hFigure,...
                'enable','off',...
                'HorizontalAlignment','left',...
                'Position',[currLeft currBottom+4 localWidth localHeight],...
                'String','',...
                'Style','edit',...
                'Tag','editTestProgress');
            
            % experiment progress
            currLeft = outerSpacing(1);
            currBottom = 100;
            localWidth = 100;
            localHeight = 20;
            uicontrol(...
                'Parent',this.hFigure,...
                'Position',[currLeft currBottom localWidth localHeight],...
                'Enable','off',...
                'String','Experiment: ',...
                'HorizontalAlignment','left',...
                'Style','text',...
                'FontSize',8,...
                'Tag','textExperimentProgress');
            currLeft = currLeft + localWidth + elementSpacing;
            uicontrol(...
                'Parent',this.hFigure,...
                'enable','off',...
                'HorizontalAlignment','left',...
                'Position',[currLeft currBottom+4 localWidth localHeight],...
                'String','',...
                'Style','edit',...
                'Tag','editExperimentProgress');
            this.guiHandles = guihandles(this.hFigure);
            
            function buttonStart_Callback
                startTest(this);
            end % END function buttonStart_Callback
            
            function buttonStop_Callback
                stopTest(this);
            end % END function buttonStop_Callback
        end % END function layout
        
        function st = toStruct(this,varargin)
            skip = {'hDebug','hTimer','hDebug'};
            st = toStruct@util.Structable(this,skip{:});
        end % END function toStruct
        
        function delete(this)
            try delete(this.hFigure); catch ME, util.errorMessage(ME); end
            try util.deleteTimer(this.hTimer); catch ME, util.errorMessage(ME); end
        end % END function delete
    end % END methods
end % END classdef testTimers