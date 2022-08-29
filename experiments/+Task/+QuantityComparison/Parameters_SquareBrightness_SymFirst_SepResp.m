function Parameters_SquareBrightness_SymFirst_SepResp(obj)
% This parameter set evaluates brightness of a square.

% define numbers first
obj.user.symbol{1} = {'shape','brightness',25:25:200}; % type of symbol, the quantity to compare, and the values for that quantity
obj.user.quadrant = {'left','right'}; % screen quadrants in which to display answers
obj.user.justify = {{'middle','middle'}}; % {'left','right'} allowable quadrant-justification pairs (each cell indicates justification for all listed quadrants)
obj.user.prompt = {@gt,@lt}; % prompt the specific comparison to make between the quantities

% control number of trials (one entry for each balance-condition option)
obj.user.balance = 'all';
obj.user.numTrialsPerBalanceCondition = 2; % number of trials for each balance condition

% miscellaneous settings
obj.user.promptFontSize = 100; % font size of the operation string
obj.user.promptFontFamily = 'CourierNew';
obj.user.promptFontBrightness = 200;
obj.user.promptFontColor = [0.6 0.6 0.6]; % color of the operation string
obj.user.symbolShapeSize = 250; % size of shapes when size is not the quantity being tested
obj.user.symbolShapeType = 'square'; % type of shape to draw
obj.user.symbolShapeColor = [0.5 0.5 0.5];
obj.user.symbolShapeBrightness = 150;
obj.user.quadrantMargin = 100; % space between quadrants, in pixels

% load default settings
Task.QuantityComparison.DefaultSettings_SymbolFirst_SeparateResponse(obj);