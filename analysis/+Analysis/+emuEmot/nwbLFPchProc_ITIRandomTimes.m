function [itiRandomTime] = nwbLFPchProc_ITIRandomTimes(data, PresentedEmotionIdx, PresentedIdentityIdx, timeStampsImage, timeStampsResponse, varargin)
%nwbLFPchProc Basic processing function to break up the data and make an
%iti that is just a bunch of randomly chosen spots. The idea is to increase
%the iti by grabbing from random spots
%   Inputs:
%        data - vector or matrix of channels, or if processed lfp, then
%        output of Analysis.emuEmot.nwbLFPchProcITI.

% example: 


[varargin, fs] = util.argkeyval('fs',varargin, 500); %sampling rate, default is 500
[varargin, itiCount] = util.argkeyval('itiCount',varargin, 250); %number of 1 second samples that will be taken. there are about 335seconds in each trial, so 250 from each feels about right
[varargin, sdThresh] = util.argkeyval('sdThresh',varargin, 3); %the standard deviation threshold you would cut it over
[varargin, chNum] = util.argkeyval('chNum',varargin, []); %for speed, if you want to load in processed data instead of running it each time
[varargin, itiEpochMinus] = util.argkeyval('itiEpochMinus',varargin, 0.5); %length of the time iti epoch before and after the randomly chosen time point
[varargin, itiEpochPlus] = util.argkeyval('itiEpochPlus',varargin, 0.5); %length of the time iti epochplus

%GOING TO FIND RANDOM TIME POINTS AND PULL THE BANDPASSED AND THE SPEC AND
%CHECK THE BANDPASS AND JUST AUTO CUT ANY THAT ARE OVER A CERTAIN RMS JUST
%LIKE I DO IN THE NOISE. CAN DO THAT RIGHT HERE. 
%WILL JUST TAKE A RANDOM TIME POINT AND THEN CONVERT THAT TIME POINT WITH THE CONVERT FUNCTION TO
%TAKE THE SPEC DATA.

if isempty(chNum)
    chNum = 1:size(data, 1);
end


% ResponseTimesAdj = ResponseTimesAdj/1e6; %convert to seconds.
% if length(ResponseTimesAdj) == length(timeStampsImage)
%     ResponseTimesAdj(1) = [];
% end
% if length(CorrectTrials) == length(timeStampsImage)
%     CorrectTrials(1) = [];
% end

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
%check the total time of the task to figure out how many samples are
%adequate. The trials are typically 335 seconds (5.5 minutes).
timeTot = length(data.iti.(chName{1}).bandPassed.(filterNames{1}))/fs;
timeStampsFiltData = data.time; %grab the time

%convert bandpass time
itiEpochMinusBand = round(itiEpochMinus*fs);
itiEpochPlusBand = round(itiEpochPlus*fs);
%convert time to units of spectral data
itiEpochC = round(itiEpochMinus/(timeStampsFiltData(2)-timeStampsFiltData(1)));
itiEpochCplus = round(itiEpochPlus/(timeStampsFiltData(2)-timeStampsFiltData(1)));



%break up into data epochs centered on image presentation
%timestamp 2 = first image, and every other is new image until the last one
itiRandomTime = struct;

for cc = 1:length(chNum)
        sAll = data.iti.(chName{cc}).bandPassed.(filterNames{7});
        meanS = mean(sAll);                 
        sdS = std(sAll, []);
        meanLine(1:itiEpochMinusBand+itiEpochPlusBand) = meanS;
        sdSline(1:itiEpochMinusBand+itiEpochPlusBand) = sdS;

    idx = 1;
    for ii = 1:itiCount

        %get a random time
        randTime = randi([(1+itiEpochMinusBand), round((length(data.iti.(chName{1}).bandPassed.(filterNames{1}))-itiEpochPlusBand))]);
        randTimeS = randTime/fs;
        %grab the bandpassed data
        randBPdata = data.iti.(chName{cc}).bandPassed.(filterNames{7})(randTime - itiEpochMinusBand: randTime + itiEpochPlusBand);
        mx = max(randBPdata);
        mn = min(randBPdata);
        if mx > (meanS + sdThresh*sdS) || mn < (meanS - sdThresh*sdS)
            %optional plotting for testing, will comment out
            % figure
            % plot(meanLine)
            % hold on
            % plot(meanLine + sdThresh*sdSline)
            % plot(meanLine - sdThresh*sdSline)
            % plot(randBPdata)
        else
            %optional plotting for testing, will comment out plotting
            % figure
            % plot(meanLine)
            % hold on
            % plot(meanLine + sdThresh*sdSline)
            % plot(meanLine - sdThresh*sdSline)
            % plot(randBPdata)

            itiRandomTime.(chName{cc}).bandPassed(idx,:) = randBPdata;

            %convert the time to spectral time
            [behavioralIndexrandTime, closestValuerandTime] = Analysis.emuEmot.timeStampConversion(randTimeS, timeStampsFiltData);
            %get the spectral data
            itiRandomTime.(chName{cc}).specD(:,:,idx) = data.iti.(chName{cc}).specD(:,behavioralIndexrandTime - itiEpochC: behavioralIndexrandTime + itiEpochCplus);
            itiRandomTime.(chName{cc}).RandomTimesInSec(idx) = randTimeS;
            idx = idx + 1;
        end

    end
    itiRandomTime.(chName{cc}).PercKept = length( itiRandomTime.(chName{cc}).RandomTimesInSec(idx))/itiCount;
end

itiRandomTime.bandPass = 0:1/fs:itiEpochMinus+itiEpochPlus;
itiRandomTime.tPlot = 0:timeStampsFiltData(2)-timeStampsFiltData(1):itiEpochMinus+itiEpochPlus;
itiRandomTime.freq = data.freq;



end




