classdef Taggable < handle & util.Structable
    % This class is intended to provide an interface for transforming a set
    % of values into a valid cache basename.
    
    properties
        tagprops % hold the key-value tag pairs in a struct
    end % END properties
    
    methods
        function this = Taggable(varargin)
            
            % process tag inputs
            if nargin==1
                
                % validate input
                assert(isstruct(varargin{1}),'Single inputs must be structs');
                
                % single input, struct, so presume user has already
                % constructed the tag fields and simply assign
                this.tagprops = varargin{1};
            elseif nargin>1
                if mod(nargin,2)==0
                    
                    % multiple inputs, even number - assume key-value pairs
                    % that will become field-values of the tag struct
                    while ~isempty(varargin)
                        add(this,varargin{1},varargin{2});
                        varargin(1:2) = [];
                    end
                else
                    
                    % multiple inputs, odd number - assume value-only
                    % inputs that require uninformative keys
                    for kk=1:length(varargin)
                        assert(ischar(varargin{kk}),'Tag values must be char, not ''%s''',class(varargin{kk}));
                        add(this,varargin{kk});
                    end
                end
            end
        end % END function Taggable
        
        function add(this,varargin)
            % ADD Add a tag
            %
            %   ADD(THIS,KEY,VAL)
            %   Add a tag with the name KEY and value VAL. VAL must be a
            %   string or convertable to a string via UTIL.ANY2STR.
            %
            %   ADD(THIS,VAL)
            %   Add a tag with the value VAL (name will be arbitrarily
            %   appointed).
            
            % process inputs
            if nargin==1,return;end
            if mod(length(varargin),2)==0
                
                % multiple inputs, even number - assume key-value pairs
                % that will become field-values of the tag struct
                while ~isempty(varargin)
                    
                    % get the key and value
                    key = varargin{1};
                    val = varargin{2};
                    varargin(1:2) = [];
                    
                    % make sure value is a string
                    if ~ischar(val),val=util.any2str(val);end
                    assert(ischar(val),'Tag values must be char, not ''%s''',class(val));
                    
                    % add the tag
                    this.tagprops.(key) = val;
                end
            else
                
                % multiple inputs, odd number - assume value-only
                % inputs that require uninformative keys
                for kk=1:length(varargin)
                    
                    % get the key
                    flds = fieldnames(this.tagprops);
                    key = sprintf('tag%03d',length(flds)+1);
                    
                    % get the value
                    val = varargin{kk};
                    
                    % make sure value is a string
                    if ~ischar(val),val=util.any2str(val);end
                    assert(ischar(val),'Tag values must be char, not ''%s''',class(val));
                    
                    % add the tag
                    this.tagprops.(key) = val;
                end
            end
        end % END function add
        
        function obj = copy(this)
            % COPY Create a copy of this object
            %
            %   OBJ = COPY(THIS)
            %   Create a copy of this TAGGABLE object, initialized with the
            %   same key-value pairs as currently exist in this object.
            obj = cache.Taggable(this.tagprops);
        end % END function copy
        
        function str = hash(this)
            % HASH Calculate the hash representation of this object
            %
            %   STR = HASH(THIS)
            %   Calculate the hash of the key-value pairs associated with
            %   the TAGGABLE object THIS and return the hash in STR.
            
            % construct the list of key-value pairs
            vals = fieldnames(this.tagprops);
            keys = struct2cell(this.tagprops);
            assert(length(vals)==length(keys),'Number of keys must match number of values (fundamental software error somewhere deep)');
            args = [vals(:)'; keys(:)'];
            
            % hash the concatenated string
            str = cache.hash(strjoin(args,','));
        end % END function hash
        
        function st = toStruct(this,varargin)
            st = this.tagprops;
        end % END function toStruct
    end % END methods
end % END classdef Taggable