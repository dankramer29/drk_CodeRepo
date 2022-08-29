classdef Interface < handle & util.StructableHierarchy
    
    properties(Abstract)
        verbosity
    end % END properties(Abstract)
    
    properties
        commentFcn
    end % END properties
    
    methods(Abstract)
        r = getResource(this,type);
        returnResource(this,name);
        refresh(this);
    end % END methods(Abstract)
    
    methods
        function this = Interface(varargin)
            this.commentFcn = {@internalComment,this};
        end % END function Interface
        
        function comment(this,msg,vb)
            % COMMENT Print a comment message
            %
            %   COMMENT(THIS,MSG,VB)
            %   Depending on message verbosity VB, print the string in MSG
            %   to the command window.
            
            % run the comment function
            feval(this.commentFcn{:},msg,vb);
        end % END function comment
        
        function internalComment(this,msg,vb)
            if vb<=this.verbosity
                fprintf('%s\n',msg);
            end
        end % END function internalComment
        
        function list = structableSkipFields(this)
            list = {'commentFcn'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st.commentFcn = func2str(this.commentFcn{1});
        end % END function structableManualFields
    end % END methods
    
end % END classdef Interface