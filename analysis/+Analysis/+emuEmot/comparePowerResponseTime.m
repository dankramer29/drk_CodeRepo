function [RTDEsec, RTDIsec, summaryStats] = comparePowerResponseTime(nback, identityTaskLFP, emotionTaskLFP, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%   ALSO WANT TO LOOK AT THE TIMING OF THE PEAKS FOR WHEN TASK RELEVANT AND
%   TASK IRRELEVANT

[varargin, plt]=util.argkeyval('plt', varargin, 1); %toggle on or off if you want to plot
[varargin, responseTime]=util.argkeyval('responseTime', varargin, []); %Include the response times
[varargin, timeMinMax]=util.argkeyval('timeMin', varargin, [.100 .700]); %Time, in S, that you want to find the peaks between 
[varargin, freqMinMax]=util.argkeyval('freqMinMax', varargin, [50 150]); %Freq, that you want to find the peaks between 


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


[pos, summaryStats.ReactionTimesEmTvIdTPval, ci, stats] = ttest(RTDEsec, RTDIsec);

%% find the indices of the times in bandpassed
[~, tMinBand] = min(abs(bTT-timeMinMax(1)));
[~, tMaxBand] = min(abs(bTT-timeMinMax(2)));

%%
%look at high gamma for areas that were positive
%NOTE: THIS IS GOING TO KEEP IT TASK RELEVANT RIGHT NOW MEANING ONLY
%   LOOKING AT IDS FOR THE IDENTITY TASK AND EMOTIONS FOR THE EMOTION TASK

for cc = 1:length(chNum)
    %identity task
    idx1 = 1; 
    clear T1; clear T2
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
    idx1 = 1; idx2 = 1;
    for nn = 1:3
        CorrectResponseTemp = identityTaskLFP.byemotion.(chNum{cc}).correctTrial{idx2};
        ResponseTimeTemp = identityTaskLFP.byemotion.(chNum{cc}).responseTimesInSec{idx2};
        CorrectResponseId = vertcat(CorrectResponseId, CorrectResponseTemp);
        ResponseTimeId = vertcat(ResponseTimeId, ResponseTimeTemp);   
        %emotion task
        if nnz(nnz(nback.(chNum{cc}).(conditionName{nn}).(resultName{3})))>0
            for ii = 1:size(nback.(chNum{cc}).(conditionName{nn}).(resultName{4}),1)
                %check the centroid is in the high gamma range in the
                %region after image presentation
                cent = nback.(chNum{cc}).(conditionName{nn}).(resultName{4})(ii,:);
                centA(1) = tt(round(cent(1))); centA(2) = ff(round(cent(2)));
                if centA(2)>=50 && centA(2)<=150 && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2)
                    bData = identityTaskLFP.byidentity.(chNum{cc}).image.bandPassed.(bandNames{6}){idx2};
                    for jj = 1:size(bData,1)
                        clusterCenter(idx1,:) = centA;
                        tstatCluster(idx1,1) = nback.(chNum{cc}).(conditionName{nn}).(resultName{5})(ii,1); %if it's gamma, grab that tstat
                        imageType{idx1,1} = (conditionName{nn});
                        [MaxValue(idx1,1), pkIndex] = max(bData(jj,tMinBand:tMaxBand));
                        TimeofMax(idx1,1) = (pkIndex + tMinBand)/1000; %get the peak time of the filtered and adjust to ms                     
                        SecondTrial(idx1,1) = identityTaskLFP.secondTrial;
                        idx1 = idx1 + 1;
                    end
                    [rval pval]=corr(TimeofMax, ResponseTime); %NEED TO FIX THIS, DECIDE IF RESPONSE TIME FOR JUST THIS TRIAL IS WORTH IT, OR COMBINE
                    RhoPeakXResponseTime(1:size(bData,1),1) = rval;
                    pPeakXResponseTime(1:size(bData,1),1) = pval;
                    T1 = table(clusterCenter, tstatCluster, imageType, MaxValue, TimeofMax,...
                        CorrectResponse, ResponseTime, SecondTrial, RhoPeakXResponseTime,...
                        pPeakXResponseTime);
                end
            end
        end
        T2 = [T1; T2];        
        idx2 = idx2+1;
    end
    T = table(clusterCenter, tstatCluster,imageType, MaxValue, TimeofMax, CorrectResponse,ResponseTime,SecondTrial);
    summaryStats.(chNum{cc}).identityTask = T2;
    clear T;
    T = [];
    clusterCenter = [];
    tstatCluster = [];
    imageType = [];
    MaxValue =[];
    pkIndex = [];
    TimeofMax=[];
    CorrectResponseEm = [];
    ResponseTimeEm = [];
    SecondTrial = [];
    idx1 = 1; idx2 = 1;
    for nn = 5:7
        CorrectResponseTemp = identityTaskLFP.byemotion.(chNum{cc}).correctTrial{idx2};
        ResponseTimeTemp = identityTaskLFP.byemotion.(chNum{cc}).responseTimesInSec{idx2};
        CorrectResponseEm = vertcat(CorrectResponseEm, CorrectResonseTemp);
        ResponseTimeEm = vertcat(ResponseTimeEm, ResponseTimeTemp);   
        %emotion task
        if nnz(nnz(nback.(chNum{cc}).(conditionName{nn}).(resultName{8})))>0
            for ii = 1:size(nback.(chNum{cc}).(conditionName{nn}).(resultName{9}),1)
                %check the centroid is in the high gamma range in the
                %region after image presentation
                cent = nback.(chNum{cc}).(conditionName{nn}).(resultName{9})(ii,:);
                centA(1) = tt(round(cent(1))); centA(2) = ff(round(cent(2)));
                if centA(2)>=50 && centA(2)<=150 && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2)
                    bData = emotionTaskLFP.byemotion.(chNum{cc}).image.bandPassed.(bandNames{6}){idx2};
                    for jj = 1:size(bData,1)
                        clusterCenter(idx1,:) = centA;
                        tstatCluster(idx1,1) = nback.(chNum{cc}).(conditionName{nn}).(resultName{10})(ii,1); %if it's gamma, grab that tstat
                        imageType{idx1,1} = (conditionName{nn});
                        [MaxValue(idx1,1), pkIndex] = max(bData(jj,tMinBand:tMaxBand));
                        TimeofMax(idx1,1) = pkIndex + tMinBand;                        
                        SecondTrial(idx1,1) = identityTaskLFP.secondTrial;
                        idx1 = idx1 + 1;
                    end
                    [rval pval]=corr(TimeofMax, ResponseTime);
                    RhoPeakXResponseTime(1:size(bData,1),1) = rval;
                    pPeakXResponseTime(1:size(bData,1),1) = pval;
                    T = table(clusterCenter, tstatCluster, imageType, MaxValue, TimeofMax,...
                        CorrectResponse, ResponseTime, SecondTrial, RhoPeakXResponseTime,...
                        pPeakXResponseTime);
                end
            end
        end    
        summaryStats.(chNum{cc}).emotionTask = T;
        idx2 = idx2+1;
    end
    if cc == 1
        %compare the reaction times to correct trial response
        summaryStats.ReactionTimeAll = vertcat(ReactionTimeId, ReactionTimeEm);
        summaryStats.CorrectResponseAll = vertcat(CorrectResponseId, CorrectResponseEm);
        [summaryStats.ReactionTimevCorrectResponse.pval, summaryStats.ReactionTimevCorrectResponse.tbl,...
            summaryStats.ReactionTimevCorrectResponse.stats] = kruskalwallis(ReactionTimeAll, CorrectResponseAll);
    end
end




if plt
    figure
    boxplot([RTDEsec, RTDIsec])
    xticklabels({'Emotion Task', 'Identity Task'});
    ylabel('Seconds')
    title('Response Times')
    set(gca, 'fontsize', 13)
end


end