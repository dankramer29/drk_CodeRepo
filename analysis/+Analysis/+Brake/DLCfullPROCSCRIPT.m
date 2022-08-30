%% the script to run the brake study


% Time in seconds, so 5.1910e3 is in seconds and K.Time(1)=first frame in the AO clock, kinematic data is
% 120fps, 0.0083s between, but the some have a large gap so double check.
% So Xpos(120) = second 1 of the video.



load_Data_File='C:\Users\kramdani\Dropbox\My PC (NSG-M-4P72P53)\Documents\Local Data\DLC_data\202110701_VM\ProcessedData_Tartare\20210701_VM01_01.mat';
load('C:\Users\kramdani\Dropbox\My PC (NSG-M-4P72P53)\Documents\Local Data\DLC_data\202110701_VM\ProcessedData_Tartare\20210701_VM01_01.mat');
 
clear posData
clear spkData
clear posDataTime
%% insert locations of the electrodes here
channelLocations{1}='centerElec';
channelLocations{2}='antElec';
channelLocations{3}='postElec';

%TO DO: auto pull the end of the file name for the output file name
outPut_20210701_VM01_01.fileName=struct;
outPut_20210701_VM01_01.fileName=load_Data_File;


%% wrap the positional data in

% current interest is finger tip x y
nmsK=fields(K);
outPut_20210701_VM01_01.bodyPart=K.Labels;
outPut_20210701_VM01_01.depth=N.Depth;
outPut_20210701_VM01_01.spikeQuantity=length(N.SpkID);

for ii=1:length(channelLocations)
    outPut_20210701_VM01_01.(channelLocations{ii})=[];
end

%TO DO: INCLUDE Z IF IT'S A FIELD
posData(:,1)=K.Xpos;
posData(:,2)=K.Ypos;
posDataTime=K.Time;

%check that the positional data is on the frame rate expected, which is
%0.0084, or 120fps
for ii=2:length(K.Time)
    tDiff(ii-1)=K.Time(ii)-K.Time(ii-1);
end

expectedfsPos=1/120; %expected frames per second
actualfsPos=mode(tDiff);
if expectedfsPos-actualfsPos > 1
    warning('the fsPos is not the expected');
else
    fsPos=120;
end


%find the frames that are too long for the frame rate, appears to be at the
%front and back, but will mark the huge time gaps to ignore (star 
idx=1;
for ii=1:length(tDiff)
    if tDiff(ii)>actualfsPos+0.0002
        if ii==length(tDiff)
            spuriousPoint(idx)=length(tDiff)+1;
            idx=idx+1;
        elseif ii<length(tDiff)-5 && ii>5 %check that any spurious frames aren't after the first 5 frames, which would indicate it skipped middle of the trial.
            warning('unexpected time gap in the frames at frame %d', ii )
        else
            spuriousPoint(idx)=ii;
            idx=idx+1;
        end        
    end   
end


%Interpolate the data between where it loses a tracker

%TO DO: this will be a crude interpolation, really just make a straight
%line between lost points, but a later step down the road.



%% wrap the neural data in

%TO DO: since some of the units don't last the whole trial, probably should
%track how long they do last and time it up with how many trials they got
%through

for ii=1:length(N.SpkTimes)
    spkData=N.SpkTimes{ii};
    spkStartTime=N.SpkTimes{ii}(1)*1000; %conversion for the start times but in ms
    [output]=Analysis.Brake.dlcProc(spkData, posData, T, K, N, 'spkStartTime', spkStartTime, 'posDataTime', posDataTime, 'spuriousPoint', spuriousPoint);
end

nmsN=fields(N);

