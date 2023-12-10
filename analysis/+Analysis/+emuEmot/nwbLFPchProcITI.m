function [Filtered] = nwbLFPchProcITI(data,varargin)
%nwbLFPchProc Basic processing function for EMU for iti data
%   Inputs:
%        data which is the output of stats.shuffleDerivedBaseline

% example: 


[varargin, fs] = util.argkeyval('fs',varargin, 500); %sampling rate, default is 500
[varargin, filtData] = util.argkeyval('filtData',varargin, []); %for speed, if you want to load in processed data instead of running it each time
[varargin, chNum] = util.argkeyval('chNum',varargin, []); %enter the channels
[varargin, multiTaperWindow] = util.argkeyval('multiTaperWindow',varargin, .2); %window to do spectrogram in with multitaper window in seconds
[varargin, multiTaperWindow] = util.argkeyval('multiTaperWindow',varargin, .2); %window to do spectrogram in with multitaper window in seconds


if isempty(chNum)
    chNum = 1:size(data, 1);
end

%% set up names for the struct

for ff=1:length(chNum)
    if isnumeric(chNum(1))
        ch = num2str(chNum(ff));
        chName{ff} = ['ch' ch];
    else
        chName{ff} = ['ch', chNum{ff}];
    end
end

    

%% this is breaking the data up by session, then filtering, see below for an alternative DO NOT NEED TO DO BOTH, JUST TROUBLESHOOTING


Filtered = struct;
filterClassicBand = [];
bandfilter = [];
for cc = 1:length(chNum) %channels
    for ii = 1:size(data,3) %trials        
        %calls this function for my basic processing stepsdata. does power
        %(signal^2 and spectrogram) and then 10log10. z scored is stored
        %but not used later as better to normalize after shuffle.
        [filtDataTemp, ~, ~, bandfilter, filterClassicBand] =  Analysis.BasicDataProc.dataPrep(data(:, cc, ii),...
            'needsCombfilter', 0, 'fs', fs, 'MaxFreq', 150, 'multiTaperWindow', multiTaperWindow,...
            'DoBandFilterBroad', true, 'bandfilter', bandfilter, 'filterClassBand', filterClassicBand,...
            'hilbertPowerAngle', true, 'Spectrogram', true, 'Freq_BandWidth', 2); 
        %Filtered.iti.(chName{cc}).specDzscore(:,:,ii) = filtDataTemp.dataSpec.dataZ;
        Filtered.iti.(chName{cc}).specD(:,:,ii) = filtDataTemp.dataSpec.data;
        Filtered.iti.(chName{cc}).bandPassed = filtDataTemp.ClassicBand.Power;
        Filtered.iti.(chName{cc}).bandPassed.filter1to200 = data(:,cc); %this has already been made by broad bandpassing
        Filtered.iti.(chName{cc}).Hilbert = filtDataTemp.Hilbert;
    end
end



Filtered.time = filtDataTemp.dataSpec.tplot;
Filtered.freq = filtDataTemp.dataSpec.f;


end




