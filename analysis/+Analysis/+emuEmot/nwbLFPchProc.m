function [nback, nbackFilterAllData] = nwbLFPchProc(data, PresentedEmotionIdx, PresentedIdentityIdx, varargin)
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
[varargin, filterByTrial] = util.argkeyval('filterByTrial',varargin, true); %if true, will process by breaking the trials up then filters them each time.
[varargin, filterAllData] = util.argkeyval('filterAllData',varargin, false); %if true, will  process by filtering all the data then breaking it up.

if isempty(chNum)
    chNum = 1:size(data, 1);
end

if isempty(timeStamps)
    timeStamps(1) = 1;
    timeStamps(2) = length(data);
end

%TO DO, PROBABLY NEED TO ROUND THE PRETIME CONVERSIONS IN CASE

%% set up names for the struct
for ff=1:length(chNum)
    ch = num2str(chNum(ff));
    chName{ff} = ['ch' ch];
end

%% this is breaking the data up by session, then filtering, see below for an alternative DO NOT NEED TO DO BOTH, JUST TROUBLESHOOTING
if filterByTrial == 1
    %% pre and post time conversion
    preTimeC = round(preTime * fs);
    postTimeC = round(postTime * fs);


    %break up into data epochs centered on image presentation
    %timestamp 2 = first image, and every other is new image until the last one
    nback = struct;
    idx1 = 1;
    idxID = 1;
    idxEmot = 1;
    idxID1 = 0; idxEmot1 = 0;
    idxID2 = 0; idxEmot2 = 0;
    idxID3 = 0; idxEmot3 = 0;
    for ii = 2:2:length(timeStamps) - 2
        if timeStamps(ii) + postTime > length(data) %make sure data not too long
            break
        else
            switch PresentedIdentityIdx(idx1)
                case 1
                    idxID1 = idxID1 +1;
                    idxID = idxID1;
                case 2
                    idxID2 = idxID2 +1;
                    idxID = idxID2;
                case 3
                    idxID3 = idxID3 +1;
                    idxID = idxID3;
            end
            switch PresentedEmotionIdx(idx1)
                case 1
                    idxEmot1 = idxEmot1 +1;
                    idxEmot = idxEmot1;
                case 2
                    idxEmot2 = idxEmot2 +1;
                    idxEmot = idxEmot2;
                case 3
                    idxEmot3 = idxEmot3 +1;
                    idxEmot = idxEmot3;
            end
            for cc = 1:length(chNum)
                %the
                %by image, second group is responese NEED TO CHECK THAT'S WHAT
                %THE SECOND EVENT IS
                % NEED TO REMOVE THE 0S OR FIGURE OUT HOW TO ONLY DO THE
                % INDICES FOR THE TRIAL.

                %image presentation epoch
                [filtDataTemp] =   Analysis.BasicDataProc.dataPrep(data(timeStamps(ii) - (preTimeC): timeStamps(ii) + (postTimeC), cc), 'needsCombfilter', 0, 'fs', fs, 'MaxFreq', 150); %calls this function for my basic processing stepsdata
                %by identity
                nback.byidentity.(chName{cc}).image.specDzscore{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.dataZ;
                nback.byidentity.(chName{cc}).image.specD{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.data;
                %by emotion
                nback.byemotion.(chName{cc}).image.specDzscore{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.dataZ;
                nback.byemotion.(chName{cc}).image.specD{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.data;

                %response epoch

                [filtDataTemp] =   Analysis.BasicDataProc.dataPrep(data(timeStamps(ii+1) - (preTimeC): timeStamps(ii+1) + (postTimeC), cc), 'needsCombfilter', 0, 'fs', fs, 'MaxFreq', 150); %calls this function for my basic processing stepsdata
                %by identity
                nback.byidentity.(chName{cc}).response.specDzscore{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.dataZ;
                nback.byidentity.(chName{cc}).response.specD{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.data;
                %by emotion
                nback.byemotion.(chName{cc}).response.specDzscore{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.dataZ;
                nback.byemotion.(chName{cc}).response.specD{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.data;
                %
                %             nback.byidentity.(chName{cc}).response{PresentedIdentityIdx(idx1)}(:,:,idxID) = data(:, timeStamps(ii+1) - (preTime): timeStamps(ii+1) + (postTime), cc);
                %              %by emotion
                %             nback.byemotion.(chName{cc}).image{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = data(:, timeStamps(ii) - (preTime): timeStamps(ii) + (postTime), cc);
                %             nback.byemotion.(chName{cc}).response{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = data(:, timeStamps(ii+1) - (preTime): timeStamps(ii+1) + (postTime), cc);
                %
                %
                %             nback.byidentity.(chName{cc}).response{PresentedIdentityIdx(idx1)}(:,:,idxID) = data(:, timeStamps(ii+1) - (preTime): timeStamps(ii+1) + (postTime), cc);
                %
                %             %by emotion
                %             nback.byemotion.(chName{cc}).image{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = data(:, timeStamps(ii) - (preTime): timeStamps(ii) + (postTime), cc);
                %             nback.byemotion.(chName{cc}).response{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = data(:, timeStamps(ii+1) - (preTime): timeStamps(ii+1) + (postTime), cc);
            end
            idx1 = idx1 + 1;
        end
    end
end






%% filter the data
%This is code to filter the whole session and break it up
nbackFilterAllData = struct;
if filterAllData == 1
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
    idxID = 1;
    idxEmot = 1;
    idxID1 = 0; idxEmot1 = 0;
    idxID2 = 0; idxEmot2 = 0;
    idxID3 = 0; idxEmot3 = 0;
    for ii = 2:2:length(behavioralIndex) - 2
        if behavioralIndex(ii) + postTimeC > length(filtD) %make sure data not too long
            break
        else
            switch PresentedIdentityIdx(idx1)
                case 1
                    idxID1 = idxID1 +1;
                    idxID = idxID1;
                case 2
                    idxID2 = idxID2 +1;
                    idxID = idxID2;
                case 3
                    idxID3 = idxID3 +1;
                    idxID = idxID3;
            end
            switch PresentedEmotionIdx(idx1)
                case 1
                    idxEmot1 = idxEmot1 +1;
                    idxEmot = idxEmot1;
                case 2
                    idxEmot2 = idxEmot2 +1;
                    idxEmot = idxEmot2;
                case 3
                    idxEmot3 = idxEmot3 +1;
                    idxEmot = idxEmot3;
            end
            for cc = 1:length(chNum)
                %the
                %by image, second group is responese NEED TO CHECK THAT'S WHAT
                %THE SECOND EVENT IS
                % NEED TO REMOVE THE 0S OR FIGURE OUT HOW TO ONLY DO THE
                % INDICES FOR THE TRIAL.


                nbackFilterAllData.byidentity.(chName{cc}).image{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtD(:, behavioralIndex(ii) - (preTimeC): behavioralIndex(ii) + (postTimeC), cc);
                nbackFilterAllData.byidentity.(chName{cc}).response{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtD(:, behavioralIndex(ii+1) - (preTimeC): behavioralIndex(ii+1) + (postTimeC), cc);

                %by emotion
                nbackFilterAllData.byemotion.(chName{cc}).image{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtD(:, behavioralIndex(ii) - (preTimeC): behavioralIndex(ii) + (postTimeC), cc);
                nbackFilterAllData.byemotion.(chName{cc}).response{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtD(:, behavioralIndex(ii+1) - (preTimeC): behavioralIndex(ii+1) + (postTimeC), cc);
            end
            idx1 = idx1 + 1;
        end
    end
end

if filterByTrial == 1
    nback.time = filtData.dataSpec.tplot;
    nback.freq = filtData.dataSpec.f;
elseif filterAllData == 1
    nbackFilterAllData.time = filtData.dataSpec.tplot;
    nbackFilterAllData.freq = filtData.dataSpec.f;
end

end




