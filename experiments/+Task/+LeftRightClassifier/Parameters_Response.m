function Parameters_Response(obj)
% This parameter set creates rectangles and possible display locations
% called by creatTrialParams which is called by Task.

% load default settings
Task.LeftRightClassifier.DefaultSettings_Response(obj);

% select blocks to use
%  cue modality: the way the cue is presented (as text or blocks of color)
%  response modality: the thing the subject has to pay attention to and report
%  words: the set of words that will be printed
%  colors: the set of colors used to print the words and blocks
obj.user.cue_modality = {'block'}; % 'text', 'block'
obj.user.response_modality = {'block'}; % 'text', 'block'
obj.user.cue_words = obj.user.block_names;
obj.user.cue_blocks = obj.user.block_names;
obj.user.cue_congruency = {'congruent'};

% control number of trials (one entry for each balance-condition option)
obj.user.conditionsToBalance = {'cue_blocks'}';
obj.user.numTrialsPerBalanceCondition = 32; % number of trials for each balance condition

% configure catch trials
obj.user.numCatchTrials = 0;
obj.user.catchTrialSelectMode = 'percomb';

