function Parameters_NumberValue(obj)
% This parameter set evaluates numerical magnitude.

% define numbers first
obj.user.symbol{1} = {'char','magnitude',0:9};
obj.user.quadrant = {'left','right'}; % screen quadrants in which to display answers
obj.user.justify = {{'middle','middle'}}; % {'left','right'} allowable quadrant-justification pairs (each cell indicates justification for all listed quadrants)
obj.user.prompt = {@gt,@lt}; % prompt the specific comparison to make between the quantities

% control number of trials (one entry for each balance-condition option)
obj.user.balance = 'all';
obj.user.numTrialsPerBalanceCondition = 1; % number of trials for each balance condition

% miscellaneous settings
obj.user.promptFontSize = 100; % font size of the operation string
obj.user.promptFontFamily = 'CourierNew';
obj.user.promptFontBrightness = 200;
obj.user.promptFontColor = [0.6 0.6 0.6]; % color of the operation string
obj.user.symbolFontFamily = 'CourierNew';
obj.user.symbolFontSize = 100; % font size to use when font size is not the quantity being tested
obj.user.symbolFontColor = [0.6 0.6 0.6]; % color of the answer
obj.user.symbolFontBrightness = 200; % brightness of the answer
obj.user.quadrantMargin = 100; % space between quadrants, in pixels

% load default settings
Task.QuantityComparison.DefaultSettings(obj);