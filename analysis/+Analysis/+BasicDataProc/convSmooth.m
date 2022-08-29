function [smoothData, tm] = convSmooth(data, win, fs)
% convSmooth- use trapz to smooth data
%convolve of a window, win which can be in s or ms
% For say envelope data, a 60ms window was pretty good.  Between 30 and 60
% seems right

%example:
%       [dataTempClassicBand, tplotCB]=Analysis.BasicDataProc.trapSmooth(dataTempClassicBand, 20, 5, fs];

%rows data, columns channels/bands/etc
if size(data, 1)<size(data,2)
    data=data';
end

if win<0 %if not in ms
    warning('win in s not ms, converted to ms for analysis');
    win=win*1000; %convert to ms
end


totaltime=size(data,1)/fs; %find the total time in secondsl;
N=size(data,1); 
bnsz=totaltime/N; %bin size in seconds
convWin=round((win/1000)/bnsz); %convert seconds to bins

%Convolve
%window to convolve over, which is just how often to smooth, don't want too big
b=ones(convWin,1)/convWin; %create the 1s, but divide by window to keep output small
%add mirrored ends
mirrorSt=flipud(data(1:convWin*5,:));
mirrorEnd=flipud(data(end-convWin*5+1:end,:));
temp=vertcat(mirrorSt, data, mirrorEnd);
%convolve the two vectors
for ii=1:size(temp,2)
    tempData(:,ii)=conv(temp(:,ii),b,'same');
end
%remove the ends
smoothData=tempData(convWin*5+1:end-convWin*5, :);

%create a time vector to plot the data
tm=linspace(1, totaltime, size(smoothData,1));

end

