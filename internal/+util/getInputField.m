function [out,used_default]=getInputField(STRUCT_OBJ,FIELD,default_val,valid_vals)
% GETINPUTFIELD process arguments with defaults and valid options
%
% STRUCT_OBJ    - structure or object
% FIELD         - property of STRUCT_OBJ to grab if available
% default_val   - value to output if STRUCT_OBJ.(FIELD) is empty or
%                 non-existent
% valid_vals    - function whos output specifies whether the output is
%                 valid.  E.g. if only valid str outputs are 'foo' and
%                 'bar', we could pass f=@(x)any(strcmp(x,{'foo','bar'}))
%
% returns the value of a structure field or object property if it is available.  If it is not
% available or is empty, the function returns default_val.  This function is useful
% for parsing a structure that is the input to a function while allowing
% for default values. If valid_vals is specified, checks to make sure out
%
% updated - work with structs or objects
%

used_default=true;

if isstruct(STRUCT_OBJ)
    condition=isfield(STRUCT_OBJ,FIELD);
elseif isobject(STRUCT_OBJ)
    condition=isprop(STRUCT_OBJ,FIELD);
elseif isempty(STRUCT_OBJ)
    condition=false;
else
    error('Utilities:getInputField:input','Object or struct expected as first arguement, not ''%s''',class(STRUCT_OBJ));
end

if condition
    if ~isempty(STRUCT_OBJ.(FIELD))
        out=STRUCT_OBJ.(FIELD);
        used_default=false;
    else
        out=default_val;
    end
else
    out=default_val;
end

if nargin==4;
    isvalid=valid_vals(out);
    if ~isvalid
        error('BMI:Utilities:getInputField:invalid','Output is not valid');
    end
end