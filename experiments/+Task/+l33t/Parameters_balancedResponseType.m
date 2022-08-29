function Parameters_balancedResponseType(obj)
% This parameter set will balance the number of trials with each response
% type.  The number of trials must be set to an integer multiple of the
% product of (number substitution pairs) x (number response types).  The
% number of trials available per response type must be at least the minimum
% specified in the default settings.
%
% For number-responses, press the number.
%
% For word-responses, press 'y' if you consider the word correct, or 'n' if
% you consider it incorrect.
%
% Press 'x' if the subject reports "I don't know" or if you think the trial
% should not be incorporated into analysis.

% letter<->number substitutions
obj.user.subs = struct('a',4,'b',8,'e',3,'i',1,'o',0,'s',5,'z',2);
obj.user.responseTypes = {'word','number'};

% load default settings
Task.l33t.DefaultSettings(obj);

% create trial parameters
obj.user.balance = 'response_type'; % 'response_type','subs','words'
obj.user.numTrials = 56; % number of trials per balance condition

% font settings
obj.user.fontFamily = 'Courier New';%'Times';
obj.user.fontSize = 80;
obj.user.fontColor = 255*[0.8 0.8 0.8];