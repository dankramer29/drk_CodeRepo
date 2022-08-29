classdef Cacheable < handle
    % This class is intended to identify whether parameters have changed
    % and invalidated a cached copy of data.  Inherit this class for
    % automated evaluation of parameter equivalence using the cache.load
    % function.
    
    methods
        function this = Cacheable
            % CACHEABLE constructor method
            
            assert(isa(this,'util.Structable'),'Cacheable classes must also be Structable');
        end % END function Cacheable
        
        function eq = isEqual(this,obj,varargin)
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
            
            % list properties of this object
            proplist = properties(this);
            
            % reduce based on user ignore/require lists
            if ~isempty(require)
                assert(isempty(ignore),'Cannot specify both required and ignored properties');
                idx_except = ismember(cellfun(@lower,require,'UniformOutput',false),cellfun(@lower,except,'UniformOutput',false));
                require(idx_except) = [];
                idx_require = ismember(cellfun(@lower,proplist,'UniformOutput',false),cellfun(@lower,require,'UniformOutput',false));
                idx_discard = ~idx_require;
            else
                assert(isempty(require),'Cannot specify both required and ignored properties');
                idx_except = ismember(cellfun(@lower,ignore,'UniformOutput',false),cellfun(@lower,except,'UniformOutput',false));
                ignore(idx_except) = [];
                idx_ignore = ismember(cellfun(@lower,proplist,'UniformOutput',false),cellfun(@lower,ignore,'UniformOutput',false));
                idx_discard = idx_ignore;
            end
            proplist(idx_discard) = [];
            
            % default true - looking for inconsistencies
            eq = true;
            
            % loop over properties
            for kk=1:length(proplist)
                
                % if not a field, not equivalent
                if ~isfield(obj,proplist{kk}),eq=false;break;end
                
                % check whether property values are equivalent
                eq = cache.checkEqual(this.(proplist{kk}),obj.(proplist{kk}));
                
                % if not equal, break and return early
                if ~eq,break;end
            end
        end % END function isEqual
    end % END methods
end % END classdef Cacheable