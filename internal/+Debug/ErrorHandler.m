classdef ErrorHandler < handle & util.Structable & util.StructableHierarchy
    % ERRORHANDLER Fine-grained control over error handling and debug.
    %
    %   The ERRORHANDLER class provides a means to execute a function within a
    %   try-catch block with well defined procedures for handling errors.
    %
    %   Below is a basic example showing how to use ERRORHANDLER.
    %
    %   >> d = ErrorHandler(Debug.Mode.OFF); % create the debugger object
    %   >> d.setHandler(err_fn,err_args); % set custom error handler
    %   ... % generate an error ME
    %   >> d.process(ME);
    
    properties
        hLogger % cell array of handles to Logger objects
        mode % debug mode (0=>off, 1=>on, 2=>validation)
        dbMessage % print error message
        dbKeyboard % drop into keyboard prompt
        dbRethrow % rethrow errors
        handlerFcn % error handler function handle, or cell array with function handle and first argument(s)
        handlerArgs % cell array of error handler arguments
        clients % table with client-specific verbosities
    end % END properties
    
    properties(SetAccess=private,GetAccess=public)
        % dbHistory
    end % END properties(SetAccess=private,GetAccess=public)
    
    methods
        function this = ErrorHandler(varargin)
            % ERRORHANDLER constructor for DEBUGGER class
            %
            %   THIS = ERRORHANDLER(MD)
            %   Create a ERRORHANDLER object based around the debug mode MD.
            %   MD can be a string ('OFF','ON','VALIDATION'), numeric
            %   (0,1,2), or a DEBUG.MODE enumeration object.
            %
            %   ERRORHANDLER(...,KEY,VAL,...)
            %   To override any defaults, provide key-value pairs where the
            %   key is the name of any publically-writeable property of
            %   ERRORHANDLER.
            this.clients = cell2table({'global',env.get('debug')},'VariableNames',{'clientID','mode'});
            
            % set the debug mode
            [varargin,modeUser] = util.argkeyval('mode',varargin,this.mode);
            if ~isequal(modeUser,this.mode)
                setDebugMode(this,modeUser);
            end
            
            % set default error handling function, arguments
            setHandler(this,{@process,this},{});
            
            % process overriding user inputs
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % % set up the error history buffer
            % this.dbHistory = Buffer.StructDynamic;
        end % END function Debugger
        
        function registerClient(this,client,mode)
            % REGISTERCLIENT Register a client with specific debug mode
            %
            %   REGISTERCLIENT(THIS,CLIENT,MODE,HANDLERFCN,HANDLERARGS)
            %   Register a client with specific debug mode. The input
            %   CLIENT should be the full path to the file that will be
            %   generating debug queries (for example, from the output of
            %   the WHICH command).
            if nargin<3||isempty(mode),mode=this.mode;end
            [idx_client,client] = processClientInput(this,client);
            
            % enforce id uniqueness
            assert(~any(idx_client),'Client ID "%s" already exists',client);
            
            % correct number of inputs
            assert(isa(mode,'Debug.Mode'),'Must provide debug mode as ''Debug.Mode'', not ''%s''',class(mode));
            
            % add client
            this.clients(end+1,:) = cell2table({client,mode});
        end % END function registerClient
        
        function deregisterClient(this,client)
            % DEREGISTERCLIENT De-register a client
            %
            %   DEREGISTERCLIENT(THIS,CLIENT)
            %   De-register a client for this logger.
            
            % convert to full path
            [idx_client,client] = processClientInput(this,client);
            
            % identify table row
            assert(nnz(idx_client)>0,'Could not find client "%s" in list of registered clients',client);
            
            % remove client
            this.clients(idx,:) = [];
        end % END function desregisterClient
        
        function tf = isRegistered(this,client)
            % ISREGISTERED Check whether a client is registered
            %
            %   TF = ISREGISTERED(THIS,CLIENT)
            %   Return a logical TRUE if the client specified by CLIENT is
            %   registered with this logger, or a FALSE otherwise.
            
            % convert to full path
            idx_client = processClientInput(this,client);
            
            % enforce id uniqueness
            tf = any(idx_client);
        end % END function isRegistered
        
        function oldMode = setDebugMode(this,newMode,client)
            % SETDEBUGMODE set the debug mode
            %
            %   OLDMODE = SETDEBUGMODE(THIS,NEWMODE)
            %   Set the debug mode to NEWMODE and configure debugger
            %   behavior, such as whether to print error messages, drop to
            %   keyboard prompt, or rethrow errors, accordingly. Return
            %   previous debug mode in OLDMODE. By default, sets the debug
            %   mode for all non-registered clients, i..e, any registered
            %   client maintains its current setting.
            %
            %   OLDMODE = SETDEBUGMODE(THIS,NEWMODE,CLIENT)
            %   Specify the client for which to modify the debug mode.
            %   CLIENT input should be full path to file which will or is
            %   making the debug query.
            
            % default client and which
            if nargin<3||isempty(client),client='global';end
            [idx_client,client] = processClientInput(this,client);
            
            % check for client registration and specific verbosities
            assert(any(idx_client),'No registered client with ID ''%s''',client);
            
            % set the verbosity
            assert(isa(newMode,'Debug.Mode'),'Must provide debug mode as ''Debug.Mode'', not ''%s''',class(newMode));
            oldMode = this.clients.mode(idx_client);
            this.clients.mode(idx_client) = newMode;
            if strcmpi(client,'global')
                this.mode = newMode;
                [this.dbMessage,this.dbKeyboard,this.dbRethrow] = settings(newMode);
            end
        end % END function setDebugMode
        
        function setHandler(this,fn,args)
            % SETHANDLER Set the error handler function and args.
            %
            %   SETHANDLER(THIS,FN,ARGS)
            %   Set the error handler function for the DEBUGGER object
            %   THIS.  FN can be either a function handle, or a cell array
            %   of a function handle and the first argument(s).  This last
            %   possibility will be necessary when the error handler is a
            %   method of an object and the first argument will therefore
            %   need to be a handle to the object.  If ARGS is provided, it
            %   must be a cell array of arguments that will be provided to
            %   the error handling function.  The MATLAB MException object,
            %   generated by the error, will be passed to the error
            %   handling function after FN{:} and before ARGS{:}.
            
            % validate input
            assert(nargin>=2,'Must provide at least a function handle or cell array with function handle in first cell');
            if nargin<3,args={};end
            
            % update properties
            this.handlerFcn = util.ascell(fn);
            this.handlerArgs = util.ascell(args);
        end % END function setHandler
        
        function addLogger(this,h)
            assert(isa(h,'Debug.Logger'),'Invalid input of class ''%s''',class(h));
            if isempty(this.hLogger)
                this.hLogger = {h};
            else
                this.hLogger{end+1} = h;
            end
        end % END function addLogger
        
        function process(this,ME,varargin)
            % PROCESS default error handler
            %
            %   PROCESS(THIS,ME)
            %   Fine-grained control over printing the error message,
            %   dropping to keyboard prompt, and rethrowing the error based
            %   on object properties.
            
            % locally overriding inputs
            [varargin,enpr] = util.argkeyval('dbMessage',varargin,this.dbMessage);
            [varargin,enkb] = util.argkeyval('dbKeyboard',varargin,this.dbKeyboard);
            [varargin,enrt] = util.argkeyval('dbRethrow',varargin,this.dbRethrow);
            [varargin,prep] = util.argkeyval('dbPrepend',varargin,'');
            [varargin,skip] = util.argkeyval('skip',varargin,{'ErrorHandler'});
            util.argempty(varargin);
            
            % produce error message
            errmsg(this,ME,enpr,'dbPrepend',prep,'skip',skip);
            
            % if debug, enter debug prompt
            kb(this,enkb);
            
            % if rethrow, rethrow the error
            if enrt, rethrow(ME); end
        end % END function process
        
        function errmsg(this,ME,en,varargin)
            % ERRMSG debug-gated error message
            %
            %   ERRMSG(THIS,ME)
            %   Print the error details if the dbMessage property is TRUE.
            %
            %   ERRMSG(THIS,ME,EN)
            %   Provide overriding value for dbMessage property TRUE|FALSE.
            %
            %   ERRMSG(...,'dbPrepend',STR)
            %   Provide string for prepending the message otuput.
            %
            %   ERRMSG(...,'skip',SKIP)
            %   Provide cell array of strings indicating which elements of
            %   the DBSTACK output to skip when printing out the error
            %   stack.
            
            if nargin<3||isempty(en),en=this.dbMessage;end
            if ~en,return;end
            [varargin,prep] = util.argkeyval('dbPrepend',varargin,'');
            [varargin,skip] = util.argkeyval('skip',varargin,{'ErrorHandler'});
            util.argempty(varargin);
            
            % configure output for each logger based on capabilities
            if isempty(this.hLogger)
                warning('There no loggers! No messages will be printed to screen or elsewhere');
            end
            for kk=1:length(this.hLogger)
                
                % hyperlinks or not
                if this.hLogger{kk}.canHTML
                    
                    % yes hyperlinks
                    [msg,stack] = util.errorMessage(ME,'noscreen','link');
                    if this.hLogger{kk}.canMultiline
                        
                        % yes multiline
                        msg = strjoin([{msg} stack],'\n');
                    end
                else
                    
                    % no hyperlinks
                    [msg,stack] = util.errorMessage(ME,'noscreen','nolink');
                    if this.hLogger{kk}.canMultiline
                        
                        % yes multiline
                        msg = strjoin([{msg} stack],'\n');
                    end
                end
                
                % identify source
                [~,source,line] = Debug.getSourceFromStack(ME.stack,skip);
                
                % add prepend
                msg = sprintf('%s%s',prep,msg);
                
                % pass message to logger
                this.hLogger{kk}.log(msg,Debug.PriorityLevel.ERROR,'source',source,'line',line);
            end
        end % END function errmsg
        
        function kb(this,dbk)
            % KB debug-gated keyboard entry
            %
            %   KB(THIS)
            %   Drop into a keyboard prompt if the enableKeyboard flag has
            %   been set for the DEBUGGER object.
            %
            %   KB(THIS,DBK)
            %   Provide an override value (TRUE|FALSE) for dbKeyboard.
            
            if nargin<2||isempty(dbk),dbk=this.dbKeyboard;end
            if ~dbk,return;end
            fprintf('\n');
            fprintf('[DEBUG]\n');
            fprintf('Use the debug stack (dbup, dbdown) to navigate to the error location.\n');
            fprintf('Type ''return'' or hit ''F5'' to continue.\n');
            keyboard;
        end % END function kb
        
        function assert(this,cond,msg,varargin)
            % ASSERT process and handle assertions
            %
            %   ASSERT(THIS,COND,MSG,ARG1,ARG2,...)
            %   Assert the truth of COND.  If the assertion fails, process
            %   the resulting error.  MSG should be the string to be logged
            %   if the assertion fails.  MSG will be processed just like
            %   the default assert function, i.e., with placeholders for
            %   variables.  ARG1, ARG2, etc. provide the values for those
            %   placeholders.
            
            % locally overriding inputs
            [varargin,enpr] = util.argkeyval('dbMessage',varargin,this.dbMessage);
            [varargin,enkb] = util.argkeyval('dbKeyboard',varargin,this.dbKeyboard);
            [varargin,enrt] = util.argkeyval('dbRethrow',varargin,this.dbRethrow);
            
            % run the assertion
            try
                
                % assert the condition
                assert(cond,msg,varargin{:});
            catch ME
                
                % catch and process the error
                process(this,ME,'dbMessage',enpr,'dbKeyboard',enkb,'dbRethrow',enrt);
            end
        end % END function assert
        
        function [idx_client,client] = processClientInput(this,client)
            
            % convert to full path
            fullpath = which(client);
            if exist(fullpath,'file')==2
                client = fullpath;
            end
            
            % check for class folder (match the class folder, not specific
            % files (i.e. methods) within the class folder
            if ~isempty(regexpi(client,filesep))
                cldir = fileparts(client);
                cldir_tokens = strsplit(cldir,filesep);
                if cldir_tokens{end}(1)=='@'
                    client = cldir;
                end
            end
            
            % look for matches in the client table
            idx_client = strcmpi(client,this.clients.clientID);
        end % END function processClientInput
        
        function list = structableSkipFields(this)
            % can't guarantee safe struct conversion of all entries in cell
            % arrays handlerFcn and handlerArgs, so punting for
            % now: just saving the string representation of the function 
            % handle.
            list = {'handlerFcn','handlerArgs'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            % st.dbHistory = this.dbHistory.get;
            st.handlerFcn = cellfun(@(x)util.any2str(x),this.handlerFcn,'UniformOutput',false);
        end % END function structableManualFields
        
        function st = toStruct(this,varargin)
            st = toStruct@util.Structable(this,varargin{:});
        end % END function toStruct
    end % END methods
end % END classdef ErrorHandler