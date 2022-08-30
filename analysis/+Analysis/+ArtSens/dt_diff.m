function [ row_diff ] = dt_diff( time_only, dt, sf, varargin )
%dt_diff takes the datetime format from the origin and gets the difference,
%in rows based on the sampling frequency
%   INPUTS
%             time_only=   the one without the datetime
%             dt=     the one with the datetime, from blc.DataStartTime
%             sf=     the sampling frequency
%             
%     OUTPUTS
%               row_diff= the row number of the time you want, based on the start time of the file


%check which day the recording happened on if it's greater than 24h,
%default, day 1.
[varargin,recordingday] = util.argkeyval('recordingday',varargin,1);



[Y, M, D]=ymd(dt); %get the year month and day from the actual datetime
if isa(time_only, 'datetime')
    [splittime{1},splittime{2}, ss]=hms(time_only);
    splittime{3}=floor(ss);
    splittime{4}=(ss-floor(ss))*1000;
else
    splittime=strsplit(time_only, {':', '.'});
end
D=D+recordingday-1; %adjust for the day being a day or 2 days after the start time (RIGHT NOW THIS DOESN'T ACCOUNT FOR DOING SOMETHING REALLY EARLY IN THE MORNING ON DAY 2 BUT WITHIN 24 HOURS OF RECORDING BUT SHOULDN'T HAPPEN LOL
%add the fucking 0
for ii=1:length(splittime)
    if length(splittime{ii})==1
        splittime{ii}=strcat('0',splittime{ii}); %add a zero where necessary
    end
end
%account for ms vs no ms
if length(splittime)==4
    tt=datetime(Y,M,D,str2double(splittime{1}),str2double(splittime{2}),str2double(splittime{3}),str2double(splittime{4}));
    tt.Format='dd-MM-uuuu HH:mm:ss.SSS';
elseif length(splittime)==3
    tt=datetime(Y,M,D,str2double(splittime{1}),str2double(splittime{2}),str2double(splittime{3}));
end


%% I STARTED TO FIX THE MULTIPLE DAY STUFF, BUT IT DIDN'T WORK, COULD TRY AGAIN LATER. GOT AS FAR AS CONFIRMING THE TIMING ISN'T RIGHT AFTER SUBTRACTING WHAT SHOULD BE THE DAY 1 STUFF
%if recordingday==1
    t_diff=tt-dt; %this seems like it's taking off the ms if you're debugging, but it's not, verified 4/2/18
    row_diff=round(seconds(t_diff)*sf);
%else
%     [hh, mm, ss]=hms(tt);
%     
%     row_diff=round((hh*60*60+mm*60+ss)*sf);
% end
    
end

