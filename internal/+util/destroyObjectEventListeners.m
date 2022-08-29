function [listeners,eventList] = destroyObjectEventListeners(listeners)
% DESTROYOBJECTEVENTLISTENERS destroy event listeners
%
%   [LISTENERS,EVENTLIST] = DESTROYOBJECTEVENTLISTENERS(LISTENERS)
%   Destroy event listeners stored as fields of the cell array of structs
%   LISTENERS, and return empty array in LISTENERS and the list of 
%   destroyed events as a cell array in EVENTLIST.
%
%   See also CREATEOBJECTEVENTLISTENERS.

% return immediately if no listeners
if isempty(listeners), return; end

% make sure it's a cell array
listeners = util.ascell(listeners);

% destroy event listeners
for kk=1:length(listeners)
    if ~isstruct(listeners{kk}), continue; end % ignore if not a struct
    eventList = fieldnames(listeners{kk}); % get list of struct fields (listeners)
    for mm=1:length(eventList) % delete each of the listeners
        delete(listeners{kk}.(eventList{mm}));
    end
end

% return empty array
listeners = [];