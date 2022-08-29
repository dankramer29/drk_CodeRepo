classdef Logger < handle & util.Structable & util.StructableHierarchy
    % LOGGER a class to support logging messages to customizable outputs
    %
    %   This class is intended to encapsulate the process of receiving a
    %   message, checking the message priority against a verbosity level,
    %   possibly modifying the message to include source or timestamp, and
    %   sending the message to an output function.
    %
    %   The default output function will print messages to the screen.
    %   However, the output function can be set to anything, for example,
    %   to add messages to a text file, or to insert comments in a neural
    %   data recording.  It is the user's responsibility to create this
    %   function and provide the function handle and any additional
    %   arguments.
    %
    %   The output function should expect the message as its first
    %   argument if it is a function, or the second argument if it is a
    %   method of a class.  For the latter scenario, provide the method
    %   name and the object as a cell array, i.e. {@fcn,obj}.  Otherwise,
    %   simply provide the function handle directly.  Any additional
    %   arguments may be provided and will be passed to the output function
    %   after the message.
    %
    %   Spencer Kellis
    %   skellis@vis.caltech.edu
    %   8/15/2015
    
    properties
        id % string id
        target % string to identify message target (i.e., 'screen' or 'logfile')
        outputFcn % function to receive and process messages
        outputArgs = {} % arguments to pass to the output function when initializing
        prependPriority = true % whether to prepend priority level of the message
        prependTime = false % whether to prepend message with a timestamp
        prependSource = false % whether to prepend message with the caller name
        canHTML = false; % whether the logger accepts messages with HTML (i.e. hyperlinks)
        canMultiline = false; % whether the logger accepts messages with newline characters
        clients % table with client-specific verbosities
    end % END properties
    
    properties(SetAccess=private,GetAccess=public)
        verbosity % the verbosity level
    end % end properties(SetAccess=private,GetAccess=public)
    
    properties(Access=private)
        fid % hold the I/O identifier for the log output
    end % END properties(Access=private)
    
    methods
        function this = Logger(varargin)
            this.clients = cell2table({'global',env.get('verbosityScreen')},'VariableNames',{'clientID','verbosity'});
            
            % process inputs
            varargin = util.argobjprop(this,varargin);
            [varargin,verbosityUser] = util.argkeyval('verbosity',varargin,Debug.PriorityLevel.ERROR);
            setVerbosity(this,verbosityUser);
            util.argempty(varargin);
            
            % default print to screen
            if isempty(this.outputFcn)
                this.outputFcn = @Debug.printToScreen;
            end
            if isempty(this.id)
                this.id = 'screen';
            end
            
            % post-process and validate properties
            this.outputArgs = util.ascell(this.outputArgs);
            this.outputFcn = util.ascell(this.outputFcn);
            if ischar(this.outputFcn{1}),this.outputFcn{1}=str2func(this.outputFcn{1});end
            assert(isa(this.outputFcn{1},'function_handle'),'Invalid output function');
            assert(isa(this.verbosity,'Debug.PriorityLevel'),'Invalid verbosity level');
            assert(~isempty(this.id),'Invalid id');
            
            % init the output
            this.fid = feval(this.outputFcn{:},-1,this.outputArgs{:});
        end % END function Logger
        
        function registerClient(this,client,verbosity)
            % REGISTERCLIENT Register a client with specific verbosity
            %
            %   REGISTERCLIENT(THIS,CLIENT,VERBOSITY)
            %   Register a client with specific verbosity for this logger.
            %   The input CLIENT should be the full path to the file that
            %   will be generating debug queries (for example, from the
            %   output of the WHICH command).
            if nargin<3||isempty(verbosity),verbosity=this.verbosity;end
            [idx_client,client] = processClientInput(this,client);
            
            % enforce id uniqueness
            assert(~any(idx_client),'Client ID "%s" already exists',client);
            
            % correct number of inputs
            if ischar(verbosity),verbosity=Debug.PriorityLevel.fromString(verbosity);end
            assert(isa(verbosity,'Debug.PriorityLevel'),'Must provide verbosity as "Debug.PriorityLevel", not "%s"',class(verbosity));
            
            % add client
            this.clients(end+1,:) = cell2table({client,verbosity},'VariableNames',{'clientID','verbosity'});
        end % END function registerClient
        
        function deregisterClient(this,client)
            % DEREGISTERCLIENT De-register a client
            %
            %   DEREGISTERCLIENT(THIS,CLIENT)
            %   De-register a client for this logger.
            
            % convert to full path
            [idx_client,client] = processClientInput(this,client);
            
            % identify table row
            assert(any(idx_client),'Could not find client "%s" in list of registered clients',client);
            
            % remove client
            this.clients(idx,:) = [];
        end % END function deregisterClient
        
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
        
        function oldLevel = setVerbosity(this,newLevel,client)
            % SETVERBOSITY Set the verbosity level
            %
            %   OLDLEVEL = SETVERBOSITY(THIS,NEWLEVEL)
            %   Set the verbosity of the Logger object to the value
            %   specified by NEWLEVEL, which can be an object of class
            %   DEBUG.PRIORITYLEVEL, or a string matching one of the
            %   enumerations of DEBUG.PRIORITYLEVEL. Returns the old
            %   verbosity in OLDLEVEL. By default, modifies the verbosity
            %   for all non-registered clients (i.e., CLIENT is 'GLOBAL').
            %
            %   OLDMODE = SETVERBOSITY(THIS,NEWLEVEL,CLIENT)
            %   Specify the client for which to modify the verbosity.
            %   CLIENT input should be full path to file which will or is
            %   making the debug query.
            
            % default client and which
            if nargin<3||isempty(client),client='global';end
            [idx_client,client] = processClientInput(this,client);
            
            % check for client registration and specific verbosities
            assert(any(idx_client),'No registered client with ID "%s"',client);
            
            % set the verbosity
            assert(isa(newLevel,'Debug.PriorityLevel'),'Must provide verbosity as "Debug.PriorityLevel", not "%s"',class(newLevel));
            oldLevel = this.clients.verbosity(idx_client);
            this.clients.verbosity(idx_client) = newLevel;
            if strcmpi(client,'global')
                this.verbosity = newLevel;
            end
        end % END function setVerbosity
        
        function log(this,msg,priority,varargin)
            % MESSAGE Output a message based on priority and verbosity
            
            % handle priority input
            if nargin<3||isempty(priority),priority=Debug.PriorityLevel.ERROR;end
            if ischar(priority),priority=Debug.PriorityLevel.fromString(priority);end
            assert(isenum(priority)&&isa(priority,'Debug.PriorityLevel'),'Priority input must be "Debug.PriorityLevel", not "%s"',class(priority));
            
            % check for client registration
            st = dbstack('-completenames');
            idx = cellfun(@(x)strcmpi(x,'Debugger.process')|strcmpi(x,'Debugger.log'),{st.name});
            assert(any(idx),'Could not find "Debugger.log" or "Debugger.process" in the call stack');
            if idx(end)
                idx_client = strcmpi('global',this.clients.clientID);
            else
                client = st(circshift(idx,1,2)).file;
                idx_client = processClientInput(this,client);
                if ~any(idx_client),idx_client=strcmpi('global',this.clients.clientID);end
            end
            
            % check priority against verbosity level
            if double(priority)>double(this.clients.verbosity(idx_client)),return;end
            
            % no input, just print newlines
            if nargin<=1
                util.argempty(varargin);
                this.fid = feval(this.outputFcn,this.fid,'\n\n');
                return;
            end
            
            % prepend source if requested
            srcstr = '';
            if this.prependSource
                
                % user may provide source name/line
                [varargin,source_name,~,found] = util.argkeyval('source',varargin,'');
                if found
                    
                    % if user provided name, may also provide line;
                    % otherwise, don't show line number (don't know
                    % whether dbstack line number matches user intent)
                    [varargin,source_line] = util.argkeyval('line',varargin,-1);
                else
                    
                    % default don't skip any stack entries
                    [varargin,skipStrings] = util.argkeyval('skip',varargin,{});
                    skipStrings = util.ascell(skipStrings);
                    
                    % get source name/line from debug stack if not
                    % provided; allow user to override the line
                    skip = [skipStrings {'comment','log','ErrorHandler','Logger'}];
                    [~,source_name,source_line_stack] = Debug.getSourceFromStack(dbstack,skip);
                    [varargin,source_line] = util.argkeyval('line',varargin,source_line_stack);
                end
                
                % if source line unspecified, just print source name
                if source_line>=1
                    srcstr = sprintf('[%s:%d]\t',source_name,source_line);
                else
                    srcstr = sprintf('[%s]\t',source_name);
                end
            end
            
            % prepend timestamp if requested
            tmstr = '';
            if this.prependTime
                
                % datevec+sprintf much faster than datestr
                [varargin,tmstr] = util.argkeyval('timestamp',varargin,sprintf('%04d-%02d-%02d %02d:%02d:%02.03f\t',datevec(now)));
            end
            
            % prepend priority level if requested
            prstr = '';
            if this.prependPriority
                
                % generate priority string
                prstr = sprintf('%d-%-9s\t',double(priority),char(priority));
            end
            
            % prepend the string as requested
            msg = sprintf('%s%s%s%s',prstr,tmstr,srcstr,msg);
            
            % send the string
            util.argempty(varargin);
            this.fid = feval(this.outputFcn{:},msg,this.fid);
        end % END function log
        
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
        
        function list = structableSkipFields(~)
            % can't guarantee safe struct conversion of all entries in cell
            % arrays handlerFcn and handlerArgs, so punting for
            % now: just saving the string representation of the function 
            % handle.
            list = {'outputFcn','outputArgs'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st.outputFcn = cellfun(@(x)util.any2str(x),this.outputFcn,'UniformOutput',false);
        end % END function structableManualFields
        
        function delete(this)
            feval(this.outputFcn{:},-1,this.fid);
        end % END functioun delete
    end % END methods
end % END classdef Logger