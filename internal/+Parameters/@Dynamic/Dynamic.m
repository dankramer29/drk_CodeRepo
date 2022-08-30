classdef Dynamic < dynamicprops & Parameters.Interface & cache.Cacheable & util.StructableHierarchy
    
    properties(Access=protected)
        state
        topics
    end % END properties(Access=protected)
    
    methods
        function this = Dynamic(varargin)
            % DYNAMIC Constructor for Dynamic object
            %
            %  PARAMS = DYNAMIC;
            %  Create an empty Dynamic object.
            %
            %  PARAMS = DYNAMIC(@CFG)
            %  Provide a configuration function handle to initialize the
            %  Dynamic object.
            %
            %  PARAMS = DYNAMIC(...,'LIKE',SRC)
            %  Provide a DYNAMIC object or struct with appropriate fields
            %  and subfields which will provide values for each parameter.
            %
            %  PARAMS = DYNAMIC(...,PARAMETER,VALUE,...)
            %  Provide a list of parameter-value pairs to override any
            %  default values, including those provided with 'LIKE' input.
            
            % call the superclass constructor (which will process config)
            this = this@Parameters.Interface(varargin{:});
            
            % get rid of config file used by superclass constructor
            cfg_idx = cellfun(@(x)isa(x,'function_handle'),varargin);
            varargin(cfg_idx) = [];
            
            % look for 'like' input (another Parameters.Dynamic object)
            idx = find(strcmpi(varargin,'like'));
            if ~isempty(idx)
                assert(length(varargin)>idx,'Not enough inputs - must provide ''like'' input as key-value pair');
                src = varargin{idx+1};
                varargin(idx+(0:1)) = [];
                
                % pull values out of src
                if isa(src,'Parameters.Dynamic')
                    [~,prm,top] = list(src);
                    
                    % loop over src topics
                    for tt=1:length(top)
                        if ~check(this,top{tt}),continue;end
                        
                        % loop over parameters in this topic
                        for pp=1:length(prm{tt})
                            this.(top{tt}).(prm{tt}{pp}) = src.(top{tt}).(prm{tt}{pp});
                        end
                    end
                elseif isstruct(src)
                    top = fieldnames(src);
                    for tt=1:length(top)
                        if ~check(this,top{tt}),continue;end
                        prm = fieldnames(src.(top{tt}));
                        
                        % loop over parameters in this topic
                        for pp=1:length(prm)
                            this.(top{tt}).(prm{pp}) = src.(top{tt}).(prm{pp});
                        end
                    end
                end
            end
            
            % process remaining inputs locally
            varargin = util.argobjprop(this,varargin);
            
            % check for topic inputs
            kk=1;
            while kk <= length(varargin)
                if isempty(strcmpi(varargin{kk},'.'))
                    topic = varargin{kk};
                    if ischar(topic) && util.existp(sprintf('Parameters.Topic.%s',topic),'file')==2
                        topic = str2func(sprintf('Parameters.Topic.%s',topic));
                    end
                    if isa(topic,'function_handle') && (strncmpi(func2str(topic),'@(',2) || util.existp(func2str(topic),'file')==2)
                        load(this,varargin{kk});
                        varargin(kk) = [];
                    else
                        kk = kk+1;
                    end
                else
                    if check(this,varargin{kk})
                        assert(length(varargin)>=kk+1,'Constructor property value inputs must be specified as name-value pairs');
                        parts = strsplit(varargin{kk},'.');
                        this.(parts{1}).(parts{2}) = varargin{kk+1};
                        varargin(kk+(0:1)) = [];
                    else
                        kk = kk+1;
                    end
                end
            end
            
            % make sure no leftover inputs
            util.argempty(varargin);
        end % END function Dynamic
        
        function [val,props,tops] = push(this,varargin)
            % PUSH push parameters onto the LIFO state buffer
            %
            %   PUSH(THIS,PROP1,PROP2,...,PROPN)
            %   Save the values of PROP1, PROP2, ... PROPN into the LIFO
            %   (last-in, first-out) state buffer.  If previous values were
            %   saved, the buffer size will increase to push these values
            %   to the front of the buffer.
            %
            % See also POP.
            
            if nargin==1
                [val,props] = cellfun(@(x)push(this.(x)),this.topics,'UniformOutput',false);
                tops = this.topics;
            elseif nargin>1
                val = cell(1,length(varargin));
                props = cell(1,length(varargin));
                tops = cell(1,length(varargin));
                for kk=1:length(varargin)
                    if isempty(strfind(varargin{kk},'.'))
                        assert(check(this,varargin{kk}),'Invalid topic ''%s''',varargin{1});
                        [val{kk},props{kk}] = push(this.(varargin{1}));
                        tops{kk} = varargin{1};
                    else
                        parts = strsplit(varargin{kk},'.');
                        assert(check(this,parts{1}),'Invalid topic ''%s''',parts{1});
                        assert(check(this.(parts{1}),parts{2}),'Invalid property ''%s'' under topic ''%s''',parts{2},parts{1});
                        [val{kk},props{kk}] = push(this.(parts{1}),parts{2});
                        tops{kk} = parts{1};
                    end
                end
            end
            val = cat(2,val{:});
            props = cat(2,props{:});
            tops = cat(2,tops{:});
        end % END function push
        
        function [oldval,newval,props,tops] = pop(this,varargin)
            % POP pop parameters from the LIFO state buffer
            %
            %   POP(THIS,PROP1,PROP2,...,PROPN)
            %   Restore the values of PROP1, PROP2, ... PROPN from LIFO
            %   (last-in, first-out) state buffer.  If additional values
            %   were buffered, they will move toward the front of the
            %   buffer.
            %
            % See also PUSH.
            
            if nargin==1
                [oldval,newval,props] = cellfun(@(x)pop(this.(x)),this.topics,'UniformOutput',false);
                tops = this.topics;
            else
                oldval = cell(1,length(varargin));
                newval = cell(1,length(varargin));
                props = cell(1,length(varargin));
                tops = cell(1,length(varargin));
                for kk=1:length(varargin)
                    if isempty(strfind(varargin{kk},'.'))
                        assert(check(this,varargin{kk}),'Invalid topic ''%s''',varargin{1});
                        [oldval{kk},newval{kk},props{kk}] = pop(this.(varargin{1}));
                        tops{kk} = varargin{1};
                    else
                        parts = strsplit(varargin{kk},'.');
                        assert(check(this,parts{1}),'Invalid topic ''%s''',parts{1});
                        assert(check(this.(parts{1}),parts{2}),'Invalid property ''%s'' under topic ''%s''',parts{2},parts{1});
                        [oldval{kk},newval{kk},props{kk}] = pop(this.(parts{1}),parts{2});
                        tops{kk} = parts{1};
                    end
                end
            end
            oldval = cat(2,oldval{:});
            newval = cat(2,newval{:});
            props = cat(2,props{:});
            tops = cat(2,tops{:});
        end % END function pop
        
        function [ok,parts,val] = check(this,varargin)
            % CHECK determine whether a parameter exists
            %
            %   [OK,PARTS,VAL] = CHECK(THIS,PARAM1,PARAM2,...)
            %   For each input PARAM1, PARAM2, ..., determine whether the
            %   input matches a parameter stored in THIS, and return the
            %   result in OK. Also identify the namespace of the input
            %   parameter and return the parts of the namespace as a cell
            %   array PARTS. Finally, the value of the parameter will be
            %   provided in VAL.
            
            % loop over inputs
            ok = true(1,length(varargin));
            parts = cell(1,length(varargin));
            val = cell(1,length(varargin));
            for kk=1:length(varargin)
                if ~ischar(varargin{kk})
                    ok(kk) = false;
                elseif isempty(strfind(varargin{kk},'.'))
                    parts{kk} = varargin(kk);
                    if isempty(this.topics)
                        ok(kk) = false;
                    else
                        ok(kk) = ok(kk) & ismember(varargin{kk},this.topics);
                    end
                    if ok(kk)
                        val{kk} = this.(parts{kk}{1});
                    end
                else
                    parts{kk} = strsplit(varargin{kk},'.');
                    if isempty(this.topics)
                        ok(kk) = false;
                    else
                        ok(kk) = ok(kk) & ismember(parts{kk}{1},this.topics);
                    end
                    if ok(kk)
                        ok(kk) = ok(kk) & check(this.(parts{kk}{1}),parts{kk}{2});
                    end
                    if ok(kk)
                        val{kk} = this.(parts{kk}{1}).(parts{kk}{2});
                    end
                end
            end
            if length(parts)==1
                parts = parts{1};
                ok = ok(1);
                val = val{1};
            end
        end % END function check
        
        function [fqp,props,tops,vals] = list(this,varargin)
            % LIST generate a list of parameters
            %
            %  FQP = LIST(THIS)
            %  Create a list of fully-qualified parameter names associated
            %  with THIS (i.e., with topic and parameter name). FQP will be
            %  a cell array with one cell per parameter.
            %
            %  FQP = LIST(...,TOPIC,...)
            %  FQP = LIST(...,PARAMETER,...)
            %  Generate a list of all parameters under TOPIC, or the
            %  specified PARAMETER to the screen.
            %
            %  [FQP,PRM,TOP,VAL] = LIST(...)
            %  Also provide the unqualified parameter names PRM and their
            %  associated topics TOP and values VAL.
            
             % process what to list
            if isempty(this.topics)
                
                % empty parameters object, nothing to display
                vals = {};
                props = {};
                tops = {};
            elseif nargin==1
                
                % list everything
                [vals,props] = cellfun(@(x)disp(this.(x)),this.topics,'UniformOutput',false);
                tops = this.topics;
            else
                
                % list only what user requested
                vals = cell(1,length(varargin));
                props = cell(1,length(varargin));
                tops = cell(1,length(varargin));
                for kk=1:length(varargin)
                    if isempty(strfind(varargin{kk},'.'))
                        assert(check(this,varargin{kk}),'Invalid topic ''%s''',varargin{kk});
                        [vals{kk},props{kk}] = disp(this.(varargin{kk}));
                        tops{kk} = varargin{kk};
                    else
                        parts = strsplit(varargin{kk},'.');
                        assert(check(this,parts{1}),'Invalid topic ''%s''',parts{1});
                        assert(check(this.(parts{1}),parts{2}),'Invalid property ''%s'' under topic ''%s''',parts{2},parts{1});
                        [vals{kk},props{kk}] = disp(this.(parts{1}),parts{2});
                        tops{kk} = parts{1};
                    end
                end
            end
            
            % construct fully-qualified parameter names
            fqp = arrayfun(@(x)cellfun(@(y)sprintf('%s.%s',tops{x},y),props{x},'UniformOutput',false),1:length(tops),'UniformOutput',false);
            fqp = cat(1,fqp{:});
        end % END function list
        
        function varargout = disp(this,varargin)
            % DISP display basic information about the parameters
            %
            %  DISP(THIS)
            %  Print a list of each parameter and its value.
            %
            %  DISP(...,TOPIC,...)
            %  DISP(...,PARAMETER,...)
            %  Print a list of each parameter and value under TOPIC, or
            %  the specified PARAMETER and its value.
            %
            %  [STR,PARAMS,TOPS] = DISP(...)
            %  Instead of printing information to the screen, return as
            %  output arguments. STR will be a cell array, with one cell
            %  per topic or requested parameter, containing string
            %  representation of the parameter values. PROPS will be a cell
            %  array containing the parameter names, and TOPS will be a
            %  cell array containing the topic names.
            
            % get a list of requested parameters/topics/values
            [~,props,tops,vals] = list(this,varargin{:});
            
            % generate the strings for each requested parameter
            if nargout==0 && ~isempty(vals)
                
                % print to the screen
                props = arrayfun(@(x)cellfun(@(y)sprintf('%s.%s',tops{x},y),props{x},'UniformOutput',false),1:length(tops),'UniformOutput',false);
                props = cat(1,props{:});
                vals = cat(1,vals{:});
                len = max(cellfun(@length,props));
                vals = cellfun(@(x,y)sprintf(['%' num2str(len) 's: %s'],x,y),props,vals,'UniformOutput',false);
                vals = strjoin(vals,'\n');
                fprintf('%s\n',vals);
            else
                
                % return as output
                if nargout>=1
                    varargout{1} = vals;
                end
                if nargout>=2
                    varargout{2} = props;
                end
                if nargout>=3
                    varargout{3} = tops;
                end
            end
        end % END function disp
        
        function varargout = help(this,varargin)
            % HELP generate help messages about the parameters
            %
            %  HELP(THIS)
            %  Print a list of parameters and their descriptions.
            %
            %  HELP(...,TOPIC,...)
            %  HELP(...,PARAMETER,...)
            %  Print descriptions for all parameters under TOPIC, or the
            %  specified PARAMETER.
            
            % get a list of requested parameters/topics/values
            [~,props,tops,vals] = list(this,varargin{:});
            
            % generate strings to display or output
            if nargout==0 && ~isempty(vals)
                
                % print to screen
                props = arrayfun(@(x)cellfun(@(y)sprintf('%s.%s',tops{x},y),props{x},'UniformOutput',false),1:length(tops),'UniformOutput',false);
                props = cat(1,props{:});
                vals = cat(1,vals{:});
                len = max(cellfun(@length,props));
                vals = cellfun(@(x,y)sprintf(['%' num2str(len) 's: %s'],x,y),props,vals,'UniformOutput',false);
                vals = strjoin(vals,'\n');
                fprintf('%s\n',vals);
            else
                
                % return as outputs
                if nargout>=1
                    varargout{1} = vals;
                end
                if nargout>=2
                    varargout{2} = props;
                end
                if nargout>=3
                    varargout{3} = tops;
                end
            end
        end % END function help
        
        function load(this,varargin)
            % LOAD Load parameters from a topic
            %
            %  LOAD(THIS,TOPIC)
            %  Load the parameters defined for the topic TOPIC. The
            %  definition resides elsewhere in the Parameters package.
            
            % loop over supplied topics
            for kk=1:length(varargin)
                
                % validate topic input
                topic = varargin{kk};
                if isa(topic,'function_handle')
                    if ~strncmpi(func2str(topic),'@(',2)
                        assert(util.existp(func2str(topic),'file')==2,'''%s'' is not a valid topic',func2str(topic));
                    end
                elseif ischar(topic)
                    assert(util.existp(sprintf('Parameters.Topic.%s',topic),'file')==2,'''%s'' is not a valid topic',topic);
                    topic = str2func(sprintf('Parameters.Topic.%s',topic));
                else
                    error('Unknown topic class ''%s''',class(topic));
                end
                assert(isa(topic,'function_handle'),'Invalid topic');
                
                % make sure topic not already added
                assert(~any(strcmpi(this.topics,topic)),'Topic ''%s'' already exists',topic);
                
                % add the dynamic property
                obj = Parameters.Topic.Interface(topic,varargin{:});
                topicInfo = obj.getTopicInfo;
                if any(strcmpi(this.topics,topicInfo.id)),continue;end
                p = addprop(this,topicInfo.id);
                p.SetAccess = 'private';
                p.GetAccess = 'public';
                this.(topicInfo.id) = obj;
                
                % update list of added topics
                this.topics = [this.topics {topicInfo.id}];
            end
        end % END function load
        
        function [eq,prop] = isEqual(this,obj,varargin)
            % ISEQUAL evaluate whether parameter object/struct are equal
            %
            %   EQ = ISEQUAL(THIS,OBJ)
            %   Compares the properties of THIS to the fields of struct OBJ
            %   and returns a logical value indicating whether they are
            %   equivalent.
            %
            %   EQ = ISEQUAL(THIS,OBJ,PROP1,PROP2,...)
            %   EQ = ISEQUAL(THIS,OBJ,{PROP1,PROP2,...})
            %   EQ = ISEQUAL(THIS,OBJ,'IGNORE',{PROP1,PROP2,...})
            %   Specify properties to ignore.
            %
            %   EQ = ISEQUAL(THIS,OBJ,'REQUIRE',{PROP1,PROP2,...})
            %   Specify properties to require.
            %
            %   EQ = ISEQUAL(...,'EXCEPT',{FIELD1,FIELD2,...})
            %   In accordance with previous arguments to either IGNORE or
            %   REQUIRE certain parameters, list any exceptions using the
            %   EXCEPT argument. For example, to require some fields that
            %   may have been listed for IGNORE, or to ignore some fields
            %   that may have been listed for REQUIRE.
            %
            %   [EQ,PROP] = ISEQUAL(...)
            %   If EQ is false, PROP will contain the name of the offending
            %   property. Otherwise, PROP will be empty.
            
            % specify ignore/require property lists
            [varargin,ignore] = util.argkeyval('ignore',varargin,{});
            [varargin,require] = util.argkeyval('require',varargin,{});
            [varargin,except] = util.argkeyval('except',varargin,{});
            if ~isempty(varargin)
                if iscell(varargin{1})
                    ignore = varargin{1};
                    varargin(1) = [];
                else
                    ignore = varargin;
                    varargin = {};
                end
            end
            ignore = util.ascell(ignore);
            require = util.ascell(require);
            util.argempty(varargin);
            
            % error check and condense for convenience
            if ~isempty(require)
                assert(isempty(ignore),'Cannot specify both required and ignored properties');
                fields = require;
                require = true;
                ignore = false;
            elseif ~isempty(ignore)
                assert(isempty(require),'Cannot specify both required and ignored properties');
                fields = ignore;
                require = false;
                ignore = true;
            else
                fields = {};
                require = false;
                ignore = false;
            end
            
            % remove the "except" fields that match up front
            idx_except1 = ismember(fields,except);
            idx_except2 = ismember(except,fields);
            fields(idx_except1) = [];
            except(idx_except2) = [];
            
            % list properties of this object
            [~,propname,proptopic] = list(this);
            
            % process user require/ignore (entire property topics)
            if require || ignore
                idx_topic = cellfun(@(x)isempty(strfind(x,'.')),fields) | cellfun(@(x)~isempty(strfind(x,'*')),fields);
                if any(idx_topic)
                    input_topics = fields(idx_topic);
                    fields(idx_topic) = [];
                    input_topics = regexp(input_topics,'(?<topic>^\w+)(\.\*)?','names');
                    input_topics = cellfun(@(x)x.topic,input_topics,'UniformOutput',false);
                    idx_match = ismember(proptopic,input_topics);
                    if require
                        idx_discard = ~idx_match;
                    elseif ignore
                        idx_discard = idx_match;
                    end
                    proptopic(idx_discard) = [];
                    propname(idx_discard) = [];
                    topicfields = arrayfun(@(x)cellfun(@(y)sprintf('%s.%s',proptopic{x},y),propname{x},'UniformOutput',false),1:length(proptopic),'UniformOutput',false);
                    topicfields = cat(1,topicfields{:});
                    fields = cat(1,fields(:),topicfields(:));
                end
            end
            
            % construct list of all available/leftover properties
            proplist = arrayfun(@(x)cellfun(@(y)sprintf('%s.%s',proptopic{x},y),propname{x},'UniformOutput',false),1:length(proptopic),'UniformOutput',false);
            proplist = cat(1,proplist{:});
            
            % remove the remaining "except" fields
            idx_except1 = ismember(proplist,except);
            idx_except2 = ismember(except,proplist);
            proplist(idx_except1) = [];
            except(idx_except2) = [];
            assert(isempty(except),'Some except fields did not match anything: %s',strjoin(except,', '));
            
            % process user require/ignore (individual properties)
            if require || ignore
                idx_match = ismember(cellfun(@lower,proplist,'UniformOutput',false),cellfun(@lower,fields,'UniformOutput',false));
                if require
                    idx_discard = ~idx_match;
                elseif ignore
                    idx_discard = idx_match;
                end
                proplist(idx_discard) = [];
            end
            
            % default true - looking for inconsistencies
            eq = true;
            
            % loop over properties
            prop = [];
            for kk=1:length(proplist)
                
                % split into topic/name
                [ok,parts,val] = check(this,proplist{kk});
                if ~ok,eq=false;break;end
                if ~isfield(obj,parts{1}),eq=false;break;end
                if ~isfield(obj.(parts{1}),parts{2}),eq=false;break;end
                
                % check whether property values are equivalent
                eq = all(cache.checkEqual(val,obj.(parts{1}).(parts{2})));
                
                % if not equal, break and return early
                if ~eq
                    prop = proplist{kk};
                    break;
                end
            end
        end % END function isEqual
        
        function list = structableSkipFields(~)
            list = {};
        end % END function structableSkipFields
        
        function st = structableManualFields(~)
            st = [];
        end % END function structableManualFields
    end % END methods
end % END classdef Dynamic