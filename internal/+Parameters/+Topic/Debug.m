function [topic,props] = Debug

topic = struct(...
    'name','Debug Properties',...
    'description','Properties related to debugging',...
    'id','dbg');

props.verbosity = struct(...
    'validationFcn',@(x)isnumeric(x)||isa(x,'Debug.PriorityLevel'),...
    'default',Debug.PriorityLevel.WARNING,...
    'attributes',struct('Description','Upper limit on the criticality of messages logged to screen and/or files (see Debug.PriorityLevel)'));