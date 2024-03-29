classdef hGUI < handle & util.Structable
    properties
        hTask
        hFigure
        guiHandles
        user_input
    end % END properties
    
    methods
        function this = GUI(t,varargin)
            assert(isa(t,'Experiment2.TaskInterface'),'Must provide object of class "Experiment2.TaskInterface", not "%s"',class(t));
            this.hTask = t;
            layout(this);
        end % END function GUI
        
        function showGUI(this)
            % display the figure
            set(this.hFigure,'Visible','on');
            figure(this.hFigure);
        end % END function showGUI
        
        function hideGUI(this)
            % hide the figure
            set(this.hFigure,'Visible','off');
        end % END function hideGUI
        
        function enableCheckpoint(this)
            % enable the checkpoint-relevant buttons
            enableCheckpointButtons(this);
            % show the figure
            showGUI(this);
%             profile viewer;
        end % END function enableCheckpoint
        
        function disableCheckpointButtons(this)
            set(this.guiHandles.panel_checkpoint,'HighlightColor',get(this.guiHandles.panel_nav,'HighlightColor'));
            % disable checkpoint buttons
            set(this.guiHandles.button_startTrial,'enable','off');
            set(this.guiHandles.button_skipTrial,'enable','off');
            set(this.guiHandles.button_quitTask,'enable','off');
        end % END function disableCheckpointButtons
        
        function enableCheckpointButtons(this)
            set(this.guiHandles.panel_checkpoint,'HighlightColor','g');
            % enable checkpoint buttons
            set(this.guiHandles.button_startTrial,'enable','on');
            set(this.guiHandles.button_skipTrial,'enable','on');
            set(this.guiHandles.button_quitTask,'enable','on');
            set(this.guiHandles.panel_statusMessage.Children,'String','Press "1" for Start Trial, "2" for Skip Trial,"3" for Quit Trial...');
        end % END function enableCheckpointButtons
        
        function enablePercept(this)
            % initialize trial data
            this.hTask.hTrial.TrialData.tr_perceptFelt = nan;
            % enable percept response GUI fields
            enablePerceptButtons(this);
            % show the figure
            showGUI(this);
        end % END function enablePercept
        
        function disablePerceptButtons(this)
            % disable percept buttons
            set(this.guiHandles.panel_response,'HighlightColor',get(this.guiHandles.panel_nav,'HighlightColor'));
            set(this.guiHandles.button_percept,'enable','off');
            set(this.guiHandles.button_nopercept,'enable','off');
        end % END function disablePerceptButtons
        
        function enablePerceptButtons(this)
            % enable percept buttons
            set(this.guiHandles.panel_response,'HighlightColor','g');
            set(this.guiHandles.button_percept,'enable','on');
            set(this.guiHandles.button_nopercept,'enable','on');
            set(this.guiHandles.panel_statusMessage.Children,'String','Press "p" for Percept, "n" for No Percept...');
        end % END function enablePerceptButtons
        
        function disableResponseEntry(this)
            % initialize gui elements
            set(this.guiHandles.edit_response,'String','');
            set(this.guiHandles.panel_response,'HighlightColor',get(this.guiHandles.panel_nav,'HighlightColor'));
            % disable response description gui elements
            set(this.guiHandles.edit_response,'enable','off');
            set(this.guiHandles.button_saveResponse,'enable','off');
            set(this.guiHandles.button_cancelResponse,'enable','off');
        end % END function disableResponseEntry
        
        function enableResponseEntry(this)
            set(this.guiHandles.panel_response,'HighlightColor','g');
            % clear and enable response description gui elements
            set(this.guiHandles.edit_response,'enable','on');
            set(this.guiHandles.panel_statusMessage.Children,'String','Enter clinical signs...');
            set(this.guiHandles.button_saveResponse,'enable','on');
            set(this.guiHandles.button_cancelResponse,'enable','on');
            set(this.guiHandles.panel_statusMessage.Children,'String','Press "Save" button for saving entry or "Cancel" to enter again...');
        end % END function enableResponseEntry
        
        function setTrialInformation(this,trial,num_trials,sec_remaining,electrode,electrode_label,amplitude,frequency,catch_trial)
            if catch_trial
                set(this.guiHandles.text_trial,'String','[Catch Trial]');
                set(this.guiHandles.text_electrode,'String','N/A');
                set(this.guiHandles.text_amplitude,'String','N/A uA');
                set(this.guiHandles.text_frequency,'String','N/A Hz');
            else
                set(this.guiHandles.text_trial,'String',sprintf('%d/%d (%d sec)',trial,num_trials,sec_remaining));
                set(this.guiHandles.text_electrode,'String',sprintf('%d (%s)',electrode,electrode_label));
                set(this.guiHandles.text_amplitude,'String',sprintf('%d uA',amplitude));
                set(this.guiHandles.text_frequency,'String',sprintf('%d Hz',frequency));
            end
        end % END function setTrialInformation
        
        function layout(this)
            
            this.hFigure = figure(...
                'PaperPositionMode','auto',...
                'Position',[300 300 1500 320],...
                'Visible','off',...
                'Units','pixels');
            
            panel_statusMessage = uipanel(...
                'tag','panel_statusMessage',...
                'units','pixels',...
                'position',[20 5 350 30],...
                'BorderType','none');
            uicontrol(...
                'Style','Text',...
                'String','Starting...',...
                'parent',panel_statusMessage,...
                'position',[1 5 335 15]);
            
            panel_checkpoint = uipanel(...
                'tag','panel_checkpoint',...
                'units','pixels',...
                'position',[20 40 290 250]);
            % start trial button
            uicontrol(...
                'style','pushbutton',...
                'tag','button_startTrial',...
                'enable','off',...
                'units','pixels',...
                'fontsize',13,...
                'string','Start Trial',...
                'position',[10 170 270 70],...
                'parent',panel_checkpoint,...
                'callback',@(h,evt)cb__button_startTrial);
            
            % skip trial button
            uicontrol(...
                'style','pushbutton',...
                'tag','button_skipTrial',...
                'enable','off',...
                'units','pixels',...
                'fontsize',13,...
                'string','Skip Trial',...
                'position',[10 90 270 70],...
                'parent',panel_checkpoint,...
                'callback',@(h,evt)cb__button_skipTrial);
            
            % quit task button
            uicontrol(...
                'style','pushbutton',...
                'tag','button_quitTask',...
                'enable','off',...
                'units','pixels',...
                'fontsize',13,...
                'string','Quit Task',...
                'position',[10 10 270 70],...
                'parent',panel_checkpoint,...
                'callback',@(h,evt)cb__button_quitTask);
            
            panel_response = uipanel(...
                'tag','panel_response',...
                'units','pixels',...
                'position',[320 40 333 250]);
            
            % response indicated button
            uicontrol(...
                'style','pushbutton',...
                'tag','button_percept',...
                'enable','off',...
                'units','pixels',...
                'fontsize',13,...
                'string','Percept',...
                'position',[10 170 150 70],...
                'parent',panel_response,...
                'callback',@(h,evt)cb__button_percept);
            
            % no response button
            uicontrol(...
                'style','pushbutton',...
                'tag','button_nopercept',...
                'enable','off',...
                'units','pixels',...
                'fontsize',13,...
                'string','No Percept',...
                'position',[170 170 150 70],...
                'parent',panel_response,...
                'callback',@(h,evt)cb__button_nopercept);
            
            % response edit box and save/cancel buttons
            uicontrol(...
                'style','edit',...
                'horizontalalignment','left',...
                'enable','off',...
                'tag','edit_response',...
                'units','pixels',...
                'position',[10 60 310 100],...
                'min',0,'max',2,...
                'parent',panel_response);
            uicontrol(...
                'style','pushbutton',...
                'enable','off',...
                'tag','button_cancelResponse',...
                'units','pixels',...
                'position',[230 10 90 40],...
                'fontsize',11,...
                'string','Cancel',...
                'parent',panel_response,...
                'callback',@(h,evt)cb__button_cancelResponse);
            uicontrol(...
                'style','pushbutton',...
                'enable','off',...
                'tag','button_saveResponse',...
                'units','pixels',...
                'position',[130 10 90 40],...
                'fontsize',11,...
                'string','Save',...
                'parent',panel_response,...
                'callback',@(h,evt)cb__button_saveResponse);
            
            panel_nav = uipanel(...
                'tag','panel_nav',...
                'units','pixels',...
                'position',[660 40 320 250]);
            col1_w = 110;
            col2_w = 180;
            row_h = 25;
            row_sp = 5;
            
            % trial number
            curr_h = 210;
            uicontrol(...
                'style','text',...
                'string','Trial: ',...
                'horizontalalignment','left',...
                'position',[10 curr_h col1_w row_h],...
                'fontsize',13,...
                'fontweight','bold',...
                'parent',panel_nav);
            uicontrol(...
                'style','text',...
                'tag','text_trial',...
                'string','NaN/NaN (NaN sec)',...
                'horizontalalignment','left',...
                'position',[10+col1_w curr_h col2_w row_h],...
                'fontsize',13,...
                'fontweight','bold',...
                'parent',panel_nav);
            
            % electrode
            curr_h = curr_h - (row_h + row_sp);
            uicontrol(...
                'style','text',...
                'string','Electrode: ',...
                'horizontalalignment','left',...
                'position',[10 curr_h col1_w row_h],...
                'fontsize',13,...
                'fontweight','bold',...
                'parent',panel_nav);
            uicontrol(...
                'style','text',...
                'tag','text_electrode',...
                'string','NaN (NaN)',...
                'horizontalalignment','left',...
                'position',[10+col1_w curr_h col2_w row_h],...
                'fontsize',13,...
                'fontweight','bold',...
                'parent',panel_nav);
            
            % amplitude
            curr_h = curr_h - (row_h + row_sp);
            uicontrol(...
                'style','text',...
                'string','Amplitude: ',...
                'horizontalalignment','left',...
                'position',[10 curr_h col1_w row_h],...
                'fontsize',13,...
                'fontweight','bold',...
                'parent',panel_nav);
            uicontrol(...
                'style','text',...
                'tag','text_amplitude',...
                'string','NaN uA',...
                'horizontalalignment','left',...
                'position',[10+col1_w curr_h col2_w row_h],...
                'fontsize',13,...
                'fontweight','bold',...
                'parent',panel_nav);
            
            % frequency
            curr_h = curr_h - (row_h + row_sp);
            uicontrol(...
                'style','text',...
                'string','Frequency: ',...
                'horizontalalignment','left',...
                'position',[10 curr_h col1_w row_h],...
                'fontsize',13,...
                'fontweight','bold',...
                'parent',panel_nav);
            uicontrol(...
                'style','text',...
                'tag','text_frequency',...
                'string','NaN Hz',...
                'horizontalalignment','left',...
                'position',[10+col1_w curr_h col2_w row_h],...
                'fontsize',13,...
                'fontweight','bold',...
                'parent',panel_nav);
            
             
            panel_checkpoint = uipanel(...
                'tag','panel_stimProgress',...
                'units','pixels',...
                'position',[990 40 490 250]);
            
            % get handles to all the gui elements
            this.guiHandles = guihandles(this.hFigure);
            set(this.hFigure,'KeyPressFcn',{@kpf_checkpoint,this});
         
            
            function kpf_checkpoint(varargin)
                % determine the key that was pressed
                keyPressed1 = varargin{1,2}.Character;
                switch keyPressed1
                    case '1'
                        disp('Start');
                        cb__button_startTrial();
                    case '2'
                        disp('Skip');
                        cb__button_skipTrial();
                    case '3'
                        disp('Quit');
                        cb__button_quitTask();
                    case 'p'
                        disp('Percept');
                        cb__button_percept();
                    case 'n'
                        disp('No Percept');
                        cb__button_nopercept();
