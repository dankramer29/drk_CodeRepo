function drawFixationPoint(hTask)
% DRAWFIXATIONPOINT Draw a fixation point on the screen
%
%   DRAWFIXATIONPOINT(HTASK)
%   Draw a fixation point on the screen. HTASK should be an object of class
%   Experiment2.TaskInterface, with a property HDISPLAYCLIENT. This 
%   function will use the method "drawOval" of the HDISPLAYCLIENT object.
%   This function also depends on the following user parameters:
%   "fixationScale" (in pixels), "fixationColor" (RGB vector, [0-1] each)
%   and "fixationBrightness" (0-255).
user = hTask.params.user;
pos = hTask.hDisplayClient.normPos2Client([0 0]);
diam = hTask.hDisplayClient.normScale2Client(user.fixationScale);
hTask.hDisplayClient.drawOval(pos,diam,user.fixationColor*user.fixationBrightness);