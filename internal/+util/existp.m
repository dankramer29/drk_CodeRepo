function type = existp(str,typestr)
% EXISTP Extension of builtin EXIST method to search package namespaces
%
%   TYPE = EXISTP('A')
%   Augment the standard exist function by checking whether 'A' exists in a
%   package namespace, e.g., PKG.FUNCTION, or PKG.CLASS.  If 'A' is
%   located in a package namespace, TYPE will be one of the following:
%
%     2 if A is a function in a package namespace or method of a class in
%       the package namespace
%     8 if A is a class in a package namespace
%     9 if A is a package or package in a package namespace
%
%   Otherwise, TYPE will conform to the same outputs as the builtin method
%   EXIST:
%
%     0 if A does not exist
%     1 if A is a variable in the caller's workspace
%     2 if A is an M-file on MATLAB's search path, or the full path to a
%       file
%     3 if A is a MEX-file on MATLAB's search path
%     4 if A is a Simulink model or library file on MATLAB's search path
%     5 if A is a built-in MATLAB function
%     6 if A is a P-file on MATLAB's search path
%     7 if A is a directory
%     8 if A is a class (but 0 for Java classes if -nojvm)
%
%   TYPE = EXISTP('A',TYPESTR)
%   Check only for objects described by TYPESTR.  This behavior follows the
%   builtin behavior with a few exceptions as noted below.
%
%     EXISTP('A','file') checks for functions in a package namespace or
%     methods of a class (in addition to files or directories).
%
%     EXISTP('A','method') checks for methods of a class only.
%
%     EXISTP('A','class') checks for classes in a package namespace in
%     addition to standalone classes.
%
%     EXISTP('A','package') checks for packages.
%
%   See also EXIST, META.CLASS, META.PACKAGE, and META.METHOD.

% defaults
if nargin<2||isempty(typestr),typestr='';end

% validate inputs
assert(ischar(str),'STR must be a string, not ''%s''',class(str));
assert(ischar(typestr),'TYPESTR must be a string, not ''%s''',class(typestr));

% check builtin version first
type = 0;
if isempty(typestr) || (~isempty(typestr) && any(strcmpi(typestr,{'var','builtin','class','dir','file'})))
    args = {};
    if ~isempty(typestr),args={typestr};end
    type = exist(str,args{:});
end

% return if identified any builtin type
if type~=0,return;end

% return if searching for types not handled by existp
if any(strcmpi(typestr,{'builtin','var','dir'})),return;end

% split up by namespace separator
nm = strsplit(str,'.');

% check existence of package, class, or function
idx = 1;
info = check_exists(nm{idx});
while ~isempty(info) && idx<length(nm)
    idx = idx+1;
    info = check_exists(nm{idx},info);
end
switch class(info)
    case 'meta.package', type=9;
    case 'meta.class',   type=8;
    case 'meta.method',  type=2;
    otherwise,           type=0;
end

% return immediately if no TYPESTR specified
if isempty(typestr),return;end

% otherwise check encountered against requested type
switch lower(typestr)
    case 'file',    if ~ismember(type,[2 3 4 6]),type=0;end
    case 'method',  if type~=2,type=0;end
    case 'class',   if type~=8,type=0;end
    case 'package', if type~=9,type=0;end
    otherwise,      warning('unknown TYPESTR value ''%s''',typestr);
end


function info = check_exists(str,parent)
% CHECK_EXISTS Check whether a package, class, or method exists
%
%   INFO = CHECK_EXISTS(STR,PARENT)
%   Check whether the package, class, or method STR exists in the package
%   or class PARENT.
if nargin<2,parent=[];end
info = [];

% check for initial call
if isempty(parent)
    
    % check whether it's a package
    pkgInfo = meta.package.fromName(str);
    if ~isempty(pkgInfo)
        info = pkgInfo;
    else
        
        % check whether it's a class
        clsInfo = meta.class.fromName(str);
        if ~isempty(clsInfo)
            info = clsInfo;
        end
    end
else
    
    % don't look for packages inside methods or classes
    pkgInfo = 0;
    if isa(parent,'meta.package')
        
        % look for package
        pkgInfo = ismember({parent.PackageList.Name},strcat(parent.Name,'.',str));
    end
    
    % look for package, class, or method
    if any(pkgInfo)
        
        % found a package
        info = parent.PackageList(pkgInfo);
    else
        
        % don't look for classes inside classes or methods
        clsInfo = 0;
        if isa(parent,'meta.package')
            clsInfo = ismember({parent.ClassList.Name},strcat(parent.Name,'.',str));
        end
        
        % look for class
        if any(clsInfo)
            
            % found a class
            info = parent.ClassList(clsInfo);
        else
            
            % look for method
            switch lower(class(parent))
                case 'meta.package'
                    fcnInfo = ismember({parent.FunctionList.Name},str);
                case 'meta.class'
                    fcnInfo = ismember({parent.MethodList.Name},str);
                otherwise
                    error('Unexpected parent class ''%s''',class(parent));
            end
            if any(fcnInfo)
                
                % found a method
                switch lower(class(parent))
                    case 'meta.package'
                        info = parent.FunctionList(fcnInfo);
                    case 'meta.class'
                        info = parent.MethodList(fcnInfo);
                    otherwise
                        error('Unexpected parent class ''%s''',class(parent));
                end
            end
        end
    end
end