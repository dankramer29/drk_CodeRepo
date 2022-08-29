function [args,logfcn] = getLogFcn(args)
% GETLOGFCN Assign log function
%
%   [ARGS,LOGFCN] = GETLOGFCN(ARGS)
%   Assign default value to LOGFCN, or, if the user has provided log input
%   (key-value pair "logfcn",LOGFCN or Debug.Debugger object DEBUG),
%   override the default with user input.

% default value
logfcn = {{@Debug.message},{struct('verbosity',inf)}};

% look for overriding "logfcn" input
idx = strcmpi(args,'logfcn');
if any(idx)
    logfcn = args{circshift(idx,1,2)};
    args(idx|circshift(idx,1,2)) = [];
end

% look for overriding debugger input
idx = cellfun(@(x)isa(x,'Debug.Debugger'),args);
if any(idx)
    debugger = args{idx};
    args(idx) = [];
    logfcn = {{@debugger.log},{}};
end