function Parameters_ForLoop(obj)
% This parameter set evaluates response speed for answers to mathematical
% operators set in quadrants of the screen.

% program
obj.user.programs = {'forloop_simple.txt'};

% define range of values for user-replaceable strings
obj.user.program_idx = {1};
obj.user.X_START = {0,1,2};
obj.user.X_INCR = {'k'};
obj.user.X_OPERATION = {'+','-'};
obj.user.LOOP_START = {1,2};
obj.user.LOOP_END = {2,3};
obj.user.response_var = {'x'};

% control number of trials (one entry for each balance-condition option)
obj.user.balance = {'LOOP_START','LOOP_END','X_OPERATION'}; % 'response', 'answer'
obj.user.numTrialsPerBalanceCondition = 1; % number of trials for each balance condition

% meta-parameters to help with the trial-balancing code
obj.user.var_labels = {'X_START','X_INCR','X_OPERATION','LOOP_START','LOOP_END','response_var','program_idx'};
obj.user.strrep_vars = {'X_START','X_INCR','X_OPERATION','LOOP_START','LOOP_END'};

% miscellaneous settings
obj.user.fontSize = 100; % font size of the operation string
obj.user.fontFamily = 'Courier'; % font of the operation string
obj.user.fontColor = 150*[0.5 0.5 0.5]; % color of the operation string

% load default settings
Task.ComputerProgramming.DefaultSettings(obj);