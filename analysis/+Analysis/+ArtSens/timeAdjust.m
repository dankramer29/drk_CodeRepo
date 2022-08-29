function [OriginTime, newStartEnd_s, recDaySt, recDayEnd] = timeAdjust(blc, newStartTime, varargin)
%timeAdjust fix times to create a new start time for the blc file and
%seconds
%   In the event that the start time is making the file too long, or the
%   recording day is different than the start day, it will change the start
%   time of the blc file (so it's consistent in the rest of the
%   programming), and give out the seconds to input into blc.read('time',
%   [newStartEnd_s(1,1) newStartEnd_s(1,2)]);

%Inputs
%     blc= the blc file you need to change
%     newStartTime= the start time you want to be the new origin time in
%     the format [hh mm ss ms] where ms is 3 digits
% eg. [15 20 30 110]
%     
% Outputs
%     blcnew= the blc with the adjusted DataStartTune
%     newStartEnd_s= the new start and end time in seconds for entering into the blc.read function
%     



%check which day the recording happened on
[varargin,recordingDay] = util.argkeyval('recordingDay',varargin,1);
%input the new end time, default is the end of the day
[varargin,endTime] = util.argkeyval('endTime',varargin,[23 59 59 000]);


origDaySt=blc.DataStartTime;
[Y, M, D]=ymd(origDaySt);
recDaySt=datetime(Y, M, D+recordingDay-1, newStartTime(1), newStartTime(2), newStartTime(3), newStartTime(4));
recDaySt.Format='dd-MM-uuuu HH:mm:ss.SSS';
temptime=recDaySt-origDaySt;
temptime.Format='hh:mm:ss.SSS';
newStartEnd_s(1)=seconds(temptime);
recDayEnd=datetime(Y, M, D+recordingDay-1, endTime(1), endTime(2), endTime(3), endTime(4));
newStartEnd_s(2)=seconds(recDayEnd-origDaySt);


blcnew=blc;
OriginTime=recDaySt;

end

