classdef UserPrompt < handle
    % USERPROMPT
    % Convenience class to manage setting up dialog boxes and potentially
    % remembering responses.
    %
    % Example
    % >> a = UserPrompt('question','Are you short or tall?',...
    %      'option','short',...
    %      'option','tall',...
    %      'default','short',...
    %      'remember');
    % >> rsp = a.prompt;
    
    properties
        title % dialog box title
        question % question to pose to the user
        options % options to present to user
        default % default option to pre-highlight
        remembered % remembered response
        flag_remember % whether to ask user to remember the response
    end % END properties
    
    methods
        function this = UserPrompt(varargin)
            % ASKTHEUSER Wrapper around questdlg for convenience
            %
            %   THIS = ASKTHEUSER(...,'TITLE',T)
            %   Specify the title of the dialog box (T must be char).
            %
            %   THIS = ASKTHEUSER(...,'QUESTION',Q)
            %   Specify the question to pose to the user (Q must be char).
            %
            %   THIS = ASKTHEUSER(...,'OPTION',O1,'OPTION',O2,...)
            %   Specify the answer options. Each option must be char.
            % 
            %   THIS = ASKTHEUSER(...,'DEFAULT',D)
            %   Specify the default option (pre-highlighted). D must be
            %   char.
            %
            %   THIS = ASKTHEUSER(...,'REMEMBER',TF)
            %   Specify whether to ask the user to remember their response
            %   (TF is true or false).
            
            % process inputs
            [varargin,this.title] = util.argkeyval('title',varargin,'');
            if ~isempty(this.title)
                assert(ischar(this.title),'Must provide char title, not "%s"',class(this.title));
            end
            [varargin,this.question] = util.argkeyval('question',varargin,'');
            if ~isempty(this.question)
                assert(ischar(this.question),'Must provide char question, not "%s"',class(this.question));
            end
            [varargin,this.options] = util.argkeyvals('option',varargin,'');
            if ~isempty(this.options) && ischar(this.options)
                this.options = {this.options};
            end
            assert(all(cellfun(@ischar,this.options)),'Must provide char options values');
            assert(length(this.options)<=3,'MATLAB builtin "questdlg" only supports up to three options (user requested %d)',length(this.options));
            [varargin,this.default] = util.argkeyval('default',varargin,'');
            if isempty(this.default) && ~isempty(this.options)
                this.default = this.options{1};
            end
            assert(ischar(this.default),'Must provide char default, not "%s"',class(this.default));
            assert(ismember(this.default,this.options),'Default must match one of the options exactly');
            [varargin,this.flag_remember] = util.argflag('remember',varargin,false);
            assert(islogical(this.flag_remember)||isnumeric(this.flag_remember),'Must provide logical value for remember, not "%s"',class(this.flag_remember));
            this.flag_remember = logical(this.flag_remember);
            util.argempty(varargin);
        end % END function UserPrompt
        
        function forget(this)
            % FORGET remove the remembered response (prompt user again).
            this.remembered = '';
        end % END function forget
        
        function rsp = prompt(this,varargin)
            % PROMPT prompt the user
            %
            %   PROMPT(THIS)
            %   Put up the dialog box and get the user response.
            %
            %   PROMPT(...,'TITLE',T)
            %   Provide title string for dialog box (default is the value
            %   provided to the constructor; if empty, will be set to "User
            %   Prompt").
            %
            %   PROMPT(...,'QUESTION',Q)
            %   Provide a question string for dialog box (default is the
            %   value provided to the constructor; cannot be empty).
            [varargin,tstr] = util.argkeyval('title',varargin,this.title);
            if isempty(tstr)
                tstr = 'User Prompt';
            end
            assert(ischar(tstr),'Must provide char title, not "%s"',class(tstr));
            [varargin,qstr] = util.argkeyval('question',varargin,this.question);
            assert(~isempty(qstr),'Must provide a question string');
            assert(ischar(qstr),'Must provide char question, not "%s"',class(qstr));
            util.argempty(varargin);
            
            % validate settings
            assert(~isempty(this.options),'No options specified');
            assert(~isempty(this.default),'No default specified');
            
            % don't remember string - hopefully unique
            noremstr = 'NoIReallyDontWantToRememberWhatTheUserSaidSoStopAsking';
            
            % query about files with this extension
            if this.flag_remember && ~isempty(this.remembered) && ~strcmpi(this.remembered,noremstr)
                rsp = this.remembered;
            else
                rsp = questdlg(qstr,tstr,this.options{:},this.default);
                if this.flag_remember && isempty(this.remembered)
                    local_qstr = 'Do you want to remember this response in the future?';
                    local_rsp = questdlg(local_qstr,'Remember Response','Yes','No','Never','No');
                    switch lower(local_rsp)
                        case 'yes'
                            this.remembered = rsp;
                        case 'no'
                            this.remembered = noremstr;
                        case 'never'
                            this.flag_remember = false;
                        otherwise
                            error('Unknown response "%s"',rsp);
                    end
                end
            end
            
            % process response
            idx_match = cellfun(@(x)strcmpi(rsp,x),this.options);
            assert(any(idx_match),'Response "%s" did not match any options',rsp);
            assert(nnz(idx_match)==1,'Found multiple options matching response "%s"',rsp);
            rsp = this.options{idx_match};
        end % END function prompt
    end % END methods
end % END classdef UserPrompt