classdef Debugger < handle & util.Structable
    
    properties
        hLogger % cell array of handles to Debug.Logger objects
        hErrorHandler % handle to Debug.ErrorHandler object
        basename % base name for this Debugger instantiation
        timestamp % timestamp for this Debugger instantiation
    end % END properties
    
    methods
        function this = Debugger(nm,varargin)
            assert(nargin>=1,'Must provide at least one argument (a char vector representing the run ID)');
            this.basename = nm;
            this.timestamp = now;
            [varargin,which] = util.argkeyword({'both','screen','logfile'},varargin,'both');
            
            % define loggers
            loggers = {};
            if any(strcmpi(which,{'both','screen'}))
                loggers = [loggers {{...
                    'id','screen','target','screen',...
                    'verbosity',env.get('verbosityScreen'),...
                    'outputFcn',@Debug.printToScreen,'outputArgs',{},...
                    'prependPriority',true,'prependTime',false,'prependSource',true,...
                    'canHTML',true,'canMultiLine',true}}];
            end
            if any(strcmpi(which,{'both','logfile'}))
                loggers = [loggers {{...
                    'id','logfile','target','logfile',...
                    'verbosity',env.get('verbosityLogfile'),...
                    'outputFcn',@Debug.printToLogfile,'outputArgs',getLogfile(this),...
                    'prependPriority',true,'prependTime',true,'prependSource',true,...
                    'canHTML',false,'canMultiline',true}}];
            end
            [varargin,loggers] = util.argkeyval('loggers',varargin,loggers);
            
            % define error handler
            handler = {'mode',env.get('debug')};
            [varargin,handler] = util.argkeyval('handler',varargin,handler);
            
            % process property name-value pairs
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % set up loggers and error handler
            this.hLogger = cellfun(@(x)Debug.Logger(x{:}),loggers,'UniformOutput',false);
            log(this,sprintf('Session "%s" begins at %s',this.basename,datestr(this.timestamp,'yyyymmdd-HHMMSS')),'info');
            this.hErrorHandler = Debug.ErrorHandler(handler{:});
            cellfun(@(x)this.hErrorHandler.addLogger(x),this.hLogger);
        end % END function Debugger
        
        function registerClient(this,client,varargin)
            % REGISTERCLIENT Register a debugger client
            %
            %   REGISTERCLIENT(THIS,CLIENT,ATTR1,ATTR2,...)
            %   Register a client with specific attributes for logger
            %   verbosities and debug mode. The input CLIENT should be the
            %   full path to the file that will be generating debug queries
            %   (for example, from the output of the WHICH command).
            
            % capture inputs for each resource: loggers and errorhandler
            % first, identify the names of the verbosity categories (by
            % default, 'Screen' and 'Logfile')
            verbosityNames = cellfun(@(x)sprintf('verbosity%s%s',upper(x.id(1)),lower(x.id(2:end))),this.hLogger,'UniformOutput',false);
            for kk=1:length(this.hLogger)
                [varargin,verbosity,~,argfound] = util.argkeyval(verbosityNames{kk},varargin,this.hLogger{kk}.verbosity);
                if argfound,this.hLogger{kk}.registerClient(client,verbosity);end
            end
            [varargin,mode,~,argfound] = util.argkeyval('debugMode',varargin,this.hErrorHandler.mode);
            if argfound,this.hErrorHandler.registerClient(client,mode);end
            
            % make sure no leftover unused inputs
            util.argempty(varargin);
        end % END function registerClient
        
        function deregisterClient(this,client)
            % DEREGISTERCLIENT De-register a client
            %
            %   DEREGISTERCLIENT(THIS,CLIENT)
            %   De-register a client for this logger.
            
            % loop over loggers and error handler
            for kk=1:length(this.hLogger)
                if this.hLogger{kk}.isRegistered(client)
                    this.hLogger{kk}.deregisterClient(client);
                end
            end
            if this.hErrorHandler.isRegistered(client)
                this.hErrorHandler.deregisterClient(client,mode);
            end
            
            % identify table row
            idx_client = strcmpi(this.clients.clientID,client);
            assert(nnz(idx_client)>0,'Could not find client "%s" in list of registered clients',client);
            
            % remove client
            this.clients(idx,:) = [];
        end % END function deregisterClient
        
        function tf = isRegistered(this,client)
            % ISREGISTERED Check whether a client is registered
            %
            %   TF = ISREGISTERED(THIS,CLIENT)
            %   Return a logical TRUE if the client specified by CLIENT is
            %   registered, or a FALSE otherwise.
            
            % enforce id uniqueness
            tf = nan(1,length(this.hLogger)+1);
            for kk=1:length(this.hLogger)
                tf(kk) = this.hLogger{kk}.isRegistered(client);
            end
            tf(end) = this.hErrorHandler.isRegistered(client);
            tf = any(tf);
        end % END function isRegistered
        
        function oldLevel = setVerbosity(this,newLevel,logger,varargin)
            % SETVERBOSITY Set new verbosity for the loggers
            %
            %   OLDLEVEL = SETVERBOSITY(THIS,NEWLEVEL)
            %   Set the verbosity to the level specified by NEWLEVEL, and
            %   return the previous verbosity in OLDLEVEL. By default,
            %   updates verbosity for the first logger in the HLOGGER
            %   property, for all non-registered clients (i.e., registered
            %   clients retain their verbosity levels). NEWLEVEL can be
            %   either a DEBUG.PRIORITYLEVEL object or the char equivalent
            %   of an enumeration of that class.
            %
            %   OLDLEVEL = SETVERBOSITY(THIS,NEWLEVEL,LOGGER)
            %   Indicate which logger should be modified. LOGGER should be
            %   a char vector reflecting the ID of one of the loggers (by
            %   default, these are 'screen' and 'logfile').
            %
            %   OLDLEVEL = SETVERBOSITY(THIS,NEWLEVEL,LOGGER,CLIENT)
            %   Specify a client to which verbosity changes should be
            %   applied. The CLIENT input should contain the full path to
            %   the file that would be making the debug query, or, to
            %   modify verbosity for all non-registered entities, use the
            %   special client string 'GLOBAL' (the default if no client is
            %   specified).
            
            % default logger
            if nargin<3||isempty(logger),logger=this.hLogger{1}.id;end
            idx_logger = cellfun(@(x)strcmpi(x.id,logger),this.hLogger);
            assert(any(idx_logger),'Could not find a logger with id "%s"',logger);
            
            % set the verbosity
            oldLevel = this.hLogger{idx_logger}.setVerbosity(newLevel,varargin{:});
        end % END function setVerbosity
        
        function oldMode = setDebugMode(this,newMode,varargin)
            % SETDEBUGMODE Set new debug mode for the error handler
            %
            %   OLDMODE = SETDEBUGMODE(THIS,NEWMODE)
            %   Set the debug mode to the mode specificied by NEWMODE, and
            %   return the previous mode in OLDMODE. NEWMODE can be either
            %   a DEBUG.MODE object or the char equivalent of an
            %   enumeration of that class.
            %
            %   OLDMODE = SETDEBUGMODE(THIS,NEWMODE,CLIENT)
            %   Specify a client to which debug mode changes should be
            %   applied. The CLIENT input should contain the full path to
            %   the file that would be making the debug query, or, to
            %   modify debug mode for all non-registered entitites, use the
            %   special client string 'GLOBAL' (the default if no client is
            %   specified).
            
            % set the debug mode
            oldMode = this.hErrorHandler.setDebugMode(newMode,varargin{:});
        end % END function setDebugMode
        
        function logfile = getLogfile(this)
            logdir = env.get('output');
            if isempty(logdir),logdir='.';end
            logfile = fullfile(logdir,sprintf('%s_%s.log',this.basename,datestr(this.timestamp,'yyyymmdd-HHMMSS')));
        end % END function getLogfile
        
        function warning(this,msg,varargin)
            % WARNING log warning message
            
            % log the warning message
            cellfun(@(x)x.log(msg,Debug.PriorityLevel.WARNING,'skip','debugger',varargin{:}),this.hLogger);
        end % END function warning
        
        function error(this,msg,varargin)
            % ERROR log error message, throw error as caller
            
            % log the error message
            cellfun(@(x)x.log(msg,Debug.PriorityLevel.ERROR,'skip','debugger',varargin{:}),this.hLogger);
            
            % throw the error as the calling function
            stack = dbstack;
            caller = stack(2).name;
            idstr = sprintf('%s:msg_%s',caller,cache.hash(msg));
            ME = MException(idstr,msg);
            throwAsCaller(ME);
        end % END function error
        
        function log(this,msg,priority,varargin)
            % LOG Log a message
            
            % default message priority
            if nargin<3||isempty(priority),priority=Debug.PriorityLevel.ERROR;end
            
            % pass message to each registered logger
            cellfun(@(x)x.log(msg,priority,varargin{:}),this.hLogger);
        end % END function log
        
        function st = toStruct(this)
            skip = {}; % may have a handle to this, creating a recursive path for toStruct
            st = toStruct@util.Structable(this,skip{:});
        end % END function toStruct
        
        function delete(this)
            if ~isempty(this.hLogger)
                try log(this,sprintf('Session ''%s'' ends at %s (%s)',this.basename,datestr(now,'yyyymmdd-HHMMSS'),getLogfile(this)),'info'); catch ME, util.errorMessage(ME); end
                try cellfun(@delete,this.hLogger); catch ME, util.errorMessage(ME); end
            end
            if ~isempty(this.hErrorHandler)
                try delete(this.hErrorHandler); catch ME, util.errorMessage(ME); end
            end
        end % END function delete
        
        % ----
        % ---- wrappers for ErrorHandler methods
        % ----
        function assert(this,varargin)
            assert(this.hErrorHandler,varargin{:});
        end % END function assert
        
        function kb(this,varargin)
            kb(this.hErrorHandler,varargin{:});
        end % END function kb
        
        function errmsg(this,varargin)
            errmsg(this.hErrorHandler,varargin{:});
        end % END function errmsg
        
        function process(this,ME,varargin)
            this.hErrorHandler.process(ME,varargin{:});
        end % END fucntion process
    end % END methods
end % END classdef Debugger