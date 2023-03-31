function [summaryStats] = comparePowerResponseTime(nback, identityTaskLFP, emotionTaskLFP, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%   ALSO WANT TO LOOK AT THE TIMING OF THE PEAKS FOR WHEN TASK RELEVANT AND
%   TASK IRRELEVANT

[varargin, plt]=util.argkeyval('plt', varargin, 1); %toggle on or off if you want to plot
[varargin, timeMinMax]=util.argkeyval('timeMin', varargin, [.100 .700]); %Time, in S, that you want to find the peaks between 
[varargin, freqMinMax]=util.argkeyval('freqMinMax', varargin, [50 150]); %Freq, that you want to find the peaks between 
[varargin, chName]=util.argkeyval('chName', varargin, 'chX'); %for arranging the outputs by channel
[varargin, patientName]=util.argkeyval('patientName', varargin, 'PtX'); %for storing a total table


summaryStats = struct;
summaryStats.timeMinMax = timeMinMax;
summaryStats.freqMinMax = freqMinMax;

%grab fields
chNum = fieldnames(nback);
conditionName = fieldnames(nback.(chNum{1}));
resultName = fieldnames(nback.(chNum{1}).(conditionName{1}));
resultNameAll = fieldnames(nback.(chNum{1}).(conditionName{4}));

bandNames = fieldnames(identityTaskLFP.byidentity.(chNum{1}).image.bandPassed);

bTT = identityTaskLFP.tPlotImageBandPass;
tt = identityTaskLFP.tPlotImage;
ff = identityTaskLFP.freq;

%% find the indices of the times in bandpassed
[~, tMinBand] = min(abs(bTT-timeMinMax(1)));
[~, tMaxBand] = min(abs(bTT-timeMinMax(2)));

%%
%look at high gamma for areas that were positive
%NOTE: THIS IS GOING TO KEEP IT TASK RELEVANT RIGHT NOW MEANING ONLY
%   LOOKING AT IDS FOR THE IDENTITY TASK AND EMOTIONS FOR THE EMOTION TASK
T2 = [];
for cc = 1:length(chNum)
    %identity task
    T1 = [];
    ClusterCenter = [];
    TstatCluster = [];
    ImageType = [];
    MaxValue =[];
    pkIndex = [];
    TimeofMax=[];
    CorrectResponseId = [];
    ResponseTimeId = [];
    SecondTrial = [];
    idx2 = 1;   
    for nn = 1:3  %runs through each id      
        T1 = [];
        ClusterCenter = [];
        TstatCluster = [];
        ImageType = [];
        MaxValue =[];
        pkIndex = [];
        TimeofMax=[];
        CorrectResponseEm = [];
        ResponseTimeEm = [];
        SecondTrial = [];
        CorrectResponseTemp = identityTaskLFP.byidentity.(chNum{cc}).correctTrial{idx2};
        ResponseTimeTemp = identityTaskLFP.byidentity.(chNum{cc}).responseTimesInSec{idx2};
        CorrectResponseId = vertcat(CorrectResponseId, CorrectResponseTemp);
        ResponseTimeId = vertcat(ResponseTimeId, ResponseTimeTemp);
        %by identity that is statistically significant
        if nnz(nnz(nback.(chNum{cc}).(conditionName{nn}).(resultName{3})))>0
            for ii = 1:size(nback.(chNum{cc}).(conditionName{nn}).(resultName{4}),1)
                %check the centroid is in the high gamma range in the
                %region after image presentation
                cent = nback.(chNum{cc}).(conditionName{nn}).(resultName{4})(ii,:);
                centA(1) = tt(round(cent(1))); centA(2) = ff(round(cent(2)));
                normS1 = normalize(nback.(chNum{cc}).(conditionName{nn}).(resultName{1}),2);
                %check that it's between the frequencies desired
                if true %centA(2)>=freqMinMax(1) && centA(2)<=freqMinMax(2) && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2) && normS1(round(cent(2)),round(cent(1)))>0
                    bData = identityTaskLFP.byidentity.(chNum{cc}).image.bandPassed.(bandNames{6}){idx2};
