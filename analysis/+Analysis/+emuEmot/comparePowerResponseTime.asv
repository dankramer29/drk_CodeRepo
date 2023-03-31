function [RTDEsec, RTDIsec, summaryStats] = comparePowerResponseTime(nback, identityTaskLFP, emotionTaskLFP, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%   ALSO WANT TO LOOK AT THE TIMING OF THE PEAKS FOR WHEN TASK RELEVANT AND
%   TASK IRRELEVANT

[varargin, plt]=util.argkeyval('plt', varargin, 1); %toggle on or off if you want to plot
[varargin, responseTime]=util.argkeyval('responseTime', varargin, []); %Include the response times
[varargin, timeMinMax]=util.argkeyval('timeMin', varargin, [.100 .700]); %Time, in S, that you want to find the peaks between 
[varargin, freqMinMax]=util.argkeyval('freqMinMax', varargin, [50 150]); %Freq, that you want to find the peaks between 
[varargin, chName]=util.argkeyval('chName', varargin, 'chX'); %for arranging the outputs by channel


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

%% check that both trials are even
%convert to seconds (was in micro seconds to adjust with neural clock)
RTDsec = responseTime/1e6;
%remove the nan from first trial
RTDsec(1,:) = [];
RTDEsec = RTDsec(:,1);
RTDIsec = RTDsec(:,2);


[pos, summaryStats.ReactionTimespValueOfComparisonBetweenTasks, ci, stats] = ttest(RTDEsec, RTDIsec);

%% find the indices of the times in bandpassed
[~, tMinBand] = min(abs(bTT-timeMinMax(1)));
[~, tMaxBand] = min(abs(bTT-timeMinMax(2)));

%%
%look at high gamma for areas that were positive
%NOTE: THIS IS GOING TO KEEP IT TASK RELEVANT RIGHT NOW MEANING ONLY
%   LOOKING AT IDS FOR THE IDENTITY TASK AND EMOTIONS FOR THE EMOTION TASK

for cc = 1:length(chNum)
    %identity task
    T1 = []; T2 = [];
    clusterCenter = [];
    tstatCluster = [];
    imageType = [];
    MaxValue =[];
    pkIndex = [];
    TimeofMax=[];
    CorrectResponseId = [];
    ResponseTimeId = [];
    SecondTrial = [];
    idx2 = 1;   
    for nn = 1:3  %runs through each id      
        T1 = [];
        clusterCenter = [];
        tstatCluster = [];
        imageType = [];
        MaxValue =[];
        pkIndex = [];
        TimeofMax=[];
        CorrectResponseEm = [];
        ResponseTimeEm = [];
        SecondTrial = [];
        CorrectResponseTemp = identityTaskLFP.byemotion.(chNum{cc}).correctTrial{idx2};
        ResponseTimeTemp = identityTaskLFP.byemotion.(chNum{cc}).responseTimesInSec{idx2};
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
                if centA(2)>=freqMinMax(1) && centA(2)<=freqMinMax(2) && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2) && normS1(round(cent(2)),round(cent(1)))>0
                    bData = identityTaskLFP.byidentity.(chNum{cc}).image.bandPassed.(bandNames{6}){idx2};
                    meanbData = mean(bData,1);
                    figure; plot(bTT,normalize(meanbData), 'LineWidth', 3); hold on; plot(bTT,normalize(bData,2))
                    figure; imagesc(tt,ff, normalize(nback.(chNum{cc}).(conditionName{nn}).(resultName{1}),2)); axis xy
                    hold on; plot(centA(1), centA(2), '*b');
                    for jj = 1:size(bData,1)
                        clusterCenter(jj,:) = centA;
                        tstatCluster(jj,1) = nback.(chNum{cc}).(conditionName{nn}).(resultName{5})(ii,1); %if it's gamma, grab that tstat
                        imageType{jj,1} = (conditionName{nn});
                        [MaxValue(jj,1), pkIndex] = max(bData(jj,tMinBand:tMaxBand));
                        TimeofMax(jj,1) = (pkIndex + tMinBand)/1000; %get the peak time of the filtered and adjust to ms                     
                        SecondTrial(jj,1) = identityTaskLFP.secondTrial;
                        CorrectResponse(jj,1) = identityTaskLFP.byemotion.(chNum{cc}).correctTrial{idx2}(jj);
                        ResponseTime(jj,1) = identityTaskLFP.byemotion.(chNum{cc}).responseTimesInSec{idx2}(jj);
                        RecordingLocation(jj,1) = chName{cc};
                        jj = jj + 1;
                    end
                    [rval pval]=corr(TimeofMax, ResponseTime); 
                    RhoPeakXResponseTime(1:size(bData,1),1) = rval;
                    pPeakXResponseTime(1:size(bData,1),1) = pval;
                    T1 = table(RecordingLocation, imageType, clusterCenter, tstatCluster,  MaxValue, TimeofMax,...
                        CorrectResponse, ResponseTime, SecondTrial, RhoPeakXResponseTime,...
                        pPeakXResponseTime);
                end
            end
        end
        T2 = [T2; T1];        
        idx2 = idx2+1;
    end
    summaryStats.(chNum{cc}).identityTask = T2;
    %% emotion task
    T3 = [];    
    idx2 = 1;   
    for nn = 1:3 %runs through each emotion
        T1 = [];
        clusterCenter = [];
        tstatCluster = [];
        imageType = [];
        MaxValue =[];
        pkIndex = [];
        TimeofMax=[];
        CorrectResponseEm = [];
        ResponseTimeEm = [];
        SecondTrial = [];
        CorrectResponseTemp = identityTaskLFP.byemotion.(chNum{cc}).correctTrial{idx2};
        ResponseTimeTemp = identityTaskLFP.byemotion.(chNum{cc}).responseTimesInSec{idx2};
        CorrectResponseEm = vertcat(CorrectResponseEm, CorrectResponseTemp);
        ResponseTimeEm = vertcat(ResponseTimeEm, ResponseTimeTemp);        
        if nnz(nnz(nback.(chNum{cc}).(conditionName{nn}).(resultName{8})))>0
            for ii = 1:size(nback.(chNum{cc}).(conditionName{nn}).(resultName{9}),1)
                %check the centroid is in the high gamma range in the
                %region after image presentation
                cent = nback.(chNum{cc}).(conditionName{nn}).(resultName{9})(ii,:);
                centA(1) = tt(round(cent(1))); centA(2) = ff(round(cent(2)));
                normS1 = normalize(nback.(chNum{cc}).(conditionName{nn}).(resultName{6}),2);
                if centA(2)>=freqMinMax(1) && centA(2)<=freqMinMax(2) && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2) && normS1(round(cent(2)),round(cent(1)))>0
                    bData = identityTaskLFP.byemotion.(chNum{cc}).image.bandPassed.(bandNames{6}){2};
                    for jj = 1:size(bData,1)
                        clusterCenter(jj,:) = centA;
                        tstatCluster(jj,1) = nback.(chNum{cc}).(conditionName{nn}).(resultName{10})(ii,1); %if it's gamma, grab that tstat
                        imageType{jj,1} = (conditionName{nn});
                        [MaxValue(jj,1), pkIndex] = max(bData(jj,tMinBand:tMaxBand));
                        TimeofMax(jj,1) = (pkIndex + tMinBand)/1000; %get the peak time of the filtered and adjust to ms
                        SecondTrial(jj,1) = identityTaskLFP.secondTrial;
                        CorrectResponse(jj,1) = identityTaskLFP.byemotion.(chNum{cc}).correctTrial{idx2}(jj);
                        ResponseTime(jj,1) = identityTaskLFP.byemotion.(chNum{cc}).responseTimesInSec{idx2}(jj);
                        RecordingLocation(jj,1) = chName{cc};
                    end
                    [rval pval]=corr(TimeofMax, ResponseTime);
                    RhoPeakXResponseTime(1:size(bData,1),1) = rval;
                    pPeakXResponseTime(1:size(bData,1),1) = pval;
                    T1 = table(RecordingLocation, imageType, clusterCenter, tstatCluster,  MaxValue, TimeofMax,...
                        CorrectResponse, ResponseTime, SecondTrial, RhoPeakXResponseTime,...
                        pPeakXResponseTime);
                end
            end
        end
        T3 = [T3; T1];        
        idx2 = idx2+1;
    end
    summaryStats.(chNum{cc}).emotionTask = T3;
    [clusterPeakTimingTaskComparisonpValue, h, stats] = ranksum(T2.TimeofMax, T3.TimeofMax);
    summaryStats.(chNum{cc}).PeakTimingTaskComparison = tstatTaskComparison;
    TimeofMax = vertcat(T2.TimeofMax, T3.TimeofMax);
    ResponseTime = vertcat(T2.ResponseTime, T3.ResponseTime);
    [rval pval]=corr(TimeofMax, ResponseTime);
    summaryStats.(chNum{cc}).RhoPeakXResponseTime = rval;
    summaryStats.(chNum{cc}).pPeakXResponseTime = pval;
    
end
%% create comparisons
%compare the reaction times to correct trial response
summaryStats.ReactionTimeAll = vertcat(ResponseTimeId, ResponseTimeEm);
correctResponseTemp = vertcat(CorrectResponseId, CorrectResponseEm);
correctResponseAll(1:size(correctResponseTemp),1) = {'Correct'};
correctResponseAll(correctResponseTemp == 0,1) = {'Incorrect'};
summaryStats.CorrectResponseAll = correctResponseAll;
[summaryStats.ReactionTimevCorrectResponse.pval, summaryStats.ReactionTimevCorrectResponse.tbl,...
    summaryStats.ReactionTimevCorrectResponse.stats] = kruskalwallis(summaryStats.ReactionTimeAll, summaryStats.CorrectResponseAll);
ax = gca;
ylabel('Response Time (s)')
ax.FontSize = 22;



if plt
    figure
    boxplot([RTDEsec, RTDIsec])
    xticklabels({'Emotion Task', 'Identity Task'});
    ylabel('Seconds')
    title('Response Times')
    set(gca, 'fontsize', 13)
end


end