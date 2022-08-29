function deleteTimer(t)

% allow passing in timer name to identify timer
if ischar(t)
    t = timerfind('Name',t);
end

% check whether the object is a timer and return if not
if isempty(t) || ~isa(t,'timer')
    return;
end

% stop/delete as needed
if ~isempty(t) && isa(t,'timer') && isvalid(t)
    if strcmpi(t.Running,'on')
        stop(t);
    end
    delete(t);
end