function [outputArg1,outputArg2] = nwbLFPchProc(data, PresentedEmotionIdx, PresentedIdentityIdx, varargin)
%nwbLFPchProc Basic processing function for EMU 
%   Inputs:
%        channel - vector or matrix of channels

% example: 


[varargin, fs] = util.argkeyval('fs',varargin, 500); %sampling rate, default is 500
[varargin, timeStamps] = util.argkeyval('timeStamps',varargin, []); %pull in the behavioral time stamps, which default is just 1 and the end of the recording
[varargin, preTime] = util.argkeyval('preTime',varargin, 0.5); %time before image presentation
[varargin, postTime] = util.argkeyval('preTime',varargin, 2); %time after image presentation
[varargin, filtData] = util.argkeyval('filtData',varargin, []); %for speed, if you want to load in processed data instead of running it each time
[varargin, chNum] = util.argkeyval('chNum',varargin, []); %for speed, if you want to load in processed data instead of running it each time

if isempty(chNum)
    chNum = 1:size(data, 1);
end

if isempty(timeStamps)
    timeStamps(1) = 1;
    timeStamps(2) = length(data);
end

%TO DO, PROBABLY NEED TO ROUND THE PRETIME CONVERSIONS IN CASE




%% filter the data
if isempty(filtData)
    [filtData, params, bandfilter] = Analysis.BasicDataProc.dataPrep(data, 'needsCombfilter', 0, 'fs', fs); %calls this function for my basic processing steps
end

%% separate the data and adjust timestamps
filtD = filtData.dataSpec.dataZ; %pulls z scored spectrogram data.

%Adjust the timestamps. Now timeStampsSeconds will be seconds from the
%start of the recording which will be zero, and can be matched to the time
%output from filtData.
%Each timestamp is a row and each row is fs ms.Convert to seconds and
%subtract one time stamps worth since row 1 = time 0 of the recording data.
timeStampsSeconds = (timeStamps/fs)-1/fs; 

%pull the time from the filt data
timeStampsFiltData = filtData.dataSpec.tplot;

%find the time stamps of all events for cutting the data up
%behavioralIndex now points to the time spot in filtD to take for each
%event stamp
[behavioralIndex, closestValue] = Analysis.emuEmot.timeStampConversion(timeStampsSeconds, timeStampsFiltData);

%convert postTime to units of spectral data
preTimeC = round(preTime/(timeStampsFiltData(2)-timeStampsFiltData(1)));
postTimeC = round(postTime/(timeStampsFiltData(2)-timeStampsFiltData(1)));

%% set up names for the struct
for ff=1:length(chNum)
    ch = num2str(chNum(ff));
    chName{ff} = ['ch' ch];
end

%break up into data epochs centered on image presentation
%timestamp 2 = first image, and every other is new image until the last one
idx1 = 1;
for ii = 2:2:length(behavioralIndex) - 3
    if behavioralIndex(ii) + postTimeC > length(filtD) %make sure data not too long
        break
    else
        for cc = 1:length(chNum)
            %the 
            %by image, second group is responese NEED TO CHECK THAT'S WHAT
            %THE SECOND EVENT IS
            % NEED TO REMOVE THE 0S OR FIGURE OUT HOW TO ONLY DO THE
            % INDICES FOR THE TRIAL.
            nback.image.(chName{cc}).image{PresentedIdentityIdx(idx1)}(:,:,idx1) = filtD(:, behavioralIndex(ii) - (preTimeC): behavioralIndex(ii) + (postTimeC), cc);
            nback.image.(chName{cc}).response{PresentedIdentityIdx(idx1)}(:,:,idx1) = filtD(:, behavioralIndex(ii+1) - (preTimeC): behavioralIndex(ii+1) + (postTimeC), cc);
            
            %by emotion
            nback.emotion.(chName{cc}).image{PresentedEmotionIdx(idx1)}(:,:,idx1) = filtD(:, behavioralIndex(ii) - (preTimeC): behavioralIndex(ii) + (postTimeC), cc);
            nback.emotion.(chName{cc}).response{PresentedEmotionIdx(idx1)}(:,:,idx1) = filtD(:, behavioralIndex(ii+1) - (preTimeC): behavioralIndex(ii+1) + (postTimeC), cc);

%             %image presentation (each cell wil be ID identity for image presentation
%             imageEpochID{PresentedIdentityIdx(idx1),1}(:,:,:) = filtD(:, behavioralIndex(ii) - (preTimeC): behavioralIndex(ii) + (postTimeC),:);
%             %response presentation (each cell wil be ID identity for response NEED TO FIND OUT IF THIS IS ACTUALLY RESPONSE)
%             imageEpochID{PresentedIdentityIdx(idx1),2}(:,:,:) = filtD(:, behavioralIndex(ii+1) - (preTimeC): behavioralIndex(ii+1) + (postTimeC),:);
% 
%             %emotion presentation arrangements
%             %emotion presentation (each cell wil be EMOTION identity for image presentation)
%             emotionEpochID{PresentedEmotionIdx(idx1),1}(:,:,:) = filtD(:, behavioralIndex(ii) - (preTimeC): behavioralIndex(ii) + (postTimeC),:);
%             %emotion presentation (each cell wil be EMOTION identity for response NEED TO FIND OUT IF THIS IS ACTUALLY RESPONSE)
%             emotionEpochID{PresentedEmotionIdx(idx1),2}(:,:,:) = filtD(:, behavioralIndex(ii+1) - (preTimeC): behavioralIndex(ii+1) + (postTimeC),:);

        end
        idx1 = idx1 + 1;
    end
end

figure


