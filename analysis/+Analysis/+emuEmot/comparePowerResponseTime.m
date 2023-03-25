function [RTDEsec, RTDIsec, summaryStats] = comparePowerResponseTime(nback, identityTaskLFP, emotionTaskLFP, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%   ALSO WANT TO LOOK AT THE TIMING OF THE PEAKS FOR WHEN TASK RELEVANT AND
%   TASK IRRELEVANT

[varargin, plt]=util.argkeyval('plt', varargin, 1); %toggle on or off if you want to plot
[varargin, responseTime]=util.argkeyval('responseTime', varargin, []); %Include the response times
[varargin, timeMinMax]=util.argkeyval('timeMin', varargin, [.100 .700]); %Time, in S, that you want to find the gamma peaks between 


summaryStats = struct;

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


[pos, summaryStats.ReactionTimesEmotTaskvIdTask, ci, stats] = ttest(RTDEsec, RTDIsec);

%% find the indices of the times in bandpassed
[~, tMinBand] = min(abs(bTT-timeMinMax(1)));
[~, tMaxBand] = min(abs(bTT-timeMinMax(2)));

%%
%look at high gamma for areas that were positive
%NOTE: THIS IS GOING TO KEEP IT TASK RELEVANT RIGHT NOW MEANING ONLY
%   LOOKING AT IDS FOR THE IDENTITY TASK AND EMOTIONS FOR THE EMOTION TASK

for cc = 1:length(chNum)
    idx1 = 1; idx2 = 1; idx3 = 1;
    for nn = 1:3
        %identity task
        if nnz(nnz(nback.(chNum{cc}).(conditionName{nn}).(resultName{3})))>0
            for ii = 1:size(nback.(chNum{cc}).(conditionName{nn}).(resultName{4}),1)
                %check the centroid is in the high gamma range in the
                %region after image presentation
                cent = nback.(chNum{cc}).(conditionName{nn}).(resultName{4})(ii,:);                
                centA(1) = tt(round(cent(1))); centA(2) = ff(round(cent(2)));
                if centA(2)>=50 && centA(2)<=150 && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2)
                    gammaCentIdTask(idx1,:) = centA;
                    tstatGammaIdTask(idx1) = nback.(chNum{cc}).(conditionName{nn}).(resultName{5})(ii,1); %if it's gamma, grab that tstat
                    imageTypeIdTask{idx1,1} = (conditionName{nn});
                    idx1 = idx1+1;
                    bData = identityTaskLFP.byidentity.(chNum{cc}).image.bandPassed.(bandNames{6}){nn};
                    for jj = 1:size(bData,1)
                        [MaxValueIdTask(idx3,1), pkIndex] = max(bData(jj,tMinBand:tMaxBand));
                        MaxTimeIdTask(idx3,1) = pkIndex + tMinBand;
                        CorrectResponseIdTask(idx3) = identityTaskLFP.byidentity.(chNum{cc}).correctTrial{nn}(jj);
                        ResponseTimeIdTask(idx3) = identityTaskLFP.byidentity.(chNum{cc}).responseTimesInSec{nn}(jj);
                        SecondTrialIdTask(idx3) = identityTaskLFP.secondTrial;
                        idx3 = idx3 + 1;
                    end
                end
            end
        end
    end
    idx1 = 1; idx2 = 1; idx3 = 1;
    for nn = 5:7
        %emotion task
        if nnz(nnz(nback.(chNum{cc}).(conditionName{nn}).(resultName{8})))==0
            for ii = 1:size(nback.(chNum{cc}).(conditionName{nn}).(resultName{9}),1)
                %check the centroid is in the high gamma range in the
                %region after image presentation
                cent = nback.(chNum{cc}).(conditionName{nn}).(resultName{9})(ii,:);
                centA(1) = tt(round(cent(1))); centA(2) = ff(round(cent(2)));
                if centA(2)>=50 && centA(2)<=150 && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2)
                    gammaCentEmTask(idx1,:) = centA;
                    tstatGammaEmTask(idx1) = nback.(chNum{cc}).(conditionName{nn}).(resultName{10})(ii,1); %if it's gamma, grab that tstat
                    imageTypeEmTask{idx1,1} = (conditionName{nn});
                    idx1 = idx1+1;
                    bData = emotionTaskLFP.byemotion.(chNum{cc}).image.bandPassed.(bandNames{6}){idx2};
                    for jj = 1:size(bData,1)
                        [MaxValueEmtask(idx3,1), pkIndex] = max(bData(jj,tMinBand:tMaxBand));
                        MaxTimeEmTask(idx3,1) = pkIndex + tMinBand;
                        CorrectResponseEmTask(idx3) = identityTaskLFP.byemotion.(chNum{cc}).correctTrial{idx2}(jj);
                        ResponseTimeEmTask(idx3) = identityTaskLFP.byemotion.(chNum{cc}).responseTimesInSec{idx2}(jj);
                        SecondTrialEmTask(idx3) = identityTaskLFP.secondTrial;
                        idx3 = idx3 + 1;
                    end
                end
            end
        end
        idx2 = idx2+1;
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