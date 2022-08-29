function Parameters_NoITI(obj)
% In this configuration, each trial has only two phases: an inter-trial
% interval and a prompt/response phase. During the prompt/response, a set N
% of numbers K (k1,k2,...,kK) will appear on the screen and the subject
% must respond as quickly as possible whether all(K==N). In some instances,
% numel(unique(K))==1 but unique(K)~=N. In other instances (catch trials),
% numel(unique(K))>1 and it is impossible for all(K==N). Ideally, the
% subject will be set up with a sip/puff interface to directly enter his or
% her responses. The sip/puff interface should be sconfigured to produce
% left/right arrow key presses.
%
% RightArrow => YES
% LeftArrow => NO

% define numbers first
obj.user.numberDisplay = 2:6; % set of numbers to display
obj.user.numberGroup = obj.user.numberDisplay; % set of numbers to determine how many appear on the screen
obj.user.catchTrialFraction = 0.2; % add additional trials where numbers are scrambled

% control number of trials (one entry for each balance-condition option)
obj.user.balance = 'all'; % 'all' - (numTrialsPerBalanceCondition) instances of each combination of (numberDisplay) and (numberGroup)
obj.user.numTrialsPerBalanceCondition = 2; % number of trials for each balance condition

% font
obj.user.fontFamily = 'Courier New';
obj.user.fontSize = 80;
obj.user.fontColor = 255*[0.8 0.8 0.8];

% load default settings
Task.NumberGroups.DefaultSettings_NoITI(obj);