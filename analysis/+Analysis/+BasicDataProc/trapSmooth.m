function [smoothData, tm] = trapSmooth(data, Nwin, Nstep, fs)
% trapSmooth- use trapz to smooth data
%trapz integral of a window Nwin, stepping Nstep
% 

%example:
%       [dataTempClassicBand, tplotCB]=Analysis.BasicDataProc.trapSmooth(dataTempClassicBand, 20, 5, fs];


smoothData=[];

%rows data, columns channels/bands/etc
if size(data, 1)<size(data,2)
    data=data';
end

totaltime=size(data,1)/fs; %find the total time in secondsl;df
N=size(data,1); 
bnsz=totaltime/N; %bin size in seconds
NstepB=round((Nstep/1000)/bnsz); %convert seconds to bins
NwinB=round((Nwin/1000)/bnsz); %convert seconds to bins
winstart=1:NstepB:N; %create the list of starting points
intsz=totaltime/length(winstart); %get the size of each integral window


if Nstep < 0 || Nwin < 0
    warning('Nstep and Nwin entered in S not ms, converted to ms for processing');
    Nstep=Nstep*1000;
    Nwin=Nwin*1000;
end


%%
for ii=1:length(winstart)
    if winstart(ii)+NwinB<N
        smoothData(ii,:,:)=trapz(data(winstart(ii):winstart(ii)+NwinB,:,:));
    else
        smoothData(ii,:,:)=trapz(data(winstart(ii):end,:,:));
    end
end

smoothData=squeeze(smoothData);

%timing for plotting
tm=linspace(1, N, size(smoothData,2));

