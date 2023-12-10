function [nback, itiFiltered] = nwbLFPchProc(data, PresentedEmotionIdx, PresentedIdentityIdx, timeStampsImage, timeStampsResponse, varargin)
%nwbLFPchProc Basic processing function for EMU 
%   Inputs:
%        data - vector or matrix of channels, or if processed lfp, then
%        output of Analysis.emuEmot.nwbLFPchProcITI.

% example: 


[varargin, fs] = util.argkeyval('fs',varargin, 500); %sampling rate, default is 500

[varargin, ImagepreTime] = util.argkeyval('ImagepreTime',varargin, 0.5); %time before image presentation
[varargin, ResponsepreTime] = util.argkeyval('ResponsepreTime',varargin, 1); %time before response 
[varargin, ImagepostTime] = util.argkeyval('ImagepostTime',varargin, 2); %time after image presentation
[varargin, ResponsepostTime] = util.argkeyval('ResponsepostTime',varargin, 0.5); %time after response
[varargin, filtData] = util.argkeyval('filtData',varargin, []); %for speed, if you want to load in processed data instead of running it each time
[varargin, chNum] = util.argkeyval('chNum',varargin, []); %for speed, if you want to load in processed data instead of running it each time
[varargin, CorrectTrials] = util.argkeyval('CorrectTrials',varargin, 1); %Input correct or incorrect trials, if you don't enter, it will just place a 1 and will be meaningless
[varargin, ResponseTimesAdj] = util.argkeyval('ResponseTimesAdj',varargin, 1e6); %Response Times in microseconds

[varargin, filterByTrial] = util.argkeyval('filterByTrial',varargin, false); %if true, will process by breaking the trials up then filters them each time.
[varargin, filterAllData] = util.argkeyval('filterAllData',varargin, true); %if true, will  process by filtering all the data then breaking it up.
[varargin, multiTaperWindow] = util.argkeyval('multiTaperWindow',varargin, .2); %what the window of the spectrogram was to adjust timing
[varargin, spectrogramWinTimeAdj] = util.argkeyval('spectrogramWinTimeAdj',varargin, 1); %for a window for multitapering, can be at the beginning (1), middle (2) or end of the window(3). Adjust here
[varargin, itiTime] = util.argkeyval('itiTime',varargin, 3); %input the times for the iti windows, which is after the response until the image presentation
[varargin, itiEpoch] = util.argkeyval('itiTime',varargin, 1.5); %length of the time iti epoch start after the response and goes to the itiEpochPlus, so the iti length will be itiEpochPlus-itiEpoch
[varargin, itiEpochPlus] = util.argkeyval('itiTime',varargin, 2.5); %length of the time iti epochplus


if isempty(chNum)
    chNum = 1:size(data, 1);
end

ResponseTimesAdj = ResponseTimesAdj/1e6; %convert to seconds.
if length(ResponseTimesAdj) == length(timeStampsImage)
    ResponseTimesAdj(1) = [];
end
if length(CorrectTrials) == length(timeStampsImage)
    CorrectTrials(1) = [];
end

switch spectrogramWinTimeAdj
    case 1
        windowCenter = 0;
    case 2
        windowCenter = round(multiTaperWindow/2);
    case 3
        windowCenter = multiTaperWindow;
end

%% set up names for the struct
for ff=1:length(chNum)
    ch = num2str(chNum(ff));
    chName{ff} = ['ch' ch];
end

filterNames = fieldnames(data.iti.(chName{1}).bandPassed);


%% this is breaking the data up by session, and can filter this way, or break up band passed data
% CURRENTLY USING BOTH AS IT BREAKS UP THE BANDPASSED OR HILBERT DATA.

%% pre and post time conversion
preTimeC = round(ImagepreTime * fs);
postTimeC = round(ImagepostTime * fs);
preTimeResC = round(ResponsepreTime * fs);
postTimeResC = round(ResponsepostTime * fs);
itiEpochBand = round(itiEpoch*fs);
itiEpochPlusBand = round(itiEpochPlus*fs);



%break up into data epochs centered on image presentation
%timestamp 2 = first image, and every other is new image until the last one
nback = struct;

