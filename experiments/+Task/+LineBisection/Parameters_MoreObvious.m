function Parameters_MoreObvious(obj)
% This parameter set judges bisection of horizontal lines

% define numbers first
obj.user.symbolTypes = {'char','char','char','char','char'};
obj.user.symbols = {'1','2','8','9','H'}; % could also be words written out
obj.user.symbolSize = 32*ones(1,length(obj.user.symbols)); % size of the symbol (units according to symbol type; e.g., char -> font pt)
obj.user.lineOrientation = 'horizontal'; % 'horizontal' or 'vertical'
obj.user.lineLength = [23 24]; % width (# of symbols) of the line
obj.user.linePosition = {'random','random'}; % for horizontal,vertical, specify 'random' (uniform on [-1,1]) or 'fixed' (centered)
obj.user.bisectorPositions = [-4 -2 0 2 4]; % bisector positions, in units of symbols distance from the center point
obj.user.bisectorExtension = 30; % how far the bisector extends on either side perpendicular to the line (in pixels)
obj.user.bisectorSize = 5; % width of the bisecting line
obj.user.bisectorColor = 150*[0.5 0.5 0.5]; % color of the bisector (in R, G, B on scale [0,255])

% control number of trials (one entry for each balance-condition option)
obj.user.balance = 'all';
obj.user.numTrialsPerBalanceCondition = 1; % number of trials for each balance condition

% font
obj.user.fontFamily = 'Courier New';
obj.user.fontSize = 80;
obj.user.fontColor = 255*[0.8 0.8 0.8];

% load default settings
Task.LineBisection.DefaultSettings(obj);