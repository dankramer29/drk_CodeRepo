function Parameters_PostDelay(obj)
% Delayed Reach GNG POST-Delay
%
% NOTE: Must set environment variable "ptbopacity" to 1.0, "ptbhid" to 1 in
% order to have the touchscreen register single-touch hits on the screen

% load default settings
Task.DelayedReachGNG.DefaultSettings_PostDelay(obj);

% load common settings
Task.DelayedReachGNG.DefaultSettings_Common(obj);