%                     meanbData = mean(bData,1);
%                     figure; plot(bTT,normalize(meanbData), 'LineWidth', 3); hold on; plot(bTT,normalize(bData,2))
%                     figure; imagesc(tt,ff, normalize(nback.(chNum{cc}).(conditionName{nn}).(resultName{1}),2)); axis xy
%                     hold on; plot(centA(1), centA(2), '*b');
                    for jj = 1:size(bData,1)
                        RecordingLocation(jj,1) = chName{cc};
                        ChannelNumber{jj,1} = chNum{cc};
                        PatientName{jj,1} =  patientName;
                        TrialType{jj,1} = 'identityTask';
                        TimeMinMax(jj,:) = timeMinMax;
                        FreqMinMax(jj,:) = freqMinMax;
                        ClusterCenter(jj,:) = centA;
                        TstatCluster(jj,1) = nback.(chNum{cc}).(conditionName{nn}).(resultName{5})(ii,1); %if it's gamma, grab that tstat
                        ImageType{jj,1} = (conditionName{nn});
                        [MaxValue(jj,1), pkIndex] = max(bData(jj,tMinBand:tMaxBand));
                        TimeofMax(jj,1) = (pkIndex + tMinBand)/1000; %get the peak time of the filtered and adjust to ms                     
                        SecondTrial(jj,1) = identityTaskLFP.secondTrial;
                        CorrectResponse(jj,1) = identityTaskLFP.byidentity.(chNum{cc}).correctTrial{idx2}(jj);
                        ResponseTime(jj,1) = identityTaskLFP.byidentity.(chNum{cc}).responseTimesInSec{idx2}(jj);
                        RecordingLocation(jj,1) = chName{cc};
                        jj = jj + 1;
                    end
                   T1 = table(PatientName, RecordingLocation, ChannelNumber, TrialType, TimeMinMax, FreqMinMax, ImageType, ClusterCenter, TstatCluster,  MaxValue, TimeofMax,...
                        CorrectResponse, ResponseTime, SecondTrial); 
                end
            end
        end
        T2 = [T2; T1];        
        idx2 = idx2+1;
    end
   
    %% emotion task
   
    idx2 = 1;   
    for nn = 1:3 %runs through each emotion
        T1 = [];
        ClusterCenter = [];
        TstatCluster = [];
        ImageType = [];
        MaxValue =[];
        pkIndex = [];
        TimeofMax=[];
        CorrectResponseEm = [];
        ResponseTimeEm = [];
        SecondTrial = [];
        CorrectResponseTemp = emotionTaskLFP.byemotion.(chNum{cc}).correctTrial{idx2};
        ResponseTimeTemp = emotionTaskLFP.byemotion.(chNum{cc}).responseTimesInSec{idx2};
        CorrectResponseEm = vertcat(CorrectResponseEm, CorrectResponseTemp);
        ResponseTimeEm = vertcat(ResponseTimeEm, ResponseTimeTemp);  
        %run through each significant cluster
        if nnz(nnz(nback.(chNum{cc}).(conditionName{nn}).(resultName{8})))>0
            for ii = 1:size(nback.(chNum{cc}).(conditionName{nn}).(resultName{9}),1)
                %check the centroid is in the high gamma range (or whatever cluster) in the
                %region after image presentation
                cent = nback.(chNum{cc}).(conditionName{nn}).(resultName{9})(ii,:);
                centA(1) = tt(round(cent(1))); centA(2) = ff(round(cent(2)));
                normS1 = normalize(nback.(chNum{cc}).(conditionName{nn}).(resultName{6}),2);
                if true %centA(2)>=freqMinMax(1) && centA(2)<=freqMinMax(2) && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2) && normS1(round(cent(2)),round(cent(1)))>0
                    bData = emotionTaskLFP.byemotion.(chNum{cc}).image.bandPassed.(bandNames{6}){2};
                    for jj = 1:size(bData,1)
                        RecordingLocation(jj,1) = chName{cc};
                        ChannelNumber{jj,1} = chNum{cc};
                        PatientName{jj,1} =  patientName;
                        TrialType{jj,1} = 'emotionTask';
                        TimeMinMax(jj,:) = timeMinMax;
                        FreqMinMax(jj,:) = freqMinMax;
                        ClusterCenter(jj,:) = centA;
                        TstatCluster(jj,1) = nback.(chNum{cc}).(conditionName{nn}).(resultName{10})(ii,1); %if it's gamma, grab that tstat
                        ImageType{jj,1} = (conditionName{nn});
                        [MaxValue(jj,1), pkIndex] = max(bData(jj,tMinBand:tMaxBand));
                        TimeofMax(jj,1) = (pkIndex + tMinBand)/1000; %get the peak time of the filtered and adjust to ms
                        SecondTrial(jj,1) = emotionTaskLFP.secondTrial;
                        CorrectResponse(jj,1) = emotionTaskLFP.byemotion.(chNum{cc}).correctTrial{idx2}(jj);
                        ResponseTime(jj,1) = emotionTaskLFP.byemotion.(chNum{cc}).responseTimesInSec{idx2}(jj);
                    end
                    T1 = table(PatientName, RecordingLocation, ChannelNumber, TrialType, TimeMinMax, FreqMinMax, ImageType, ClusterCenter, TstatCluster,  MaxValue, TimeofMax,...
                        CorrectResponse, ResponseTime, SecondTrial); 
                end
            end
        end
        T2 = [T2; T1];        
        idx2 = idx2+1;
    end    
end
summaryStats = T2;


end