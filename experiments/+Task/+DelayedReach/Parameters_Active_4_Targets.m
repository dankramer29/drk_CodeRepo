function Parameters_Active_4_Targets(obj)
% Delayed Active Reach Task parameters
%
% NOTE: Must set environment variable "ptbopacity" to 1.0, "ptbhid" to 1 in
% order to have the touchscreen register single-touch hits on the screen

% load default settings
Task.DelayedReach.DefaultSettings_Active(obj);

% load common settings
Task.DelayedReach.DefaultSettings_Common_4_Targets(obj);