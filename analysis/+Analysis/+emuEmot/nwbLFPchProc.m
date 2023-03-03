function [nback, nbackFilterAllData] = nwbLFPchProc(data, PresentedEmotionIdx, PresentedIdentityIdx, varargin)
%nwbLFPchProc Basic processing function for EMU 
%   Inputs:
%        channel - vector or matrix of channels

% example: 


[varargin, fs] = util.argkeyval('fs',varargin, 500); %sampling rate, default is 500
[varargin, timeStampsImage] = util.argkeyval('timeStampsImage',varargin, []); %pull in the behavioral time stamps, which default is just 1 and the end of the recording
[varargin, timeStampsResponse] = util.argkeyval('timeStampsResponse',varargin, []); %pull in the behavioral time stamps, which default is just 1 and the end of the recording
[varargin, preTime] = util.argkeyval('preTime',varargin, 0.5); %time before image presentation
[varargin, postTime] = util.argkeyval('preTime',varargin, 2); %time after image presentation
[varargin, filtData] = util.argkeyval('filtData',varargin, []); %for speed, if you want to load in processed data instead of running it each time
[varargin, chNum] = util.argkeyval('chNum',varargin, []); %for speed, if you want to load in processed data instead of running it each time
[varargin, filterByTrial] = util.argkeyval('filterByTrial',varargin, false); %if true, will process by breaking the trials up then filters them each time.
[varargin, filterAllData] = util.argkeyval('filterAllData',varargin, true); %if true, will  process by filtering all the data then breaking it up.
[varargin, multiTaperWindow] = util.argkeyval('multiTaperWindow',varargin, .2); %what the window of the spectrogram was to adjust timing
[varargin, spectrogramWinTimeAdj] = util.argkeyval('spectrogramWinTimeAdj',varargin, .2); %for a window for multitapering, can be at the beginning (1), middle (2) or end of the event(3). Adjust here


if isempty(chNum)
    chNum = 1:size(data, 1);
end

if isempty(timeStampsImage)
    timeStampsImage(1) = 1;
    timeStampsImage(2) = length(data);
end

%TO DO, PROBABLY NEED TO ROUND THE PRETIME CONVERSIONS IN CASE

%% set up names for the struct
for ff=1:length(chNum)
    ch = num2str(chNum(ff));
    chName{ff} = ['ch' ch];
end

%% this is breaking the data up by session, then filtering, see below for an alternative DO NOT NEED TO DO BOTH, JUST TROUBLESHOOTING
if filterByTrial 
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
    for ii = 2:2:length(timeStampsImage) - 2
        if timeStampsImage(ii) + postTime > length(data) %make sure data not too long
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
                [filtDataTemp] =   Analysis.BasicDataProc.dataPrep(data(timeStampsImage(ii) - (preTimeC): timeStampsImage(ii) + (postTimeC), cc), 'needsCombfilter', 0, 'fs', fs, 'MaxFreq', 150, 'multiTaperWindow', multiTaperWindow); %calls this function for my basic processing stepsdata
                %by identity
                nback.byidentity.(chName{cc}).image.specDzscore{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.dataZ;
                nback.byidentity.(chName{cc}).image.specD{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.data;
                %by emotion
                nback.byemotion.(chName{cc}).image.specDzscore{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.dataZ;
                nback.byemotion.(chName{cc}).image.specD{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.data;

                %response epoch

                [filtDataTemp] =   Analysis.BasicDataProc.dataPrep(data(timeStampsImage(ii+1) - (preTimeC): timeStampsImage(ii+1) + (postTimeC), cc), 'needsCombfilter', 0, 'fs', fs, 'MaxFreq', 150, 'multiTaperWindow', multiTaperWindow); %calls this function for my basic processing stepsdata
                %by identity
                nback.byidentity.(chName{cc}).response.specDzscore{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.dataZ;
                nback.byidentity.(chName{cc}).response.specD{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.data;
                %by emotion
                nback.byemotion.(chName{cc}).response.specDzscore{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.dataZ;
                nback.byemotion.(chName{cc}).response.specD{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.data;
            end
            idx1 = idx1 + 1;
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%pull the time from the filt data
timeStampsFiltData = data.time;

%% filter the data
%This is code to filter the whole session and break it up
nbackFilterAllData = struct;
if filterAllData
    %% separate the data and adjust timestamps
    for cc = 1:length(chNum)
        filtD = data.iti.(chName{cc}).specD; %pulls non z scored spectrogram data. (the iti struct is not actually the iti, ignore that)

        %Adjust the timestamps. Now timeStampsSeconds will be seconds from the
        %start of the recording which will be zero, and can be matched to the time
        %output from filtData.
        %Each timestamp is a row and each row is fs ms.Convert to seconds and
        %subtract one time stamps worth since row 1 = time 0 of the recording data.
        timeStampsSeconds = (timeStampsImage/fs)-1/fs;



        %find the time stamps of all events for cutting the data up
        %behavioralIndex now points to the time spot in filtD to take for each
        %event stamp
        [behavioralIndex, closestValue] = Analysis.emuEmot.timeStampConversion(timeStampsSeconds, timeStampsFiltData);

        %convert postTime to units of spectral data
        preTimeC = round(preTime/(timeStampsFiltData(2)-timeStampsFiltData(1)));
        postTimeC = round(postTime/(timeStampsFiltData(2)-timeStampsFiltData(1)));

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
end

if filterByTrial 
    timePlot = filtDataTemp.dataSpec.tplot-preTime;
    nback.time = timePlot;
    nback.freq = filtDataTemp.dataSpec.f;
elseif filterAllData 
    timePlot = filtDataTemp.dataSpec.tplot-preTime;
    nbackFilterAllData.time = timePlot;
    nbackFilterAllData.freq = filtData.dataSpec.f;
end

end




