function Parameters_OvalSize_PromptFirst_SepResp(obj)
% This parameter set evaluates the size of an oval.

% define numbers first
obj.user.symbol{1} = {'shape','size',50:50:400}; % type of symbol, the quantity to compare, and the values for that quantity
obj.user.quadrant = {'left','right'}; % screen quadrants in which to display answers
obj.user.justify = {{'middle','middle'}}; % {'left','right'} allowable quadrant-justification pairs (each cell indicates justification for all listed quadrants)
obj.user.prompt = {@gt,@lt}; % prompt the specific comparison to make between the quantities

% control number of trials (one entry for each balance-condition option)
obj.user.balance = 'all';
obj.user.numTrialsPerBalanceCondition = 2; % number of trials for each balance condition

% miscellaneous settings
obj.user.promptFontFamily = 'CourierNew';
obj.user.promptFontSize = 100; % font size of the operation string
obj.user.promptFontBrightness = 200;
obj.user.promptFontColor = [0.6 0.6 0.6]; % color of the operation string
obj.user.symbolFontFamily = 'CourierNew';
obj.user.symbolFontSize = 100; % font size to use when font size is not the quantity being tested
obj.user.symbolFontBrightness = 200; % brightness of the answer
obj.user.symbolFontColor = [0.6 0.6 0.6]; % color of the answer
obj.user.symbolShapeSize = 100; % size of shapes when size is not the quantity being tested
obj.user.symbolShapeBrightness = 200;
obj.user.symbolShapeColor = [0.6 0.6 0.6];
obj.user.symbolShapeType = 'oval'; % type of shape to draw
obj.user.symbolOtherArguments = {};
obj.user.quadrantMargin = 100; % space between quadrants, in pixels

% load default settings
Task.QuantityComparison.DefaultSettings_PromptFirst_SeparateResponse(obj);