function Parameters_LargeNumbers(obj)
% This parameter set evaluates response speed for answers to mathematical
% operators set in quadrants of the screen.

% define numbers first
obj.user.operators = {@plus,@minus}; % operators to test
obj.user.numbers = 0:999; % numbers to use in operations
obj.user.answers = -999:999; % how big the answers can be
obj.user.quadrants = {'left','right'}; % screen quadrants in which to display answers
obj.user.fontsizes = 160; % font sizes of the answers [80,160]
obj.user.justify = {'left','middle','right'}; % justification of text within quadrant

% control number of trials (one entry for each balance-condition option)
obj.user.balance = 'all';
obj.user.numTrialsPerBalanceCondition = 2; % number of trials for each balance condition

% miscellaneous settings
obj.user.operationFontSize = 160; % font size of the operation string
obj.user.operationFontFamily = 'Courier New'; % font of the operation string
obj.user.operationFontColor = 150*[0.5 0.5 0.5]; % color of the operation string
obj.user.answerFontColor = 150*[0.5 0.5 0.5]; % color of the answer
obj.user.distractorFontColor = 150*[0.5 0.5 0.5]; % color of the distractor
obj.user.quadrantMargin = 100; % space between quadrants, in pixels

% load default settings
Task.SpatialAttentionArithmetic.DefaultSettings(obj);