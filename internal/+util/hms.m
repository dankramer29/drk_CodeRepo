function str=hms(sec,format)
% HMS calcaulte HH:MM:SS from seconds
%
%   STR = HMS(SEC)
%   Generate a time-formatted string STR representing SEC seconds of time.
%   By default, the string will be formatted with 2-digit entries for
%   hours, minutes, and seconds: HH:MM:SS.
%
%   STR = HMS(SEC,FORMAT)
%   Request a custom time format using any of the following string
%   substitutions:
%
%     dd    2-digit day
%     d     variable-digit day
%     hh    2-digit hour
%     h     variable-digit hour
%     mm    2-digit minute
%     m     variable-digit minute
%     ss    2-digit seconds
%     s     variable-digit seconds
%     iii   3-digit milliseconds
%     i     variable-digit milliseconds

% default or custom format
if nargin<2||isempty(format),format='hh:mm:ss';end

% days
dy=floor(sec/(24*60*60));
sec=sec-floor(sec/(24*60*60))*(24*60*60);

% hours
hr=floor(sec/(60*60));
sec=sec-floor(sec/(60*60))*(60*60);

% minutes
mn=floor(sec/60);
sec=sec-floor(sec/60)*60;

% seconds
sc=round(sec);

% milliseconds
mil=round(1000*(sec-sc));

% adjust if necessary due to rounding errors
if mil>=1000
    sc = sc+1;
    mil = mil-1000;
end
if sc>=60
    mn = mn+1;
    sc = sc-60;
end
if mn>=60
    hr = hr+1;
    mn = mn-60;
end
if hr>=24
    dy = dy+1;
    dy = dy-24;
end

str = format;
str = strrep(str,'dd',sprintf('%02d',dy));
str = strrep(str,'d',sprintf('%d',dy));
str = strrep(str,'hh',sprintf('%02d',hr));
str = strrep(str,'h',sprintf('%d',hr));
str = strrep(str,'mm',sprintf('%02d',mn));
str = strrep(str,'m',sprintf('%d',mn));
str = strrep(str,'ss',sprintf('%02d',sc));
str = strrep(str,'s',sprintf('%d',sc));
str = strrep(str,'iii',sprintf('%03d',mil));
str = strrep(str,'i',sprintf('%d',mil));

%str=[sprintf('%02d',hr) ':' sprintf('%02d',mn) ':' sprintf('%02d',sc)];

