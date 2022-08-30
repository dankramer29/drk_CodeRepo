function Parameters_ColorOnly(obj)
% This parameter set asks the subject to name the color of a square on the
% screen (no text information presented).
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
obj.user.cue_modality = {'color'}; % 'text', 'color'
obj.user.response_modality = {'color'}; % 'text', 'color'
obj.user.cue_words = obj.user.color_names;
obj.user.cue_colors = obj.user.color_names;
obj.user.cue_congruency = {'congruent'};

% control number of trials (one entry for each balance-condition option)
obj.user.conditionsToBalance = {'cue_colors'}';
obj.user.numTrialsPerBalanceCondition = 2; % number of trials for each balance condition

% configure catch trials
obj.user.numCatchTrials = 0;
obj.user.catchTrialSelectMode = 'percomb';