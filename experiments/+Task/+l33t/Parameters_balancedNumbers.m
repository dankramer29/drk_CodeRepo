function Parameters_balancedNumbers(obj)
% This parameter set will balance the number of trials associated with a
% particular number.  The number of trials must be set to an integer
% multiple of the product of (number substitution pairs) x (number response
% types).  The number of trials available per substitution pair must be at
% least the minimum specified in the default settings.
%
% For number-responses, press the number.
%
% For word-responses, press 'y' if you consider the word correct, or 'n' if
% you consider it incorrect.
%
% Press 'x' if the subject reports "I don't know" or if you think the trial
% should not be incorporated into analysis.

% letter<->number substitutions
obj.user.subs = struct('e',3,'a',4,'s',5); % choose any 3 (trials must be at least N*2*8, so N>3 means many trials)
obj.user.responseTypes = {'word','number'};

% load default settings
Task.l33t.DefaultSettings(obj);

% create trial parameters
obj.user.balance = 'subs'; % 'response_type','subs','words'
obj.user.numTrials = 48; % number of trials per balance condition

% font settings
obj.user.fontFamily = 'Courier New';%'Times';
obj.user.fontSize = 80;
obj.user.fontColor = 255*[0.8 0.8 0.8];