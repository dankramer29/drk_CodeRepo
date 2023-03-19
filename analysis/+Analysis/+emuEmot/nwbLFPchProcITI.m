function [itiFiltered, nbackFilterAllData] = nwbLFPchProcITI(data,varargin)
%nwbLFPchProc Basic processing function for EMU for iti data
%   Inputs:
%        data which is the output of stats.shuffleDerivedBaseline

% example: 


[varargin, fs] = util.argkeyval('fs',varargin, 500); %sampling rate, default is 500
[varargin, filtData] = util.argkeyval('filtData',varargin, []); %for speed, if you want to load in processed data instead of running it each time
[varargin, chNum] = util.argkeyval('chNum',varargin, []); %enter the channels
[varargin, multiTaperWindow] = util.argkeyval('multiTaperWindow',varargin, .2); %window to do spectrogram in with multitaper window in seconds


if isempty(chNum)
    chNum = 1:size(data, 1);
end

%% set up names for the struct
for ff=1:length(chNum)
    ch = num2str(chNum(ff));
    chName{ff} = ['ch' ch];
end

%% this is breaking the data up by session, then filtering, see below for an alternative DO NOT NEED TO DO BOTH, JUST TROUBLESHOOTING


itiFiltered = struct;

for cc = 1:length(chNum) %channels
    for ii = 1:size(data,3) %trials        
        [filtDataTemp] =   Analysis.BasicDataProc.dataPrep(data(:, cc, ii), 'needsCombfilter', 0, 'fs', fs, 'MaxFreq', 150, 'multiTaperWindow', multiTaperWindow); %calls this function for my basic processing stepsdata
        itiFiltered.iti.(chName{cc}).specDzscore(:,:,ii) = filtDataTemp.dataSpec.dataZ;
        itiFiltered.iti.(chName{cc}).specD(:,:,ii) = filtDataTemp.dataSpec.data;
    end
end



itiFiltered.time = filtDataTemp.dataSpec.tplot;
itiFiltered.freq = filtDataTemp.dataSpec.f;


end




