function [outputArg1,outputArg2] = nwbLFPchProc(data, macroTimeStamps varargin)
%nwbLFPchProc Basic processing function for EMU 
%   Inputs:
%        channel - vector or matrix of channels

% example: 


[varargin, fs] = util.argkeyval('fs',varargin, 500); %sampling rate, default is 500
[varargin, timeStamps] = util.argkeyval('timeStamps',varargin, []); %pull in the behavioral time stamps, which default is just 1 and the end of the recording
[varargin, preTime] = util.argkeyval('preTime',varargin, 0.5); %time before image presentation
[varargin, postTime] = util.argkeyval('preTime',varargin, 2); %time after image presentation

if isempty(timeStamps)
    timeStamps(1) = 1;
    timeStamps(2) = length(data);
end

%TO DO, PROBABLY NEED TO ROUND THE PRETIME CONVERSIONS IN CASE
%NEED TO MATCH THE TIME STAMPS, IS A LITTLE ANNOYING, BUT WILL NEED TO
%MATCH BEH_TIMESTAMPS TO MA_TIMESTAMPS IN ORDER TO FIND THE CORRECT INDEX
%INTO THE MACROWIRE DATA. PROBABLY BEST TO PREPROCESS THE TIMESTAMPS AND
%THEN INPUT THAT INTO THIS FUNCTION



%% filter the data

[filtData, params, bandfilter] = Analysis.BasicDataProc.dataPrep(data, 'needsCombfilter', 0, 'fs', fs); %calls this function for my basic processing steps

%% separate the data
filtD = filtData.dataSpec.dataZ;

%break up into data epochs centered on image presentation
%timestamp 2 = first image, and every other is new image
idx1 = 1;
for ii = 2:2:length(timeStamps) - 3
    if timeStamps(ii+1) + (fs*postTime) > length(filtD) %make sure data not too long
        break
    else
    %image presentation arrangements
    %image presentation (each cell wil be ID identity for image presentation)
    imageEpochID{PresentedIdentityIdx(idx1),1}(:,:,idx1) = filtD(:, timeStamps(ii) - (fs * preTime): timeStamps(ii) + (fs * postTime),:);
    %response presentation (each cell wil be ID identity for response NEED TO FIND OUT IF THIS IS ACTUALLY RESPONSE)
    imageEpochID{PresentedIdentityIdx(idx1),2}(:,:,idx1) = filtD(:, timeStamps(ii+1) - (fs * preTime): timeStamps(ii+1) + (fs * postTime),:);

    %emotion presentation arrangements
    %emotion presentation (each cell wil be EMOTION identity for image presentation)
    emotionEpochID{PresentedEmotionIdx(idx1),1}(:,:,idx1) = filtD(:, timeStamps(ii) - (fs * preTime): timeStamps(ii) + (fs * postTime),:);
    %emotion presentation (each cell wil be EMOTION identity for response NEED TO FIND OUT IF THIS IS ACTUALLY RESPONSE)
    emotionEpochID{PresentedEmotionIdx(idx1),2}(:,:,idx1) = filtD(:, timeStamps(ii+1) - (fs * preTime): timeStamps(ii+1) + (fs * postTime),:);

    idx1 = idx1 + 1;
    end
end