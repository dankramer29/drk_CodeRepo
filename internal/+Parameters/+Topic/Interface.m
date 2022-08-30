classdef Interface < dynamicprops & cache.Cacheable & util.Structable & util.StructableHierarchy
    
    properties(Access=private)
        propertyList
        propertyValues
        metaObjects
        topicName
        topicDescription
        topicID
        propertyInfo
        state
    end % END properties(Access=private)
    
    methods
        function this = Interface(tpc,varargin)
            assert(isa(tpc,'function_handle'),'Invalid topic function');
            if ~strncmpi(func2str(tpc),'@(',2)
                assert(util.existp(func2str(tpc),'file')==2,'Invalid topic function');
            end
            
            % get topic/property data
            [topic,props] = feval(tpc);
            this.propertyInfo = props;
            
            % set topic descriptor properties
            this.topicName = topic.name;
            this.topicDescription = topic.description;
            this.topicID = topic.id;
            
            % add properties
            this.propertyList = fieldnames(props);
            for kk=1:length(this.propertyList)
                
                % add the dynamic property
                p = addprop(this,this.propertyList{kk});
                if isempty(this.metaObjects)
                    this.metaObjects = p;
                else
                    this.metaObjects = [this.metaObjects p];
                end
                
                % set property attributes
                try
                if isfield(props.(this.propertyList{kk}),'attributes')
                    attrs = fieldnames(props.(this.propertyList{kk}).attributes);
                    for nn=1:length(attrs)
                        p.(attrs{nn}) = props.(this.propertyList{kk}).attributes.(attrs{nn});
                    end
                end
                catch ME
                    util.errorMessage(ME);
                    keyboard
                end
                
                % update SetMethod if not already set
                if isempty(p.SetMethod) && isfield(props.(this.propertyList{kk}),'validationFcn') && ~isempty(props.(this.propertyList{kk}).validationFcn)
                    
                    % make the property dependent
                    p.Dependent = true;
                    
                    % get name, description, validation fcn for convenience
                    pname = this.propertyList{kk};
                    pvalfn = props.(this.propertyList{kk}).validationFcn;
                    
                    % define set/get methods
                    p.SetMethod = @(obj,val)genericSetMethod(obj,val,pname,pvalfn);
                    p.GetMethod = @(obj)genericGetMethod(obj,pname);
                end
                
                % set the default value
                this.(this.propertyList{kk}) = props.(this.propertyList{kk}).default;
            end
            
            function genericSetMethod(obj,val,prop,valfcn)
                % GENERICSETMETHOD
                % validate input value and set the property
                assert(feval(valfcn,val),'Invalid value specified for property ''%s'' (must satisfy %s)',prop,func2str(valfcn));
                obj.propertyValues.(prop) = val;
            end % END function genericSetMethod
            
            function val = genericGetMethod(obj,prop)
                % GENERICGETMETHOD
                val = obj.propertyValues.(prop);
            end % END function genericGetMethod
        end % END function Interface
        
        function [val,props] = push(this,varargin)
            if nargin==1
                props = this.propertyList;
            else
                props = varargin;
            end
            val = cell(1,length(props));
            for kk=1:length(props)
                assert(check(this,props{kk}),'Invalid property ''%s'' under topic ''%s''',props{kk},this.topicID);
                val{kk} = this.(props{kk});
                if ~isfield(this.state,props{kk})
                    this.state.(props{kk}) = val(kk);
                else
                    this.state.(props{kk}) = [this.state.(props{kk}) val(kk)];
                end
            end
        end % END function push
        
        function [oldval,newval,props] = pop(this,varargin)
            if nargin==1
                props = fieldnames(this.state);
            else
                props = varargin;
            end
            oldval = cell(1,length(props));
            newval = cell(1,length(props));
            for kk=1:length(props)
                assert(check(this,props{kk}),'Invalid property ''%s'' under topic ''%s''',props{kk},this.topicID);
                if ~isfield(this.state,props{kk}),continue;end
                oldval{kk} = this.(props{kk});
                newval{kk} = this.state.(props{kk}){end};
                this.(props{kk}) = newval{kk};
                this.state.(props{kk})(end) = [];
                if isempty(this.state.(props{kk}))
                    this.state = rmfield(this.state,props{kk});
                end
            end
        end % END function pop
        
        function info = getTopicInfo(this)
            info.name = this.topicName;
            info.description = this.topicDescription;
            info.id = this.topicID;
        end % END function getTopicInfo
        
        function ok = check(this,varargin)
            ok = true;
            for kk=1:length(varargin)
                ok = ok & ismember(varargin{kk},this.propertyList);
            end
        end % END function check
        
        function varargout = disp(this,varargin)
            if nargin==1
                props = this.propertyList;
            else
                props = varargin;
            end
            
            % print information for each property in the topic
            if isempty(props)
                str = {};
            else
                str = cell(1,length(props));
                for kk=1:length(props)
                    val = this.propertyValues.(props{kk});
                    valstr = util.any2str(val);
                    str{kk} = valstr;
                end
            end
            
            % print the text to screen if no outputs
            if nargout==0
                props = cellfun(@(y)sprintf('%s.%s',this.topicID,y),props,'UniformOutput',false);
                len = max(cellfun(@length,props));
                str = cellfun(@(x,y)sprintf(['%' num2str(len) 's: %s'],x,y),props(:),str(:),'UniformOutput',false);
                str = strjoin(str,'\n');
                fprintf('%s\n',str);
            else
                if nargout>=1
                    varargout{1} = str(:);
                end
                if nargout>=2
                    varargout{2} = props(:);
                end
            end
        end % END function disp
        
        function varargout = help(this,varargin)
            if nargin==1
                props = this.propertyList;
            else
                props = varargin;
            end
            
            % generate messages
            if isempty(props)
                str = {};
            else
                str = cell(1,length(props));
                for kk=1:length(props)
                    assert(check(this,props{kk}),'Invalid property ''%s'' under topic ''%s''',props{kk},this.topicID);
                    p = this.metaObjects(strcmpi(this.propertyList,props{kk}));
                    str{kk} = p.Description;
                end
            end
            
            % print the text to screen if no outputs
            if nargout==0 && ~isempty(str)
                props = cellfun(@(y)sprintf('%s.%s',this.topicID,y),props,'UniformOutput',false);
                len = max(cellfun(@length,props));
                str = cellfun(@(x,y)sprintf(['%' num2str(len) 's: %s'],x,y),props(:),str(:),'UniformOutput',false);
                str = strjoin(str,'\n');
                fprintf('%s\n',str);
            else
                if nargout>=1
                    varargout{1} = str(:);
                end
                if nargout>=2
                    varargout{2} = props(:);
                end
            end
        end % END function help
        
        function list = structableSkipFields(this)
            list = {'propertyInfo'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st.topicInfo = struct('name',util.any2str(this.topicName),'description',util.any2str(this.topicDescription),'id',util.any2str(this.topicID));
            propertyNames = fieldnames(this.propertyInfo);
            for nn=1:length(propertyNames)
                st.propertyInfo.(propertyNames{nn}) = struct(...
                    'validationFcn',util.any2str(this.propertyInfo.(propertyNames{nn}).validationFcn),...
                    'default',util.any2str(this.propertyInfo.(propertyNames{nn}).default));
                attributeNames = fieldnames(this.propertyInfo.(propertyNames{nn}).attributes);
                for mm=1:length(attributeNames)
                    st.propertyInfo.(propertyNames{nn}).attributes.(attributeNames{mm}) = util.any2str(this.propertyInfo.(propertyNames{nn}).attributes.(attributeNames{mm}));
                end
            end
        end % END function structableManualFields
    end % END methods
end % END classdef Interface