%                     case 'control'
%                         keyPressed2 = varargin{1,2}.Character;
%                         if strcmpi(keyPressed2,'s')
%                             disp('Save');
%                             cb__button_saveResponse();
%                         elseif strcmpi(keyPressed2,'c')
%                             disp('Cancel');
%                             cb__button_cancelResponse();
%                         else
%                             disp('Bad key press for Ctrl combo');
%                         end
                    otherwise
                        disp('Bad key press');
                end
            end
            function cb__button_saveResponse
                % confirm user intends to save and continue
%                 prompt = 'Save this response and continue to the next trial? [y/n] or press buttons below';
%                 header = 'Confirm Save Response';
                % call dialog with prompt and return y/n or yes or no based
                % on user input
                
                %                 user_response = questdlg('Save this response and continue to the next trial?','Confirm Save Response','Yes','No','Yes');
%                 user_response = input('Save this response and continue to the next trial? [y/n]','s');
                %                 if ~ischar(user_response) || ~strcmpi(user_response,'yes')
                %                     return;
                %                 end
%                 if ~ischar(user_response) || ~strcmpi(user_response,'y')
%                     return;
%                 end
                
                % get the response string
                response_string = get(this.guiHandles.edit_response,'String');
                response_string = strtrim(response_string);
                response_string = deblank(response_string);
                if isempty(response_string)
                    warning('No response entered; please try again.');
                    return;
                end
                
                % update the trial data struct
                this.hTask.hTrial.TrialData.tr_perceptDescription = response_string;
                
                % disable the checkpoint-relevant buttons
                disableResponseEntry(this);
                
                % hide the GUI
                hideGUI(this);
                
                % advance to the next phase
                this.hTask.hTrial.advance;
            end % END function cb__button_saveResponse
            
            function cb__button_cancelResponse
                
                % confirm user intends to cancel
                %                 user_response = questdlg('Cancel this response (any text already entered will be lost)?','Confirm Cancel Response','Yes','No','Yes');
