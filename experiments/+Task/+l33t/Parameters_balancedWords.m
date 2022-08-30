function Parameters_balancedWords(obj)
% This parameter set will balance the number of trials associated with a
% particular word (evenly distributing substitution pairs and response
% types as far as possible).
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
obj.user.subs = struct('a',4,'b',8,'e',3,'i',1,'o',0,'s',5,'z',2); % must be multiple of mintrialspercondition (8)
obj.user.responseTypes = {'word','number'};

% load default settings
Task.l33t.DefaultSettings(obj);

% create trial parameters
obj.user.balance = 'words'; % 'response_type','subs','words'
obj.user.numTrials = 48; % number of trials per balance condition

% font settings
obj.user.fontFamily = 'Courier New';%'Times';
obj.user.fontSize = 80;
obj.user.fontColor = 255*[0.8 0.8 0.8];