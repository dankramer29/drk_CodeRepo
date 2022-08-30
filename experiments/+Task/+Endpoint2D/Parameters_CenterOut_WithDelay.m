function Parameters_CenterOut_WithDelay(obj)

% default values
obj.user.target_profile.default = struct('color',[0.4 0.4 0.4],'scale',0.02,'brightness',180);
obj.user.target_profile.active = struct('color',[0.5 0 0],'scale',0.02,'brightness',180);
obj.user.target_profile.contact = struct('color',[0.5 0 0],'scale',0.02,'brightness',180);
obj.user.effector_profile.default = struct('color',[0.8 0.8 0.8],'scale',0.0075,'brightness',180);
obj.user.effector_profile.active = struct('color',[0 0.5 0],'scale',0.0075,'brightness',180);

% set up task
obj.user.type = 'CenterOut';
obj.user.flagInbound = true;

% target locations
obj.user.num_targets = 8;
theta = linspace(0,2*pi,obj.user.num_targets+1);
rho = 0.23;
[x,y] = pol2cart(theta(1:end-1),rho);
obj.user.target_locations = arrayfun(@(z)[x(z) y(z)],1:obj.user.num_targets,'UniformOutput',false);
obj.user.state_modes = {'pro'};

% conditions to balance
obj.user.balance = {'target_locations'};
obj.user.numTrialsPerBalanceCondition = 10;
obj.user.numCatchTrials = 0;
obj.user.catchTrialSelectMode = 'global';

% phases
obj.phaseDefinitions{1} = {@Task.Endpoint2D.PhaseShowTarget,...
    'Name','ShowTarget',...
    'durationTimeout',1};
obj.phaseDefinitions{2} = {@Task.Endpoint2D.PhaseDelay,...
    'Name','Delay',...
    'durationTimeout',1};
obj.phaseDefinitions{3} = {@Task.Endpoint2D.PhaseMoveCursor,...
    'Name','MoveCursor',...
    'durationTimeout',20};

% load default settings
Task.Endpoint2D.DefaultSettings_Common(obj);