classdef Input < handle & util.Structable & util.StructableHierarchy
    % INPUT Manage detection of registered keypress combinations
    %
    %   The Keyboard.Input class provides a mechanism for registering
    %   keypress combinations, checking whether those keypress combinations
    %   have been input through the keyboard, and providing information
    %   about timing and specific keys pressed.  It is intended to be used
    %   in the Experiment2 package but it should be general enough to
    %   operate independently.
    %
    %     Example:
    %     >> k = Keyboard.Input('verbosity',3); % override verbosity level
    %
    %   Keypresses are defined by NAME, a string identifier; ALLKEYS, a 
    %   list of keys that must all be pressed; and, ANYKEYS, a list of keys
    %   of which any may be pressed.  Keypress detection may be enabled and
    %   disabled individually for each registered key combination.
    %
    %     Example:
    %     >> k.register('help',{'LeftControl','LeftAlt'},{'h','p'});
    %     >> k.enable('help');
    %
    %   Keypress combinations are checked when the update function is 
    %   called.  Information about the keypresses is stored in a one-sample
    %   history with the name, keys pressed, and time of the event.  This
    %   information is also attached to the KeyPress event which fires when
    %   a registered keypress is detected.
    %
    %     Example:
    %     >> k.update;
    %     >> info = k.check('help');
    %
    %   The one-sample history resets automatically when calling the check
    %   function.  However, when using the event callback method of
    %   responding to key combinations, use the reset function to manually
    %   reset the history.
    %
    %     Example:
    %     >> k.reset('help');
    %
    %   Keypresses may also be simulated (only locally within the class,
    %   not at the O/S level) in order to automate tasks with expected
    %   responses.
    %
    %     Example:
    %     >> k.simulate('help','h');
    %
    %   See also KEYBOARD.VALIDKEYNAMES, KEYBOARD.GETVALIDKEYNAME,
    %   LISTENCHAR.
    
    properties
        commentFcn % handle to comment function (or cell array with first cell containing function handle)
        timeout = 0.2; % default wait 0.2s before registering same keypress
        resetOnListenModeChange = false; % whether to reset the character buffer when changing listen mode
        defaultMultipleMatches = false; % if true, accept all valid key names matching input strings (strncmpi); otherwise, force a single match
        defaultEnable = false; % if true, key combinations are enabled by default, otherwise disabled by default
        unifyNumberKeys = true; % if true, number row and number pad numbers are equivalent, and represented by the single number
        unifyArithmeticOperators = false; % if true, number row and number pad arithmetic operators are equivalent (except * which conflicts with 8)
        unifiedKeyList
        debug % debug level
        verbosity % verbosity level
    end
    
    properties(GetAccess='public',SetAccess='private')
        isListening = false; % status, i.e. whether listening to characters or not
        isEchoing = false; % status, i.e. whether echoing characters to command window or not
        history % struct with fields for each of the registered key combinations providing most recent detection information
        keyBindings % cell array of registered key bindingss
        alias % cell array of alias names (different names for same keypress combinations)
    end % END properties(GetAccess='public',SetAccess='private')
    
    properties(Access=private)
        nextUpdateTime
    end % END properties(Access=private)
    
    events
        KeyPress % fires when keypress identified
    end % END events
    
    methods
        function this = Input(varargin)
            % INPUT listen for character presses and trigger callbacks
            %
            %   THIS = INPUT
            %   Create a Keyboard.Input object THIS.
            
            % unify key names to MacOS-X naming scheme regardless of O/S
            KbName('UnifyKeyNames');
            
            % start listening, allow echo
            listen(this,'reset',true,'echo',true);
            
            % load debug/verbosity HST env vars
            [this.debug,this.verbosity] = env.get('debug','verbosity');
            this.commentFcn = {@internalComment,this};
            
            % property-style inputs override config, make sure no remaining
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % keyBindings and alias init as empty cells with correct cols
            this.keyBindings = cell(0,6);
            this.alias = cell(0,5);
            this.unifiedKeyList = {};
            
            % initialize update time
            this.nextUpdateTime = GetSecs;
            
            % unified number keys
            if this.unifyNumberKeys
                unify(this,'0',{'0)','0'});
                unify(this,'1',{'1!','1'});
                unify(this,'2',{'2@','2'});
                unify(this,'3',{'3#','3'});
                unify(this,'4',{'4$','4'});
                unify(this,'5',{'5%','5'});
                unify(this,'6',{'6^','6'});
                unify(this,'7',{'7&','7'});
                unify(this,'8',{'8*','8'});
                unify(this,'9',{'9(','9'});
            end
            if this.unifyArithmeticOperators
                unify(this,'-',{'-_','-'});
                unify(this,'+',{'=+','+'});
                unify(this,'/',{'/?','/'});
            end
        end % END function Input
        
        function register(this,name,allkeys,anykeys,description,fcn,varargin)
            % REGISTER Register a key combination
            %
            %   REGISTER(THIS,NAME,ALLKEY,ANYKEY,DESCRIPTION,FCN)
            %   Register the keys listed in cell arrays ALLKEY and ANYKEY 
            %   to the string identifier NAME, with the description listed 
            %   in DESCRIPTION, and the callback function FCN.  This last
            %   input can be a function handle or a cell array in which the
            %   first element is a function handle and the rest are
            %   arguments to provide to the function.  All keys listed in 
            %   ALLKEY, plus at least one of the keys listed in ANYKEY, 
            %   must be pressed for the key combination to trigger. Either
            %   ALLKEY or ANYKEY may be empty, but not both.  The minimum
            %   required information to register a key combination are the
            %   first three arguments: the Keyboard object THIS, string
            %   NAME, and cell array of strings ALLKEY.  All other values
            %   will be set to default values of empty or false as
            %   appropriate.
            %
            %   REGISTER(...,'AllowMultipleMatches',[TRUE|FALSE])
            %   Allow multiple matches when associating input keys with
            %   valid key names.  In some cases this may be useful, for
            %   example, when '1' matches both '1' and '1!'.  In other
            %   cases it may be unhelpful, as when 'h' matches 'h' and
            %   'home'.  See KEYBOARD.GETVALIDKEYNAME for more information.
            %
            %   REGISTER(...,'enabled',[TRUE|FALSE])
            %   Set the enable flag for the registered combination to the 
            %   logical value.
            
            % default empty on both allkeys and anykeys
            if nargin<3,allkeys={}; end
            if nargin<4,anykeys={}; end
            if nargin<5,description=''; end
            if nargin<6,fcn={}; end
            [varargin,enable,~,found] = util.argflag('enable',varargin,this.defaultEnable);
            if found,enable=true;end
            util.argempty(varargin);
            
            % make sure not both empty
            assert(~(isempty(allkeys)&&isempty(anykeys)),'Must provide at least one key');
            
            % make sure key lists and function are cell arrays
            allkeys = util.ascell(allkeys);
            anykeys = util.ascell(anykeys);
            fcn = util.ascell(fcn);
            
            % make sure empty or valid function
            assert(isempty(fcn)||(iscell(fcn)&&isa(fcn{1},'function_handle')),'FCN must be a function handle or cell array in which the first element is a function handle.');
            
            % get valid keynames (multiple matches need to be cat'd)
            keyfcn = @(x)Keyboard.getValidKeyName(x,'AllowMultipleMatches',this.defaultMultipleMatches);
            allkeys = cellfun(keyfcn,allkeys,'UniformOutput',false);
            while ~isempty(allkeys) && any(cellfun(@iscell,allkeys))
                allkeys = cat(2,allkeys{:});
            end
            anykeys = cellfun(keyfcn,anykeys,'UniformOutput',false);
            while ~isempty(anykeys) && any(cellfun(@iscell,anykeys))
                anykeys = cat(2,anykeys{:});
            end
            
            % check conflicts with previous key registrations
            %  1. unique NAME
            %  2. for given ALLKEY, no overlapping ANYKEY
            if any(ismember(name,this.keyBindings(:,1)))
                comment(this,sprintf('A key combination is already registered under the name ''%s''',name),3);
                return;
            elseif any(ismember(name,this.alias(:,1)))
                comment(this,sprintf('An alias is already registered under the name ''%s''',name),3);
                return;
            end
            for kk=1:size(this.keyBindings,1)
                
                % check exact same as existing
                if length(allkeys)==length(this.keyBindings{kk,2}) && all(ismember(allkeys,this.keyBindings{kk,2})) && ... % same ALLKEY
                        length(anykeys)==length(this.keyBindings{kk,3}) && all(ismember(anykeys,this.keyBindings{kk,3})) % same ANYKEY
                    
                    % create an alias
                    this.alias(end+1,:) = {name,kk,description,fcn,enable}; % name, index of registered keybinding, description, callback, enable
                    this.history.(name) = []; % initialize history to empty
                    comment(this,sprintf('Alias ''%s'' created for key binding ''%s'' (enabled=%d)',name,this.keyBindings{kk,1},enable),5);
                    return;
                end
            end
            
            % update key binding
            this.keyBindings(end+1,:) = {name,allkeys,anykeys,description,fcn,enable};
            this.history.(name) = []; % initialize history to empty
            comment(this,sprintf('Key binding ''%s'' created (enabled=%d)',name,enable),5);
        end % END registerKeyBinding
        
        function unregister(this,name)
            % UNREGISTER Unregister a key combination
            %
            %   UNREGISTER(THIS,NAME)
            %   Unregister the key combination identified by the string
            %   NAME.
            
            % identify the registered keypress combination
            idx = strcmpi(this.keyBindings(:,1),name);
            if nnz(idx)==1
                comment(this,sprintf('Removing key binding ''%s''',this.keyBindings{this.alias{idx,2},1}),5);
                
                % remove from list of key bindings
                this.keyBindings(idx,:) = [];
                
                % remove from history
                this.history = rmfield(this.history,name);
            else
                
                % check for alias
                idx = strcmpi(this.alias(:,1),name);
                if nnz(idx)==1
                    comment(this,sprintf('Removing alias ''%s'' for key binding ''%s''',this.alias{idx,1},this.keyBindings{this.alias{idx,2},1}),5);
                    
                    % remove from list of aliases
                    this.alias(idx,:) = [];
                    
                    % remove from history
                    this.history = rmfield(this.history,name);
                else
                    
                    % inform user nothing found by that name
                    comment(this,sprintf('No registered key binding or alias exists under the name ''%s''',name),2);
                end
            end
        end % END function unregisterKeyBinding
        
        function tf = isRegistered(this,varargin)
            % ISREGISTERED Check whether a key combination is registered
            %
            %   VAL = ISREGISTERED(THIS,NAME1,NAME2,...)
            %   Check whether a key combination has been registered with
            %   the string identifiers NAME1, NAME2, etc. and return the 
            %   logical result in the vector VAL.
            
            % check whether keypress has been registered
            val_kk = ismember(...
                cellfun(@lower,varargin,'UniformOutput',false),...
                cellfun(@lower,this.keyBindings(:,1),'UniformOutput',false));
            
            % check whether alias exists
            val_aa = ismember(...
                cellfun(@lower,varargin,'UniformOutput',false),...
                cellfun(@lower,this.alias(:,1),'UniformOutput',false));
            
            % either match indicates registered
            tf = val_kk|val_aa;
        end % END function isRegistered
        
        function unify(this,primary,keys)
            % UNIFY group multiple keys under one key name
            %
            %   UNIFY(THIS,PRIMARY,KEYS)
            %   Group all keys listed in the cell array KEYS under the
            %   single name PRIMARY.
            
            % validate input
            assert(iscell(keys)&&all(cellfun(@ischar,keys)),'Must provide KEYS as a cell array of strings');
            assert(ischar(primary),'Must provide primary as char');
            
            % create the new entry
            newEntry = {primary,keys};
            
            % add new entry to the current list of unified keys
            if isempty(this.unifiedKeyList)
                this.unifiedKeyList = {newEntry};
            else
                assert(~any(cellfun(@(x)any(ismember(x{2},keys)),this.unifiedKeyList)),'One of the listed keys is already unified under a different entry');
                this.unifiedKeyList{end+1} = newEntry;
            end
            comment(this,sprintf('Unified keys {%s} under primary key name ''%s''',strjoin(keys,', '),primary),5);
        end % END function unify
        
        function ununify(this,primary)
            % UNUNIFY remove a unified key listing
            %
            %   UNUNIFY(THIS,PRIMARY)
            %   Remove the unified key listing identified by the primary
            %   string PRIMARY from the list of unified keys.
            
            % validate input
            assert(ischar(primary),'Must provide primary as char');
            
            % identify location and remove
            idx = cellfun(@(x)strcmpi(x{1},primary),this.unifiedKeyList);
            this.unifiedKeyList(idx) = [];
            comment(this,sprintf('Un-unified unified primary key ''%s''',primary),5);
        end % END function ununify
        
        function name = getKeyName(this,name)
            % GETKEYNAME get unified key name
            %
            %   NAME = GETKEYNAME(THIS,NAME)
            %   Get the valid, unified key name associated with input name.
            
            % validate input
            assert(ischar(name),'Must provide char input, not ''%s''',class(name));
            
            % get the "valid" version
            name = Keyboard.getValidKeyName(name);
            
            % look for "name" in aliased key names and replace with primary
            idxUnified = cellfun(@(x)any(strcmpi(x{2},name)),this.unifiedKeyList);
            if any(idxUnified)
                assert(nnz(idxUnified)==1,'Cannot match multiple aliased keys');
                name = this.unifiedKeyList{idxUnified}{1};
            end
        end % END function getKeyName
        
        function varargout = update(this)
            % UPDATE check for key presses
            %
            %   UPDATE(THIS)
            %   Check for key presses and fire an event if one is
            %   activated.
            %
            %   OUTPUT = UPDATE(THIS)
            %   In addition to the behavior described above, return key 
            %   press information as the struct OUTPUT, with fields 'NAME' 
            %   containing the keypress combination name, 'ALLKEYS' 
            %   containing the required keys, 'ANYKEYS' containing the
            %   possible keys, and 'TIME' containing the timestamp of the
            %   keypress.
            
            % default empty if output requested
            if nargout>=1,varargout{1}=[];end
            
            % check whether we've finished the refractory period
            currTime = GetSecs;
            if currTime<this.nextUpdateTime, return; end
            
            % get all keys pressed
            [keyIsDown,~,keyCode] = KbCheck;
            if ~keyIsDown
                comment(this,'Nothing pressed',7);
                return
            end
            
            % get key names
            PressedKeys = util.ascell(KbName(find(keyCode)));
            
            % look for registered key bindings
            detected = zeros(1,size(this.keyBindings,1));
            whichAllkeys = cell(1,size(this.keyBindings,1));
            whichAnykeys = cell(1,size(this.keyBindings,1));
            for kk=1:size(this.keyBindings,1)
                
                % check whether this keybinding or its aliases are enabled
                FlagProcess = false;
                if this.keyBindings{kk,end}
                    FlagProcess = true;
                else
                    idx = ismember(kk,[this.alias{:,2}]) & [this.alias{:,end}];
                    if any(idx), FlagProcess = true; end
                end
                if ~FlagProcess, continue; end
                
                % pull out activation key list, key list
                allkeys = this.keyBindings{kk,2};
                anykeys = this.keyBindings{kk,3};
                
                % check for "allkey" match
                [FlagAllkeys,idxAllkeys] = matchKeys(PressedKeys,allkeys,@all,this.unifiedKeyList);
                whichAllkeys{kk} = allkeys(logical(idxAllkeys));
                
                % check for "anykey" match
                [FlagAnykeys,idxAnykeys] = matchKeys(PressedKeys,anykeys,@any,this.unifiedKeyList);
                whichAnykeys{kk} = anykeys(logical(idxAnykeys));
                
                % if it's a match, count number of matched keys
                if FlagAllkeys && FlagAnykeys
                    detected(kk) = length(whichAllkeys{kk}) + length(whichAnykeys{kk});
                end
            end
            
            % handle specific detection scenarios
            if nnz(detected)==0
                
                % no registered combinations pressed so return
                return;
            elseif nnz(detected)>1
                
                % multiple matches: choose one with the most keys matched
                detected(detected<max(detected))=0;
            end
            
            % find the index of the detected key combination
            idx = find(detected);
            assert(nnz(idx)==1,'Multiple keypress combinations detected!');
            
            % process the registered keypress
            st = process(this,idx,whichAllkeys{idx},whichAnykeys{idx},currTime);
            
            % return pressed keys if requested
            if nargout>0, varargout{1} = st; end
            
            function [match,idxMatch] = matchKeys(pressed,check,fn,unifiedKeyList)
                % MATCHKEYS Convenience function to reduce code duplicate
                %
                %   [MATCH,IDXMATCH] = MATCHKEYS(PRESSED,CHECK,FN,UNINUM)
                %   For list of pressed keys PRESSED, list of keys to check
                %   against pressed keys CHECK, logical function for
                %   determining final match FN (@any or @all), and
                %   indication of whether number keys are unified UNINUM,
                %   return whether there is a match in MATCH, and the
                %   indices of CHECK corresponding to the matched keys in
                %   IDXMATCH.
                
                % if empty, return true so as not to block anything
                % for example, a registered key binding with no "allkey"
                % entries should still be able to match on one of the
                % "anykey" entries.
                if isempty(check) || isempty(pressed)
                    idxMatch = [];
                    match = true;
                else
                    
                    % empty index
                    idxMatch = false(size(check));
                    
                    % loop over "pressed" keys
                    for nn=1:length(pressed)
                        
                        % see if we can find "pressed" in unified key alias
                        idxPressedInUnified = cellfun(@(x)any(strcmpi(x{2},pressed{nn})),unifiedKeyList);
                        if any(idxPressedInUnified)
                            
                            % replace "pressed" with the unified key name
                            pressed{nn} = unifiedKeyList{idxPressedInUnified}{1};
                        end
                        
                        % check for a match
                        idxMatch = idxMatch | strcmpi(check,pressed{nn});
                    end
                    
                    % update match flag
                    match = feval(fn,idxMatch);
                end
            end % END function matchKeys
        end % END function update
        
        function varargout = check(this,varargin)
            % CHECK Check whether keypress has occurred
            %
            %   [INFO1,INFO2,...] = CHECK(THIS,NAME1,NAME2,...)
            %   Check whether the keypress identified by the strings NAME1,
            %   NAME2, ... have occurred.  The outputs INFO1, INFO2, ...
            %   will be empty if the corresponding key combination has not
            %   occurred, or will be structs with relevant information:
            %   'NAME' (the string identifier); 'ALLKEYS' (keys which all 
            %   must be pressed for the key combination); 'ANYKEYS' (keys 
            %   of which any may be pressed to trigger the combination); 
            %   and, 'TIME' (the timestamp, in seconds, at which the 
            %   keypress was registered).  Checking any particular key 
            %   combination clears the history for that combination.
            
            % loop over all inputs
            varargout = cell(1,length(varargin));
            for kk=1:length(varargin)
                if isfield(this.history,varargin{kk})
                    
                    % pull out keypress info
                    varargout{kk} = this.history.(varargin{kk});
                    
                    % clear the history
                    this.history.(varargin{kk}) = [];
                else
                    
                    % return empty
                    varargout{kk} = [];
                end
            end
        end % END function check
        
        function reset(this,varargin)
            % RESET Clear history of key combinations
            %
            %   RESET(THIS)
            %   Clear all history of all registered key combinations.
            %
            %   RESET(THIS,NAME1,NAME2,...)
            %   Clear the history of the specified registered key
            %   combinations.
            
            % branch based on inputs
            if nargin==1
                
                % clear the entire history
                for kk=1:size(this.keyBindings,1)
                    this.history.(this.keyBindings{kk,1}) = [];
                end
                comment(this,'Cleared all keyboard history',5);
            else
                
                % clear history of specified key combinations
                for kk=1:length(varargin)
                    if isfield(this.history,varargin{kk})
                        this.history.(varargin{kk}) = [];
                        comment(this,sprintf('Cleared keyboard history for ''%s''',varargin{kk}),5);
                    else
                        comment(this,sprintf('No keyboard history for ''%s''',varargin{kk}),3);
                    end
                end
            end
        end % END function reset
        
        function enable(this,varargin)
            % ENABLE Enable detection of a registered keypress or alias
            %
            %   ENABLE(THIS,NAME1,NAME2,...)
            %   Enable detection of the keypress combinations or alias
            %   identified by the input strings NAME1, NAME2, etc.
            
            % loop over the inputs
            for kk=1:length(varargin)
                
                % identify the registered keypress combination
                idx = strcmpi(this.keyBindings(:,1),varargin{kk});
                if nnz(idx)==1
                    
                    % cannot overlap with any enabled key combinations
                    for nn=1:size(this.keyBindings,1)
                        if ~this.keyBindings{nn,end},continue;end
                        if idx(nn),continue;end
                        assert(~(...
                            length(this.keyBindings{idx,2})==length(this.keyBindings{nn,2}) && all(ismember(this.keyBindings{idx,2},this.keyBindings{nn,2})) && ... % same ALLKEY
                            any(ismember(this.keyBindings{idx,3},this.keyBindings{nn,3}))... % overlapping ANYKEY
                            ),'Cannot enable key combination ''%s'': {%s},{%s} because it overlaps with ''%s'': {%s},{%s}',...
                            this.keyBindings{idx,1},util.cell2str(this.keyBindings{idx,2}),util.cell2str(this.keyBindings{idx,3}),...
                            this.keyBindings{nn,1},util.cell2str(this.keyBindings{nn,2}),util.cell2str(this.keyBindings{nn,3}));
                    end
                    
                    % update the enable flag
                    this.keyBindings{idx,end} = true;
                    comment(this,sprintf('Enabled key binding ''%s''',this.keyBindings{idx,1}),5);
                else
                     % check for an alias
                     idx = strcmpi(this.alias(:,1),varargin{kk});
                     if nnz(idx)==1
                         
                         % cannot overlap with any enabled key combinations
                         for nn=1:size(this.keyBindings,1)
                             if ~this.keyBindings{nn,end},continue;end
                             if nn==this.alias{idx,2},continue;end
                             assert(~(...
                                 length(this.keyBindings{this.alias{idx,2},2})==length(this.keyBindings{nn,2}) && all(ismember(this.keyBindings{this.alias{idx,2},2},this.keyBindings{nn,2})) && ... % same ALLKEY
                                 any(ismember(this.keyBindings{this.alias{idx,2},3},this.keyBindings{nn,3}))... % overlapping ANYKEY
                                 ),'Cannot enable key combination ''%s'': {%s},{%s} because it overlaps with ''%s'': {%s},{%s}',...
                                 this.keyBindings{this.alias{idx,2},1},util.cell2str(this.keyBindings{this.alias{idx,2},2}),util.cell2str(this.keyBindings{this.alias{idx,2},3}),...
                                 this.keyBindings{nn,1},util.cell2str(this.keyBindings{nn,2}),util.cell2str(this.keyBindings{nn,3}));
                         end
                         
                         % update the enable flag
                         this.alias{idx,end} = true;
                         comment(this,sprintf('Enabled alias ''%s'' for key binding ''%s''',this.alias{idx,1},this.keyBindings{this.alias{idx,2},1}),5);
                     else
                         
                         % inform user nothing found by that name
                         comment(this,sprintf('No registered key binding or alias exists under the name ''%s''',name),2);
                     end
                end
            end
        end % END function enable
        
        function disable(this,varargin)
            % DISABLE Disable detection of a registered keypress
            %
            %   DISABLE(THIS,NAME1,NAME2,...)
            %   Disable detection of the keypress combination identified by
            %   the string NAME.
            
            % loop over inputs
            for kk=1:length(varargin)
                
                % identify the registered keypress combination
                idx = strcmpi(this.keyBindings(:,1),varargin{kk});
                if nnz(idx)==1
                    
                    % update the enable flag
                    this.keyBindings{idx,end} = false;
                    comment(this,sprintf('Disabled key binding ''%s''',this.keyBindings{idx,1}),5);
                else
                     % check for an alias
                     idx = strcmpi(this.alias(:,1),varargin{kk});
                     if nnz(idx)==1
                         
                         % update the enable flag
                         this.alias{idx,end} = false;
                         comment(this,sprintf('Disabled alias ''%s''',this.alias{idx,1}),5);
                     else
                         
                         % inform user nothing found by that name
                         comment(this,sprintf('No registered key binding or alias exists under the name ''%s''',name),2);
                     end
                end
            end
        end % END function enable
        
        function varargout = describe(this,name)
            % DESCRIBE Get description of a key combination
            %
            %   DESCRIBE(THIS,NAME)
            %   Print a description of the key combination identified by
            %   the string NAME to the command window.
            %
            %   TXT = DESCRIBE(THIS,NAME)
            %   Return a description of the key combination identified by
            %   the string NAME into the output TXT.  Nothing will be
            %   printed to the command window.
            
            % validate usage
            assert(nargout<=1,'This function supports only 1 or no output arguments.');
            assert(nargin==2,'This function requires 2 input arguments.');
            
            % identify the registered keypress combination
            idx = strcmpi(this.keyBindings(:,1),name);
            if nnz(idx)==1
                
                % get the description
                if nargout==0
                    fprintf('%s: %s\n',name,this.keyBindings{idx,4});
                else
                    varargout{1} = this.keyBindings{idx,4};
                end
            else
                
                idx = strcmpi(this.alias(:,1),name);
                if nnz(idx)==1
                    
                    % get the description
                    if nargout==0
                        fprintf('%s: %s\n',name,this.alias{idx,3});
                    else
                        varargout{1} = this.alias{idx,3};
                    end
                else
                    
                    % inform user nothing found by that name
                    comment(this,sprintf('No registered key binding or alias exists under the name ''%s''',name),2);
                end
            end
        end % END function describe
        
        function st = simulate(this,name,anykeys)
            % SIMULATE Simulate a keypress event without it occurring
            %
            %   ST = SIMULATE(THIS,NAME,ANYKEYS)
            %   Simulate the keypress combination specified by the string
            %   identifier NAME, and which of the anykeys should be
            %   triggered in ANYKEYS.  ANYKEYS can be character arrays
            %   corresponding to the valid key names contained in the
            %   registered key combination, or numerical or logical
            %   indexing into the registered key combination's anykeys. ST
            %   will contain the keypress event data including the name, 
            %   the list of allkeys and anykeys, and the timestamp.  The
            %   keypress will only be simulated if it is enabled.
            
            % identify the registered keypress combination
            idx = strcmpi(this.keyBindings(:,1),name);
            if nnz(idx)==1
                
                % make sure it's enabled
                if ~this.keyBindings{idx,end}, return; end
            else
                
                % check for alias
                idx = strcmpi(this.alias(:,1),name);
                if nnz(idx)==1
                    
                    % make sure it's enabled
                    if ~this.alias{idx,end}, return; end
                    
                    % use key binding index
                    idx = this.alias{idx,2};
                else
                    
                    % inform user nothing found by that name
                    comment(this,sprintf('No registered key binding or alias exists under the name ''%s''',name),2);
                    return;
                end
            end
            
            % default all of the anykeys pressed
            if nargin<3, anykeys=1:length(this.keyBindings{idx,3}); end
            
            % handle different styles of anykey input
            anykeys = util.ascell(anykeys);
            if all(cellfun(@ischar,anykeys)) % all string representations of keys
                assert(all(ismember(anykeys,this.keyBindings{idx,3})),'Some elements of anykeys provided are not valid');
            elseif all(cellfun(@isnumeric,anykeys)) % numeric indices into anykey list
                assert(all(ismember([anykeys{:}],1:length(this.keyBindings{idx,3}))),'Provided indices are outside the range of available anykey list');
                anykeys = this.keyBindings{idx,3}([anykeys{:}]);
            elseif all(cellfun(@islogical,anykeys)) % logical indices into anykey list
                assert(length(anykeys)==length(this.keyBindigns{idx,3}),'Logical indices must match the dimensions of the registered anykey list.');
                anykeys = this.keyBindings{idx,3}([anykeys{:}]);
            else
                error('Invalid specification of anykey list');
            end
            
            % convert to vector of indices;
            anykeys = [anykeys{:}];
            
            % current timestamp
            currTime = GetSecs;
            
            % identify which of the anykeys was pressed
            whichAnykeys = this.keyBindings{idx,3};
            whichAnykeys = whichAnykeys(anykeys);
            
            % process the keypress event
            st = process(this,idx,whichAnykeys,currTime);
        end % END function simulate
        
        function setTimeout(this,period)
            % SETTIMEOUT Set the timeout period between consecutive keys
            %
            %   SETTIMEOUT(THIS,PERIOD)
            %   Set the timeout period between consecutive keypresses to
            %   the value in PERIOD (in seconds).
            
            % update the property
            this.timeout = period;
        end % END function setTimeout
        
        function listen(this,varargin)
            % LISTEN Change how the object listens for character input
            %
            %   LISTEN(THIS)
            %   Reset the character buffer and start listening to 
            %   characters, allowing characters to echo to the command
            %   window.
            %
            %   LISTEN(...,'listen',[TRUE|FALSE])
            %   Enable or disable listening.
            %
            %   LISTEN(...,'reset',[TRUE|FALSE])
            %   Reset (TRUE) or do not reset (FALSE) the character
            %   buffer.  Default is TRUE.
            %
            %   LISTEN(...,'echo',[TRUE|FALSE])
            %   Allow character input to echo to the command window (TRUE)
            %   or not (FALSE).  Default is TRUE.
            %
            %   See also LISTENCHAR.
            
            % process user inputs
            [varargin,FlagListen] = util.argkeyval('listen',varargin,true);
            [varargin,FlagReset] = util.argkeyval('reset',varargin,this.resetOnListenModeChange);
            [varargin,FlagEcho] = util.argkeyval('echo',varargin,true);
            util.argempty(varargin);
            
            % listen with or without echo
            if FlagListen
                
                % reset the character buffer
                if FlagReset
                    ListenChar(0);
                    this.isListening = false;
                    this.isEchoing = false;
                end
                
                % enable listening with or without echo
                if FlagEcho
                    ListenChar(1);
                    this.isListening = true;
                    this.isEchoing = true;
                else
                    ListenChar(2);
                    this.isListening = true;
                    this.isEchoing = false;
                end
            else
                
                % turn off listening (and reset character buffer)
                ListenChar(0);
                this.isListening = false;
                this.isEchoing = false;
            end
        end % END function listen
        
        function hideKeypress(this)
            % HIDEKEYPRESS start listening for characters (no echo)
            %
            %   HIDEKEYPRESS(THIS)
            %   Enable listening, but suppress characters from echoing to
            %   the command window.
            %
            %   See also LISTENCHAR.
            
            % change the listen mode
            listen(this,'echo',false);
        end % END function hideKeypress
        
        function showKeypress(this)
            % SHOWKEYPRESS start listening for characters (with echo)
            %
            %   SHOWKEYPRESS(THIS)
            %   Enable listening, but allow keypress outputs to echo to
            %   command window.
            %
            %   See also LISTENCHAR.
            
            % change the listen mode
            listen(this,'echo',true);
        end % END function listenKeypress
        
        function varargout = list(this,condition)
            % LIST List the current key bindings
            %
            %   LIST(THIS)
            %   Print a list of key binding names and key combinations to
            %   the command window.
            %
            %   LIST(THIS,'ALL')
            %   LIST(THIS,'ENABLED')
            %   LIST(THIS,'DISABLED')
            %   List all key bindings (default), or list only those key
            %   bindings that are enabled or disabled.
            %
            %   [NAMES,ALLKEYS,ANYKEYS] = LIST(THIS)
            %   Return a the names, allkeys and anykeys key lists for the
            %   registered key combinations as outputs, and do not print to
            %   the screen.
            if nargin<2||isempty(condition),condition='all';end
            
            % get values
            enabled_binding = cat(1,this.keyBindings{:,end});
            enabled_alias = cat(1,this.alias{:,end});
            
            % subselect based on condition
            switch lower(condition)
                case 'all'
                    idx_binding = enabled_binding|~enabled_binding;
                    idx_alias = enabled_alias|~enabled_alias;
                case 'disabled'
                    idx_binding = ~enabled_binding;
                    idx_alias = ~enabled_alias;
                case 'enabled'
                    idx_binding = enabled_binding;
                    idx_alias = enabled_alias;
                case 'binding'
                    idx_binding = enabled_binding|~enabled_binding;
                    idx_alias = false(size(enabled_alias));
                case 'alias'
                    idx_binding = false(size(enabled_binding));
                    idx_alias = enabled_alias|~enabled_alias;
                otherwise
                    error('Unknown condition ''%s''',condition);
            end
            
            % index into the list of key bindings
            names = [this.keyBindings(idx_binding,1);this.alias(idx_alias,1)];
            allkeys = [this.keyBindings(idx_binding,2);this.keyBindings([this.alias{idx_alias,2}],2)];
            anykeys = [this.keyBindings(idx_binding,3);this.keyBindings([this.alias{idx_alias,2}],3)];
            descriptions = [this.keyBindings(idx_binding,4);this.alias(idx_alias,3)];
            
            % calculate max name length
            namelen = max(cellfun(@length,names));
            
            % either print to the screen or return as outputs
            if nargout==0
                fprintf('\n');
                fprintf('  Registered Keypresses\n');
                fprintf('  ==========================\n');
                for kk=1:length(names)
                    allkeystr = util.cell2str(allkeys{kk},', ');
                    if isempty(allkeystr), allkeystr='none'; end
                    anykeystr = util.cell2str(anykeys{kk},', ');
                    if isempty(anykeystr), anykeystr='none'; end
                    fprintf(['%3d. %-' num2str(namelen+1) 's: {%s}, {%s}\n'],kk,names{kk},allkeystr,anykeystr);
                end
            else
                if nargout>=1, varargout{1}=names; end
                if nargout>=2, varargout{2}=allkeys; end
                if nargout>=3, varargout{3}=anykeys; end
                if nargout>=4, varargout{4}=descriptions; end
            end
        end % END function list
        
        function list = getAnykeys(this,name)
            % GETANYKEYS Get the list of anykeys for a key combination
            %
            %   LIST = GETANYKEYS(THIS,NAME)
            %   Return a cell array of strings in LIST containg the anykeys
            %   for the registered key combination identified by NAME.
            
            % identify the registered keypress combination
            idx = strcmpi(this.keyBindings(:,1),name);
            if nnz(idx)==1
                
                % get the list of anykeys
                list = this.keyBindings{idx,3};
            else
                
                % look for aliases
                idx = strcmpi(this.alias(:,1),name);
                if nnz(idx)==1
                    
                    % get the list of anykeys
                    list = this.keyBindings{this.alias{idx,2},3};
                else
                    
                    % inform user nothing found by that name
                    comment(this,sprintf('No registered key binding or alias exists under the name ''%s''',name),2);
                end
            end
        end % END function getAnykeys
        
        function list = getAllkeys(this,name)
            % GETALLKEYS Get the list of allkeys for a key combination
            %
            %   LIST = GETALLKEYS(THIS,NAME)
            %   Return a cell array of strings in LIST containg the allkeys
            %   for the registered key combination identified by NAME.
            
            % identify the registered keypress combination
            idx = strcmpi(this.keyBindings(:,1),name);
            if nnz(idx)==1
                
                % get the list of anykeys
                list = this.keyBindings{idx,2};
            else
                
                % look for aliases
                idx = strcmpi(this.alias(:,1),name);
                if nnz(idx)==1
                    
                    % get the list of anykeys
                    list = this.keyBindings{this.alias{idx,2},2};
                else
                    
                    % inform user nothing found by that name
                    comment(this,sprintf('No registered key binding or alias exists under the name ''%s''',name),2);
                end
            end
        end % END function getAllkeys
        
        function name = getName(this,idx)
            % GETNAME Get the name of a registered key combination
            %
            %   NAME = GETNAME(THIS,IDX)
            %   Return the name of the key combination at position IDX in 
            %   the list of registered key combinations.
            
            % validate the index
            assert(idx<=size(this.keyBindings,1),'Invalid index %d (must be less than or equal to %d)',idx,size(this.keyBindings,1));
            
            % get the name
            name = this.keyBindings{idx,1};
        end % END function getName
        
        function comment(this,msg,vb)
            % COMMENT Display a message on the screen
            %
            %   COMMENT(THIS,MSG,VB)
            %   Display the text in MSG on the screen depending on the
            %   message verbosity level VB.  MSG should not include a
            %   newline at the end, unless an extra newline is desired.  If
            %   VB is not specified, the default value is 1.
            
            % default message verbosity
            if nargin<3,vb=1;end
            
            % execute the comment function
            feval(this.commentFcn{:},msg,vb);
        end % END function comment
        
        function list = structableSkipFields(this)
            list = {'commentFcn'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st.commentFcn = func2str(this.commentFcn{1});
        end % END function structableManualFields
        
        function delete(this)
            if this.isListening
                listen(this,'listen',false);
            end
        end % END function delete
    end % END methods
    
    methods(Access=private)
        function st = process(this,idx,allkeys,anykeys,currTime)
            % PROCESS Process a registered keypress
            %
            %   ST = PROCESS(THIS,IDX,ANYKEY,CURRTIME)
            %   Given a keypress index IDX, index into anykeys indicating
            %   which were hit ANYKEY, and a timestamp CURRTIME, update the 
            %   history, fire the KeyPress event, and return the event data
            %   in ST.
            
            % either matched key binding is enabled, or an alias is
            if this.keyBindings{idx,end}
                name = this.keyBindings{idx,1};
                fcn = this.keyBindings{idx,5};
                comment(this,sprintf('Processing key binding ''%s''',name),4);
            else
                idx_alias = ismember([this.alias{:,2}],idx) & [this.alias{:,end}];
                if nnz(idx_alias)>1,warning('Matched multiple aliases - ignoring all except first');end
                if nnz(idx_alias)==0,warning('Nothing is enabled -- how did we get here?');end
                idx_alias = find(idx_alias,1,'first');
                try
                    name = this.alias{idx_alias,1};
                catch ME
                    util.errorMessage(ME);
                    keyboard;
                end
                fcn = this.alias{idx_alias,4};
                comment(this,sprintf('Processing key binding ''%s'' (under the alias ''%s'')',this.keyBindings{idx,1},name),4);
            end
            
            % update user
            comment(this,sprintf('Processing ''%s'': {%s}, {%s}',...
                name,...
                util.cell2str(allkeys),...
                util.cell2str(anykeys)),3);
            
            % default refractory period
            this.nextUpdateTime = currTime+this.timeout;
            
            % store keypress in history
            this.history.(name).allkeys = allkeys;
            this.history.(name).anykeys = anykeys;
            this.history.(name).time = currTime;
            
            % fire the event
            evt = util.EventDataWrapper(...
                'name',name,...
                'allkeys',allkeys,...
                'anykeys',anykeys,...
                'time',currTime);
            notify(this,'KeyPress',evt);
            
            % run the callback
            if ~isempty(fcn)
                feval(fcn{1},evt,fcn{2:end});
            end
            
            % return the keypress information
            st = evt.UserData;
        end % END function process
        
        function internalComment(this,msg,vb)
            % INTERNALCOMMENT Internal method for displaying text to screen
            %
            %   INTERNALCOMMENT(THIS,MSG,VB)
            %   If the message verbosity level VB is less than or equal to
            %   the object verbosity level, print the text in MSG to the
            %   command window with a newline appended.
            
            % print the message to the screen if verbosity level allows
            if vb<=this.verbosity,fprintf('[KEYBOARD] %s\n',msg);end
        end % END function comment
    end % END methods(Access=private)
end % END classdef Input