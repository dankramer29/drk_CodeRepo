function Parameters_SmallNum_OpFirst_SepResp(obj)
% This parameter set evaluates response speed for answers to mathematical
% operators set in quadrants of the screen.

% define numbers first
obj.user.operators = {@plus,@minus}; % operators to test
obj.user.numbers = 0:9; % numbers to use in operations
obj.user.answers = -9:9; % how big the answers can be
obj.user.quadrants = {'left','right'}; % screen quadrants in which to display answers
obj.user.fontsizes = 160; % font sizes of the answers [80,160]
obj.user.justify = {{'middle','middle'}}; % {'left','right'} allowable quadrant-justification pairs (each cell indicates justification for all listed quadrants)

% control number of trials (one entry for each balance-condition option)
obj.user.balance = 'all';
obj.user.numTrialsPerBalanceCondition = 8; % number of trials for each balance condition

% miscellaneous settings
obj.user.operationFontSize = 160; % font size of the operation string
obj.user.operationFontFamily = 'Courier New'; % font of the operation string
obj.user.operationFontColor = 150*[0.5 0.5 0.5]; % color of the operation string
obj.user.answerFontColor = 150*[0.5 0.5 0.5]; % color of the answer
obj.user.distractorFontColor = 150*[0.5 0.5 0.5]; % color of the distractor
obj.user.quadrantMargin = 100; % space between quadrants, in pixels

% load default settings
Task.SpatialAttentionArithmetic.DefaultSettings_OpFirst_SeparateResponse(obj);