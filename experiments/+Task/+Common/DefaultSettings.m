function DefaultSettings(obj,varargin)

% screen
obj.user.displayresolution = env.get('displayresolution'); % screen size in pixels (width x height)

% fixation point size/color
obj.user.fixationScale = 0.02;
obj.user.fixationColor = [0.5 0.5 0.5];
obj.user.fixationBrightness = 150;

% font settings
obj.user.defaultFontFamily = 'Courier New';%'Times';
obj.user.defaultFontSize = 80;
obj.user.defaultFontColor = 255*[0.8 0.8 0.8];

% stimulation
obj.useStimulation = false;
obj.stimConstructor = @Experiment2.Stim.BlackrockStimulator;
obj.stimConfig = @(x)x;

% display
obj.useDisplay = true;
obj.displayConstructor = @Experiment2.DisplayClient.PsychToolbox;
obj.displayConfig = @DisplayClient.Config.PTB;

% keyboard
obj.useKeyboard = true;
obj.keyboardConstructor = {@Experiment2.Keyboard.Input,'unifyNumberKeys',true};
obj.keyboardConfig = @(x)x;
obj.keys.dontknow = {{},{'x'}};
obj.keys.next = {{},{'RightArrow'}};
obj.keys.prev = {{},{'LeftArrow'}};
obj.keys.skip = {{},{'escape'}};

% sound
obj.useSound = true;
type = env.get('type');
if strcmpi(type,'PRODUCTION')
    %obj.soundConstructor = {@Experiment2.Sound.PTBSoundRemote};
    obj.soundConstructor = {@Experiment2.Sound.MatlabSound};
elseif strcmpi(type,'DEVELOPMENT')
    obj.soundConstructor = {@Experiment2.Sound.MatlabSound};
    %obj.soundConstructor = {@Experiment2.Sound.PTBSound};
end
obj.soundConfig = @(x)x;
obj.sounds.newtrial = 'blip1.wav';
obj.sounds.countdown = 'digital_blip.wav';
obj.sounds.respond = 'doubletap_n045.wav';
obj.sounds.timeout = 'honk.wav';

% sync
if any(strcmpi(varargin,'sync'))
    
    % shape parameters
    sz = 20;
    pos = [sz/2 obj.user.displayresolution(2)-15-(sz/2)];
    clr = 255*ones(1,3);
    
    % configure sync output
    obj.useSync = true;
    obj.useFrameworkSync = true;
    
    % note that when this code runs, the display client has not been
    % populated yet; still, we want to keep this code general enough that
    % future iterations might generate sync signals through some other
    % medium besides the display client, so want to provide a full
    % namespace for the sync function (i.e., object and method).  hence,
    % the first cell contains a function handle for the drawing method, and
    % the second cell holds an anonymous function to get the object to
    % which that method belongs.
    obj.syncFcn = {@drawRect,@(x)x.hDisplayClient};
    obj.syncArgs = {pos,sz,clr};
end

% external refresh
if any(strcmpi(varargin,'extrefresh'))
    obj.externalDisplayRefresh = true;
end

% event handlers
obj.objectEventHandlers = {};
obj.trialEventHandlers = {};
obj.taskEventHandlers = {};