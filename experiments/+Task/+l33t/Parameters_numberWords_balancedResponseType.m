function Parameters_numberWords_balancedResponseType(obj)
% This parameter set will balance the number of trials with each response
% type.  The number of trials must be set to an integer multiple of the
% product of (number substitution pairs) x (number response types).  The
% number of trials available per response type must be at least the minimum
% specified in the default settings.  In this case, the words are the
% numbers, spelled out in English.
%
% The number of words selected will be calculated by the number of trials
% divided by the minimum number of trials per condition (see
% DefaultSettings).  48 trials divided by 8 trials per condition would
% result in 6 words.  After a word is selected, the set of applicable
% substitutions will be identified.
%
% For number-responses, press the number.
%
% For word-responses, press 'y' if you consider the word correct, or 'n' if
% you consider it incorrect.
%
% Press 'x' if the subject reports "I don't know" or if you think the trial
% should not be incorporated into analysis.

% letter<->number substitutions
obj.user.subs = struct('o',0,'i',1,'z',2,'e',3,'s',5,'t',7);
obj.user.responseTypes = {'numberword','number'};

% load default settings
Task.l33t.DefaultSettings(obj);

% change the source file
obj.user.wordFile = 'wordlist_numbers2.txt';

% create trial parameters
obj.user.balance = 'response_type'; % 'response_type','subs','words'
obj.user.numTrials = 48; % number of trials per balance condition

% font settings
obj.user.fontFamily = 'Courier New';%'Times';
obj.user.fontSize = 80;
obj.user.fontColor = 255*[0.8 0.8 0.8];