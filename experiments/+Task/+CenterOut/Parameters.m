function Parameters(obj)

obj.user.targetScale = 0.07;
obj.user.frameLimit = 3600;

% targets
obj.user.effectorTargetLocations = 1.15*[...
    0.0000    0.2000
    0.1414    0.1414
    0.2000    0.0000
    0.1414   -0.1414
    0.0000   -0.2000
    -0.1414   -0.1414
    -0.2000    0.0000
    -0.1414    0.1414];
obj.user.effectorHomeLocation = [0 0];

% trial data
obj.trialDataConstructor = @Task.CenterOut.TrialData;

% display
obj.useDisplay = true;
obj.displayConstructor = @Experiment2.DisplayClient.PsychToolbox;
obj.displayConfig = @DisplayClient.Config.PTB;
obj.user.displayresolution = env.get('displayresolution');

% keyboard
obj.useKeyboard = true;
obj.keyboardConstructor = @Experiment2.Keyboard.Input;
obj.keyboardConfig = @(x)x;
obj.keys.next = {{},{'RightArrow'}};
obj.keys.prev = {{},{'LeftArrow'}};
obj.keys.skip = {{},{'escape'}};

% sound
obj.useSound = false;
obj.soundConstructor = @Experiment2.Sound.PTBSoundRemote;
obj.soundConfig = @(x)x;

% external refresh
if ~isempty(obj.hTask.hFramework) && isa(obj.hTask.hFramework,'Framework.Interface')  && obj.hTask.hFramework.options.taskDisplayRefresh
    obj.externalDisplayRefresh = true;
end

% sync
if ~isempty(obj.hTask.hFramework) && isa(obj.hTask.hFramework,'Framework.Interface') && obj.hTask.hFramework.options.enableSync
    
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

% effectors
obj.effectorDefinitions{1} = {@Task.CenterOut.EndpointEffector,...
    1,... % id
    'nStateVars',4,... % nStateVars
    'idxStateHitTest',[1 3],... % idxStateHitTest
    'primaryTarget',1,...
    'defaultShape','oval',...
    'defaultColor',[0 1 0],...
    'defaultScale',obj.user.targetScale,...
    'defaultAlpha',100,...
    'defaultBrightness',180,...
    'stateIntExtMode','same'};

obj.targetDefinitions{1} = {@Task.CenterOut.EndpointTarget,...
    1,... % id
    'nStateVars',2,... % nStateVars
    'idxStateHitTest',[1 2],... % idxStateHitTest
    'defaultShape','square',...
    'defaultColor',[1 0 0],...
    'defaultScale',obj.user.targetScale,...
    'defaultAlpha',100,...
    'defaultBrightness',180,...
    'locationHome',obj.user.effectorHomeLocation,...
    'targetLocations',obj.user.effectorTargetLocations,...
    'stateIntExtMode','same',...
    'durationHold',1};

% phases
obj.phaseDefinitions{1} = {@Task.CenterOut.PhaseShowOutboundTarget,...
    'Name','TargetShowOut',...
    'durationTimeout',1};
obj.phaseDefinitions{2} = {@Task.CenterOut.PhaseEndpointOutbound,...
    'Name','EndpointOut',...
    'durationTimeout',20};

% summary
obj.summaryDefinitions{1} = {@Task.CenterOut.SummaryScore,...
    'Name','Score',...
    'durationTimeout',Inf};
obj.summaryDefinitions{2} = {@Task.CenterOut.SummaryReward,...
    'Name','Reward',...
    'durationTimeout',Inf};

% event handlers
obj.objectEventHandlers = {
    'ObjectHit',    'ObjectHitFcn'};
obj.trialEventHandlers = {};
obj.taskEventHandlers = {};