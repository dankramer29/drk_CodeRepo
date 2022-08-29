function Parameters_AttendText_Congruent(obj)
% This parameter set asks the subject to read the text (with congruent
% color information)
%
% If the subject provides the correct response, type "y". Type "n" for the
% incorrect response.
%
% If the subject does not know the answer, type in "x" and press "Enter".

% load default settings
Task.Stroop.DefaultSettings_Common(obj);

% select colors to use for text and text-color
%  cue modality: the way the cue is presented (as text or blocks of color)
%  response modality: the thing the subject has to pay attention to and report
%  words: the set of words that will be printed
%  colors: the set of colors used to print the words
obj.user.cue_modality = {'text'}; % 'text', 'color'
obj.user.response_modality = {'text'}; % 'text', 'color'
obj.user.cue_words = obj.user.color_names;
obj.user.cue_colors = obj.user.color_names;
obj.user.cue_congruency = {'congruent'};

% control number of trials (one entry for each balance-condition option)
obj.user.conditionsToBalance = {'cue_words'}';
obj.user.numTrialsPerBalanceCondition = 2; % number of trials for each balance condition

% set up pairwise checks on equal condition IDs (force same words/colors)
obj.user.allowedEqualIDs(strcmpi(obj.user.conditionsToDistribute,'cue_words'),strcmpi(obj.user.conditionsToDistribute,'cue_colors')) = true;
obj.user.allowedEqualIDs(strcmpi(obj.user.conditionsToDistribute,'cue_colors'),strcmpi(obj.user.conditionsToDistribute,'cue_words')) = true;

% configure catch trials
obj.user.numCatchTrials = 0;
obj.user.catchTrialSelectMode = 'percomb';