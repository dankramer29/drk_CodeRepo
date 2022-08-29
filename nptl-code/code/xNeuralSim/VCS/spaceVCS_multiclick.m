function spaceVCS_multiclick()

% Velocity-Control Simulator (using space mouse input device)
%
% Function: sends velocity and click commands to simulink system based on
% the mouse position and click state

% created by Dan Bacher (original Mouse version 12/7/2009)
% space mouse version created 04/13/2010

%% 1.0 User Settings

% set IP address and port numbers
% ********************************************************************
%remoteIP = '192.168.137.1';
%remoteIP = '128.148.107.69'; % Sergey Desktop
%remoteIP = '128.148.107.72'; % Dan's workstation

% % % % % remoteIP = '255.255.255.255'; % broadcast to any IP
% % % % % %remoteIP = '192.168.137.82'; % DLR CPU direct robot control
% % % % % 
% % % % % 
% % % % % remotePort = 49500;   % iSLC simulator receive port
% % % % % 
% % % % % % target port, default = 5555 for now
% % % % % %remotePort = 1001; % for direct DLR robot control
% % % % % 
% % % % % 
% % % % % localPort = 5554;            % local port, keep at 5554
% ********************************************************************
%% 1.0 User Settings
% set IP address and port numbers
remoteIP = '192.168.137.255'; % broadcast to any IP
remotePort = 49255;   % VCS in xPC model.
% localIP
getXpcIPs = getMyIP('192.168.137.255');
if ~isempty(getXpcIPs{1})
    localIP = getXpcIPs{1};
else
    getAnyIP = getMyIP;
    localIP = getAnyIP{1};
end
% NPTL
localPort = 49454;
% receive data from screen
gameFormattingPort = 50112;
gameDataPort = 50114;
%% 2.0 Initialization
S.timerSamplePeriod = 0.05; % sampling rate of simulator
%S.mouseGain = 160; % normalize mouse output to [-.5 .5]
S.mouseGain = 320;
S.figPos = get(0,'screensize');

% create figure
S.fig = figure('menubar','none', ...
    'toolbar','none', 'numbertitle','off', ...
    'Name','Velocity Control Simulator');
axis off
S.ax = gca;
set(S.fig,'color','k')
text(.1,.6,'space-VCS','color','w','fontsize',50,...
    'fontangle','italic');
text(-.05,.3,'Press ESCAPE to stop the application',...
    'color','w','fontsize',20);

% use figure UserData to pass click and keystroke data around
set(S.fig,'UserData',[0 0]); % [click stop]

% init UDP (pnet) connections
pnet('closeall')
S.socket = InitUDPsender(localIP, localPort,remoteIP,remotePort);
S.dataSocket = InitUDPreceiver(localIP, gameDataPort);
S.formatSocket = InitUDPreceiver(localIP, gameFormattingPort);
% create timer object
timer_h = timer('TimerFcn',{@VCSloop, S}, ...
    'BusyMode','drop','TasksToExecute',inf, ...
    'ExecutionMode','FixedRate', 'Period', S.timerSamplePeriod, ...
    'StartDelay', S.timerSamplePeriod);

% START SIMULATOR
Mouse3D('start'); % start space mouse actxserver
clc;
start(timer_h)
disp('Velocity Control Simulator: started')

%% 3.0 Main Loop (Timer Function)
function VCSloop(obj, event, S)
% INITIALIZE

% initialize variables
persistent t vel % place holder for time stamp
if isempty(t); t = 0; end
if isempty(vel); vel = [0 0 0]; end

udpData = zeros(1,7); % [t x y click1 click2 click3 click4]
velocity = [0 0 0]; 
clickState = 0;

%% set event callback functions
% mouse click
set(S.fig,'WindowButtonDownFcn', ...
    {@MouseClickFcn, S});
set(S.fig,'WindowButtonUpFcn', ...
    {@MouseUnclickFcn, S});
% key press
set(S.fig,'WindowKeyPressFcn', ...
    {@KeyHitFcn, S});
% key release
set(S.fig,'WindowKeyReleaseFcn', ...
    {@KeyReleaseFcn, S});
%% EXECUTE

% increment time stamp / counter
t = t+1;

% get user data
uData = get(S.fig,'UserData'); % [click stop]

% get space mouse data
M = Mouse3D('get');
velocity = M.pos./S.mouseGain;
% if you also want rotations use:
% rotation = M.rot;

% get click status
clickState = zeros(1,4); %resets if button unclicked
if uData(1)
    clickState(uData(1)) = 1; 
end
% this only uses 2D vel
udpData = [t velocity([1,3]) clickState]; 
disp(udpData(2:end))

%velocity = velocity .* 0.4;
%udpData = [21 t velocity clickState zeros(1,8)];
%disp(udpData(3:6));

try
    SendUDP(S.socket,udpData);
catch
    stop(timerfind);
    delete(timerfind);
    CloseUDP(S.socket);
    close all;
    clear all;
    fprintf('Velocity Control Simulator: Aborted\n');
    fprintf('*** UDP send failed... Check network connection\n');
    return;
end

% update user data to reset click state
%uData(1) = 0; %resetting it again
%set(S.fig,'UserData',uData);

% check for program stop command
stopCheck = uData(2);
if stopCheck
    disp('Velocity Control Simulator: stopped')
    stop(timerfind); % stop timer
    delete(timerfind); % delete timer
    CloseUDP(S.socket); % close UDP pnet connections
    
    close; % close figure
    clear all;
end

%% 4.0 Callback Functions

function MouseClickFcn(obj,event,S)
% callback fcn upon mouse click event
    uData = get(S.fig, 'UserData');
    uData(1) = 1;
    disp('CLICK')
    set(S.fig, 'UserData', uData);

function MouseUnclickFcn(obj,event,S)
% callback fcn upon mouse click event
    uData = get(S.fig, 'UserData');
    uData(1) = 0;
    set(S.fig, 'UserData', uData);

function KeyHitFcn(obj,event,S)
% callback fcn upon key press event
% SNF: this assumes someone hit esc to stop or 1-4 for click targets
    uData = get(S.fig, 'UserData');
    fprintf(['KEY : ', event.Key, '\n']);
    if strcmp(event.Key,'escape') % if escape is pressed
        uData(2) = 1; % send stop message to timer
    else    % BOLD ASSUMPTION ALERT! This assumes you hit a number key.
        if strcmp(event.Key(1), 'n') %if the numpad was used
            uData(1) = str2double(event.Key(7)); %get the number
        else                        % if you used the numbers above the letters
            uData(1) = str2double( event.Key ); %one of the clicks executed
        end
    end
    set(S.fig, 'UserData', uData);

function KeyReleaseFcn(obj, event, S)
    % assumes a user released 1-4. we don't care when they release esc
    disp('KEY RELEASED')
    uData = get(S.fig, 'UserData');
    uData(1) = 0; % whatever click it was is now off
    set(S.fig, 'UserData', uData);