%                 user_response = input('Cancel this response (any text already entered will be lost)? [y/n]','s');
%                 if ~ischar(user_response) || ~strcmpi(user_response,'y')
%                     return;
%                 end
                
                % clear text
                set(this.guiHandles.edit_response,'String','');
                
                % reset GUI
                disableResponseEntry(this);
                enablePerceptButtons(this);
            end % END function cb__button_cancelResponse
            
            function cb__button_nopercept
                this.hTask.hTrial.TrialData.tr_perceptFelt = false;
                
                % confirm no percept
                %                 user_response = questdlg('Move on to next trial without any percept?','Confirm No Percept','Yes','No','Yes');
%                 user_response = input('Move on to next trial without any percept?[y/n]','s');
%                 if ~ischar(user_response) || ~strcmpi(user_response,'y')
%                     return;
%                 end
%                 
                % reset GUI
                disablePerceptButtons(this);
                
                % disable the GUI
                hideGUI(this);
                
                % advance to next phase
                this.hTask.hTrial.advance;
            end % END function cb__button_nopercept
            
            function cb__button_percept
                this.hTask.hTrial.TrialData.tr_perceptFelt = true;
                % set up GUI
                disablePerceptButtons(this);
                enableResponseEntry(this);
            end % END function cb__button_percept
            
            function cb__button_startTrial
                % confirm user intends to save and continue