for cc = 1:length(chNum)
    idx1 = 1;
    idxID = 1;
    idxEmot = 1;
    idxIti = 1;

    idxID1 = 0; idxEmot1 = 0;
    idxID2 = 0; idxEmot2 = 0;
    idxID3 = 0; idxEmot3 = 0;
    for ii = 1:length(timeStampsImage)
        if timeStampsImage(ii) + postTimeC > length(data.iti.(chName{1}).bandPassed.(filterNames{1}))...
                || timeStampsResponse(ii) + postTimeC > length(data.iti.(chName{1}).bandPassed.(filterNames{1}))%make sure data not too long
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

            %the
            %by image, second group is responese
            for fn = 1:length(filterNames)
                if fn == 1
                    nback.byidentity.(chName{cc}).image.Hilbert.Power{PresentedIdentityIdx(idx1)}(:,:,idxID)...
                        = data.iti.(chName{cc}).Hilbert.Power(:,timeStampsImage(ii) - (preTimeC): timeStampsImage(ii) + (postTimeC));
                    nback.byidentity.(chName{cc}).image.Hilbert.Angle{PresentedIdentityIdx(idx1)}(:,:,idxID)...
                        = data.iti.(chName{cc}).Hilbert.Angle(:,timeStampsImage(ii) - (preTimeC): timeStampsImage(ii) + (postTimeC));

                end
                nback.byidentity.(chName{cc}).image.bandPassed.(filterNames{fn}){PresentedIdentityIdx(idx1)}(idxID,:)...
                    = data.iti.(chName{cc}).bandPassed.(filterNames{fn})(timeStampsImage(ii) - (preTimeC): timeStampsImage(ii) + (postTimeC));
                if ii >1
                    if fn == 1
                        nback.byidentity.(chName{cc}).response.Hilbert.Power{PresentedIdentityIdx(idx1)}(:,:,idxID)...
                            = data.iti.(chName{cc}).Hilbert.Power(:,timeStampsResponse(ii) - (preTimeResC): timeStampsResponse(ii) + (postTimeResC));
                        nback.byidentity.(chName{cc}).response.Hilbert.Angle{PresentedIdentityIdx(idx1)}(:,:,idxID)...
                            = data.iti.(chName{cc}).Hilbert.Angle(:,timeStampsResponse(ii) - (preTimeResC): timeStampsResponse(ii) + (postTimeResC));
                        % grab an iti of the hilbert.
                        if size(data.iti.(chName{cc}).Hilbert.Power,2) < timeStampsResponse(ii) + itiEpochPlusBand
                            continue
                        else
                            itiFiltered.(chName{cc}).Hilbert.Power(:,:,idxIti) = data.iti.(chName{cc}).Hilbert.Power(:, timeStampsResponse(ii) + itiEpochBand: timeStampsResponse(ii) + itiEpochPlusBand);%will take 1 second of iti.
                            itiFiltered.(chName{cc}).Hilbert.Angle(:,:,idxIti) = data.iti.(chName{cc}).Hilbert.Angle(:, timeStampsResponse(ii) + itiEpochBand: timeStampsResponse(ii) + itiEpochPlusBand);%will take 1 second of iti.
                            idxIti = idxIti +1;
                        end
                    end
                    nback.byidentity.(chName{cc}).response.bandPassed.(filterNames{fn}){PresentedIdentityIdx(idx1)}(idxID,:)...
                        = data.iti.(chName{cc}).bandPassed.(filterNames{fn})(timeStampsResponse(ii) - (preTimeResC): timeStampsResponse(ii) + (postTimeResC));
                end
            end
            for fn = 1:length(filterNames) %%
                if fn == 1
                    nback.byemotion.(chName{cc}).image.Hilbert.Power{PresentedEmotionIdx(idx1)}(:,:,idxEmot)...
                        = data.iti.(chName{cc}).Hilbert.Power(:,timeStampsImage(ii) - (preTimeC): timeStampsImage(ii) + (postTimeC));
                    nback.byemotion.(chName{cc}).image.Hilbert.Angle{PresentedEmotionIdx(idx1)}(:,:,idxEmot)...
                        = data.iti.(chName{cc}).Hilbert.Angle(:,timeStampsImage(ii) - (preTimeC): timeStampsImage(ii) + (postTimeC));
                end
                nback.byemotion.(chName{cc}).image.bandPassed.(filterNames{fn}){PresentedEmotionIdx(idx1)}(idxEmot,:)...
                    = data.iti.(chName{cc}).bandPassed.(filterNames{fn})(timeStampsImage(ii) - (preTimeC): timeStampsImage(ii) + (postTimeC));
                if ii >1
                    if fn == 1
                        nback.byemotion.(chName{cc}).response.Hilbert.Power{PresentedEmotionIdx(idx1)}(:,:,idxEmot)...
                            = data.iti.(chName{cc}).Hilbert.Power(:,timeStampsResponse(ii) - (preTimeResC): timeStampsResponse(ii) + (postTimeResC));
                        nback.byemotion.(chName{cc}).response.Hilbert.Angle{PresentedEmotionIdx(idx1)}(:,:,idxEmot)...
                            = data.iti.(chName{cc}).Hilbert.Angle(:,timeStampsResponse(ii) - (preTimeResC): timeStampsResponse(ii) + (postTimeResC));
                    end
                    nback.byemotion.(chName{cc}).response.bandPassed.(filterNames{fn}){PresentedEmotionIdx(idx1)}(idxEmot,:)...
                        = data.iti.(chName{cc}).bandPassed.(filterNames{fn})(timeStampsResponse(ii) - (preTimeResC): timeStampsResponse(ii) + (postTimeResC));
                end
            end

            %THIS IS WHERE IT IS BROKEN UP BY TRIAL AND FILTERED LIKE THAT,
            %BETTER TO FILTER THE WHOLE THING.
            if filterByTrial
                %image presentation epoch
                [filtDataTemp] =   Analysis.BasicDataProc.dataPrep(data(timeStampsImage(ii) - (preTimeC): timeStampsImage(ii) + (postTimeC), cc), 'needsCombfilter', 0, 'fs', fs, 'MaxFreq', 150, 'multiTaperWindow', multiTaperWindow); %calls this function for my basic processing stepsdata
                %by identity
                nback.byidentity.(chName{cc}).image.specDzscore{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.dataZ;
                nback.byidentity.(chName{cc}).image.specD{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.data;
                %by emotion
                nback.byemotion.(chName{cc}).image.specDzscore{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.dataZ;
                nback.byemotion.(chName{cc}).image.specD{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.data;

                %response epoch
                if ii~=1
                    [filtDataTemp] =   Analysis.BasicDataProc.dataPrep(data(timeStampsResponse(ii) - (preTimeC): timeStampsResponse(ii) + (postTimeC), cc), 'needsCombfilter', 0, 'fs', fs, 'MaxFreq', 150, 'multiTaperWindow', multiTaperWindow); %calls this function for my basic processing stepsdata
                    %by identity
                    nback.byidentity.(chName{cc}).response.specDzscore{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.dataZ;
                    nback.byidentity.(chName{cc}).response.specD{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtDataTemp.dataSpec.data;
                    %by emotion
                    nback.byemotion.(chName{cc}).response.specDzscore{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.dataZ;
                    nback.byemotion.(chName{cc}).response.specD{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtDataTemp.dataSpec.data;
                end
            end
        end
        idx1 = idx1 + 1;
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% filter the data
%break up prefiltered spectrogram data
if filterAllData
    %pull the time from the filt data
    timeStampsFiltData = data.time;

    %% separate the data and adjust timestamps
    for cc = 1:length(chNum)
        %currently not pulling the specDz scored data, can but mostly z
        %scoring after running
        filtD = data.iti.(chName{cc}).specD; %pulls non z scored spectrogram data. (the iti struct is not actually the iti, ignore that)

        %Adjust the timestamps. Now timeStampsSeconds will be seconds from the
        %start of the recording which will be zero, and can be matched to the time
        %output from filtData.
        %Each timestamp is a row and each row is fs ms.Convert to seconds and
        %subtract one time stamps worth since row 1 = time 0 of the recording data.
        timeStampsImageSeconds = (timeStampsImage/fs)-1/fs;
        timeStampsResponseSeconds = (timeStampsResponse/fs)-1/fs;



        %find the time stamps of all events for cutting the data up
        %behavioralIndex now points to the time spot in filtD to take for each
        %event stamp
        [behavioralIndexImage, closestValueImage] = Analysis.emuEmot.timeStampConversion(timeStampsImageSeconds, timeStampsFiltData);
        [behavioralIndexResponse, closestValueResponse] = Analysis.emuEmot.timeStampConversion(timeStampsResponseSeconds, timeStampsFiltData);
        
        %convert postTime to units of spectral data
        preTimeC = round(ImagepreTime/(timeStampsFiltData(2)-timeStampsFiltData(1)));
        postTimeC = round(ImagepostTime/(timeStampsFiltData(2)-timeStampsFiltData(1)));
        preTimeCRes = round(ResponsepreTime/(timeStampsFiltData(2)-timeStampsFiltData(1)));
        postTimeCRes = round(ResponsepostTime/(timeStampsFiltData(2)-timeStampsFiltData(1)));
        itiEpochC = round(itiEpoch/(timeStampsFiltData(2)-timeStampsFiltData(1)));
        itiEpochCplus = round(itiEpochPlus/(timeStampsFiltData(2)-timeStampsFiltData(1)));

        %break up into data epochs centered on image presentation
        %timestamp 2 = first image, and every other is new image until the last one
        idx1 = 1;
        idxID = 1;
        idxEmot = 1;
        idxID1 = 0; idxEmot1 = 0;
        idxID2 = 0; idxEmot2 = 0;
        idxID3 = 0; idxEmot3 = 0;
        idxIti = 1;
        for ii = 1:length(behavioralIndexImage)
            if behavioralIndexImage(ii) + postTimeC > length(filtD) || behavioralIndexResponse(ii) + postTimeC > length(filtD)%make sure data not too long
                break
            else
                if ii > 2
                    if itiTime(idxIti) < 2.5
                        warning(['iti time is less than 2 seconds for itiTime ' num2str(idxIti)]) %warn if not long enough, but will just spill into the preimage presentation time
                    end
                    if size(filtD,2) < behavioralIndexResponse(ii) + itiEpochCplus
                        continue
                    else
                        itiFiltered.(chName{cc}).specD(:,:,idxIti) = filtD(:, behavioralIndexResponse(ii) + itiEpochC: behavioralIndexResponse(ii) + itiEpochCplus);%will take 1 second of iti.
                    end
                    idxIti = idxIti +1;
                end
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
                %by identity
                nback.byidentity.(chName{cc}).image.specD{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtD(:, behavioralIndexImage(ii) - (preTimeC): behavioralIndexImage(ii) + (postTimeC));
                if ii ~= 1 %no response for the first one, is a nan
                    nback.byidentity.(chName{cc}).response.specD{PresentedIdentityIdx(idx1)}(:,:,idxID) = filtD(:, behavioralIndexResponse(ii) - (preTimeCRes): behavioralIndexResponse(ii) + (postTimeCRes));
                    nback.byidentity.(chName{cc}).responseTimesInSec{PresentedIdentityIdx(idx1)}(idxID,:) = ResponseTimesAdj(ii-1);
                    nback.byidentity.(chName{cc}).correctTrial{PresentedIdentityIdx(idx1)}(idxID,:) = CorrectTrials(ii-1);
                end

                %by emotion
                nback.byemotion.(chName{cc}).image.specD{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtD(:, behavioralIndexImage(ii) - (preTimeC): behavioralIndexImage(ii) + (postTimeC));
                if ii ~=1
                    nback.byemotion.(chName{cc}).response.specD{PresentedEmotionIdx(idx1)}(:,:,idxEmot) = filtD(:, behavioralIndexResponse(ii) - (preTimeCRes): behavioralIndexResponse(ii) + (postTimeCRes));
                    nback.byemotion.(chName{cc}).responseTimesInSec{PresentedIdentityIdx(idx1)}(idxID,:) = ResponseTimesAdj(ii-1);
                    nback.byemotion.(chName{cc}).correctTrial{PresentedIdentityIdx(idx1)}(idxID,:) = CorrectTrials(ii-1);
                end
                idx1 = idx1 + 1;
            end
        end
    end
end

if filterByTrial 
    timePlot = filtDataTemp.dataSpec.tplot-ImagepreTime;
    nback.tPlot = timePlot;
    nback.freq = filtDataTemp.dataSpec.f;
elseif filterAllData 
    timeInterval = timeStampsFiltData(1);
    timePlotImage = -ImagepreTime:timeInterval:((preTimeC+postTimeC)*timeInterval-ImagepreTime);
    timePlotResponse = -ResponsepreTime:timeInterval:ResponsepostTime+timeInterval;
    timePlotImage = timePlotImage + windowCenter; %this adjusts the time window for plotting.
    timePlotResponse = timePlotResponse + windowCenter; %this adjusts the time window for plotting.
    nback.tPlotImage = timePlotImage;
    nback.tPlotResponse = timePlotResponse;
    nback.freq = data.freq;
    nback.freqHilbert = data.iti.(chName{1}).Hilbert.f;

end

nback.tPlotImageBandPass = -ImagepreTime:1/fs:ImagepostTime;
nback.tPlotResponseBandPass = -ResponsepreTime:1/fs:ResponsepostTime;

end




