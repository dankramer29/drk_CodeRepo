function [listeners,eventList] = createObjectEventListeners(obj,fcn,varargin)
% CREATEOBJECTEVENTLISTENERS add listeners for object events
%
%   [LISTENERS,EVENTS] = CREATEOBJECTEVENTLISTENERS(OBJ,FCN)
%   For the cell array of objects OBJ, create listeners for each event of
%   OBJ{K} as a field of the struct LISTENERS{K}, with the callback 
%   function FCN.  Return a cell array of the event names in EVENTS.
%
%   CREATEOBJECTLISTENERS(...,IGNORE1,IGNORE2,...)
%   Provide a list of events to ignore.
%
%   See also DESTROYOBJECTEVENTLISTENERS.

% list of events to ignore
ignore = varargin;

% force OBJ to be a cell
obj = util.ascell(obj);

% initialize to empty in case no events
listeners = cell(1,length(obj));

% add listeners for object events
for kk=1:length(obj)
    eventList = events(obj{kk}); % get a list of events
    for mm=1:length(ignore)
        eventList( strcmpi(eventList,ignore{mm}) ) = []; % remove unneeded event from list
    end
    for mm=1:length(eventList)
        listeners{kk}.(eventList{mm}) = addlistener(obj{kk},eventList{mm},fcn);
    end
end