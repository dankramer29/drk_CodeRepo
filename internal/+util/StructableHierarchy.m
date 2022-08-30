classdef StructableHierarchy < handle
    % STRUCTABLEHIERARCHY Supporting struct conversion of class hierarchies
    %
    %   In complicated class hierarchies, class-specific information 
    %   required to perform struct conversion should be localized to each 
    %   class so that class definitions can  change modularly.  This class
    %   provides a mechanism for retrieving unique information from
    %   inherited classes to perform integrated struct conversion.
    %
    %   STRUCTABLEHIERARCHY uses method overloading, specifically the 
    %   feature that overloaded methods can call methods of the same name 
    %   and signature on their superclasses, retrieve class-specific 
    %   information required for the struct conversion process.  In this
    %   way, STRUCTABLEHIERARCHY allows each class to define its own 
    %   conversion, so that a single call to TOSTRUCT on the instantiated 
    %   object will ripple through the entire hierarchy to produce a 
    %   single converted struct.  Two additional methods are required for 
    %   this process: STRUCTABLESKIPFIELDS and STRUCTABLEMANUALFIELDS.
    %
    %   All classes in the hierarchy must inherit STRUCTABLEHIERARCHY, and
    %   each class requiring any kind of customized processing should 
    %   overload STRUCTABLESKIPFIELDS and STRUCTABLEMANUALFIELDS.  At least
    %   one class in the hierarchy must inherit STRUCTABLE.
    %
    %   The base class must overload the methods STRUCTABLESKIPFIELDS and 
    %   STRUCTABLEMANUALFIELDS (otherwise, there would be a naming conflict
    %   error, since MATLAB could not know which of all the superclasses' 
    %   versions of these methods to call at runtime).  The overloaded 
    %   methods call the superclass methods of the same name in order to 
    %   get unique information from each superclass.
    %
    %   STRUCTABLESKIPFIELDS provides a method for skipping properties that
    %   will either be ignored entirely or processed manually. Following is
    %   an example using STRUCTABLESKIPFIELDS to collect a list of all 
    %   properties to be skipped from the local class MyClass and its 
    %   inherited classes SuperClass1 through SuperClassN:
    %
    %     classdef MyClass < SuperClass1 & ... & SuperClassN
    %       properties
    %         prop1 % needs manual processing
    %         ...   % all need manual processing
    %         propn % needs manual processing
    %       end
    %       methods
    %         ...
    %         function list = structableSkipFields(this)
    %           list1 = structableSkipFields@SuperClass1(this);
    %           ...
    %           listn = structableSkipFields@SuperClassN(this);
    %           list = [{'prop1',...,'propn'} list1 ... listn];
    %         end
    %       end
    %     end
    %
    %   STRUCTABLEMANUALFIELDS provides a way to add customized fields to 
    %   the output struct.  Fields of the struct returned by this method
    %   will be added to the automatically-generated struct.  Following is
    %   an example using STRUCTABLEMANUALFIELDS to pull manually processed
    %   structs from each of the inherited classes SuperClass1 through
    %   SuperClassN, and concatenate them to the local class' manually
    %   processed fields:
    %
    %     classdef MyClass < SuperClass1 & ... & SuperClassN
    %       properties
    %         prop1 % needs manual processing
    %         ...   % all need manual processing
    %         propn % needs manual processing
    %       end
    %       methods
    %         ...
    %         function st = structableManualFields(this)
    %           st1 = structableManualFields@SuperClass1(this);
    %           ...
    %           stN = structableManualFields@SuperClassN(this);
    %           st = catstruct(st1,...,stN);
    %           st.prop1 = VAL1;
    %           ...
    %           st.propn = VALn;
    %         end
    %       end
    %     end
    %
    %   See also STRUCTABLE, STRUCTABLE/TOSTRUCT,
    %   STRUCTABLEHIERARCHY/STRUCTABLESKIPFIELDS, 
    %   STRUCTABLEHIERARCHY/STRUCTABLEMANUALFIELDS, and CATSTRUCT.
    
    methods
        function list = structableSkipFields(this)
            % STRUCTABLESKIPFIELDS Provide a list of properties to ignore.
            %
            %   LIST = STRUCTABLESKIPFIELDS(THIS)
            %   Provide a cell array LIST of properties names to ignore
            %   when converting THIS to a struct.  Overload this method in
            %   the inheriting class to customize the list of properties to
            %   ignore.
            %
            %   See also STRUCTABLE,
            %   STRUCTABLE/TOSTRUCT, and
            %   STRUCTABLEHIERARCHY/STRUCTABLEMANUALFIELDS.
            
            list = {};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            % STRUCTABLEMANUALFIELDS Provide customized struct fields.
            %
            %   ST = STRUCTABLESKIPFIELDS(THIS)
            %   Returns a struct ST with custom fields to be added to the
            %   output of TOSTRUCT.
            %
            %   See also STRUCTABLE,
            %   STRUCTABLE/TOSTRUCT, and
            %   STRUCTABLEHIERARCHY/STRUCTABLEMANUALFIELDS.
            st = [];
        end % END function structableManualFields
    end % END methods(Abstract)
end % END classdef Structable