%                 prompt = 'Proceed with the current trial? [y/n] or press the buttons:';
%                 header = 'Confirm Intent to Proceed';
%                 user_response = input('Proceed with the current trial?[y/n]','s');
%                 %                 dialogbox(this,prompt,header);
%                 if ~ischar(user_response) || ~strcmpi(user_response,'y')
%                     return;
%                 end
                % disable the checkpoint-relevant buttons
                disableCheckpointButtons(this);
                % hide the GUI
                hideGUI(this);
                % advance to the next phase
                this.hTask.hTrial.advance;
            end % END function cb__button_startTrial
            
            function cb__button_skipTrial
                
                % confirm user intends to save and continue
                %                 user_response = questdlg('Skip the current trial?','Confirm Intent to Skip Trial','Yes','No','Yes');
%                 user_response = input('Skip the current trial?[y/n]','s');
%                 if ~ischar(user_response) || ~strcmpi(user_response,'y')
%                     return;
%                 end
                
                % disable the checkpoint-relevant buttons
                disableCheckpointButtons(this);
                
                % hide the GUI
                hideGUI(this);
                
                % advance to the next phase
                this.hTask.hTrial.abort(true,false);
            end % END function cb__button_skipTrial
            
            function cb__button_quitTask
                % confirm user intends to save and continue
                %                 user_response = questdlg('Quit the task?','Confirm Intent to Quit Task','Yes','No','Yes');
%                 user_response = input('Quit the task? [y/n]','s');
%                 if ~ischar(user_response) || ~strcmpi(user_response,'y')
%                     return;
%                 end
                
                % disable the checkpoint-relevant buttons
                disableCheckpointButtons(this);
                
                % hide the GUI
                hideGUI(this);
                
                % advance to the next phase
                this.hTask.stop(true);
            end % END function cb__button_quitTask
        end % END function layoutPercept
        function st = toStruct(this)
            st = toStruct@util.Structable(this,'hTask','hFigure','guiHandles');
        end % END function toStruct
        
        function dialogbox(this,question,title)
            dialog_confirm = dialog('Position',[300,300,350,140],'Name',title);
            panel_dialog = uipanel(...
                'tag','panel_dialog',...
                'units','pixels',...
                'position',[20 20 310 120]);
            uicontrol(...
                'style','text',...
                'tag','text_confirm',...
                'enable','on',...
                'units','pixels',...
                'fontsize',11,...
                'string',question,...
                'position',[10 20 300 70],...
                'parent',panel_dialog);
            uicontrol(...
                'style','pushbutton',...
                'tag','button_yes',...
                'enable','on',...
                'units','pixels',...
                'fontsize',11,...
                'string','Yes',...
                'position',[80 20 70 20],...
                'parent',panel_dialog,...
                'callback',@(h,evt)cb__button_confirm);
            uicontrol(...
                'style','pushbutton',...
                'tag','button_no',...
                'enable','on',...
                'units','pixels',...
                'fontsize',11,...
                'string','No',...
                'position',[170 20 70 20],...
                'parent',panel_dialog,...
                'callback',@(h,evt)cb__button_confirm);
            set(dialog_confirm,'KeyPressFcn',{@kpf_dialog,this});
            function kpf_dialog(varargin)
                % determine the key that was pressed
                hDialogBox = varargin{1};
                keyPressed = varargin{2}.Character;
                switch keyPressed
                    case 'y'
                        disp('Yes');
                        cb__button_confirm(keyPressed);
                        return;
                    case 'n'
                        disp('No');
                        cb__button_confirm(keyPressed);
                        return;
                    otherwise
                        disp('Bad key press');
                        return;
                end
            end
            function cb__button_confirm(key)
                close(dialog_confirm);
                this.user_input = key;
                return;
            end
        end
    end  % END methods
end  % END classdef GUI


