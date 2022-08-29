function Parameters_ShellGame(obj)
% This parameter set evaluates response speed for answers to mathematical
% operators set in quadrants of the screen.

% program
obj.user.programs = {'shell_game.txt'};

% define range of values for user-replaceable strings
obj.user.program_idx = {1};
obj.user.X_START = {-2,-1,0,1,2};
obj.user.Y_START = {-2,-1,0,1,2};
obj.user.Z_START = {-2,-1,0,1,2};
obj.user.XXY_OPERATION = {'+','-'};
obj.user.YXZ_OPERATION = {'+','-'};
obj.user.ZXY_OPERATION = {'+','-'};
obj.user.response_var = {'x','y','z'};

% control number of trials (one entry for each balance-condition option)
obj.user.balance = {'response_var','XXY_OPERATION','YXZ_OPERATION','ZXY_OPERATION'};
obj.user.numTrialsPerBalanceCondition = 1; % number of trials for each balance condition

% meta-parameters to help with the trial-balancing code
obj.user.var_labels = {'program_idx','X_START','Y_START','Z_START','XXY_OPERATION','YXZ_OPERATION','ZXY_OPERATION','response_var'}; % list of all the user fields that contain trial parameters
obj.user.strrep_vars = {'X_START','Y_START','Z_START','XXY_OPERATION','YXZ_OPERATION','ZXY_OPERATION'}; % list all of the user fields that contain names of placeholders in the code

% miscellaneous settings
obj.user.fontSize = 100; % font size of the operation string
obj.user.fontFamily = 'Courier'; % font of the operation string
obj.user.fontColor = 150*[0.5 0.5 0.5]; % color of the operation string

% load default settings
Task.ComputerProgramming.DefaultSettings(obj);